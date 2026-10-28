#!/usr/bin/env python3
"""Official release binaries only, pinned and checksum checked. Linux x86_64 CI helper."""
import urllib.request,zipfile,hashlib
from pathlib import Path
TOOLS={
 'rojo':('https://github.com/rojo-rbx/rojo/releases/download/v7.7.1/rojo-7.7.1-linux-x86_64.zip','00feb4fa0829a1dd72b49df2639da519a352bfe13cadcd83969e2ba2bb5693c4'),
 'luau':('https://github.com/luau-lang/luau/releases/download/0.744/luau-ubuntu.zip','6506f0852c623aaffcb28494aac16c26dc04a269ea0e16cc0aafc8c8ac79f3ec'),
}
for name,(url,expected) in TOOLS.items():
 out=Path('.tools')/name;out.mkdir(parents=True,exist_ok=True);archive=out/'download.zip';urllib.request.urlretrieve(url,archive)
 assert hashlib.sha256(archive.read_bytes()).hexdigest()==expected,'Tool checksum mismatch: '+name
 with zipfile.ZipFile(archive) as z:z.extractall(out)
 archive.unlink()
 for f in out.iterdir():
  if f.is_file():f.chmod(0o755)
