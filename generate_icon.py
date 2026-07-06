from PIL import Image, ImageDraw

SIZE = 1024
img = Image.new("RGB", (SIZE, SIZE), "#12141D")
draw = ImageDraw.Draw(img)

cx, cy = SIZE // 2, SIZE // 2 + 20

# Ghost body: rounded top + wavy bottom, filling ~70% of tile.
body_w = 600
top = cy - 320
bottom = cy + 260
left = cx - body_w // 2
right = cx + body_w // 2

# Rounded top (半circle-ish dome).
draw.pieslice([left, top, right, top + body_w], 180, 360, fill="#9268EE")
draw.rectangle([left, top + body_w // 2, right, bottom], fill="#9268EE")

# Wavy bottom scallops (cut circles out of background color to form waves).
scallop_r = 75
num = 4
for i in range(num):
    scx = left + scallop_r + i * (body_w - 2 * scallop_r) / (num - 1) * (num / (num - 1))
for i in range(5):
    scx = left + i * (body_w / 4)
    draw.ellipse([scx - scallop_r, bottom - scallop_r, scx + scallop_r, bottom + scallop_r], fill="#12141D")

# Eyes (dark ovals).
eye_w, eye_h = 60, 80
draw.ellipse([cx - 140 - eye_w//2, cy - 60 - eye_h//2, cx - 140 + eye_w//2, cy - 60 + eye_h//2], fill="#12141D")
draw.ellipse([cx + 140 - eye_w//2, cy - 60 - eye_h//2, cx + 140 + eye_w//2, cy - 60 + eye_h//2], fill="#12141D")

# Mouth ("oOo" surprised ghost mouth).
draw.ellipse([cx - 55, cy + 40, cx + 55, cy + 150], fill="#12141D")

# Cyan glow dot accent (signal that someone "replied").
draw.ellipse([cx + 210, cy - 340, cx + 210 + 110, cy - 340 + 110], fill="#49D3D0")

img.save("/tmp/ghosted_icon.png")
print("saved")
