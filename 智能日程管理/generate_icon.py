import math
from PIL import Image, ImageDraw, ImageFont

# Size 1024x1024 macOS app icon
size = 1024
img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Squircle / rounded rect for macOS (radius 225 at 1024px)
margin = 40
r = 220
draw.rounded_rectangle(
    [margin, margin, size - margin, size - margin],
    radius=r,
    fill=(18, 18, 20, 255)
)

# Subtle border
draw.rounded_rectangle(
    [margin, margin, size - margin, size - margin],
    radius=r,
    outline=(45, 45, 50, 255),
    width=6
)

# Yellow neon sparkle pill center #eefb40 -> (238, 251, 64)
# Let's draw an elegant glowing icon symbol
cx, cy = size // 2, size // 2

# Glow circle behind
for i in range(120, 0, -10):
    alpha = int(40 * (1 - i / 120))
    draw.ellipse([cx - 200 - i, cy - 200 - i, cx + 200 + i, cy + 200 + i], fill=(238, 251, 64, alpha))

# Four-point star / Sparkle in neon yellow
sparkle_color = (238, 251, 64, 255)

# Star points
points = []
num_points = 8
for i in range(num_points * 2):
    angle = i * math.pi / num_points
    # Alternate radii
    radius = 230 if i % 2 == 0 else 60
    x = cx + radius * math.cos(angle - math.pi / 2)
    y = cy + radius * math.sin(angle - math.pi / 2)
    points.append((x, y))

draw.polygon(points, fill=sparkle_color)

# Small secondary sparkles
def draw_small_star(sx, sy, r1, r2):
    pts = []
    for i in range(8):
        angle = i * math.pi / 4
        rad = r1 if i % 2 == 0 else r2
        pts.append((sx + rad * math.cos(angle), sy + rad * math.sin(angle)))
    draw.polygon(pts, fill=sparkle_color)

draw_small_star(cx + 250, cy - 220, 70, 22)
draw_small_star(cx - 240, cy + 200, 50, 16)

img.save('build/icon_1024.png', 'PNG')
print("Successfully generated build/icon_1024.png")
