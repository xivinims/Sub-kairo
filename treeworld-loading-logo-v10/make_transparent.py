from PIL import Image
import numpy as np, sys, os, hashlib

src=sys.argv[1]
dst=sys.argv[2]

im=Image.open(src).convert("RGB")
arr=np.asarray(im).astype(np.float32)

dist=np.sqrt(((255.0-arr)**2).sum(axis=2))
low,high=18.0,110.0
alpha=np.clip((dist-low)/(high-low),0.0,1.0)
alpha=alpha*alpha*(3.0-2.0*alpha)

safe=np.clip(alpha,1e-5,1.0)[...,None]
fg=(arr-255.0*(1.0-safe))/safe
fg=np.clip(fg,0.0,255.0)

rgba=np.zeros((arr.shape[0],arr.shape[1],4),dtype=np.uint8)
rgba[...,:3]=fg.astype(np.uint8)
rgba[...,3]=(alpha*255.0).astype(np.uint8)

out=Image.fromarray(rgba,"RGBA")
bbox=out.getbbox()
if not bbox:
    raise RuntimeError("transparent conversion produced empty image")

pad=20
l=max(0,bbox[0]-pad); t=max(0,bbox[1]-pad)
r=min(out.width,bbox[2]+pad); b=min(out.height,bbox[3]+pad)
out=out.crop((l,t,r,b))

w=1024
h=round(out.height*w/out.width)
out=out.resize((w,h),Image.Resampling.LANCZOS)
out.save(dst,optimize=True)

raw=open(dst,"rb").read()
print({"png":dst,"bytes":len(raw),"size":out.size,"sha1":hashlib.sha1(raw).hexdigest()})
