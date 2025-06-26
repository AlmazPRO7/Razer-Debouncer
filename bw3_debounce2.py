#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
bw3_debounce.py – v3.7  (Windows 10/11, Python 3.11+)
Полностью подавляет дребезг и ложные повторы клавиш.
"""

import os, sys, json, time, threading, statistics, argparse, ctypes, logging, keyboard
from ctypes import wintypes
from logging.handlers import RotatingFileHandler
from PIL import Image, ImageDraw
import pystray

# ─────────────── WinAPI константы и типы ────────────────────────────────
WH_KEYBOARD_LL               = 13
WM_KEYDOWN, WM_KEYUP         = 0x0100, 0x0101
WM_SYSKEYDOWN, WM_SYSKEYUP   = 0x0104, 0x0105

LRESULT   = ctypes.c_ssize_t
ULONG_PTR = ctypes.c_void_p
LPARAM    = ctypes.c_void_p

class KBDLLHOOKSTRUCT(ctypes.Structure):
    _fields_ = [("vkCode",      wintypes.DWORD),
                ("scanCode",    wintypes.DWORD),
                ("flags",       wintypes.DWORD),
                ("time",        wintypes.DWORD),
                ("dwExtraInfo", ULONG_PTR)]

user32   = ctypes.WinDLL("user32",   use_last_error=True)
kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)

# корректные сигнатуры — иначе OverflowError на 64‑битах
user32.SetWindowsHookExW.argtypes  = [wintypes.INT, ULONG_PTR,
                                      wintypes.HINSTANCE, wintypes.DWORD]
user32.SetWindowsHookExW.restype   = ULONG_PTR
user32.CallNextHookEx.argtypes     = [ULONG_PTR, wintypes.INT,
                                      wintypes.WPARAM, LPARAM]
user32.CallNextHookEx.restype      = LRESULT
user32.UnhookWindowsHookEx.argtypes= [ULONG_PTR]
user32.UnhookWindowsHookEx.restype = wintypes.BOOL
user32.GetMessageW.argtypes        = [ctypes.POINTER(wintypes.MSG),
                                      wintypes.HWND, wintypes.UINT,
                                      wintypes.UINT]
user32.GetMessageW.restype         = wintypes.BOOL

# ─────────────── файлы и лог ────────────────────────────────────────────
APPDATA  = os.getenv("APPDATA") or os.path.expanduser("~\\AppData\\Roaming")
CFG_PATH = os.path.join(APPDATA, "bw3_chatter_cfg.json")
LOG_PATH = os.path.join(APPDATA, "bw3_chatter.log")

logger = logging.getLogger("bw3")
logger.setLevel(logging.INFO)
RotatingFileHandler(LOG_PATH, 512*1024, 3, encoding="utf-8").setFormatter(
    logging.Formatter("%(asctime)s  %(message)s"))
logger.addHandler(logging.StreamHandler(sys.stdout))  # видно при --debug

def load_cfg():
    try:  return json.load(open(CFG_PATH, encoding="utf-8"))
    except FileNotFoundError: return {}
def save_cfg(c): json.dump(c, open(CFG_PATH,"w",encoding="utf-8"),
                           indent=2, ensure_ascii=False)

# ─────────────── админ‑права и автозапуск ───────────────────────────────
def is_admin():
    try: return ctypes.windll.shell32.IsUserAnAdmin()
    except: return False
def elevate():
    ctypes.windll.shell32.ShellExecuteW(
        None, "runas", sys.executable,
        " ".join(['"'+os.path.abspath(__file__)+'"']+sys.argv[1:]),
        None, 1); sys.exit()

def set_autostart(on=True):
    import winreg
    key=r"Software\Microsoft\Windows\CurrentVersion\Run"
    with winreg.OpenKey(winreg.HKEY_CURRENT_USER, key, 0, winreg.KEY_ALL_ACCESS) as rk:
        name="BW3Debounce"
        if on:
            winreg.SetValueEx(rk, name, 0, winreg.REG_SZ,
                f'"{sys.executable}" "{os.path.abspath(__file__)}"')
        else:
            try: winreg.DeleteValue(rk, name)
            except FileNotFoundError: pass

# ─────────────── Debouncer ──────────────────────────────────────────────
class Debouncer:
    MAX_MS, STEP_MS, BURST = 150, 10, 3   # агрессивная адаптация
    def __init__(self, base_ms=100, debug=False):
        self.base = base_ms/1000.0
        self.th   = load_cfg()
        self.last = {}
        self.cnt  = {}
        self.pressed=set()
        self.cal=None
        self.debug=debug
    def win(self, sc): return self.th.get(sc, self.base)

# ─────────────── глобальные ссылки ──────────────────────────────────────
hook_id   = ULONG_PTR(0)
hook_proc = None

def install_hook(deb: Debouncer):
    global hook_proc
    HOOKPROC = ctypes.WINFUNCTYPE(LRESULT, wintypes.INT,
                                  wintypes.WPARAM, LPARAM)

    @HOOKPROC
    def low_level(nCode, wParam, lParam):
        if nCode==0:
            ks = ctypes.cast(lParam, ctypes.POINTER(KBDLLHOOKSTRUCT)).contents
            sc = str(ks.scanCode); now=time.perf_counter()

            if wParam in (WM_KEYDOWN, WM_SYSKEYDOWN):
                if sc in deb.pressed:        # повтор без UP → блок
                    logger.info("BLOCK_STATE %s", sc)
                    if deb.debug: print("BLOCK_STATE", sc)
                    return 1

                if sc not in deb.last:       # первый нормальный DOWN
                    deb.last[sc]=now; deb.pressed.add(sc)
                    return user32.CallNextHookEx(hook_id, nCode, wParam, lParam)

                dt=now-deb.last[sc]
                if deb.cal is not None: deb.cal.append(dt*1000)

                if dt < deb.win(sc):         # дребезг
                    deb.cnt[sc]=deb.cnt.get(sc,0)+1
                    if deb.cnt[sc]%deb.BURST==0 and deb.win(sc)*1000<deb.MAX_MS:
                        deb.th[sc]=min(deb.MAX_MS/1000,
                                       deb.win(sc)+deb.STEP_MS/1000)
                        save_cfg(deb.th)
                    logger.info("BLOCK_BOUNCE %s Δ%.1f ms", sc, dt*1000)
                    if deb.debug: print(f"BLOCK_BOUNCE {sc} Δ{dt*1000:.1f} ms")
                    return 1

                # корректное нажатие
                deb.last[sc]=now; deb.pressed.add(sc)
                if sc in deb.th and deb.th[sc]-deb.base>0.002:
                    deb.th[sc]-=.002
                if deb.debug: print(f"DOWN {sc} Δ{dt*1000:.1f} ms")

            elif wParam in (WM_KEYUP, WM_SYSKEYUP):
                deb.pressed.discard(sc)

        return user32.CallNextHookEx(hook_id, nCode, wParam, lParam)

    hook_proc = low_level
    return user32.SetWindowsHookExW(WH_KEYBOARD_LL, hook_proc, 0, 0)

# ─────────────── трей‑GUI ───────────────────────────────────────────────
def tray(deb):
    global hook_id
    icon = pystray.Icon("BW‑Debounce")
    img  = Image.new("RGBA",(64,64),(0,0,0,0))
    d    = ImageDraw.Draw(img)
    d.rectangle((8,24,56,40),fill="white"); d.text((18,18),"⌨",fill="black")
    icon.icon=img; icon.title="BW3 Debounce (вкл)"

    def toggle(_):
        global hook_id
        if hook_id:
            user32.UnhookWindowsHookEx(hook_id); hook_id=ULONG_PTR(0)
            icon.title="BW3 Debounce (выкл)"
        else:
            hook_id = install_hook(deb)
            if not hook_id:
                icon.notify(f"Hook error {ctypes.get_last_error()}")
            else:
                icon.title="BW3 Debounce (вкл)"

    def calibrate(_):
        deb.cal=[]; icon.title="Калибровка… Esc для выхода"
        keyboard.wait('esc')
        if len(deb.cal)>=5:
            med=statistics.median(deb.cal); sc=list(deb.last)[-1]
            deb.th[sc]=max(deb.base, med/1000+0.005); save_cfg(deb.th)
            icon.notify(f"Порог {sc}= {deb.th[sc]*1000:.1f} мс")
        deb.cal=None; icon.title="BW3 Debounce (вкл)"

    icon.menu=pystray.Menu(
        pystray.MenuItem("Вкл/Выкл", toggle, default=True),
        pystray.MenuItem("Калибровать…", calibrate),
        pystray.MenuItem("Открыть лог", lambda *_: os.startfile(LOG_PATH)),
        pystray.MenuItem("Выход", lambda *_:(icon.stop(), sys.exit())))
    icon.run()

# ─────────────── Main ───────────────────────────────────────────────────
def main():
    global hook_id
    ap = argparse.ArgumentParser()
    ap.add_argument("--ms", type=int, default=100,
        help="Базовое окно, мс (по умолч. 100)")
    ap.add_argument("--debug", action="store_true",
        help="Печатать блокировки/нажатия в консоль")
    ap.add_argument("--no-startup", action="store_true",
        help="Не добавлять скрипт в автозапуск")
    args = ap.parse_args()

    if not is_admin(): elevate()
    if not args.no_startup: set_autostart(True)
    deb = Debouncer(args.ms, args.debug)

    hook_id = install_hook(deb)
    if not hook_id:
        print("SetWindowsHookEx failed →", ctypes.get_last_error())
        sys.exit(1)
    print("Hook ID =", int(hook_id))
    threading.Thread(target=tray, args=(deb,), daemon=True).start()
    print("Started message loop…")

    msg = wintypes.MSG()
    while user32.GetMessageW(ctypes.byref(msg), None, 0, 0) != 0:
        user32.TranslateMessage(ctypes.byref(msg))
        user32.DispatchMessageW(ctypes.byref(msg))

if __name__ == "__main__":
    main()
