#!/usr/bin/env python3
"""Tiny harness around liblua5.4 (ctypes): syntax-check Lua files and run snippets.
LuaJIT/LOVE specifics (bit, ffi, love.*) are NOT available; use stubs in the snippet."""
import ctypes, sys, os
L = ctypes.CDLL('liblua5.4.so.0')
L.luaL_newstate.restype = ctypes.c_void_p
for fn in ('luaL_openlibs', 'lua_close'): getattr(L, fn).argtypes = [ctypes.c_void_p]
L.luaL_loadbufferx.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t, ctypes.c_char_p, ctypes.c_char_p]
L.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p]
L.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]; L.lua_tolstring.restype = ctypes.c_char_p
L.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
def run(code, name='chunk', state=None):
    st = state or L.luaL_newstate(); 
    if not state: L.luaL_openlibs(st)
    b = code.encode() if isinstance(code, str) else code
    r = L.luaL_loadbufferx(st, b, len(b), name.encode(), None)
    if r == 0: r = L.lua_pcallk(st, 0, 0, 0, None, None)
    msg = None
    if r != 0: msg = L.lua_tolstring(st, -1, None).decode(errors='replace'); L.lua_settop(st, -2)
    return r == 0, msg, st
def check_file(p):
    code = open(p, 'rb').read()
    st = L.luaL_newstate(); L.luaL_openlibs(st)
    r = L.luaL_loadbufferx(st, code, len(code), ('@' + p).encode(), None)
    msg = L.lua_tolstring(st, -1, None).decode(errors='replace') if r else None
    L.lua_close(st); return r == 0, msg
if __name__ == '__main__':
    bad = 0
    for p in sys.argv[1:]:
        ok, msg = check_file(p)
        print(('OK   ' if ok else 'FAIL ') + p + ('' if ok else '  -> ' + msg)); bad += (not ok)
    sys.exit(1 if bad else 0)
