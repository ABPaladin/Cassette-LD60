"""Original deterministic tones/noise, not music or voice. Requires ffmpeg.
Never run over replacement recordings: outputs live in assets/audio/placeholder/.
"""
from pathlib import Path
import array, math, random, re, subprocess, wave
OUT = Path('assets/audio/placeholder')
OUT.mkdir(parents=True, exist_ok=True)
RATE = 22050
rng = random.Random(1998)
def wav(name, samples):
    path = OUT / (name + '.wav')
    with wave.open(str(path), 'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed'))
        f.writeframes(array.array('h',(int(max(-.95,min(.95,x))*32767) for x in samples)).tobytes())
    return path
def signal(seconds, fn):
    return array.array('f',(fn(i/RATE) for i in range(int(seconds*RATE))))
wav('lamp',signal(4,lambda t:.15*math.sin(math.tau*50*t)+.035*math.sin(math.tau*100*t)+.012*math.sin(math.tau*150*t)))
wav('room',signal(8,lambda t:rng.uniform(-.08,.08)*math.sin(math.pi*t/8)**2))
times = [float(x) for x in re.findall(r'"time":([0-9.]+)',Path('resources/investigation.tres').read_text())]
tape = signal(180,lambda t:rng.uniform(-.004,.004))
for i,time in enumerate(times,1):
    clip = signal(3,lambda t:.13*math.sin(math.tau*(260+i*85)*t)*math.sin(math.pi*min(t%1/.15,1)) if t%1<.15 else 0)
    wav('fragment_'+str(i),clip)
    start=int(time*RATE)
    for j,x in enumerate(clip): tape[start+j]+=x
source=wav('tape_source',tape)
subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(source),'-c:a','libvorbis','-q:a','2',str(OUT/'tape.ogg')],check=True)
# The large source is a build artifact, not an imported shipping asset.
source.replace(Path('.rebuild_backup')/'tape_source.wav')
print('Generated original placeholder tone recording and ambient loops.')
