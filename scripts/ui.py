#!/usr/bin/env python3
"""Doubao runtime UI helper: dump, tap by text/resource-id, screenshot, scroll."""
import argparse, os, re, subprocess, sys, time, xml.etree.ElementTree as ET
ADB = os.environ.get('ADB', '/Users/lwblx/Library/Android/sdk/platform-tools/adb')
SERIAL = os.environ.get('SERIAL', 'emulator-5554')
ROOT = '/Users/lwblx/huapohen/agent/rea/doubao_input/evidence/runtime'
SHOTS = os.path.join(ROOT, 'screenshots')

def adb(*args, capture=False):
    cmd = [ADB, '-s', SERIAL] + list(args)
    if capture:
        return subprocess.run(cmd, check=True, capture_output=True).stdout
    return subprocess.run(cmd, check=True, capture_output=True, text=True).stdout

def dump(name='window'):
    adb('shell', 'uiautomator', 'dump', '/sdcard/window.xml')
    data = adb('shell', 'cat', '/sdcard/window.xml', capture=True)
    path = os.path.join(ROOT, name + '.xml')
    open(path, 'wb').write(data)
    return path

def nodes(path):
    root = ET.parse(path).getroot()
    out = []
    for n in root.iter('node'):
        b = n.get('bounds', '')
        m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', b)
        if not m: continue
        x1,y1,x2,y2 = map(int, m.groups())
        out.append({'text': n.get('text',''), 'rid': n.get('resource-id',''), 'desc': n.get('content-desc',''),
                    'cls': n.get('class',''), 'clickable': n.get('clickable'), 'bounds': (x1,y1,x2,y2),
                    'center': ((x1+x2)//2,(y1+y2)//2)})
    return out

def find(ns, text=None, rid=None, exact=False):
    for n in ns:
        if text is not None:
            hay = n['text'] or n['desc']
            if (hay == text) if exact else (text in hay):
                return n
        if rid is not None and rid in n['rid']:
            return n
    return None

def shot(name):
    os.makedirs(SHOTS, exist_ok=True)
    path = os.path.join(SHOTS, name + '.png')
    data = adb('exec-out', 'screencap', '-p', capture=True)
    open(path, 'wb').write(data)
    return path

def scroll(direction='down', amount=1500):
    if direction == 'down':
        adb('shell','input','swipe','672','2400','672',str(2400-amount),'350')
    else:
        adb('shell','input','swipe','672',str(2400-amount),'672','2400','350')
    time.sleep(0.8)

def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('dump'); p.add_argument('name', nargs='?', default='window'); p.add_argument('--list', action='store_true')
    p = sub.add_parser('tap'); p.add_argument('text', nargs='?'); p.add_argument('--rid'); p.add_argument('--exact', action='store_true'); p.add_argument('--name', default='tap')
    p = sub.add_parser('shot'); p.add_argument('name'); p.add_argument('--dump', action='store_true')
    p = sub.add_parser('scroll'); p.add_argument('direction', nargs='?', default='down'); p.add_argument('--amount', type=int, default=1500)
    p = sub.add_parser('key'); p.add_argument('code')
    p = sub.add_parser('start'); p.add_argument('component'); p.add_argument('--wait', type=float, default=2.0)
    args = ap.parse_args()
    if args.cmd == 'dump':
        path = dump(args.name); ns = nodes(path)
        if args.list:
            for n in ns:
                if n['text'] or n['desc'] or n['clickable']=='true':
                    print(f"{n['text'][:80]!r}\t{n['desc'][:50]!r}\t{n['rid']}\t{n['cls'].split('.')[-1]}\t{n['center']}\t{'C' if n['clickable']=='true' else ''}")
        else:
            print(path)
    elif args.cmd == 'tap':
        path = dump(args.name); ns = nodes(path)
        n = find(ns, args.text, args.rid, args.exact)
        if not n:
            print('NOT FOUND', args.text, args.rid); sys.exit(1)
        print('TAP', n['center'], repr(n['text']), n['rid'])
        adb('shell','input','tap',str(n['center'][0]),str(n['center'][1])); time.sleep(1.5)
    elif args.cmd == 'shot':
        print(shot(args.name))
        if args.dump:
            path = dump(args.name); print(path)
            for n in nodes(path):
                if n['text']: print(repr(n['text']), n['center'])
    elif args.cmd == 'scroll':
        scroll(args.direction, args.amount)
    elif args.cmd == 'key':
        adb('shell','input','keyevent',args.code); time.sleep(1)
    elif args.cmd == 'start':
        out = adb('shell','am','start','-W','-n',args.component)
        print(out)
        time.sleep(args.wait)
if __name__ == '__main__':
    main()
