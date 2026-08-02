"""
prepare_images.py
──────────────────
Downloads open agricultural disease-image datasets and converts a subset into
the reference photos used by the app's Iterative Visual Comparison (IVC)
gallery (assets/images/<crop>/<disease_code>_<n>.jpg).

Run once from the project root:

    pip install kagglehub pillow
    python scripts/prepare_images.py

Requires a Kaggle account + API token (kaggle.json in ~/.kaggle/, or the
KAGGLE_USERNAME / KAGGLE_KEY environment variables) for the kagglehub
download — the datasets themselves are free, but kagglehub needs this to
authenticate.

IMPORTANT — coverage is partial, by design of the available open data.
Of the app's 25 diseases across 5 crops, only 10 have a matching public
dataset at the time of writing:

  Maize (3 of 5):      Grey Leaf Spot, Common Rust, Northern Corn Leaf
                        Blight — via PlantVillage (Penn State / Kaggle).
                        Maize Streak Virus and Stalk Rot (Fusarium) are
                        NOT in PlantVillage and have no other known open
                        dataset; still need field photography.

  Groundnuts (2 of 5):  Early Leaf Spot, Late Leaf Spot — via the
                        Mendeley "groundnut plant leaf images" dataset
                        (data.mendeley.com/datasets/22p2vcbxfk/3).
                        Groundnut Rosette Virus, Aflatoxin, and GRAV
                        still need another source.

  Sorghum (2 of 5):     Anthracnose, Head Smut — via the Mendeley
                        "Sorghum Disease Image Dataset"
                        (data.mendeley.com/datasets/fgb3cmfrg2/1).
                        Downy Mildew, Ergot, and Leaf Blight still need
                        another source.

  Tobacco, Sweet Potatoes (0 of 5 via this script): A tobacco disease
  research set (TPDD) and isolated sweet-potato datasets exist but are
  not reliably available via a stable Kaggle/kagglehub identifier at
  the time of writing — download these manually if used, and verify
  their licence terms before bundling into the app.

This script only downloads what's confirmed accessible via kagglehub.
The Mendeley sets must be downloaded manually from the URLs above (they
are not on Kaggle) and placed under MENDELEY_DIR before running.

License: confirm the exact licence on each dataset's page before
redistributing images inside a built APK. Credit data sources (Penn
State University / Hughes & Salathé for PlantVillage; the respective
Mendeley dataset authors) in the app's About screen.
"""

import random
from pathlib import Path

from PIL import Image

# ─── Config ─────────────────────────────────────────────────────

PROJECT_ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = PROJECT_ROOT / "assets" / "images"
MENDELEY_DIR = PROJECT_ROOT / "scripts" / "mendeley_downloads"  # manual downloads go here
IMAGES_PER_DISEASE = 3
MAX_DIMENSIONS = (800, 600)   # matches the spec in the project report
JPEG_QUALITY = 75
SEED = 42

# PlantVillage class folder -> (crop, disease asset prefix). Pulled via kagglehub.
PLANTVILLAGE_CLASS_MAP = {
    "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot": ("maize", "gls"),
    "Corn_(maize)___Common_rust_": ("maize", "rust"),
    "Corn_(maize)___Northern_Leaf_Blight": ("maize", "nclb"),
}

# Mendeley folder name (as found inside MENDELEY_DIR after manual download/extraction)
# -> (crop, disease asset prefix). These datasets are NOT on Kaggle, so they
# are not fetched automatically — download them by hand from the URLs in the
# module docstring above and extract into scripts/mendeley_downloads/<crop>/.
MENDELEY_CLASS_MAP = {
    "groundnuts/early_leaf_spot": ("groundnuts", "early_leaf_spot"),
    "groundnuts/late_leaf_spot": ("groundnuts", "late_leaf_spot"),
    "sorghum/anthracnose": ("sorghum", "anthracnose"),
    "sorghum/head_smut": ("sorghum", "head_smut"),
}

