"""Include new gameplay resources automatically; exclude editor/source-only folders."""
from pathlib import Path
presets=[]
for i,(name,platform,output,features) in enumerate([('Web','Web','build/web/index.html',''),('Windows','Windows Desktop','build/windows/Cassette.exe',''),('Web QA','Web','build/web-qa/index.html','web_qa')]):
    Path(output).parent.mkdir(parents=True,exist_ok=True)
    presets.append(f'''[preset.{i}]
name="{name}"
platform="{platform}"
runnable={'false' if name == 'Web QA' else 'true'}
advanced_options=false
dedicated_server=false
custom_features="{features}"
export_filter="all_resources"
include_filter="assets/fonts/OFL.txt"
exclude_filter="*.md,tests/*,tools/*,artifacts/*,build/*,addons/godot-mcp/*,addons/psx_shader/example/*"
export_path="{output}"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.{i}.options]
''')
    if platform=='Web':
        presets.append('''variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
''')
    else:
        presets.append('''binary_format/architecture="x86_64"
binary_format/embed_pck=true
codesign/enable=false
application/modify_resources=false
texture_format/s3tc_bptc=true
''')
Path('export_presets.cfg').write_text('\n'.join(presets),encoding='utf-8')
Path('build/.gdignore').touch()
print('Prepared Web, Web QA and Windows release presets.')
