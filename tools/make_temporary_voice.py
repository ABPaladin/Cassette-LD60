"""Bake clearly temporary local speech; never overwrite artist recordings.
Requires Windows System.Speech (Zira Desktop) and ffmpeg. Content is central data.
"""
from pathlib import Path
import array, json, math, random, re, subprocess, wave
out=Path('assets/audio/temporary_voice');out.mkdir(parents=True,exist_ok=True)
work=Path('.rebuild_backup');work.mkdir(exist_ok=True)
data=Path('resources/investigation.tres').read_text(encoding='utf-8')
fragments=json.loads(re.search(r'fragments = Array\[Dictionary\]\((\[.*?\])\)',data,re.S)[1])
captions=json.loads(re.search(r'captions = Array\[Dictionary\]\((\[.*?\])\)',data,re.S)[1])
entries=[dict(name='fragment_'+f['id'],time=f['time'],text=f['message']) for f in fragments]
entries += [dict(name='narrative_'+str(i),time=c['start'],text=c['text']) for i,c in enumerate(captions)]
jobs=[dict(path=str(work/(e['name']+'_sapi.wav')),text=e['text']) for e in entries]
(work/'speech-input.json').write_text(json.dumps(jobs),encoding='utf-8')
subprocess.run(['powershell','-NoProfile','-File','tools/bake_temporary_voice.ps1'],check=True)
rate=22050
rng=random.Random(1998)
tape=array.array('f',(rng.uniform(-.003,.003) for _ in range(180*rate)))
for e,j in zip(entries,jobs):
    clip=out/(e['name']+'.wav') if e['name'].startswith('fragment_') else work/(e['name']+'.wav')
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',j['path'],'-ar',str(rate),'-ac','1','-c:a','pcm_s16le',str(clip)],check=True)
    with wave.open(str(clip),'rb') as f: samples=array.array('h',f.readframes(f.getnframes()))
    start=round(e['time']*rate)
    for i,x in enumerate(samples):
        if start+i<len(tape):tape[start+i]+=x/32768*.85
def wav(path,samples):
    with wave.open(str(path),'wb') as f:
        f.setparams((1,2,rate,0,'NONE','not compressed'))
        f.writeframes(array.array('h',(round(max(-.98,min(.98,x))*32767) for x in samples)).tobytes())
source=work/'temporary_voice_source.wav';wav(source,tape)
subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(source),'-c:a','libvorbis','-q:a','3',str(out/'tape.ogg')],check=True)
wav(out/'spool.wav',(rng.uniform(-.12,.12)*(.6+.4*math.sin(math.tau*18*i/rate)) for i in range(rate*2)))
print('Baked 180-second temporary spoken clue tape, four replay clips and spool texture.')
