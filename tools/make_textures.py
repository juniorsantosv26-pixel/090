"""Deterministic, original procedural tile textures (no copyrighted game assets)."""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import gaussian_filter

OUT=Path(__file__).resolve().parents[1]/'assets/textures'; OUT.mkdir(parents=True,exist_ok=True)
S=512
rng=np.random.default_rng(204112)

def field(seed):
 r=np.random.default_rng(seed); out=np.zeros((S,S),np.float32)
 for sigma,weight in [(80,.30),(32,.24),(13,.22),(4,.15),(.75,.09)]:
  n=r.normal(size=(S,S)).astype(np.float32)
  n=gaussian_filter(n,sigma,mode='wrap')
  n=(n-n.mean())/(n.std()+1e-6)
  out+=n*weight
 return np.clip(out*.18+.50,0,1)

def save(name,colors,f,extra=None):
 stops=np.array([x[0] for x in colors]); rgb=np.array([x[1] for x in colors],np.float32)
 pix=np.stack([np.interp(f,stops,rgb[:,c]) for c in range(3)],axis=-1)
 if extra: pix=extra(pix,f)
 a=np.uint8(np.clip(pix,0,255));Image.fromarray(a,'RGB').save(OUT/(name+'.png'),optimize=True)
 lum=np.dot(pix,[.2126,.7152,.0722])/255
 h=gaussian_filter(lum,.75,mode='wrap')
 dy,dx=np.gradient(h); strength=7
 xyz=np.stack([-dx*strength,-dy*strength,np.ones_like(dx)],axis=-1)
 xyz=xyz/np.maximum(np.linalg.norm(xyz,axis=-1,keepdims=True),1e-6)
 n=np.uint8(np.clip((xyz*.5+.5)*255,0,255))
 Image.fromarray(n,'RGB').save(OUT/(name+'_n.png'),optimize=True)

stone=field(12)
save('ground',[(0,[22,35,24]),(.35,[43,51,37]),(.55,[66,69,46]),(.75,[92,87,62]),(1,[141,132,92])],stone)
save('mud',[(0,[31,32,27]),(.38,[62,57,43]),(.67,[100,86,60]),(1,[154,143,101])],field(23))
save('concrete',[(0,[37,42,40]),(.5,[93,95,87]),(.75,[124,124,110]),(1,[183,174,148])],field(62))
save('stone',[(0,[25,33,32]),(.4,[67,75,73]),(.65,[107,107,98]),(1,[170,158,136])],field(79))

# Irregular fractures and tire stains on aged road surface.
road=field(81)
def asphalt_noise(pix,f):
 yy,xx=np.mgrid[:S,:S]; pix=pix.copy()
 wav=np.sin(xx*.043+np.sin(yy*.021)*4+yy*.019)
 fractures=(np.abs(wav)<.032) & (field(141)>.46)
 pix[fractures]=pix[fractures]*.31
 stains=field(177)>.68;pix[stains]=pix[stains]*.76
 return pix
save('asphalt',[(0,[21,25,24]),(.45,[49,53,52]),(.7,[71,73,70]),(1,[104,100,89])],road,asphalt_noise)

# Cracked plaster wall, water stains.
def plaster_mod(pix,f):
 y,x=np.mgrid[:S,:S]
 stain=(gaussian_filter(rng.random((S,S)),16,mode='wrap')-.5)
 pix=pix + stain[...,None]*160
 damp=(field(50)>.64)&(y>S*.45)
 pix[damp]*=.75
 return pix
save('plaster',[(0,[71,73,67]),(.4,[135,130,112]),(.7,[174,164,141]),(1,[212,199,166])],field(92),plaster_mod)

# Rust blooms on metal, highlight a little cold blue-gray exposed paint.
def metal_mod(pix,f):
 bloom=(field(25)>.62);pix[bloom]=pix[bloom]*.35+np.array([140,68,36])*.65
 return pix
save('metal',[(0,[34,44,46]),(.4,[66,81,83]),(.75,[102,110,107]),(1,[150,144,128])],field(54),metal_mod)

# Exposed timber: longitudinal grain plus knots.
y,x=np.mgrid[:S,:S]
wood=field(101)*.28+.50+.12*np.sin(x*.20+np.sin(y*.032)*3.2)
save('wood',[(0,[40,25,17]),(.4,[77,48,29]),(.65,[116,78,47]),(1,[158,117,78])],np.clip(wood,0,1))
bark=field(153)*.31+.43+.18*np.sin(x*.13+np.sin(y*.011)*3+field(16)*3)
save('bark',[(0,[29,24,19]),(.45,[67,50,36]),(.70,[94,78,56]),(1,[138,120,83])],np.clip(bark,0,1))
save('foliage',[(0,[14,39,24]),(.40,[34,65,32]),(.65,[67,88,39]),(1,[122,131,67])],field(130))
save('fabric',[(0,[24,29,29]),(.45,[49,61,59]),(.67,[67,82,76]),(1,[112,116,101])],field(225))
save('skin',[(0,[58,42,34]),(.45,[122,89,68]),(.69,[173,132,99]),(1,[221,173,135])],field(229))

# Low cost alpha cutouts for vegetation (transparent PNG); not glossy geometry.
from PIL import ImageDraw
sz=256
for kind in ('grass_blade','shrub'):
 tile=Image.new('RGBA',(sz,sz),(0,0,0,0)); d=ImageDraw.Draw(tile,'RGBA')
 rr=np.random.default_rng(19 if kind=='grass_blade' else 27)
 count=25 if kind=='grass_blade' else 115
 for i in range(count):
  x=int(rr.integers(30,225)); by=250 if kind=='grass_blade' else int(rr.integers(135,255))
  dx=int(rr.integers(-58,58)); top=int(rr.integers(23,135)) if kind=='grass_blade' else int(rr.integers(18,205))
  green=(int(rr.integers(26,71)),int(rr.integers(53,115)),int(rr.integers(22,68)),255)
  d.polygon([(x-5,by),(x+dx,top),(x+5,by)], fill=green)
 tile.save(OUT/(kind+'.png'))
print('Procedural original texture set:',len(list(OUT.glob('*.png'))),'PNGs')