# Diseases in the app's database with no confirmed open dataset.
# Surfaced as a printed report at the end of the run — not silently dropped.
UNCOVERED = {
    "maize": ["Maize Streak Virus (msv)", "Stalk Rot (stalk_rot)"],
    "groundnuts": [
        "Groundnut Rosette Virus (rosette)", "Aflatoxin Contamination (aflatoxin)",
        "Groundnut Rosette Assistor Virus (grav)",
    ],
    "sorghum": ["Sorghum Downy Mildew (downy_mildew)", "Sorghum Ergot (ergot)", "Leaf Blight (leaf_blight)"],
    "tobacco": [
        "Blue Mould (blue_mould)", "Black Shank (black_shank)",
        "Tobacco Mosaic Virus (tmv) — see TPDD research dataset, manual download",
        "Frogeye Leaf Spot (frogeye) — see TPDD research dataset, manual download",
        "Wildfire (wildfire) — see TPDD research dataset, manual download",
    ],
    "sweet_potatoes": ["all 5 diseases — no reliable public dataset found; needs field photography"],
}


def download_plantvillage() -> Path:
    import kagglehub
    # Full 38-class PlantVillage set (includes Corn), not the emmarex mirror,
    # which omits Corn entirely.
    path = kagglehub.dataset_download("abdallahalidev/plantvillage-dataset")
    return Path(path)


def find_class_dir(dataset_root: Path, class_name: str) -> Path | None:
    matches = list(dataset_root.rglob(class_name))
    return matches[0] if matches else None


def process_image(src: Path, dst: Path) -> None:
    with Image.open(src) as img:
        img = img.convert("RGB")
        img.thumbnail(MAX_DIMENSIONS, Image.LANCZOS)
        dst.parent.mkdir(parents=True, exist_ok=True)
        img.save(dst, "JPEG", quality=JPEG_QUALITY, optimize=True)


def process_class(class_dir: Path, crop: str, prefix: str, covered: list, missing: list) -> None:
    images = sorted(class_dir.glob("*.JPG")) + sorted(class_dir.glob("*.jpg")) + sorted(class_dir.glob("*.png"))
    if len(images) < IMAGES_PER_DISEASE:
        missing.append(f"{crop}/{prefix} (only {len(images)} images found in {class_dir})")
        return
    chosen = random.sample(images, IMAGES_PER_DISEASE)
    for i, src in enumerate(chosen, start=1):
        dst = ASSETS_DIR / crop / f"{prefix}_{i}.jpg"
        process_image(src, dst)
    covered.append(f"{crop}/{prefix} ({len(chosen)} images)")
    print(f"  done: {crop}/{prefix}_*.jpg")


def main() -> None:
    random.seed(SEED)
    covered, missing = [], []

    print("Downloading PlantVillage dataset via kagglehub...")
    pv_root = download_plantvillage()
    print(f"PlantVillage cached at: {pv_root}\n")

    for class_name, (crop, prefix) in PLANTVILLAGE_CLASS_MAP.items():
        class_dir = find_class_dir(pv_root, class_name)
        if class_dir is None:
            missing.append(f"{crop}/{prefix} (PlantVillage class folder not found: {class_name})")
            continue
        process_class(class_dir, crop, prefix, covered, missing)

    print("\nChecking for manually-downloaded Mendeley datasets...")
    if not MENDELEY_DIR.exists():
        print(f"  {MENDELEY_DIR} not found — skipping Mendeley sources.")
        print("  Download manually from the URLs in this script's docstring,")
        print(f"  extract into {MENDELEY_DIR}/<crop>/<disease>/, then re-run.")
        for rel_path, (crop, prefix) in MENDELEY_CLASS_MAP.items():
            missing.append(f"{crop}/{prefix} (Mendeley source not downloaded)")
    else:
        for rel_path, (crop, prefix) in MENDELEY_CLASS_MAP.items():
            class_dir = MENDELEY_DIR / rel_path
            if not class_dir.exists():
                missing.append(f"{crop}/{prefix} (expected folder not found: {class_dir})")
                continue
            process_class(class_dir, crop, prefix, covered, missing)

    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"\nPopulated ({len(covered)}):")
    for c in covered:
        print(f"  - {c}")

    if missing:
        print(f"\nNot found / not downloaded ({len(missing)}):")
        for m in missing:
            print(f"  - {m}")

    print("\nNOT covered by any known open dataset (need field photography or another source):")
    for crop, diseases in UNCOVERED.items():
        for d in diseases:
            print(f"  - {crop}: {d}")

    print(
        "\nNote: still missing assets/images/<crop>/<crop>_crop.jpg cover "
        "photos for each crop, and the crop_tile widget's thumbnails — "
        "this script only fills disease-comparison images. Wikimedia "
        "Commons and the ICRISAT/CIMMYT/CIP photo archives cited in the "
        "project report are reasonable sources for those."
    )


if __name__ == "__main__":
    main()
