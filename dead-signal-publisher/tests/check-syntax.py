"""Parse the Lua-compatible subset with Lua 5.3 after expanding Luau assignments.
Roblox prepublish validator separately requires real ModuleScripts in the engine.
"""
from pathlib import Path
import re, subprocess, tempfile
root=Path(__file__).resolve().parents[1]
files=list((root/'base').rglob('*.luau'))+list(root.glob('arena-*.luau'))+[root/'chapter-map.luau',root/'visual-dressing.luau',root/'environment-pass.luau',root/'collision-pass.luau',root/'grabpack-install.luau',root/'menu-stage.luau',root/'chapter-install.luau',root/'chapter-validate.luau',root/'assembled-install.luau']
checker='''local p=arg[1]\nlocal f,e=loadfile(p)\nif not f then print(e); os.exit(1) end\n'''
with tempfile.TemporaryDirectory() as temp:
 check=Path(temp)/'check.lua';check.write_text(checker)
 for index,path in enumerate(files):
  if path.name in {'chapter-install.luau','arena-install.luau'}:continue # template placeholders are replaced in assembled-install
  text=path.read_text()
  text=re.sub(r'([\w.]+)\s*([+*\-])=\s*([\w.]+)',lambda m:f'{m[1]} = {m[1]} {m[2]} {m[3]}',text)
  out=Path(temp)/f'{index}.lua';out.write_text(text)
  result=subprocess.run(['texlua',str(check),str(out)],capture_output=True,text=True)
  if result.returncode: raise SystemExit(f'{path.name}: {result.stdout}{result.stderr}')
 print(f'Syntax OK: {len(files)-1} Luau source files (expanded assignment subset)')
