"""Resize + compress a downloaded reference photo to the README's target
(max 800x600, JPEG quality 75) since ImageMagick isn't installed on this
machine. Usage: python3 scripts/compress_image.py <in> <out>
"""
import sys
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
img = Image.open(src).convert('RGB')
img.thumbnail((800, 600), Image.LANCZOS)
img.save(dst, 'JPEG', quality=75)
print(f'{dst}: {img.size[0]}x{img.size[1]}')
