#!/usr/bin/env python3
"""Whitespace-only Lua re-indenter (4 spaces). Refuses to write if anything but whitespace would change.
usage: python3 tools/lua_format.py file.lua [more.lua ...]"""
import re, sys

OPEN_KW = {'function', 'if', 'repeat'}
def scan(line):
    """Return (net_depth_change, leading_closers) for one line, ignoring strings and comments."""
    s, i, n = line, 0, len(line)
    toks = []
    while i < n:
        c = s[i]
        if c == '-' and s.startswith('--', i): break
        if c in '"\'':
            q = c; i += 1
            while i < n and s[i] != q:
                i += 2 if s[i] == '\\' else 1
            i += 1; continue
        if c.isalpha() or c == '_':
            j = i
            while j < n and (s[j].isalnum() or s[j] == '_'): j += 1
            toks.append(s[i:j]); i = j; continue
        if c in '{}()': toks.append(c)
        i += 1
    depth, lead, seen_content, pending_do = 0, 0, False, 0
    for t in toks:
        closer = t in ('end', 'until', '}', ')')
        mid = t in ('else', 'elseif')
        if not seen_content and (closer or mid):
            lead += 1
        elif t not in ('end', 'until', '}', ')', 'else', 'elseif'):
            seen_content = True
        if t in OPEN_KW or t == '{' or t == '(':
            depth += 1
        elif t in ('for', 'while'):
            depth += 1; pending_do += 1
        elif t == 'do':
            if pending_do: pending_do -= 1
            else: depth += 1
        elif t in ('end', 'until', '}', ')'):
            depth -= 1
    return depth, lead, toks

def fmt(src):
    out, level = [], 0
    for raw in src.split('\n'):
        stripped = raw.strip()
        if not stripped:
            out.append(''); continue
        depth, lead, toks = scan(stripped)
        first = toks[0] if toks else ''
        dedent = 1 if first in ('end', 'until', '}', ')', 'else', 'elseif') else 0
        # a line like "end end" or "}) end" can dedent more than once
        k = 0
        for t in toks:
            if t in ('end', 'until', '}', ')'): k += 1
            else: break
        dedent = max(dedent, k)
        out.append('    ' * max(0, level - dedent) + stripped)
        level = max(0, level + depth)
    return '\n'.join(out)

for p in sys.argv[1:]:
    src = open(p, encoding='utf-8').read()
    if '[[' in src: print('SKIP (long string)', p); continue
    new = fmt(src.replace('\r\n', '\n'))
    if re.sub(r'\s+', '', new) != re.sub(r'\s+', '', src): print('REFUSED (content differs)', p); continue
    open(p, 'w', encoding='utf-8').write(new.rstrip('\n') + '\n'); print('formatted', p)
