from pathlib import Path
import sys,json
sys.path.insert(0,str(Path('.rebuild_backup/python_packages').resolve()))
from playwright.sync_api import sync_playwright
Path('artifacts').mkdir(exist_ok=True)
with sync_playwright() as p:
    browser=p.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe',headless=True)
    page=browser.new_page(viewport={'width':1000,'height':620})
    messages=[]
    page.on('console',lambda m:messages.append(m.type+': '+m.text))
    page.on('pageerror',lambda e:messages.append('PAGEERROR: '+str(e)))
    page.goto('http://127.0.0.1:8765/iframe-qa.html')
    page.wait_for_timeout(12000)
    page.screenshot(path='artifacts/browser-menu.png')
    frame=page.frames[-1]
    print('STATE',frame.evaluate('window.cassetteQA || null'))
    Path('artifacts/browser-smoke.log').write_text('\n'.join(messages),encoding='utf-8')
    print('\n'.join(messages)[-4500:])
    browser.close()
