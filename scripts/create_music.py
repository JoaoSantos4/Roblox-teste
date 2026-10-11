"""Composições instrumentais próprias para RNG. Requer numpy e ffmpeg.
Execução: python scripts/create_music.py. Sem amostras ou faixas externas.
"""
from pathlib import Path
import subprocess, tempfile, wave
import numpy as np
SR = 22050
# nome, BPM, timbre, raiz MIDI, graus do motivo, acordes (graus da raiz)
TRACKS = [
 ('Praia_Ambiente',100,'steel',60,[0,4,7,9,7,4,2,4,7,12,9,7,4,2,0,None],[0,5,7,0]),
 ('Comum_Conforto',112,'kalimba',60,[0,4,7,None,4,2,0,None,7,4,2,4,0,None,2,None],[0,5,0,7]),
 ('Incomum_Natureza',86,'flute',62,[0,2,7,9,7,None,2,0,5,9,12,9,7,5,2,None],[0,5,7,5]),
 ('Raro_Oceano',92,'bell',62,[0,7,12,None,14,12,7,5,9,12,16,14,12,9,7,None],[0,7,5,0]),
 ('Epico_Sombras',90,'pad',57,[0,3,7,10,7,None,3,0,5,8,12,8,7,3,0,None],[0,5,3,7]),
 ('Lendario_Solar',118,'brass',60,[0,4,7,12,7,12,16,None,14,12,7,4,9,7,4,0],[0,5,7,0]),
 ('Divino_Cosmos',74,'choir',60,[0,7,12,16,19,None,16,12,5,12,17,21,19,17,12,None],[0,5,0,7]),
 ('Segredo_Enigma',78,'box',57,[0,1,7,None,8,7,1,0,3,7,10,8,7,3,1,None],[0,1,5,0]),
]
OUT = Path(__file__).resolve().parents[1] / 'music'
OUT.mkdir(exist_ok=True)
for track_index,(name,bpm,kind,root,motif,chords) in enumerate(TRACKS):
 beat=60/bpm
 n=round(8*4*beat*SR)
 mix=np.zeros(n,dtype=np.float64)
 rng=np.random.default_rng(4100+track_index)
 def put(at,samples):
  start=round(at*SR)%n
  # Faz a cauda atravessar o começo do loop, evitando corte no ponto de repetição.
  indices=(np.arange(len(samples))+start)%n
  np.add.at(mix,indices,samples)
 def tone(midi,at,duration,volume,timbre):
  t=np.arange(round(duration*SR))/SR
  f=440*2**((midi-69)/12)
  if timbre in ('steel','kalimba','box','bell'):
   ratios={'steel':[1,2,3.01,4.02],'kalimba':[1,2,4.04],'box':[1,2.01,3.98],'bell':[1,2.71,4.08]}[timbre]
   sound=sum(np.sin(2*np.pi*f*r*t)*(0.5**i)*np.exp(-t*(2.7+i*1.6)) for i,r in enumerate(ratios))
   env=np.minimum(1,t/0.006)*np.minimum(1,(duration-t)/0.04)
  elif timbre=='flute':
   sound=np.sin(2*np.pi*f*t+0.014*np.sin(2*np.pi*5*t))+0.12*np.sin(4*np.pi*f*t)
   env=np.minimum(1,t/0.07)*np.minimum(1,(duration-t)/0.15)
  elif timbre=='brass':
   sound=sum(np.sin(2*np.pi*f*i*t)/i for i in range(1,5))
   env=np.minimum(1,t/0.06)*np.exp(-t*1.2)*np.minimum(1,(duration-t)/0.1)
  else:
   sound=np.sin(2*np.pi*f*t)+0.3*np.sin(2*np.pi*f*1.003*t)+0.15*np.sin(4*np.pi*f*t)
   env=np.minimum(1,t/0.22)*np.minimum(1,(duration-t)/0.3)
  put(at,sound*env*volume)
 for bar in range(8):
  chord=chords[bar%len(chords)]
  third=3 if kind in ('pad','box') else 4
  for degree in [0,third,7]:
   tone(root+chord+degree-12,bar*4*beat,4.5*beat,0.045,'pad')
  for b in range(4):
   at=(bar*4+b)*beat
   tone(root+chord-24,at,0.7*beat,0.075,'kalimba')
   if kind in ('steel','kalimba','brass','bell'):
    t=np.arange(round(0.08*SR))/SR
    percussion=rng.normal(0,1,len(t))*np.exp(-t*55)
    # Chocalho curto, discreto e sintetizado.
    percussion=np.concatenate(([0],np.diff(percussion)))
    put(at+beat*0.5,percussion*0.016)
  for step in range(8):
   note=motif[(bar%2)*8+step]
   if note is not None:
    tone(root+note,(bar*4+step*0.5)*beat,beat*(1.8 if kind in ('pad','choir') else 1.1),0.13,kind)
 if kind=='steel':
  # Ruído de ondas suave: não usa gravações externas.
  noise=rng.normal(0,1,n)
  soft=np.convolve(noise,np.ones(40)/40,mode='same')
  phase=np.arange(n)/n
  mix += soft*(0.012+0.015*(1-np.cos(2*np.pi*phase*4))/2)
 peak=np.max(np.abs(mix))
 mix=mix/max(1,peak/0.72)
 pcm=np.rint(mix*32767).astype('<i2')
 with tempfile.TemporaryDirectory(prefix='rng-music-') as temp:
  wav=Path(temp)/'track.wav'
  with wave.open(str(wav),'wb') as handle:
   handle.setnchannels(1);handle.setsampwidth(2);handle.setframerate(SR);handle.writeframes(pcm.tobytes())
  target=OUT/(name+'.mp3')
  subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(wav),'-codec:a','libmp3lame','-b:a','128k',str(target)],check=True)
 print(name,round(n/SR,2),'segundos; pico',round(float(np.max(np.abs(mix))),3))
