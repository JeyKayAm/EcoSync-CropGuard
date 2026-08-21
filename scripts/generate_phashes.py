"""
generate_phashes.py
────────────────────
Computes a 64-bit average-hash (aHash) for every disease reference photo
under assets/images/<crop>/, so the on-device Photo Lookup feature can rank
a captured photo against these hashes via Hamming distance without any
runtime image comparison work. Writes scripts/phash_cache.json, which
populate_db.py reads (it stays stdlib-only itself) to fill the diseases
table's `image_phashes` column.

Run after adding/changing any reference photo, before populate_db.py:

    python scripts/generate_phashes.py
    python scripts/populate_db.py

Requirements: Pillow (pip install pillow) — unlike populate_db.py, this
script only runs at content-authoring time, never on a user's device, so a
non-stdlib image library is fine here.

The hashing algorithm (resize to 8x8 grayscale, threshold against the mean)
must stay in sync with lib/utils/phash.dart, which computes the same hash
for a captured photo on-device.
"""

import json
import os

from PIL import Image

IMAGES_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'images')
OUTPUT_PATH = os.path.join(os.path.dirname(__file__), 'phash_cache.json')


def average_hash(image_path: str) -> str:
    # Resize first (box/area average over RGB), *then* grayscale — same
    # order and filter as lib/utils/phash.dart's computeAverageHash (which
    # uses img.copyResize(..., interpolation: Interpolation.average) before
    # img.grayscale). Grayscaling before resizing, or resizing with a
    # sharpening filter like LANCZOS, changes which pixels land on which
    # side of the mean threshold and desyncs the two hashes for the same
    # source photo.
    with Image.open(image_path) as img:
        small = img.convert('RGB').resize((8, 8), Image.BOX).convert('L')
        pixels = list(small.getdata())
    mean = sum(pixels) / len(pixels)
    bits = ''.join('1' if p >= mean else '0' for p in pixels)
    return f'{int(bits, 2):016x}'


def main():
    hashes = {}
    for crop_dir in sorted(os.listdir(IMAGES_DIR)):
        crop_path = os.path.join(IMAGES_DIR, crop_dir)
        if not os.path.isdir(crop_path):
            continue
        for filename in sorted(os.listdir(crop_path)):
            if not filename.lower().endswith(('.jpg', '.jpeg', '.png')):
                continue
            relative_path = f'assets/images/{crop_dir}/{filename}'
            full_path = os.path.join(crop_path, filename)
            hashes[relative_path] = average_hash(full_path)

    with open(OUTPUT_PATH, 'w') as f:
        json.dump(hashes, f, indent=2, sort_keys=True)

    print(f'Hashed {len(hashes)} images -> {os.path.abspath(OUTPUT_PATH)}')


if __name__ == '__main__':
    main()
