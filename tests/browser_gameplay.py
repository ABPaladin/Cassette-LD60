"""Real browser input in an opaque-origin iframe. QA feature exposes READ-ONLY state.
The action trace is replayed unchanged against the shipping export afterward.
"""
from pathlib import Path
import sys,os,json,time,math,threading
sys.path.insert(0,str(Path('tools').resolve()))
from serve_web import ThreadingHTTPServer,Handler
server=ThreadingHTTPServer(('127.0.0.1',8765),Handler)
threading.Thread(target=server.serve_forever,daemon=True).start()
sys.path.insert(0,str(Path('.rebuild_backup/python_packages').resolve()))
os.environ['PLAYWRIGHT_BROWSERS_PATH']=str(Path('.rebuild_backup/browsers').resolve())
from playwright.sync_api import sync_playwright
kind=sys.argv[1] if len(sys.argv)>1 else 'chromium'
replay_mode='--release' in sys.argv
out=Path('artifacts');out.mkdir(exist_ok=True)
with sync_playwright() as p:
    browser=(p.chromium.launch(executable_path='C:/Program Files/Google/Chrome/Application/chrome.exe',headless=True) if kind=='chromium' else p.firefox.launch(headless=True))
    page=browser.new_page(viewport={'width':1000,'height':620})
    logs=[];requests=[];trace=[];started=time.monotonic()
    page.on('console',lambda m:logs.append(m.type+': '+m.text))
    page.on('pageerror',lambda e:logs.append('PAGEERROR: '+str(e)))
    page.on('request',lambda r:requests.append(r.url))
    page.add_init_script('''window.testAudioContexts=[];window.testAudioStarts=0;
    const NativeAC=window.AudioContext;if(NativeAC){window.AudioContext=class extends NativeAC {constructor(...args){super(...args);window.testAudioContexts.push(this);}};}
    const start=AudioBufferSourceNode.prototype.start;AudioBufferSourceNode.prototype.start=function(...args){window.testAudioStarts++;return start.apply(this,args);};''')
    page.goto('http://127.0.0.1:8765/iframe-'+('release' if replay_mode else 'qa')+'.html')
    frame=page.frames[-1]
    def record(op,**args): trace.append(dict(t=round(time.monotonic()-started,4),op=op,**args))
    def pause(ms): page.wait_for_timeout(ms)
    def click(x,y):
        record('click',x=x,y=y);page.mouse.click(x*948/960,y*533/540);pause(160)
    def move(x,y):
        record('move',x=x,y=y);page.mouse.move(x*948/960,y*533/540)
    def key(value): record('key',value=value);page.keyboard.press(value);pause(300)
    def state(): return frame.evaluate('window.cassetteQA || {}')
    def wait(test,limit=25):
        end=time.monotonic()+limit
        while time.monotonic()<end:
            s=state()
            if test(s): return s
            pause(100)
        raise AssertionError('Timeout, state='+str(state()))
    def button(label):
        s=wait(lambda s:any(b['text']==label and not b['disabled'] for b in s.get('buttons',[])))
        b=next(b for b in s['buttons'] if b['text']==label);click(b['x'],b['y'])
    def object_click(name):
        pos=state()['objects'][name]
        click(pos[0],max(65,min(485,pos[1])))
        wait(lambda s:s.get('selected')==name);pause(1000)
    def shot(name):
        record('shot',name=name);page.screenshot(path=str(out/(kind+'-'+('release-' if replay_mode else '')+name+'.png')))
    def circle_to(target):
        s=state();center=s['reel'];angle=-(target-s['time'])/12*math.tau
        count=max(2,math.ceil(abs(angle)/.12));radius=68
        move(center[0]+radius,center[1]);record('down');page.mouse.down();pause(50)
        for i in range(1,count+1):
            a=angle*i/count;move(center[0]+math.cos(a)*radius,center[1]+math.sin(a)*radius);pause(35)
        record('up');page.mouse.up();pause(200)
        assert abs(state()['time']-target)<1.0,(state()['time'],target)
    try:
        if replay_mode:
            pause(12000);started=time.monotonic()
            source=json.loads((out/(kind+'-actions.json')).read_text())
            first=source[0]['t']
            for action in source:
                delay=action['t']-first-(time.monotonic()-started)
                if delay>0:pause(delay*1000)
                op=action['op']
                if op in ('click','move'):getattr(page.mouse,op)(action['x']*948/960,action['y']*533/540)
                elif op=='key':page.keyboard.press(action['value'])
                elif op=='down':page.mouse.down()
                elif op=='up':page.mouse.up()
                elif op=='shot':page.screenshot(path=str(out/(kind+'-release-'+action['name']+'.png')))
            pause(1000)
            assert frame.evaluate('typeof window.cassetteQA')=='undefined','QA feature leaked into release'
            print('PASS: shipping build replay completed with no QA bridge',flush=True)
        else:
            wait(lambda s:s.get('state')=='menu',60);shot('menu')
            assert not any('DEBUG' in b['text'] for b in state()['buttons'])
            button('START');wait(lambda s:s.get('state')=='intro');pause(1000);shot('intro')
            button('SKIP');wait(lambda s:s.get('state')=='tabletop');pause(1200)
            assert frame.evaluate('window.testAudioContexts.some(c=>c.state==="running")'),'Audio not unlocked'
            assert frame.evaluate('window.testAudioStarts')>=2,'Ambient samples did not start'
            camera=state()['camera_position'];fov=state()['camera_fov']
            for pos in [(2,2),(958,2),(958,538),(2,538),(480,270)]:
                move(*pos);pause(600);assert state()['camera_position']==camera and state()['camera_fov']==fov
            shot('tabletop');print('PASS: menu, START audio, intro, fixed camera',flush=True)
            object_click('sketchbook');button('OPEN / CLOSE');pause(500);button('PAGE >');pause(200)
            assert state()['page']==1;button('PAGE >');pause(200);assert state()['page']==2;shot('clues');key('Escape')
            wait(lambda s:s.get('selected')=='');pause(1600)
            object_click('tamagotchi');values=[state()['pet']]
            for i in range(3):
                click(*state()['pet_buttons'][2]);pause(250);values.append(state()['pet'])
            assert values==['2','4','1','3'],values
            key('Escape');pause(1600)
            object_click('cassette');button('PLAY');pause(1400);button('PAUSE');assert state()['time']>1
            key('Escape');pause(1600);object_click('pencil');button('USE ON CASSETTE');pause(1300)
            print('PASS: notebook clues, physical pet buttons, playback/pause, pencil insertion',flush=True)
            for i,target in enumerate([24.2,51.2,79.2,104.2]):
                if i:button('INSERT PENCIL');pause(1300)
                assert len(state()['discovered'])==i
                circle_to(target);assert len(state()['discovered'])==i,'Seek awarded fragment'
                if i==0:
                    circle_to(target-3);circle_to(target);shot('rewind')
                button('REMOVE PENCIL / LISTEN');pause(1000);button('PLAY')
                wait(lambda s:len(s.get('discovered',[]))==i+1);button('PAUSE')
                print('PASS: actual circular mouse seek and played fragment',i+1,flush=True)
            button('ARRANGE FRAGMENTS');pause(300)
            for text in ['1 / CHECK',"2 / DON'T",'3 / THE DOOR','4 / TRUST HIM']:button(text)
            button('CHECK ORDER');assert not state()['solved'];button('CLEAR')
            for text in ["2 / DON'T",'4 / TRUST HIM','1 / CHECK','3 / THE DOOR']:button(text)
            button("> 1: DON'T");before=frame.evaluate('window.testAudioStarts');button('LISTEN AGAIN');pause(300)
            assert frame.evaluate('window.testAudioStarts')>before,'Replay sample did not start'
            shot('puzzle');button('CHECK ORDER');wait(lambda s:s.get('solved'));shot('warning')
            wait(lambda s:s.get('ending')=='end',30);shot('ending')
            assert not state()['playing'];button('RETURN TO MENU');wait(lambda s:s.get('state')=='menu');pause(1000)
            button('START');wait(lambda s:s.get('state')=='intro');pause(1000);button('SKIP');wait(lambda s:s.get('state')=='tabletop');pause(1000)
            assert state()['discovered']==[];shot('restarted')
            print('PASS: incorrect/correct reconstruction, replay, full ending, restart',flush=True)
        errors=[x for x in logs if x.startswith(('error:','PAGEERROR:'))]
        assert not errors,'Browser errors: '+'\n'.join(errors)
        assert all(url.startswith(('http://127.0.0.1:8765/','data:','blob:')) for url in requests),'External request detected'
        print('PASS: no browser console errors or external requests',flush=True)
    finally:
        suffix='-release' if replay_mode else ''
        (out/(kind+suffix+'-console.log')).write_text('\n'.join(logs),encoding='utf-8')
        if not replay_mode:(out/(kind+'-actions.json')).write_text(json.dumps(trace),encoding='utf-8')
        page.screenshot(path=str(out/(kind+suffix+'-last.png')))
        print('LAST STATE',state() if not replay_mode else 'release',flush=True)
        browser.close()
