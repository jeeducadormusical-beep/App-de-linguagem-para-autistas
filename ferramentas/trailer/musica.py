# Trilha calma gerada por codigo: acordes suaves (pad) + sininhos lentos.
import numpy as np, sys, wave
dur=float(sys.argv[1]); sr=44100; n=int(dur*sr); t=np.arange(n)/sr
def nota(m): return 440*2**((m-69)/12)
acordes=[[48,55,64,71],[45,52,60,67],[41,48,57,64],[43,50,59,66]]  # Cmaj7 Am7 Fmaj7 G
seg=4.0
pad=np.zeros(n)
for k in range(int(dur/seg)+1):
    a=acordes[k%4]; i0=int(k*seg*sr); i1=min(n,int((k+1)*seg*sr+sr))
    if i0>=n: break
    tt=np.arange(i1-i0)/sr
    env=np.minimum(1,tt/1.2)*np.minimum(1,np.maximum(0,(seg+1-tt))/1.5)
    for m in a:
        f=nota(m)
        pad[i0:i1]+=env*(np.sin(2*np.pi*f*tt)+0.3*np.sin(2*np.pi*2*f*tt+0.5))*0.06
sino=np.zeros(n)
penta=[72,74,76,79,81,84]
rng=np.random.default_rng(7)
for k in range(int(dur/1.0)):
    if rng.random()<0.55:
        m=penta[rng.integers(len(penta))]; i0=int((k+rng.random()*0.3)*sr); L=int(2.5*sr)
        if i0+L>n: continue
        tt=np.arange(L)/sr; f=nota(m)
        sino[i0:i0+L]+=np.exp(-tt*2.2)*np.minimum(1,tt/0.01)*(np.sin(2*np.pi*f*tt)+0.25*np.sin(2*np.pi*3*f*tt))*0.05
x=pad+sino
fade=np.minimum(1,np.minimum(t/2.0,(dur-t)/3.0))
x=x*fade; x=x/np.max(np.abs(x))*0.5
with wave.open(sys.argv[2],'wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes((x*32767).astype(np.int16).tobytes())
