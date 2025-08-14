#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
bw3_debounce.py – v4.6  (2025‑08‑09)

• Надёжное подавление дребезга одиночных клавиш.
• Корректная работа сочетаний (Ctrl/Shift/Alt/Win + …) — мгновенный отклик.
• Нормальный автоповтор при удержании (Backspace/стрелки/Tab и т.д.).
• Мягкая обработка модификаторов: пред‑повторная задержка к ним не применяется.
"""

import os, sys, json, time, threading, statistics, argparse, ctypes, logging
from ctypes import wintypes
from logging.handlers import RotatingFileHandler
# Ленивая загрузка GUI/иконок: в self-test/WSL они не нужны
try:
    from PIL import Image, ImageDraw
except Exception:
    Image = ImageDraw = None
try:
    import pystray
except Exception:
    pystray = None
try:
    import tkinter as tk
    from tkinter import ttk
except Exception:
    tk = ttk = None

# ───────── WinAPI ─────────
WH_KEYBOARD_LL = 13
WM_KEYDOWN, WM_KEYUP       = 0x0100, 0x0101
WM_SYSKEYDOWN, WM_SYSKEYUP = 0x0104, 0x0105

LRESULT   = ctypes.c_ssize_t
ULONG_PTR = ctypes.c_void_p
LPARAM    = ctypes.c_void_p
SHORT     = ctypes.c_short

VK_ESCAPE = 0x1B

class KBDLLHOOKSTRUCT(ctypes.Structure):
    _fields_ = [("vkCode",      wintypes.DWORD),
                ("scanCode",    wintypes.DWORD),
                ("flags",       wintypes.DWORD),
                ("time",        wintypes.DWORD),
                ("dwExtraInfo", ULONG_PTR)]

user32 = None

def _init_winapi():
    global user32
    if user32 is not None:
        return True
    try:
        user32 = ctypes.WinDLL("user32", use_last_error=True)
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
        user32.GetAsyncKeyState.argtypes   = [wintypes.INT]
        user32.GetAsyncKeyState.restype    = SHORT
        return True
    except Exception:
        user32 = None
        return False

# ───────── файлы/лог ─────────
APPDATA = os.getenv("APPDATA") or os.path.expanduser("~\\AppData\\Roaming")
# В не-Windows окружениях создадим локальную папку, чтобы логгер не падал
try:
    os.makedirs(APPDATA, exist_ok=True)
except Exception:
    pass
CFG = os.path.join(APPDATA, "bw3_chatter_cfg.json")
LOG = os.path.join(APPDATA, "bw3_chatter.log")
PREFS = os.path.join(APPDATA, "bw3_chatter_prefs.json")

logger = logging.getLogger("bw3")
logger.setLevel(logging.INFO)
_rot = RotatingFileHandler(LOG, 512*1024, 3, encoding="utf-8")
_rot.setFormatter(logging.Formatter("%(asctime)s  %(message)s"))
logger.addHandler(_rot)
logger.addHandler(logging.StreamHandler(sys.stdout))

# ───────── утилиты ─────────
def load_cfg():
    try: return json.load(open(CFG, encoding="utf-8"))
    except: return {}

def save_cfg(d):
    try: json.dump(d, open(CFG,"w",encoding="utf-8"), indent=2, ensure_ascii=False)
    except: pass

def load_prefs():
    try: return json.load(open(PREFS, encoding="utf-8"))
    except: return {}

def save_prefs(d):
    try: json.dump(d, open(PREFS,"w",encoding="utf-8"), indent=2, ensure_ascii=False)
    except: pass

def is_admin():
    try: return ctypes.windll.shell32.IsUserAnAdmin()
    except: return False

def elevate():
    ctypes.windll.shell32.ShellExecuteW(
        None,"runas",sys.executable,
        f'"{os.path.abspath(__file__)}" {" ".join(sys.argv[1:])}',
        None,1); sys.exit()

def set_autostart(on=True):
    import winreg
    key=r"Software\Microsoft\Windows\CurrentVersion\Run"
    with winreg.OpenKey(winreg.HKEY_CURRENT_USER,key,0,winreg.KEY_ALL_ACCESS) as rk:
        name="BW3Debounce"
        if on:
            winreg.SetValueEx(rk,name,0,winreg.REG_SZ,
                f'"{sys.executable}" "{os.path.abspath(__file__)}"')
        else:
            try: winreg.DeleteValue(rk,name)
            except FileNotFoundError: pass

def read_system_repeat_delay_ms(default_ms=250):
    """HKCU\Control Panel\Keyboard\KeyboardDelay: 0..3 → ~{250,500,750,1000} мс."""
    try:
        import winreg
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Control Panel\Keyboard") as k:
            v, _ = winreg.QueryValueEx(k, "KeyboardDelay")
            i = max(0, min(3, int(str(v).strip())))
            return 250 * (i + 1)
    except:
        return default_ms

def read_system_repeat_interval_ms(default_ms=33):
    """HKCU\Control Panel\Keyboard\KeyboardSpeed: 0..31 → ~400..33 ms между повторами.
    Линеаризуем по интервалу: 0→400ms, 31→33ms. Возвращаем (interval_ms, step).
    """
    try:
        import winreg
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Control Panel\Keyboard") as k:
            v, _ = winreg.QueryValueEx(k, "KeyboardSpeed")
            s = max(0, min(31, int(str(v).strip())))
            interval = int(round(400 - (367 * (s / 31.0))))
            interval = max(33, min(400, interval))
            return interval, s
    except:
        return default_ms, None

# ───────── Debouncer ─────────
class Debouncer:
    """
    • Первое нажатие любой клавиши → сразу пропускаем (важно для аккордов).
    • До системной задержки авто‑повтора: режем только настоящий дребезг.
    • После задержки авто‑повтора: пропускаем повторы, но не чаще repeat_min.
    • Модификаторы (Ctrl/Shift/Alt/Win) НЕ проверяются на «пред‑повторную» задержку,
      только на узкое окно явного дребезга (mod_bounce_ms), чтобы комбинации были мгновенными.
    • Состояние синхронизируется с GetAsyncKeyState, чтобы гасить залипания.
    """
    MAX_MS, STEP_MS, BURST = 150, 10, 3

    MODIFIERS = {0x10,0x11,0x12,0x5B,0x5C,  # VK_SHIFT, VK_CONTROL, VK_MENU(Alt), LWIN, RWIN
                 0xA0,0xA1,0xA2,0xA3,0xA4,0xA5}  # L/R variants

    def __init__(self, base_ms=100, repeat_delay_ms=None, repeat_min_ms=None,
                 mod_bounce_ms=30, post_up_guard_ms=35, up_bounce_ms=30,
                 down_guard_ms=40, debug=False,
                 up_guard_max_ms=80, up_guard_step_ms=7,
                 repeat_jitter_ms=5,
                 no_rate_limit_vks=None):
        self.base         = base_ms/1000.0
        self.repeat_delay = (repeat_delay_ms or read_system_repeat_delay_ms())/1000.0
        # Повторный интервал: если не задан, оценим по системному KeyboardSpeed
        if repeat_min_ms is None:
            interval_ms, step = read_system_repeat_interval_ms()
            # Принимаем чуть ниже системного, чтобы не резать валидные повторы ОС
            self.repeat_min = max(0.010, (0.85 * interval_ms)/1000.0)
            self._sys_rate_step = step
            self._sys_rate_ms   = interval_ms
        else:
            self.repeat_min = max(0.010, repeat_min_ms/1000.0)
            self._sys_rate_step = None
            self._sys_rate_ms   = None
        self.mod_bounce   = max(0.005, mod_bounce_ms/1000.0)
        self.post_up_guard= max(0.005, post_up_guard_ms/1000.0)
        self.up_bounce    = max(0.005, up_bounce_ms/1000.0)
        self.down_guard   = max(0.010, down_guard_ms/1000.0)
        self.up_guard_max = max(self.post_up_guard, up_guard_max_ms/1000.0)
        self.up_guard_step= max(0.001, up_guard_step_ms/1000.0)
        # Допуск на системный джиттер таймингов авто‑повтора (мс → сек)
        self.repeat_jitter= max(0.0, repeat_jitter_ms/1000.0)

        self.th   = load_cfg()   # пороги per‑key (scanCode:str → секунд)
        self.last = {}           # время последнего good DOWN
        self.first= {}           # время первого DOWN до UP (удержание)
        self.last_up = {}        # время последнего KEYUP (для пост‑UP защиты «первого» DOWN)
        self.down_guard_until = {}  # время, до которого игнорируем ранние UP (и спайки)
        self.pressed=set()       # множество scanCode (строки)
        self.pressed_vk=set()    # множество vkCode (int)
        self.rep_started=set()   # у каких клавиш автоповтор уже начался
        self.cnt  = {}           # счётчик блокировок (для адаптации)
        self.no_rate_limit_vks = set(no_rate_limit_vks or [])
        # Калибровка:
        self.cal_active=False
        self.cal_target=None   # scanCode целевой клавиши
        self.cal=list()
        self.debug=debug
        # Персональные пост‑UP окна на клавишу: адаптивные
        self.up_guard = {}
        # Для трея: временные метки активности
        self.last_block_ts = 0.0
        self.last_repeat_ts = 0.0
        self.last_note_ts   = 0.0
        # Счётчик блокировок за окно времени
        self._block_events = []  # list[float]; perf_counter timestamps
        self.counter_window = 60.0  # seconds
        # Тема и prefs
        prefs = load_prefs()
        self.theme = prefs.get('theme', 'light')

    def mark_block(self):
        self.last_block_ts = time.perf_counter()
        self._block_events.append(self.last_block_ts)
        # очистка старых
        thr = self.last_block_ts - self.counter_window
        if len(self._block_events) > 200:
            self._block_events = [t for t in self._block_events if t >= thr]
    def mark_repeat(self):
        self.last_repeat_ts = time.perf_counter()
    def mark_note(self):
        self.last_note_ts = time.perf_counter()

    def block_count_recent(self, window_sec=None):
        if window_sec is None:
            window_sec = self.counter_window
        now = time.perf_counter()
        thr = now - window_sec
        # быстрая чистка на чтении
        self._block_events = [t for t in self._block_events if t >= thr]
        return len(self._block_events)

    def win(self, sc):
        # Поддержка старых ключей конфигурации (без суффикса extended):
        if sc in self.th:
            return self.th[sc]
        if ":" in sc:
            base = sc.split(":", 1)[0]
            if base in self.th:
                return self.th[base]
        return self.base
    def is_mod(self, vk): return vk in self.MODIFIERS
    def up_guard_win(self, sc, vk):
        if self.is_mod(vk):
            return self.mod_bounce
        return min(self.up_guard.get(sc, min(self.win(sc), self.post_up_guard)), self.up_guard_max)
    def inc_up_guard(self, sc):
        cur = self.up_guard.get(sc, self.post_up_guard)
        self.up_guard[sc] = min(self.up_guard_max, cur + self.up_guard_step)
    def dec_up_guard(self, sc):
        cur = self.up_guard.get(sc, self.post_up_guard)
        if cur - self.up_guard_step > 0.005:
            self.up_guard[sc] = cur - self.up_guard_step
    def bump_up_guard_to(self, sc, target):
        cur = self.up_guard.get(sc, self.post_up_guard)
        if target > cur:
            self.up_guard[sc] = min(self.up_guard_max, target)


def run_selftest(args):
    print("SELFTEST: starting synthetic scenarios (no Windows hook)")
    deb = Debouncer(base_ms=args.ms,
                    repeat_delay_ms=args.repeat_delay,
                    repeat_min_ms=args.repeat_min,
                    mod_bounce_ms=args.mod_bounce,
                    post_up_guard_ms=args.post_up_guard,
                    up_bounce_ms=args.up_bounce,
                    down_guard_ms=args.down_guard,
                    up_guard_max_ms=args.up_guard_max,
                    up_guard_step_ms=args.up_guard_step,
                    repeat_jitter_ms=args.repeat_jitter,
                    debug=args.debug)

    t0 = 1000.0  # synthetic perf_counter baseline (seconds)

    def log(msg):
        print(f"SELFTEST: {msg}")

    def state(sc):
        return {
            'pressed': (sc in deb.pressed),
            'last': deb.last.get(sc),
            'first': deb.first.get(sc),
            'last_up': deb.last_up.get(sc),
        }

    def down(sc_base, vk, ext, now):
        sc = f"{sc_base}:{ext}"
        if sc not in deb.pressed:
            deb.pressed.add(sc)
            deb.pressed_vk.add(vk)
            deb.first[sc] = now
            deb.last[sc]  = now
            deb.down_guard_until[sc] = now + deb.down_guard
            deb.rep_started.discard(sc)
            log(f"DOWN first sc={sc} vk={vk}")
            return "PASS"
        # repeat before UP
        dt_last = now - deb.last.get(sc, now)
        dt_hold = now - deb.first.get(sc, now)
        if dt_hold < deb.repeat_delay:
            if dt_last < deb.win(sc):
                deb.last[sc] = now
                deb.inc_up_guard(sc)
                log(f"BLOCK_BOUNCE sc={sc} Δ{dt_last*1000:.1f}ms")
                return "BLOCK"
            else:
                deb.last[sc] = now
                deb.inc_up_guard(sc)
                log(f"BLOCK_PREDELAY sc={sc} Δ{dt_last*1000:.1f}ms")
                return "BLOCK"
        else:
            if dt_last + deb.repeat_jitter >= deb.repeat_min:
                deb.rep_started.add(sc)
                deb.last[sc] = now
                log(f"REPEAT sc={sc} Δ{dt_last*1000:.1f}ms")
                return "PASS"
            else:
                deb.inc_up_guard(sc)
                log(f"BLOCK_RATE sc={sc} Δ{dt_last*1000:.1f}ms")
                return "BLOCK"

    def up(sc_base, vk, ext, now):
        sc = f"{sc_base}:{ext}"
        ignore_up = False
        # emulate: if early and within guards, mark as bounce but don't block
        if (now - deb.first.get(sc, now)) < deb.up_bounce or now < deb.down_guard_until.get(sc, 0):
            ignore_up = True
        if ignore_up:
            deb.inc_up_guard(sc)
            log(f"NOTE_UP_BOUNCE sc={sc}")
        deb.pressed.discard(sc)
        deb.pressed_vk.discard(vk)
        deb.rep_started.discard(sc)
        deb.first.pop(sc, None)
        deb.last_up[sc] = now
        log(f"UP sc={sc}")
        return "PASS"

    # Scenario 1: single key with chatter and repeat
    scA, vkA = 30, 0x41  # 'A'
    now = t0
    down(scA, vkA, 0, now)
    now += 0.015  # 15ms bounce
    down(scA, vkA, 0, now)
    now += 0.120  # another pre-repeat hit
    down(scA, vkA, 0, now)
    # wait past repeat delay
    now = t0 + deb.repeat_delay + 0.010
    # fast repeat too soon
    down(scA, vkA, 0, now)
    now += max(0.0, deb.repeat_min - 0.010)
    down(scA, vkA, 0, now)
    # good repeat
    now += deb.repeat_min + 0.005
    down(scA, vkA, 0, now)
    # early UP (bounce)
    up(scA, vkA, 0, t0 + 0.020)
    # proper UP later
    up(scA, vkA, 0, now + 0.050)

    # Scenario 2: extended vs non-extended separation (same sc_base)
    scX, vkX = 77, 0x27  # Right arrow vk (approx), sc=77
    now += 0.100
    down(scX, vkX, 1, now)  # extended
    now += 0.040
    down(scX, vkX, 0, now)  # non-extended – should be treated as separate key first down
    up(scX, vkX, 1, now + 0.060)
    up(scX, vkX, 0, now + 0.080)

    print("SELFTEST: done")
    return 0

# ───────── иконки ─────────
def _rounded_rect(d: ImageDraw.ImageDraw, box, r, fill=None, outline=None, width=1):
    x0,y0,x1,y1 = box
    d.rounded_rectangle((x0,y0,x1,y1), radius=r, fill=fill, outline=outline, width=width)

def _linear_grad(size, top, bottom):
    w,h = size
    img = Image.new('RGBA', (w,h))
    for y in range(h):
        t = y/(h-1) if h>1 else 0
        r = int(top[0]*(1-t) + bottom[0]*t)
        g = int(top[1]*(1-t) + bottom[1]*t)
        b = int(top[2]*(1-t) + bottom[2]*t)
        a = int(top[3]*(1-t) + bottom[3]*t)
        ImageDraw.Draw(img).line([(0,y),(w,y)], fill=(r,g,b,a))
    return img

def render_icon(enabled=True, pulse=None, theme='light', counter=None):
    # pulse: None | 'repeat' | 'block' | 'note'; counter: int or None
    if Image is None:
        return None
    W,H = 64,64
    base = Image.new('RGBA',(W,H),(0,0,0,0))
    # Background gradient
    if theme == 'dark':
        if enabled:
            bg = _linear_grad((W,H), (40,55,71,255), (30,39,46,255))
        else:
            bg = _linear_grad((W,H), (80,80,80,255), (60,60,60,255))
    else:  # light/green accent
        if enabled:
            bg = _linear_grad((W,H), (46,204,113,255), (22,160,133,255))  # green→teal
        else:
            bg = _linear_grad((W,H), (180,180,180,255), (120,120,120,255))
    base.alpha_composite(bg)

    d = ImageDraw.Draw(base)
    # Keyboard body
    if theme == 'dark':
        key_fill=(225,225,225,255); key_outline=(90,90,90,220); ring_col=(200,200,200,220) if enabled else (120,120,120,180)
    else:
        key_fill=(245,245,245,255); key_outline=(60,60,60,220); ring_col=(255,255,255,220) if enabled else (80,80,80,180)
    _rounded_rect(d, (8,14,56,50), r=8, fill=key_fill, outline=key_outline, width=2)
    # Keys grid
    cols, rows = 6, 3
    padding = 4
    x0,y0,x1,y1 = 12,18,52,46
    key_w = (x1-x0 - (cols-1)*2)/cols
    key_h = (y1-y0 - (rows-1)*2)/rows
    for r in range(rows):
        for c in range(cols):
            kx0 = x0 + c*(key_w+2)
            ky0 = y0 + r*(key_h+2)
            kx1 = kx0 + key_w
            ky1 = ky0 + key_h
            _rounded_rect(d, (kx0,ky0,kx1,ky1), r=2, fill=(255,255,255,255), outline=(160,160,160,200))

    # Activity pulse indicator
    if pulse:
        if pulse == 'repeat':
            color = (52,152,219,230)  # blue
        elif pulse == 'block':
            color = (231,76,60,230)   # red
        else:
            color = (241,196,15,230)  # yellow
        _rounded_rect(d, (46,2,62,18), r=8, fill=color, outline=(30,30,30,200))

    # Counter bubble (blocks per recent window)
    if isinstance(counter, int) and counter > 0:
        cnt = max(0, min(99, counter))
        _rounded_rect(d, (2,40,24,62), r=8, fill=(30,30,30,230), outline=(255,255,255,180))
        txt = str(cnt)
        # crude centering for 1-2 digits
        x = 7 if cnt < 10 else 4
        y = 44
        d.text((x,y), txt, fill=(255,255,255,255))

    # Ring overlay
    d.ellipse((2,2,62,62), outline=ring_col, width=2)
    return base

if Image is not None:
    ICON_ON, ICON_OFF = render_icon(True), render_icon(False)
else:
    ICON_ON = ICON_OFF = None

# ───────── Hook ─────────
hook_id   = ULONG_PTR(0)
hook_proc = None

def install_hook(deb: Debouncer):
    if not _init_winapi():
        return ULONG_PTR(0)
    global hook_proc
    HOOKPROC = ctypes.WINFUNCTYPE(LRESULT, wintypes.INT, wintypes.WPARAM, LPARAM)

    @HOOKPROC
    def proc(nCode, wParam, lParam):
        if nCode == 0:
            ks = ctypes.cast(lParam, ctypes.POINTER(KBDLLHOOKSTRUCT)).contents
            # Различаем обычные и «extended» клавиши, чтобы не смешивать одинаковые scanCode
            # LLKHF_EXTENDED = 0x01
            ext_flag = 1 if (int(ks.flags) & 0x01) else 0
            sc_base = str(int(ks.scanCode))
            sc = f"{sc_base}:{ext_flag}"
            vk = int(ks.vkCode)
            now = time.perf_counter()

            is_down = wParam in (WM_KEYDOWN, WM_SYSKEYDOWN)
            is_up   = wParam in (WM_KEYUP,   WM_SYSKEYUP)

            # Быстрая синхронизация: если локально "нажата", а ОС говорит "вверх" → сброс
            if is_down and sc in deb.pressed:
                try:
                    if user32 and (user32.GetAsyncKeyState(vk) & 0x8000 == 0):
                        deb.pressed.discard(sc)
                        deb.pressed_vk.discard(vk)
                        deb.first.pop(sc, None)
                        deb.rep_started.discard(sc)
                except: pass

            if is_down:
                if sc not in deb.pressed:
                    # Пост‑UP защита: если новый первый DOWN приходит слишком близко после UP — блокируем как дребезг
                    # Небольшое адаптивное окно после UP для фильтрации послевыборочного дребезга.
                    guard_thr = deb.up_guard_win(sc, vk)
                    lu = deb.last_up.get(sc)
                    if lu is not None:
                        gap = now - lu
                        if gap < guard_thr:
                            if deb.debug: print(f"BLOCK_POST_UP {sc} Δ{gap*1000:.1f} ms (thr {guard_thr*1000:.1f})")
                            logger.info("BLOCK_POST_UP %s Δ%.1f ms", sc, gap*1000)
                            # усилить персональное пост‑UP окно для этой клавиши
                            deb.inc_up_guard(sc)
                            return 1
                        # если прошли едва‑едва и интервал подозрительно короткий — аккуратно расширим окно
                        if gap < 0.045:  # 45 мс — типичная длительность «чирпа»
                            deb.bump_up_guard_to(sc, gap + 0.010)

                    # Первое нажатие — пропускаем (комбинации работают мгновенно)
                    deb.pressed.add(sc)
                    deb.pressed_vk.add(vk)
                    deb.first[sc] = now
                    deb.last[sc]  = now
                    deb.down_guard_until[sc] = now + deb.down_guard
                    deb.rep_started.discard(sc)
                    if deb.cal_active and deb.cal_target is None:
                        deb.cal_target = sc
                    # Мягкое снижение индивидуального порога после успешного нажатия,
                    # как в bw3_debounce.py (быстрее возвращаемся к базовому окну)
                    try:
                        if sc in deb.th and deb.th[sc] - deb.base > 0.002:
                            deb.th[sc] -= 0.002
                    except Exception:
                        pass
                    # также понемногу уменьшаем персональное пост‑UP окно
                    deb.dec_up_guard(sc)
                    if deb.debug: print(f"DOWN first sc={sc} vk={vk}")
                    return user32.CallNextHookEx(hook_id, nCode, wParam, lParam)

                # Повторный DOWN до UP
                dt_last  = now - deb.last.get(sc, now)
                dt_hold  = now - deb.first.get(sc, now)

                # Калибровка: собираем интервалы для выбранной клавиши
                if deb.cal_active and deb.cal_target == sc:
                    deb.cal.append(dt_last*1000.0)

                if deb.is_mod(vk):
                    # Для модификаторов не применяем пред‑повторную задержку:
                    # режем только явный дребезг < mod_bounce.
                    if dt_last < deb.mod_bounce:
                        if deb.debug: print(f"BLOCK_MOD_BOUNCE {sc} Δ{dt_last*1000:.1f} ms")
                        logger.info("BLOCK_MOD_BOUNCE %s Δ%.1f ms", sc, dt_last*1000)
                        # Обновим last, чтобы не спамить одинаковыми Δ
                        deb.last[sc] = now
                        return 1
                    # всё остальное — пропускаем; модификаторы сами по себе действий не вызывают
                    deb.last[sc] = now
                    return user32.CallNextHookEx(hook_id, nCode, wParam, lParam)

                # Обычная (не модификатор)
                if dt_hold < deb.repeat_delay:
                    # До начала штатного автоповтора Windows:
                    if dt_last < deb.win(sc):
                        # Явный дребезг
                        deb.cnt[sc] = deb.cnt.get(sc,0)+1
                        if deb.cnt[sc] % deb.BURST == 0 and deb.win(sc)*1000 < deb.MAX_MS:
                            deb.th[sc] = min(deb.MAX_MS/1000.0, deb.win(sc)+deb.STEP_MS/1000.0)
                            save_cfg(deb.th)
                        if deb.debug: print(f"BLOCK_BOUNCE {sc} Δ{dt_last*1000:.1f} ms")
                        logger.info("BLOCK_BOUNCE %s Δ%.1f ms", sc, dt_last*1000)
                        deb.mark_block()
                        deb.last[sc] = now  # сброс Δ, чтобы не копить одинаковые пред‑повторы
                        # адаптивно увеличим порог для проблемной клавиши
                        if deb.win(sc)*1000 < deb.MAX_MS:
                            deb.th[sc] = min(deb.MAX_MS/1000.0, deb.win(sc)+deb.STEP_MS/1000.0)
                            save_cfg(deb.th)
                        deb.inc_up_guard(sc)
                        return 1
                    else:
                        # Повторный DOWN до начала автоповтора — не норма → блок
                        if deb.debug: print(f"BLOCK_PREDELAY {sc} Δ{dt_last*1000:.1f} ms")
                        logger.info("BLOCK_PREDELAY %s Δ%.1f ms", sc, dt_last*1000)
                        deb.mark_block()
                        deb.last[sc] = now
                        if deb.win(sc)*1000 < deb.MAX_MS:
                            deb.th[sc] = min(deb.MAX_MS/1000.0, deb.win(sc)+deb.STEP_MS/1000.0)
                            save_cfg(deb.th)
                        deb.inc_up_guard(sc)
                        return 1
                else:
                    # Автоповтор начался
                    if vk in deb.no_rate_limit_vks:
                        # Для указанных клавиш (например, Backspace) не ограничиваем интервал повтора
                        deb.rep_started.add(sc)
                        deb.last[sc] = now
                        if deb.debug: print(f"REPEAT_PASS {sc} Δ{dt_last*1000:.1f} ms [no_rate_limit]")
                        deb.mark_repeat()
                        return user32.CallNextHookEx(hook_id, nCode, wParam, lParam)
                    # Иначе — ограничиваем минимальный интервал с учётом джиттера
                    if dt_last + deb.repeat_jitter >= deb.repeat_min:
                        deb.rep_started.add(sc)
                        deb.last[sc] = now
                        if deb.debug: print(f"REPEAT {sc} Δ{dt_last*1000:.1f} ms")
                        deb.mark_repeat()
                        return user32.CallNextHookEx(hook_id, nCode, wParam, lParam)
                    else:
                        if deb.debug: print(f"BLOCK_RATE {sc} Δ{dt_last*1000:.1f} ms")
                        logger.info("BLOCK_RATE %s Δ%.1f ms", sc, dt_last*1000)
                        deb.mark_block()
                        # ВАЖНО: не обновляем last на блокировке частого повтора,
                        # чтобы следующий Δ накапливался от последнего разрешённого DOWN.
                        if deb.win(sc)*1000 < deb.MAX_MS:
                            deb.th[sc] = min(deb.MAX_MS/1000.0, deb.win(sc)+deb.STEP_MS/1000.0)
                            save_cfg(deb.th)
                        deb.inc_up_guard(sc)
                        return 1

            elif is_up:
                if deb.cal_active and int(ks.vkCode) == VK_ESCAPE:
                    _finalize_calibration(deb)
                    return user32.CallNextHookEx(hook_id, nCode, wParam, lParam)

                # Блокировка раннего UP (дребезг) — если физически клавиша всё ещё вниз
                ignore_up = False
                try:
                    if user32 and (user32.GetAsyncKeyState(vk) & 0x8000):
                        if (now - deb.first.get(sc, now)) < deb.up_bounce or now < deb.down_guard_until.get(sc, 0):
                            ignore_up = True
                except Exception:
                    pass
                if ignore_up:
                    # Не блокируем KEYUP, чтобы не вызывать «залипание» в ОС.
                    # Только усиливаем защитные окна адаптивно и пропускаем событие дальше.
                    if deb.debug: print(f"NOTE_UP_BOUNCE {sc}")
                    logger.info("NOTE_UP_BOUNCE %s", sc)
                    deb.mark_note()
                    deb.inc_up_guard(sc)
                    
                deb.pressed.discard(sc)
                deb.pressed_vk.discard(int(ks.vkCode))
                deb.rep_started.discard(sc)
                deb.first.pop(sc, None)
                deb.last_up[sc] = now  # Запоминаем время последнего UP для пост‑UP защиты
                # Не обновляем deb.last на KEYUP — измеряем интервалы DOWN→DOWN

        return user32.CallNextHookEx(hook_id, nCode, wParam, lParam)

    hook_proc = proc
    return user32.SetWindowsHookExW(WH_KEYBOARD_LL, hook_proc, 0, 0)

# ───────── Калибровка ─────────
def _finalize_calibration(deb: Debouncer):
    if deb.cal_active and deb.cal_target and len(deb.cal) >= 5:
        med = statistics.median(deb.cal)
        thr = max(deb.base, (med/1000.0) + 0.005)
        deb.th[deb.cal_target] = thr
        save_cfg(deb.th)
        logger.info("CAL_DONE sc=%s median=%.1f ms → thr=%.1f ms", deb.cal_target, med, thr*1000)
    deb.cal_active=False; deb.cal_target=None; deb.cal.clear()

# ───────── Настройки (Tk) ─────────
def show_settings(deb, icon):
    if tk is None:
        print("GUI недоступен (tkinter не найден)")
        return
    root = tk.Tk()
    root.title("BW3‑Debounce – настройки"); root.resizable(False, False)

    frm = ttk.Frame(root); frm.pack(padx=10, pady=10)

    ttk.Label(frm, text="Базовое окно дребезга (мс)").grid(row=0, column=0, sticky="w")
    var_base = tk.IntVar(value=int(deb.base*1000))
    ttk.Scale(frm, from_=20, to=200, variable=var_base,
              orient="horizontal", length=240).grid(row=1, column=0, sticky="we", pady=(2,6))
    ttk.Label(frm, textvariable=var_base).grid(row=1, column=1, padx=(8,0))

    ttk.Label(frm, text="Системная задержка автоповтора (мс)").grid(row=2, column=0, sticky="w", pady=(6,0))
    var_rep = tk.IntVar(value=int(deb.repeat_delay*1000))
    ttk.Scale(frm, from_=150, to=1000, variable=var_rep,
              orient="horizontal", length=240).grid(row=3, column=0, sticky="we", pady=(2,6))
    ttk.Label(frm, textvariable=var_rep).grid(row=3, column=1, padx=(8,0))

    ttk.Label(frm, text="Мин. интервал повторов после старта (мс)").grid(row=4, column=0, sticky="w", pady=(6,0))
    var_rate = tk.IntVar(value=int(deb.repeat_min*1000))
    ttk.Scale(frm, from_=10, to=60, variable=var_rate,
              orient="horizontal", length=240).grid(row=5, column=0, sticky="we", pady=(2,6))
    ttk.Label(frm, textvariable=var_rate).grid(row=5, column=1, padx=(8,0))

    ttk.Label(frm, text="Окно дребезга для модификаторов (мс)").grid(row=6, column=0, sticky="w", pady=(6,0))
    var_mod = tk.IntVar(value=int(deb.mod_bounce*1000))
    ttk.Scale(frm, from_=10, to=60, variable=var_mod,
              orient="horizontal", length=240).grid(row=7, column=0, sticky="we", pady=(2,6))
    ttk.Label(frm, textvariable=var_mod).grid(row=7, column=1, padx=(8,0))

    def apply():
        deb.base         = max(0.015, var_base.get()/1000.0)
        deb.repeat_delay = max(0.150, var_rep.get()/1000.0)
        deb.repeat_min   = max(0.010, var_rate.get()/1000.0)
        deb.mod_bounce   = max(0.005, var_mod.get()/1000.0)
        icon.title = f"BW3 Debounce (вкл | {int(deb.base*1000)} мс, repeat≥{int(deb.repeat_delay*1000)} мс)"
        root.destroy()

    ttk.Button(frm, text="Применить", command=apply).grid(row=8, column=0, pady=(12,0))
    root.mainloop()

# ───────── Трей ─────────
def tray_thread(deb):
    if pystray is None:
        print("Трей недоступен (pystray не найден)")
        return
    _init_winapi()
    global hook_id
    icon = pystray.Icon("bw3",
                        ICON_ON,
                        title=f"BW3 Debounce (вкл | {int(deb.base*1000)} мс, repeat≥{int(deb.repeat_delay*1000)} мс)")

    def toggle(_=None):
        global hook_id
        if hook_id:
            if user32:
                user32.UnhookWindowsHookEx(hook_id)
            hook_id = ULONG_PTR(0)
            icon.icon = ICON_OFF; icon.title = "BW3 Debounce (выкл)"
        else:
            hook_id = install_hook(deb)
            if hook_id:
                icon.icon = ICON_ON
                icon.title = f"BW3 Debounce (вкл | {int(deb.base*1000)} мс, repeat≥{int(deb.repeat_delay*1000)} мс)"
            else:
                icon.notify(f"Hook error {ctypes.get_last_error()}")

    def calibrate(_):
        deb.cal_active=True; deb.cal_target=None; deb.cal.clear()
        root = tk.Tk(); root.title("Калибровка – нажимайте проблемную клавишу быстро, затем Esc/Готово")
        ttk.Label(root, text="1) Быстро нажмите проблемную клавишу ~20 раз\n2) Нажмите Esc или кнопку 'Готово'").pack(padx=10, pady=10)
        def finish():
            _finalize_calibration(deb); root.destroy()
        ttk.Button(root, text="Готово", command=finish).pack(pady=(0,10))
        root.bind("<Escape>", lambda e: finish())
        root.mainloop()

    def set_theme_light(_):
        deb.theme = 'light'
        p = load_prefs(); p['theme'] = 'light'; save_prefs(p)
    def set_theme_dark(_):
        deb.theme = 'dark'
        p = load_prefs(); p['theme'] = 'dark'; save_prefs(p)

    icon.menu = pystray.Menu(
        pystray.MenuItem("Вкл/Выкл", toggle, default=True),  # ЛКМ по иконке → toggle
        pystray.MenuItem("Настройки…", lambda _:
            threading.Thread(target=show_settings, args=(deb,icon), daemon=True).start()),
        pystray.MenuItem("Калибровать…", calibrate),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem(
            "Тема",
            pystray.Menu(
                pystray.MenuItem("Светлая", set_theme_light, checked=lambda item: deb.theme=='light'),
                pystray.MenuItem("Тёмная", set_theme_dark, checked=lambda item: deb.theme=='dark')
            )
        ),
        pystray.MenuItem("Открыть лог", lambda *_: os.startfile(LOG)),
        pystray.MenuItem("Выход", lambda *_:(icon.stop(), sys.exit()))
    )
    # Фоновое обновление иконки: пульс активности на основе последних событий
    def updater():
        while True:
            try:
                now = time.perf_counter()
                pulse = None
                # Пульс в приоритете: block > repeat > note
                if now - deb.last_block_ts < 0.5:
                    pulse = 'block'
                elif now - deb.last_repeat_ts < 0.5:
                    pulse = 'repeat'
                elif now - deb.last_note_ts < 0.5:
                    pulse = 'note'
                enabled = bool(hook_id)
                # blocks per recent window (~60s)
                counter = deb.block_count_recent()
                img = render_icon(enabled=enabled, pulse=pulse, theme=deb.theme, counter=counter) if Image else None
                if img is not None:
                    icon.icon = img
                time.sleep(0.2)
            except Exception:
                time.sleep(0.5)
    threading.Thread(target=updater, daemon=True).start()

    icon.run()

# ───────── main ─────────
def main():
    global hook_id
    ap = argparse.ArgumentParser()
    ap.add_argument("--ms", type=int, default=100, help="Базовое окно дребезга, мс (по умолчанию 100)")
    ap.add_argument("--repeat-delay", type=int, default=None, help="Задержка автоповтора, мс (по умолчанию — системная)")
    ap.add_argument("--repeat-min", type=int, default=None, help="Мин. интервал повторов после старта, мс (по умолчанию — из системного KeyboardSpeed)")
    ap.add_argument("--mod-bounce", type=int, default=30, help="Окно дребезга для модификаторов, мс (по умолчанию 30)")
    ap.add_argument("--repeat-jitter", type=int, default=5, help="Допуск джиттера для авто‑повтора, мс (по умолчанию 5)")
    ap.add_argument("--debug", action="store_true", help="Печатать события в консоль")
    ap.add_argument("--post-up-guard", type=int, default=35, help="Лимит пост‑UP фильтра, мс (по умолчанию 35)")
    ap.add_argument("--up-bounce", type=int, default=30, help="Фильтр раннего UP (если физически ещё вниз), мс")
    ap.add_argument("--down-guard", type=int, default=40, help="Защита после первого DOWN от раннего UP, мс")
    ap.add_argument("--up-guard-max", type=int, default=80, help="Максимум адаптивного пост‑UP окна, мс")
    ap.add_argument("--up-guard-step", type=int, default=7, help="Шаг изменения пост‑UP окна, мс")
    ap.add_argument("--no-startup", action="store_true", help="Не добавлять в автозапуск")
    ap.add_argument("--no-rate-limit-vks", type=str, default="", help="CSV VK-кодов без ограничения повтора (напр., 8 для Backspace)")
    ap.add_argument("--selftest", action="store_true", help="Запустить самотест без хука/GUI (консольный вывод)")
    args = ap.parse_args()

    if args.selftest:
        return run_selftest(args)

    if not is_admin(): elevate()
    if not args.no_startup: set_autostart(True)

    def _parse_vks(s):
        if not s:
            return []
        out = []
        for part in s.split(','):
            part = part.strip()
            if not part:
                continue
            try:
                if part.lower().startswith('0x'):
                    out.append(int(part,16))
                else:
                    out.append(int(part))
            except Exception:
                pass
        return out

    vks = _parse_vks(args.no_rate_limit_vks)
    if not vks:
        # По умолчанию не ограничиваем автоповтор Backspace (VK=8)
        vks = [8]

    deb = Debouncer(base_ms=args.ms,
                    repeat_delay_ms=args.repeat_delay,
                    repeat_min_ms=args.repeat_min,
                    mod_bounce_ms=args.mod_bounce,
                    post_up_guard_ms=args.post_up_guard,
                    up_bounce_ms=args.up_bounce,
                    down_guard_ms=args.down_guard,
                    up_guard_max_ms=args.up_guard_max,
                    up_guard_step_ms=args.up_guard_step,
                    repeat_jitter_ms=args.repeat_jitter,
                    no_rate_limit_vks=vks,
                    debug=args.debug)

    hook_id = install_hook(deb)
    if not hook_id:
        print("Hook error", ctypes.get_last_error()); sys.exit(1)
    print("Hook ID =", int(hook_id))
    sys_rate = f" SpeedStep={deb._sys_rate_step} (~{deb._sys_rate_ms} ms)" if deb._sys_rate_step is not None else ""
    print(f"Debounce={int(deb.base*1000)} ms | RepeatDelay≈{int(deb.repeat_delay*1000)} ms | "
          f"RepeatMin={int(deb.repeat_min*1000)} ms{sys_rate} | ModBounce={int(deb.mod_bounce*1000)} ms")

    threading.Thread(target=tray_thread, args=(deb,), daemon=True).start()
    print("Запущено. ЛКМ по иконке в трее — вкл/выкл фильтр.")

    msg = wintypes.MSG()
    while user32 and user32.GetMessageW(ctypes.byref(msg), None, 0, 0):
        user32.TranslateMessage(ctypes.byref(msg))
        user32.DispatchMessageW(ctypes.byref(msg))

if __name__=="__main__":
    main()
