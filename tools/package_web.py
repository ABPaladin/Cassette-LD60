"""Apply documented LD sandbox compatibility and create a root-level ZIP."""
from pathlib import Path
import re,sys,zipfile
root=Path(sys.argv[1] if len(sys.argv)>1 else 'build/web').resolve()
workspace=Path.cwd().resolve()
assert root.is_relative_to(workspace/'build'), 'Build must be inside this workspace/build'
html=root/'index.html'
text=html.read_text(encoding='utf-8')
if '"persistentPaths":[]' not in text:
    text=text.replace('const GODOT_CONFIG = {','const GODOT_CONFIG = {"persistentPaths":[],')
    text=text.replace('var GODOT_CONFIG = {','var GODOT_CONFIG = {"persistentPaths":[],')
if '"persistentPaths":[]' not in text: raise RuntimeError('Locate engine config before disabling persistence')
html.write_text(text,encoding='utf-8')
js=root/'index.js'
text=js.read_text(encoding='utf-8')
text,count=re.subn(r'''["']serviceWorker["']\s*in\s*navigator''','false',text)
js.write_text(text,encoding='utf-8')
archive=root.parent/(root.name+'-cassette.zip')
(root/'FONT-LICENSE.txt').write_bytes((workspace/'assets/fonts/OFL.txt').read_bytes())
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for p in root.iterdir():
        if p.is_file() and (p.suffix in ['.html','.js','.wasm','.pck','.png','.svg'] or p.name == 'FONT-LICENSE.txt'):
            z.write(p,p.name)
assert archive.stat().st_size < 256*1024*1024
print(f'{archive}: {archive.stat().st_size/1024/1024:.2f} MiB; patched {count} service-worker probes; persistence disabled')
