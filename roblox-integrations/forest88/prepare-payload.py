from pathlib import Path
import json
import sys

root = Path(__file__).parent
phase = sys.argv[1]
files = {f'roblox-integrations/forest88/{p.name}': p.read_text()
         for p in root.iterdir() if p.suffix in ('.luau', '.py')}
files['roblox-publisher/patch.luau'] = (root / ('install.luau' if phase == 'publish' else 'stage.luau')).read_text()
files['roblox-integrations/forest88/README.md'] = (root / 'README.md').read_text()
if phase == 'publish':
    files['roblox-publisher/verify.luau'] = (root / 'verify.luau').read_text()
content = json.dumps(files, ensure_ascii=False)
(root / 'tree-payload.json').write_text(content)
print(json.dumps({'characters':len(content), 'files':len(files)}))
