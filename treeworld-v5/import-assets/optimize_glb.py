import struct, json, io, sys, os
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
max_dim = int(sys.argv[3]) if len(sys.argv) > 3 else 2048

with open(src, "rb") as f:
    magic, version, length = struct.unpack("<4sII", f.read(12))
    if magic != b"glTF" or version != 2:
        raise SystemExit("Input is not GLB 2.0")
    chunks = []
    while f.tell() < length:
        clen, ctype = struct.unpack("<II", f.read(8))
        chunks.append((ctype, f.read(clen)))

json_bytes = next(data for ctype, data in chunks if ctype == 0x4E4F534A)
bin_bytes = next(data for ctype, data in chunks if ctype == 0x004E4942)
gltf = json.loads(json_bytes.decode("utf-8").rstrip("\\x00 "))

replacements = {}
for image in gltf.get("images", []):
    bv_index = image.get("bufferView")
    if bv_index is None:
        continue
    view = gltf["bufferViews"][bv_index]
    off = view.get("byteOffset", 0)
    raw = bin_bytes[off:off + view["byteLength"]]
    im = Image.open(io.BytesIO(raw))
    if max(im.size) > max_dim:
        scale = max_dim / max(im.size)
        size = (max(1, round(im.size[0] * scale)), max(1, round(im.size[1] * scale)))
        im = im.resize(size, Image.Resampling.LANCZOS)
    out = io.BytesIO()
    im.save(out, format="PNG", optimize=True, compress_level=9)
    replacements[bv_index] = out.getvalue()
    image["mimeType"] = "image/png"

new_bin = bytearray()
order = sorted(range(len(gltf["bufferViews"])), key=lambda i: gltf["bufferViews"][i].get("byteOffset", 0))
for idx in order:
    while len(new_bin) % 4:
        new_bin.append(0)
    view = gltf["bufferViews"][idx]
    old_off = view.get("byteOffset", 0)
    old_len = view["byteLength"]
    raw = replacements.get(idx, bin_bytes[old_off:old_off + old_len])
    view["byteOffset"] = len(new_bin)
    view["byteLength"] = len(raw)
    new_bin.extend(raw)

while len(new_bin) % 4:
    new_bin.append(0)

gltf["buffers"][0]["byteLength"] = len(new_bin)
new_json = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
while len(new_json) % 4:
    new_json += b" "

total = 12 + 8 + len(new_json) + 8 + len(new_bin)
with open(dst, "wb") as f:
    f.write(struct.pack("<4sII", b"glTF", 2, total))
    f.write(struct.pack("<II", len(new_json), 0x4E4F534A))
    f.write(new_json)
    f.write(struct.pack("<II", len(new_bin), 0x004E4942))
    f.write(new_bin)

print(json.dumps({
    "sourceBytes": os.path.getsize(src),
    "optimizedBytes": os.path.getsize(dst),
    "maxTextureDimension": max_dim
}))
