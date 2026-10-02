"""Real loader API + local display behavior; no game or account log access."""
import argparse
import pathlib
import subprocess
import sys

p = argparse.ArgumentParser()
p.add_argument('--lupa-dir', required=True)
p.add_argument('--services', required=True)
p.add_argument('--patched-source')
a = p.parse_args()
sys.path.insert(0, a.lupa_dir)
from lupa.lua54 import LuaRuntime
root = pathlib.Path(__file__).resolve().parents[1]
server = subprocess.Popen([a.services, '--serve', str(root / 'mod/mod.ini')],
                          stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

def route(_, path):
    server.stdin.write((path + '\n').encode())
    server.stdin.flush()
    n = int(server.stdout.readline())
    data = server.stdout.read(n)
    assert len(data) == n
    return data.decode('utf-8')

try:
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().route = route
    lua.execute('loadstring=load; LuaManagerInst={LoadLua=function(self,p)return route(self,p)end}')
    lua.execute(route(None, 'ZML/Api'))
    helper = (root / 'mod/hud-fields.lua').read_text(encoding='utf-8')
    lua.globals().H = lua.execute(helper)
    lua.globals().TestFreshHelper = lua.execute(helper)
    lua.execute((root / 'tests/display_mock.lua').read_text(encoding='utf-8'))
    lua.execute('verifyHelper()')
    if a.patched_source:
        # Execute actual newly decoded/atomically patched game source with strict stubs.
        lua.execute('setupHL()')
        lua.execute(pathlib.Path(a.patched_source).read_text(encoding='utf-8'))
        lua.execute('verifyController()')
    print('PASS: Lua54, real schema/API/save/subscription, default/hide/custom/reset, warning/cloud/cleanup/failure' +
          (', actual patched controller lifecycle' if a.patched_source else ''))
finally:
    server.stdin.close()
    try:
        server.wait(timeout=5)
    except subprocess.TimeoutExpired:
        server.kill()
        server.wait()
    if server.returncode:
        raise RuntimeError(server.stderr.read().decode(errors='replace'))
