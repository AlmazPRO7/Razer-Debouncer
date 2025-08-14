import importlib


def test_import_and_init():
    mod = importlib.import_module("bw3_debounce3")
    d = mod.Debouncer()
    assert d.repeat_min > 0.0

