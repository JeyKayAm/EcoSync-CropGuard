"""
populate_db.py
──────────────
Generates assets/db/cropguard.db with all crops, diseases, symptoms,
and treatments. Run once from the project root:

    python scripts/populate_db.py

Requirements: Python 3.8+ (stdlib only — no pip installs needed)

All disease and treatment data is sourced from:
  - FAO Plant Production and Protection Series (publicly available)
  - CIMMYT Maize Disease Guide (https://www.cimmyt.org)
  - CORESTA Tobacco Disease Guide (https://www.coresta.org)
  - CABI Crop Protection Compendium (https://www.cabidigitallibrary.org)
  - AGRITEX Zimbabwe Extension Guidelines (Zimbabwe Ministry of Lands)
  - Syngenta Zimbabwe / Corteva Agriscience product labels (public)
  - ZFC Limited (Zimbabwe Fertilizer Company) agro-dealer price lists
"""

import sqlite3
import os
import json

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'db', 'cropguard.db')
os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

# Perceptual hashes for reference photos, precomputed by generate_phashes.py
# (needs Pillow, so that step stays out of this stdlib-only script). Powers
# the on-device Photo Lookup feature's image-similarity ranking.
PHASH_CACHE_PATH = os.path.join(os.path.dirname(__file__), 'phash_cache.json')
if os.path.exists(PHASH_CACHE_PATH):
    with open(PHASH_CACHE_PATH) as f:
        PHASH_CACHE = json.load(f)
else:
    PHASH_CACHE = {}
    print(f'Warning: {PHASH_CACHE_PATH} not found — run generate_phashes.py '
          f'first, or image_phashes will be blank for all diseases. '
          f'Continuing with empty hashes.')

# ─── Schema ───────────────────────────────────────────────────

SCHEMA = """
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS crops (
    id          INTEGER PRIMARY KEY,
    name        TEXT    NOT NULL,
    local_name  TEXT    NOT NULL,
    description TEXT    NOT NULL,
    image_path  TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS diseases (
    id          INTEGER PRIMARY KEY,
    crop_id     INTEGER NOT NULL REFERENCES crops(id),
    name        TEXT    NOT NULL,
    pathogen    TEXT    NOT NULL,
    plant_part  TEXT    NOT NULL CHECK(plant_part IN ('leaf','stem','root','cob','whole')),
    severity    TEXT    NOT NULL CHECK(severity IN ('Low','Medium','High')),
    description TEXT    NOT NULL,
    prevention  TEXT    NOT NULL,
    image_paths TEXT    NOT NULL,  -- comma-separated relative asset paths
    image_phashes TEXT NOT NULL DEFAULT ''  -- comma-separated 16-hex-char aHashes, same order as image_paths
);

CREATE TABLE IF NOT EXISTS symptoms (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    disease_id  INTEGER NOT NULL REFERENCES diseases(id),
    description TEXT    NOT NULL,
    stage       TEXT    NOT NULL CHECK(stage IN ('early','mid','late'))
);

CREATE TABLE IF NOT EXISTS symptom_tags (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    label       TEXT    NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS disease_symptom_tags (
    disease_id  INTEGER NOT NULL REFERENCES diseases(id),
    tag_id      INTEGER NOT NULL REFERENCES symptom_tags(id),
    PRIMARY KEY (disease_id, tag_id)
);

CREATE TABLE IF NOT EXISTS treatments (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    disease_id          INTEGER NOT NULL REFERENCES diseases(id),
    type                TEXT    NOT NULL CHECK(type IN ('organic','chemical')),
    product_name        TEXT    NOT NULL,
    active_ingredient   TEXT    NOT NULL,
    dosage              TEXT    NOT NULL,
    application_method  TEXT    NOT NULL,
    estimated_cost_usd  TEXT    NOT NULL,
    availability        TEXT    NOT NULL,
    source              TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS bookmarks (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    disease_id   INTEGER NOT NULL,
    disease_name TEXT    NOT NULL,
    crop_name    TEXT    NOT NULL,
    saved_at     TEXT    NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_diseases_crop     ON diseases(crop_id);
CREATE INDEX IF NOT EXISTS idx_diseases_part     ON diseases(plant_part);
CREATE INDEX IF NOT EXISTS idx_symptoms_disease  ON symptoms(disease_id);
CREATE INDEX IF NOT EXISTS idx_treatments_disease ON treatments(disease_id);
CREATE INDEX IF NOT EXISTS idx_dst_tag           ON disease_symptom_tags(tag_id);
"""

# ─── Crops ────────────────────────────────────────────────────

CROPS = [
    # (id, name, local_name, description, image_path)
    (1, 'Maize', 'Chibage / Umbila',
     'Zimbabwe\'s staple food crop, grown by the majority of smallholder farmers across all agro-ecological zones.',
     'assets/images/maize/maize_crop.jpg'),
    (2, 'Tobacco', 'Fodya / Ugwayi',
     'Zimbabwe\'s primary export cash crop. Flue-cured Virginia tobacco is grown predominantly in Mashonaland provinces.',
     'assets/images/tobacco/tobacco_crop.jpg'),
    (3, 'Groundnuts', 'Nzungu / Indlubu',
     'Drought-tolerant legume widely grown by smallholders for both household consumption and local sale. Important rotation crop for soil nitrogen fixation.',
     'assets/images/groundnuts/groundnuts_crop.jpg'),
    (4, 'Sorghum', 'Mapfunde / Amabele',
     'Drought-resistant small grain cereal grown in low-rainfall regions where maize yields are unreliable. Key food security crop in Matabeleland and the Lowveld.',
     'assets/images/sorghum/sorghum_crop.jpg'),
    (5, 'Sweet Potatoes', 'Mbatata / Ibhatata',
     'Resilient root crop grown for food security and income across most agro-ecological zones. Tolerates poor soils and erratic rainfall better than most staples.',
     'assets/images/sweet_potatoes/sweet_potatoes_crop.jpg'),
]

# ─── Diseases ─────────────────────────────────────────────────
# (id, crop_id, name, pathogen, plant_part, severity, description, prevention, image_paths)

DISEASES = [
    # ── MAIZE (crop_id=1) ──────────────────────────────────────
    (1, 1, 'Grey Leaf Spot',
     'Cercospora zeae-maydis (fungus)',
     'leaf', 'High',
     'Grey to tan rectangular lesions with yellow halos running parallel to leaf veins. Lesions coalesce under humid conditions, causing premature leaf senescence and significant yield loss.',
     'Plant resistant hybrids. Rotate with non-host crops (soybeans, wheat) for at least one season. Avoid overhead irrigation. Remove and destroy crop residues after harvest.',
     'assets/images/maize/gls_1.jpg,assets/images/maize/gls_2.jpg,assets/images/maize/gls_3.jpg'),

    (2, 1, 'Northern Corn Leaf Blight',
     'Exserohilum turcicum (fungus)',
     'leaf', 'High',
     'Large, elliptical, grey-green lesions 2.5–15 cm long that turn tan/brown at maturity. Lesions appear first on lower leaves and move upward. Reduces photosynthetic area significantly during grain fill.',
     'Use resistant hybrids. Ensure adequate plant spacing for air circulation. Apply fungicides at VT/R1 growth stage if disease pressure is high.',
     'assets/images/maize/nclb_1.jpg,assets/images/maize/nclb_2.jpg,assets/images/maize/nclb_3.jpg'),

    (3, 1, 'Maize Streak Virus',
     'Maize streak virus (MSV) — transmitted by leafhopper Cicadulina spp.',
     'leaf', 'High',
     'Pale yellow streaks along leaf veins, beginning on youngest leaves. Severely infected plants are stunted and fail to produce cobs. Most damaging when infection occurs in the first 3–4 weeks after germination.',
     'Plant MSV-tolerant/resistant varieties. Control leafhopper vectors with insecticide seed dressing. Early planting to escape peak leafhopper populations.',
     'assets/images/maize/msv_1.jpg,assets/images/maize/msv_2.jpg'),

    (4, 1, 'Common Rust',
     'Puccinia sorghi (fungus)',
     'leaf', 'Medium',
     'Small, oval, brick-red to dark brown pustules scattered on both leaf surfaces. Pustules rupture at maturity releasing powdery spores. Severe infection causes premature drying of leaves.',
     'Plant resistant hybrids. Avoid late planting into cooler conditions that favour rust development. Monitor regularly from V6 stage.',
     'assets/images/maize/rust_1.jpg,assets/images/maize/rust_2.jpg,assets/images/maize/rust_3.jpg'),

    (5, 1, 'Stalk Rot (Fusarium)',
     'Fusarium moniliforme / F. graminearum (fungi)',
     'stem', 'High',
     'Internal pith discolouration (pink to salmon) with shredding of stalk tissue. Infected plants lodge (fall over) before harvest. External symptoms include bleached internodes and dead lower leaves.',
     'Avoid water stress and mechanical damage. Balance soil nutrition — excess nitrogen increases susceptibility. Harvest promptly when mature. Rotate with legumes.',
     'assets/images/maize/stalk_rot_1.jpg'),

    # ── TOBACCO (crop_id=2) ────────────────────────────────────
    (6, 2, 'Blue Mould',
     'Peronospora tabacina (oomycete)',
     'leaf', 'High',
     'Yellow to light green angular spots on upper leaf surface with blue-grey sporulation on the underside in humid conditions. Affected leaves shrivel and die rapidly. Spreads explosively in cool, wet weather.',
     'Use certified disease-free transplants. Apply preventive fungicides from the seedbed stage. Improve air circulation in seedbeds and fields. Destroy infected plants immediately.',
     'assets/images/tobacco/blue_mould_1.jpg,assets/images/tobacco/blue_mould_2.jpg'),

    (7, 2, 'Black Shank',
     'Phytophthora nicotianae (oomycete)',
     'stem', 'High',
     'Dark brown to black lesion at or below the soil line. Infected stem collapses, pith turns brown and ladder-like. Plants wilt rapidly and die. Disease spreads through waterlogged soils.',
     'Plant in well-drained soils. Use resistant varieties where available. Avoid introducing infested soil on equipment. Long rotations (4+ years) with non-solanaceous crops.',
     'assets/images/tobacco/black_shank_1.jpg'),

    (8, 2, 'Tobacco Mosaic Virus (TMV)',
     'Tobacco mosaic virus (tobamovirus)',
     'leaf', 'Medium',
     'Mosaic pattern of light and dark green patches on leaves. Leaves may be distorted, blistered, or reduced in size. Mechanically transmitted by hands, tools, and clothing.',
     'Use TMV-tolerant varieties. Wash hands thoroughly with soap before handling plants. Disinfect tools. Do not smoke near plants (cigarettes carry TMV). Control aphid vectors.',
     'assets/images/tobacco/tmv_1.jpg,assets/images/tobacco/tmv_2.jpg'),

    (9, 2, 'Frogeye Leaf Spot',
     'Cercospora nicotianae (fungus)',
     'leaf', 'Medium',
     'Small circular spots with white to tan centres and dark brown borders, resembling a frog\'s eye. Spots may coalesce in severe cases, reducing leaf quality significantly.',
     'Apply protective fungicides. Ensure adequate plant spacing. Avoid excessive nitrogen fertilization. Collect and burn crop debris after harvest.',
     'assets/images/tobacco/frogeye_1.jpg,assets/images/tobacco/frogeye_2.jpg'),

    (10, 2, 'Wildfire',
     'Pseudomonas syringae pv. tabaci (bacterium)',
     'leaf', 'Medium',
     'Water-soaked spots that turn brown with a characteristic yellow halo. The yellow halo distinguishes wildfire from angular leaf spot. Lesions coalesce under wet conditions.',
     'Avoid working in fields when foliage is wet. Use copper-based bactericides preventively. Ensure good drainage. Destroy infected plant material.',
     'assets/images/tobacco/wildfire_1.jpg'),

    # ── GROUNDNUTS (crop_id=3) ──────────────────────────────────
    (11, 3, 'Groundnut Rosette Virus',
     'Groundnut rosette virus (GRV) + satellite RNA — aphid-transmitted (Aphis craccivora)',
     'leaf', 'High',
     'Severe stunting with a characteristic rosette (bushy, dwarfed) growth habit. Leaves are small, chlorotic, and often mottled or distorted. Plants infected within the first 3-4 weeks after emergence may produce no pods at all.',
     'Plant early and densely to reduce aphid landing rate. Intercrop with a tall cereal barrier crop (maize or sorghum) around field margins. Control aphid vectors with seed dressing. Use rosette-tolerant varieties where available.',
     'assets/images/groundnuts/rosette_1.jpg,assets/images/groundnuts/rosette_2.jpg'),

    (12, 3, 'Early Leaf Spot',
     'Cercospora arachidicola (fungus)',
     'leaf', 'Medium',
     'Small circular dark brown to black spots with a pale yellow halo, appearing first on the upper leaf surface of older leaves. Severe infection causes premature leaf drop, reducing pod fill and yield.',
     'Apply protective fungicide from 30 days after emergence. Rotate with cereals (maize, sorghum) for at least 2 seasons. Remove and destroy crop residue after harvest.',
     'assets/images/groundnuts/early_leaf_spot_1.jpg'),

    (13, 3, 'Late Leaf Spot',
     'Phaeoisariopsis personata (fungus)',
     'leaf', 'High',
     'Circular, darker, more uniformly black spots than early leaf spot, usually appearing later in the season. Underside of the spot is rough/velvety with visible fungal fruiting structures. Causes significant defoliation under wet conditions, often more damaging than early leaf spot.',
     'Apply fungicide at first sign, especially after early leaf spot has been seen earlier in the season. Use resistant or tolerant varieties recommended by ICRISAT. Avoid late planting.',
     'assets/images/groundnuts/late_leaf_spot_1.jpg'),

    (14, 3, 'Aflatoxin Contamination',
     'Aspergillus flavus (fungus)',
     'whole', 'High',
     'Fungal contamination of pods and kernels, most severe under drought stress during pod-fill and during damp post-harvest storage. Produces aflatoxin, a carcinogenic toxin that is invisible without laboratory testing but renders grain unsafe for human and animal consumption.',
     'Avoid drought stress during pod development where irrigation is possible. Harvest promptly at maturity, dry pods to below 8% moisture before storage, and store in clean, dry, well-ventilated containers. Discard visibly mouldy or discoloured kernels.',
     'assets/images/groundnuts/aflatoxin_1.jpg'),

    (15, 3, 'Groundnut Rosette Assistor Virus (GRAV)',
     'Groundnut rosette assistor virus — aphid-transmitted (Aphis craccivora)',
     'leaf', 'Medium',
     'Causes only mild mosaic or no visible symptoms when present alone, but is the helper virus required for the aphid to transmit Groundnut Rosette Virus between plants. Fields with high GRAV presence carry elevated risk of a severe rosette outbreak.',
     'Same vector-control measures as Groundnut Rosette Virus: control aphids, plant cereal border rows, use tolerant varieties, and rogue out volunteer groundnut plants between seasons that could harbour the virus.',
     ''),

    # ── SORGHUM (crop_id=4) ──────────────────────────────────────
    (16, 4, 'Sorghum Downy Mildew',
     'Peronosclerospora sorghi (oomycete)',
     'whole', 'High',
     'Systemic infection visible from early seedling stage as chlorotic striping along leaf veins, with white downy fungal growth on the underside in humid mornings. Severely infected shoots are stunted, fail to produce a normal head, and may produce a sterile, leafy "green ear" instead of grain.',
     'Plant certified, treated seed. Rotate with non-cereal crops for at least one season. Remove and destroy infected plants as soon as identified, before sporulation spreads the disease.',
     'assets/images/sorghum/downy_mildew_1.jpg'),

    (17, 4, 'Head Smut',
     'Sporisorium reilianum (fungus)',
     'cob', 'High',
     'The entire grain head is replaced by a grey-black powdery mass of fungal spores, initially enclosed in a thin membrane that ruptures to release spores. Infected plants are often slightly stunted before head emergence reveals the disease. Soil-borne and seed-borne.',
     'Use certified, fungicide-treated seed. Rotate with non-host crops for 2+ seasons in fields with a history of head smut. Remove and burn smutted heads before the membrane ruptures to limit soil spore load.',
     'assets/images/sorghum/head_smut_1.jpg'),

    (18, 4, 'Anthracnose',
     'Colletotrichum sublineola (fungus)',
     'leaf', 'High',
     'Small circular to oval red, tan, or straw-coloured lesions with dark margins on leaves, which can coalesce in severe infections. The same pathogen can also cause stalk rot and head blight later in the season, the latter discolouring grain and reducing quality.',
     'Plant resistant or tolerant varieties. Rotate with non-host crops. Avoid excessive nitrogen fertilization, which increases susceptibility. Remove and destroy crop residue after harvest.',
     'assets/images/sorghum/anthracnose_1.jpg,assets/images/sorghum/anthracnose_2.jpg'),

    (19, 4, 'Sorghum Ergot',
     'Claviceps africana (fungus)',
     'cob', 'High',
     'Sticky, sugary honeydew exudate oozes from infected flowers shortly after flowering, often attracting insects. Infected ovaries are eventually replaced by hard, dark sclerotia in place of normal grain. Sclerotia are toxic to livestock if consumed in quantity.',
     'Plant during the recommended window to ensure flowering avoids cool, humid conditions that favour infection. Use ergot-free certified seed. Avoid feeding heavily contaminated grain or screenings to livestock.',
     'assets/images/sorghum/ergot_1.jpg,assets/images/sorghum/ergot_2.jpg'),

    (20, 4, 'Leaf Blight',
     'Exserohilum turcicum (fungus)',
     'leaf', 'Medium',
     'Elongated, tan to grey-green lesions with reddish-purple borders on leaves, beginning on lower leaves and progressing upward. Severe infection reduces the photosynthetic leaf area available during grain fill, lowering yield.',
     'Plant resistant or tolerant varieties. Ensure adequate plant spacing for airflow. Rotate with non-host crops to reduce residue-borne inoculum.',
     'assets/images/sorghum/leaf_blight_1.jpg'),

    # ── SWEET POTATOES (crop_id=5) ────────────────────────────────
    (21, 5, 'Sweet Potato Virus Disease (SPVD)',
     'Co-infection of SPFMV + SPCSV — whitefly and aphid transmitted',
     'leaf', 'High',
     'Severe stunting, leaf distortion, vein clearing or purpling, and chlorotic mottling. SPVD results from two viruses infecting the same plant together; the combination is dramatically more damaging than either virus alone, capable of causing total yield loss in susceptible varieties.',
     'Use certified virus-free planting material (vines) rather than re-using vines from a previous infected crop. Control whitefly and aphid vectors. Rogue out and destroy infected plants early. Plant tolerant varieties where available.',
     'assets/images/sweet_potatoes/spvd_1.jpg'),

    (22, 5, 'Alternaria Leaf Blight',
     'Alternaria bataticola (fungus)',
     'leaf', 'Medium',
     'Irregular brown to black spots with concentric ring patterns on leaves, sometimes with a yellow halo. Severe infection causes premature defoliation, which reduces the plant\u2019s ability to bulk roots.',
     'Avoid overhead irrigation. Maintain adequate spacing for airflow. Remove and destroy heavily infected vines. Apply protective fungicide in high-risk wet seasons.',
     'assets/images/sweet_potatoes/alternaria_1.jpg'),

    (23, 5, 'Black Rot',
     'Ceratocystis fimbriata (fungus)',
     'root', 'High',
     'Circular, sunken, dark brown to black lesions on storage roots, with a greenish-black discolouration in the flesh beneath and a bitter taste that develops even in unaffected tissue of the same root. Spreads readily in storage, destroying entire batches.',
     'Use disease-free planting material from clean nursery beds. Practice crop rotation of 3+ years in affected fields. Cure roots properly after harvest and inspect carefully before storage; discard any lesioned roots immediately.',
     'assets/images/sweet_potatoes/black_rot_1.jpg,assets/images/sweet_potatoes/black_rot_2.jpg'),

    (24, 5, 'Fusarium Wilt',
     'Fusarium oxysporum f. sp. batatas (fungus)',
     'whole', 'High',
     'Yellowing and wilting beginning with the lower, older leaves and progressing upward. Internal vascular tissue shows brown discolouration when the stem base is cut. Infected plants are stunted and may die before harvest, especially under heat or moisture stress.',
     'Use resistant or tolerant varieties. Plant only certified disease-free vines. Rotate with non-host crops for several seasons in fields with a history of wilt.',
     'assets/images/sweet_potatoes/fusarium_wilt_1.jpg,assets/images/sweet_potatoes/fusarium_wilt_2.jpg'),

    (25, 5, 'Scurf',
     'Monilochaetes infuscans (fungus)',
     'root', 'Low',
     'Superficial dark brown to black blemishes on the skin of storage roots, which do not affect the internal flesh or eating quality but significantly reduce market appearance and value. Spreads in storage between roots in contact with each other under humid conditions.',
     'Plant disease-free vine cuttings from clean nursery stock. Rotate fields. Cure and store roots in a well-ventilated, moderately dry environment to limit spread between roots.',
     'assets/images/sweet_potatoes/scurf_1.jpg'),
]

# ─── Symptoms ─────────────────────────────────────────────────
# (disease_id, description, stage)

SYMPTOMS = [
    # Grey Leaf Spot (1)
    (1, 'Small pale spots with yellow borders on lower leaves', 'early'),
    (1, 'Rectangular grey-tan lesions running parallel to leaf veins', 'mid'),
    (1, 'Lesions coalesce; leaves die from the tip downward', 'late'),
    # NCLB (2)
    (2, 'Small water-soaked oval spots on lower leaves', 'early'),
    (2, 'Large elliptical grey-green lesions 2.5–15 cm long', 'mid'),
    (2, 'Lesions turn tan-brown; whole lower canopy dies off', 'late'),
    # MSV (3)
    (3, 'Faint yellow streaks on youngest leaves', 'early'),
    (3, 'Clear yellow-white streaks along leaf veins; plant stunting begins', 'mid'),
    (3, 'Severe stunting; no cob formation; whole plant yellows', 'late'),
    # Common Rust (4)
    (4, 'Tiny raised chlorotic spots on leaf surfaces', 'early'),
    (4, 'Brick-red oval pustules on both leaf surfaces', 'mid'),
    (4, 'Pustules turn dark brown; leaves dry prematurely', 'late'),
    # Stalk Rot (5)
    (5, 'Lower leaves yellowing; plant looks water-stressed', 'early'),
    (5, 'Soft, spongy feel on lower internodes when squeezed', 'mid'),
    (5, 'Plant lodges; pith completely shredded; bleached stem', 'late'),
    # Blue Mould (6)
    (6, 'Pale green-yellow spots on upper leaf surface', 'early'),
    (6, 'Blue-grey sporulation on underside of leaf spots', 'mid'),
    (6, 'Leaf shrivels and dies; rapid spread through crop', 'late'),
    # Black Shank (7)
    (7, 'Slight wilting of lower leaves during daytime', 'early'),
    (7, 'Black lesion visible at soil line on stem', 'mid'),
    (7, 'Plant collapses; pith brown and hollow; whole plant dies', 'late'),
    # TMV (8)
    (8, 'Faint mosaic mottling on young leaves', 'early'),
    (8, 'Clear light-dark green mosaic; leaf distortion', 'mid'),
    (8, 'Severe leaf curl; plant stunted; reduced leaf size', 'late'),
    # Frogeye Tobacco (9)
    (9, 'Tiny circular spots with faint yellow borders', 'early'),
    (9, 'White-tan centres with dark brown circular borders', 'mid'),
    (9, 'Spots coalesce; leaf quality severely reduced', 'late'),
    # Wildfire (10)
    (10, 'Water-soaked spots appear after rain', 'early'),
    (10, 'Brown lesions with distinctive yellow halo', 'mid'),
    (10, 'Large coalesced lesions; leaf death under continued wet weather', 'late'),
    # Groundnut Rosette Virus (11)
    (11, 'Slight stunting; faint leaf mottling visible up close', 'early'),
    (11, 'Clear bushy rosette growth habit; leaves small and chlorotic', 'mid'),
    (11, 'Severe stunting; plant fails to produce pods', 'late'),
    # Early Leaf Spot (12)
    (12, 'Tiny dark specks on upper surface of older leaves', 'early'),
    (12, 'Circular dark brown spots with pale yellow halo', 'mid'),
    (12, 'Heavy defoliation; lower canopy leaves dropped', 'late'),
    # Late Leaf Spot (13)
    (13, 'Small dark spots appearing later in the season than early leaf spot', 'early'),
    (13, 'Uniform black circular spots; rough underside texture', 'mid'),
    (13, 'Severe defoliation under wet conditions; reduced pod fill', 'late'),
    # Aflatoxin (14)
    (14, 'No visible symptom in field; risk highest under drought at pod-fill', 'early'),
    (14, 'Visible mould growth on damaged or cracked pods at harvest', 'mid'),
    (14, 'Discoloured, mouldy kernels in poorly dried or stored grain', 'late'),
    # GRAV (15)
    (15, 'No visible symptom, or very faint mosaic mottling', 'early'),
    (15, 'Mild mosaic pattern on some leaves if symptoms appear at all', 'mid'),
    (15, 'Co-infected plants develop full rosette disease via GRV', 'late'),
    # Sorghum Downy Mildew (16)
    (16, 'Pale chlorotic striping on youngest leaves of seedlings', 'early'),
    (16, 'White downy fungal growth visible on leaf underside in early morning', 'mid'),
    (16, 'Severe stunting; sterile leafy "green ear" instead of grain head', 'late'),
    # Head Smut (17)
    (17, 'Slight stunting before head emergence; otherwise symptomless', 'early'),
    (17, 'Head emerges enclosed in a thin grey membrane', 'mid'),
    (17, 'Membrane ruptures releasing black powdery spore mass', 'late'),
    # Anthracnose Sorghum (18)
    (18, 'Small red-tan flecks on leaves', 'early'),
    (18, 'Oval lesions with dark margins; lesions coalesce', 'mid'),
    (18, 'Stalk rot and head blight discolouring grain at maturity', 'late'),
    # Sorghum Ergot (19)
    (19, 'Sticky honeydew exudate from flowers shortly after flowering', 'early'),
    (19, 'Honeydew attracts insects; ovaries begin to swell abnormally', 'mid'),
    (19, 'Hard dark sclerotia replace grain in affected florets', 'late'),
    # Leaf Blight Sorghum (20)
    (20, 'Small water-soaked lesions on lower leaves', 'early'),
    (20, 'Elongated tan-grey lesions with reddish-purple borders', 'mid'),
    (20, 'Lesions progress up the plant; significant leaf area lost', 'late'),
    # SPVD (21)
    (21, 'Faint vein clearing on youngest leaves', 'early'),
    (21, 'Leaf distortion, mottling, and vein purpling develop', 'mid'),
    (21, 'Severe stunting; little to no root bulking', 'late'),
    # Alternaria Sweet Potato (22)
    (22, 'Small brown spots appear on lower leaves', 'early'),
    (22, 'Spots enlarge with visible concentric ring pattern', 'mid'),
    (22, 'Premature defoliation reduces root bulking capacity', 'late'),
    # Black Rot (23)
    (23, 'Small dark lesions appear on root surface, often near wounds', 'early'),
    (23, 'Lesion enlarges into a sunken, circular black spot', 'mid'),
    (23, 'Greenish-black flesh discolouration and bitter taste spread inward', 'late'),
    # Fusarium Wilt Sweet Potato (24)
    (24, 'Lower, older leaves begin yellowing', 'early'),
    (24, 'Wilting progresses upward; vascular browning visible at stem base', 'mid'),
    (24, 'Plant stunted or dies before harvest under stress conditions', 'late'),
    # Scurf (25)
    (25, 'Small dark blemishes appear on root skin near harvest', 'early'),
    (25, 'Blemishes enlarge into irregular dark brown-black patches', 'mid'),
    (25, 'Patches spread between roots in storage under humid conditions', 'late'),
]

# ─── Symptom Tags (shared checklist vocabulary for the Symptom Checker) ──
# Curated from the free-text SYMPTOMS above — same sourcing, just normalized
# into a shared vocabulary a user can pick from as checklist input rather
# than only viewing symptoms read-only per disease.

SYMPTOM_TAGS = [
    (1,  'Yellowing of lower/older leaves'),
    (2,  'Small pale or yellow-bordered leaf spots'),
    (3,  'Circular/oval leaf spots with a dark or brown border'),
    (4,  'Elongated grey-tan or grey-green leaf lesions'),
    (5,  'Leaf lesions merging, causing dieback or premature leaf death'),
    (6,  'Powdery, mouldy, or fungal growth visible on plant surface'),
    (7,  'Raised pustules on leaf surface'),
    (8,  'Yellow streaking or striping along leaf veins'),
    (9,  'Mosaic or mottled leaf colour pattern'),
    (10, 'Leaf curling, distortion, or blistering'),
    (11, 'Water-soaked spots on leaves'),
    (12, 'Stunted plant growth'),
    (13, 'Wilting despite normal soil moisture'),
    (14, 'Dark lesion or rot at stem base / soil line'),
    (15, 'Soft, rotting, or collapsed stem/stalk tissue'),
    (16, 'Plant lodging (falling over)'),
    (17, 'Internal stem/vascular discolouration'),
    (18, 'Premature or heavy leaf drop (defoliation)'),
    (19, 'Sunken or dark lesions on storage roots/tubers'),
    (20, 'Internal root/tuber flesh discolouration'),
    (21, 'Surface blemishes on root/tuber skin only'),
    (22, 'Grain head or cob replaced by abnormal/fungal mass'),
    (23, 'Sticky exudate on flowers or developing grain'),
    (24, 'No visible field symptom (risk shows post-harvest/in storage)'),
]

# (disease_id, tag_id) — each disease mapped to the tags matching its
# SYMPTOMS entries above.
DISEASE_SYMPTOM_TAGS = [
    (1, 2), (1, 4), (1, 5),                    # Grey Leaf Spot
    (2, 11), (2, 4), (2, 5),                   # Northern Corn Leaf Blight
    (3, 8), (3, 12), (3, 1),                   # Maize Streak Virus
    (4, 7), (4, 5),                            # Common Rust
    (5, 1), (5, 15), (5, 16),                  # Stalk Rot
    (6, 2), (6, 6), (6, 5),                    # Blue Mould
    (7, 13), (7, 14), (7, 17),                 # Black Shank
    (8, 9), (8, 10), (8, 12),                  # Tobacco Mosaic Virus
    (9, 2), (9, 3), (9, 5),                    # Frogeye Leaf Spot
    (10, 11), (10, 2), (10, 5),                # Wildfire
    (11, 12), (11, 9),                         # Groundnut Rosette Virus
    (12, 2), (12, 3), (12, 18),                # Early Leaf Spot
    (13, 2), (13, 3), (13, 18),                # Late Leaf Spot
    (14, 24), (14, 6),                         # Aflatoxin Contamination
    (15, 24), (15, 9), (15, 12),               # Groundnut Rosette Assistor Virus
    (16, 8), (16, 6), (16, 12),                # Sorghum Downy Mildew
    (17, 12), (17, 22),                        # Head Smut
    (18, 2), (18, 3), (18, 15),                # Anthracnose (Sorghum)
    (19, 23), (19, 22),                        # Sorghum Ergot
    (20, 11), (20, 4), (20, 18),               # Leaf Blight (Sorghum)
    (21, 9), (21, 10), (21, 12),               # Sweet Potato Virus Disease
    (22, 2), (22, 3), (22, 18),                # Alternaria Leaf Blight
    (23, 19), (23, 20),                        # Black Rot
    (24, 1), (24, 13), (24, 17), (24, 12),     # Fusarium Wilt
    (25, 21),                                  # Scurf
]

# ─── Treatments ───────────────────────────────────────────────
# (disease_id, type, product_name, active_ingredient, dosage,
#  application_method, estimated_cost_usd, availability, source)

TREATMENTS = [
    # Grey Leaf Spot (1)
    (1,'organic','Crop Rotation + Debris Removal','Cultural practice',
     'Remove all crop residue after harvest; rotate with soybeans or wheat for 1 season',
     'Field management','$0 (labour only)',
     'All districts','FAO Plant Production Series No.23; CIMMYT Maize Disease Guide 2022'),
    (1,'chemical','Amistar (Azoxystrobin 250 SC)','Azoxystrobin',
     '0.5 L/ha in 200–300 L water; apply at VT stage, repeat after 14 days if needed',
     'Knapsack or boom sprayer','$18–$24 / litre',
     'Syngenta Zimbabwe dealers; Agribank agro-dealers','Syngenta Zimbabwe product label; CIMMYT 2022'),

    # NCLB (2)
    (2,'organic','Plant Spacing Optimisation','Cultural practice',
     'Maintain 75 cm between rows; 25 cm between plants for adequate airflow',
     'Planting layout','$0','All districts',
     'CIMMYT Maize Production Guidelines for Zimbabwe 2021'),
    (2,'chemical','Dithane M-45 (Mancozeb 80 WP)','Mancozeb 80%',
     '2 kg/ha in 400 L water; apply at first sign of disease; repeat every 10–14 days',
     'Boom sprayer or knapsack','$4.50–$6.00 / kg',
     'Farmers World; ZFC Agro-dealers; Agritex depots','Dow AgroSciences label; CABI CPC'),

    # MSV (3)
    (3,'organic','Leafhopper Barrier Planting','Cultural practice',
     'Plant a 2-row border of a resistant variety around the field; rogue out heavily infected plants',
     'Field management','$0',
     'All districts','CIMMYT MSV Management Guide 2019'),
    (3,'chemical','Confidor (Imidacloprid 350 SC)','Imidacloprid 350 g/L',
     'Seed treatment: 7 mL per kg of seed; OR foliar: 0.35 L/ha at V3–V4 for vector control',
     'Seed dressing or knapsack sprayer','$12–$16 / litre',
     'Bayer Crop Science dealers; Farmers World','Bayer CropScience Zimbabwe label; FAO IPM Guidelines'),

    # Common Rust (4)
    (4,'organic','Resistant Variety Selection','Cultural practice',
     'Plant SC403, SC513, or other rust-tolerant hybrids recommended by Seed Co Zimbabwe',
     'Variety selection at planting','$0',
     'Seed Co dealers nationwide','Seed Co Zimbabwe 2023 Variety Guide'),
    (4,'chemical','Tilt 250 EC (Propiconazole)','Propiconazole 250 g/L',
     '0.5 L/ha in 200 L water; apply at first pustule appearance',
     'Knapsack or boom sprayer','$14–$18 / litre',
     'Syngenta Zimbabwe; Agribank dealers','Syngenta label; CABI Crop Protection Compendium'),

    # Stalk Rot (5)
    (5,'organic','Balanced Nutrition & Timely Harvest','Cultural practice',
     'Apply recommended NPK; avoid excess nitrogen; harvest within 2 weeks of physiological maturity',
     'Field management','$0',
     'All districts','FAO Maize Production Manual; CIMMYT Stalk Rot Guide'),
    (5,'chemical','Apron Star (Metalaxyl + Thiamethoxam)','Metalaxyl-M 20g/L + Thiamethoxam 560g/L',
     'Seed treatment: 4 g/kg of seed',
     'Seed dressing','$18–$22 / kg',
     'Syngenta Zimbabwe dealers','Syngenta Zimbabwe product label'),

    # Blue Mould (6)
    (6,'organic','Seedbed Hygiene & Spacing','Cultural practice',
     'Sanitize seedbeds; remove volunteer tobacco plants; maintain spacing 90 x 60 cm in field',
     'Field management','$0',
     'All districts','CORESTA Blue Mould Guidelines 2020'),
    (6,'chemical','Ridomil Gold (Metalaxyl-M + Mancozeb)','Metalaxyl-M 40g/kg + Mancozeb 640g/kg',
     '2.5 kg/ha; apply preventively at transplanting and every 7–10 days in high-risk weather',
     'Knapsack sprayer — thorough coverage of all leaf surfaces','$22–$28 / kg',
     'Syngenta Zimbabwe dealers; Tobacco Research Board (TRB) depots',
     'CORESTA 2020; TRB Zimbabwe Technical Bulletin; Syngenta label'),

    # Black Shank (7)
    (7,'organic','Drainage Improvement','Cultural practice',
     'Plant on ridges or in well-drained soils; avoid waterlogged fields; long crop rotation (4+ years)',
     'Field management','$0',
     'All districts','FAO Tobacco Production Guidelines; CORESTA Black Shank Technical Bulletin'),
    (7,'chemical','Ridomil Gold MZ (Metalaxyl-M + Mancozeb)','Metalaxyl-M 40g/kg + Mancozeb 640g/kg',
     '3 kg/ha as soil drench at transplanting; repeat at 6-week interval',
     'Soil drench applied to base of plant','$22–$28 / kg',
     'TRB depots; Syngenta Zimbabwe dealers','Syngenta label; CORESTA 2020'),

    # TMV (8)
    (8,'organic','Hand Hygiene & Tool Disinfection','Cultural practice',
     'Wash hands with soap before handling plants; soak tools in 10% skimmed milk solution for 10 min',
     'Field management','Minimal cost',
     'All districts','CORESTA TMV Management Guide; FAO Plant Virus Bulletin'),
    (8,'chemical','No effective chemical cure — prevention only','N/A',
     'Rogue out and destroy infected plants; no post-infection chemical treatment available',
     'Manual removal','$0',
     'N/A','CORESTA 2020; CABI CPC TMV entry'),

    # Frogeye Tobacco (9)
    (9,'organic','Crop Debris Management','Cultural practice',
     'Collect and burn all crop debris after harvest; do not leave residues in field',
     'Field management','$0',
     'All districts','FAO Tobacco Disease Guide; CABI CPC'),
    (9,'chemical','Dithane M-45 (Mancozeb 80 WP)','Mancozeb 80%',
     '2 kg/ha in 400 L water; apply at first spot appearance; repeat every 10–14 days',
     'Knapsack sprayer','$4.50–$6.00 / kg',
     'Farmers World; Agribank dealers','Dow AgroSciences label; CABI CPC'),

    # Wildfire (10)
    (10,'organic','Avoid Wet-Weather Operations','Cultural practice',
     'Do not work in field when foliage is wet; control workers moving between infected and healthy blocks',
     'Field management','$0',
     'All districts','FAO Plant Bacteriology Guidelines'),
    (10,'chemical','Kocide 2000 (Copper Hydroxide 53.8 WG)','Copper hydroxide 538 g/kg',
     '1.5–2 kg/ha in 400 L water; apply preventively after rain events',
     'Knapsack or boom sprayer','$16–$20 / kg',
     'FMC Zimbabwe dealers; Agribank agro-dealers','DuPont/FMC label; CORESTA Wildfire Bulletin'),

    # Groundnut Rosette Virus (11)
    (11,'organic','Cereal Border Planting + Early Sowing','Cultural practice',
     'Plant a 2-row maize or sorghum border around groundnut fields; sow at onset of rains to reduce aphid colonisation window',
     'Field management','$0',
     'All districts','ICRISAT Groundnut Rosette Management Guide; AGRITEX Bulletin'),
    (11,'chemical','Confidor (Imidacloprid 350 SC)','Imidacloprid 350 g/L',
     'Seed treatment: 7 mL per kg seed for early-season aphid vector suppression',
     'Seed dressing','$12–$16 / litre',
     'Bayer Crop Science dealers; Farmers World','Bayer label; ICRISAT Rosette Guide'),

    # Early Leaf Spot (12)
    (12,'organic','Crop Rotation','Cultural practice',
     'Rotate with maize or sorghum for at least 2 seasons; remove crop residue after harvest',
     'Field management','$0',
     'All districts','ICRISAT Groundnut Disease Compendium'),
    (12,'chemical','Dithane M-45 (Mancozeb 80 WP)','Mancozeb 80%',
     '2 kg/ha in 400 L water from 30 days after emergence; repeat every 14 days',
     'Knapsack sprayer','$4.50–$6.00 / kg',
     'Farmers World; ZFC Agro-dealers','Dow AgroSciences label; ICRISAT Compendium'),

    # Late Leaf Spot (13)
    (13,'organic','Tolerant Variety Selection','Cultural practice',
     'Plant ICRISAT-recommended tolerant varieties; avoid late planting which extends exposure',
     'Variety selection','$0',
     'ICRISAT/AGRITEX seed outlets','ICRISAT Groundnut Disease Compendium'),
    (13,'chemical','Tilt 250 EC (Propiconazole)','Propiconazole 250 g/L',
     '0.5 L/ha in 200 L water at first sign, especially following an early leaf spot outbreak',
     'Knapsack or boom sprayer','$14–$18 / litre',
     'Syngenta Zimbabwe dealers','Syngenta label; ICRISAT Compendium'),

    # Aflatoxin (14)
    (14,'organic','Timely Harvest & Proper Drying','Cultural practice',
     'Harvest promptly at maturity; dry pods to below 8% moisture before storage; avoid drought stress where irrigation is possible',
     'Post-harvest management','$0 (labour only)',
     'All districts','FAO/ICRISAT Aflatoxin Prevention Guidelines'),
    (14,'chemical','No chemical treatment removes existing aflatoxin','N/A',
     'Discard visibly mouldy or discoloured kernels before consumption or sale; prevention through drying and storage hygiene is the only control',
     'N/A','$0',
     'N/A','FAO Aflatoxin Management Guidance; ICRISAT Compendium'),

    # GRAV (15)
    (15,'organic','Vector Control & Volunteer Plant Removal','Cultural practice',
     'Apply the same aphid-control and cereal-border measures used for Groundnut Rosette Virus; rogue out volunteer groundnut plants between seasons',
     'Field management','$0',
     'All districts','ICRISAT Groundnut Rosette Management Guide'),
    (15,'chemical','Confidor (Imidacloprid 350 SC)','Imidacloprid 350 g/L',
     'Seed treatment: 7 mL per kg seed for aphid vector suppression',
     'Seed dressing','$12–$16 / litre',
     'Bayer Crop Science dealers','Bayer label; ICRISAT Rosette Guide'),

    # Sorghum Downy Mildew (16)
    (16,'organic','Certified Seed & Rotation','Cultural practice',
     'Plant certified, treated seed only; rotate with non-cereal crops for at least one season in affected fields',
     'Field management','$0',
     'All districts','ICRISAT Sorghum Pathology Reports'),
    (16,'chemical','Apron Star (Metalaxyl + Thiamethoxam)','Metalaxyl-M 20g/L + Thiamethoxam 560g/L',
     'Seed treatment: 4 g/kg of seed before planting',
     'Seed dressing','$18–$22 / kg',
     'Syngenta Zimbabwe dealers','Syngenta label; ICRISAT Sorghum Pathology Reports'),

    # Head Smut (17)
    (17,'organic','Resistant Variety & Residue Management','Cultural practice',
     'Plant resistant varieties where available; remove and burn smutted heads before the membrane ruptures',
     'Field management','$0',
     'All districts','ICRISAT Sorghum Pathology Reports; FAO Sorghum Guide'),
    (17,'chemical','Vitavax (Carboxin + Thiram)','Carboxin 200g/kg + Thiram 200g/kg',
     'Seed treatment: 2-3 g/kg seed before planting',
     'Seed dressing','$10–$14 / kg',
     'Windmill Agro; ZFC Agro-dealers','Windmill Agro label; ICRISAT Compendium'),

    # Anthracnose Sorghum (18)
    (18,'organic','Resistant Variety & Balanced Fertilization','Cultural practice',
     'Plant resistant or tolerant varieties; avoid excessive nitrogen; rotate with non-host crops',
     'Field management','$0',
     'All districts','ICRISAT Sorghum Pathology Reports'),
    (18,'chemical','Tilt 250 EC (Propiconazole)','Propiconazole 250 g/L',
     '0.5 L/ha in 200 L water at first sign of leaf lesions',
     'Knapsack or boom sprayer','$14–$18 / litre',
     'Syngenta Zimbabwe dealers','Syngenta label; ICRISAT Compendium'),

    # Sorghum Ergot (19)
    (19,'organic','Timed Planting & Seed Selection','Cultural practice',
     'Plant within the recommended window so flowering avoids cool, humid conditions; use ergot-free certified seed',
     'Planting schedule','$0',
     'All districts','FAO Sorghum Guide; ICRISAT Ergot Advisory'),
    (19,'chemical','No effective in-season chemical control','N/A',
     'No registered fungicide reliably controls ergot once flowering has begun; avoid feeding heavily contaminated grain to livestock',
     'N/A','$0',
     'N/A','ICRISAT Sorghum Pathology Reports; FAO Sorghum Guide'),

    # Leaf Blight Sorghum (20)
    (20,'organic','Resistant Variety & Plant Spacing','Cultural practice',
     'Plant resistant or tolerant varieties; maintain adequate row spacing for airflow',
     'Field management','$0',
     'All districts','FAO Sorghum Guide; ICRISAT Compendium'),
    (20,'chemical','Dithane M-45 (Mancozeb 80 WP)','Mancozeb 80%',
     '2 kg/ha in 400 L water at first sign; repeat every 10–14 days',
     'Knapsack or boom sprayer','$4.50–$6.00 / kg',
     'Farmers World; ZFC Agro-dealers','Dow AgroSciences label; ICRISAT Compendium'),

    # SPVD (21)
    (21,'organic','Certified Vine Material & Vector Control','Cultural practice',
     'Use certified virus-free planting vines rather than re-using vines from a previous crop; rogue out infected plants early',
     'Field management','$0',
     'CIP-affiliated nursery outlets; AGRITEX district offices','CIP Sweet Potato Disease Guide'),
    (21,'chemical','Confidor (Imidacloprid 350 SC)','Imidacloprid 350 g/L',
     '0.35 L/ha for whitefly and aphid vector suppression, applied from early growth stage',
     'Knapsack sprayer','$12–$16 / litre',
     'Bayer Crop Science dealers','Bayer label; CIP Sweet Potato Disease Guide'),

    # Alternaria Sweet Potato (22)
    (22,'organic','Spacing & Vine Removal','Cultural practice',
     'Maintain adequate spacing for airflow; avoid overhead irrigation; remove heavily infected vines',
     'Field management','$0',
     'All districts','CIP Sweet Potato Disease Guide'),
    (22,'chemical','Dithane M-45 (Mancozeb 80 WP)','Mancozeb 80%',
     '2 kg/ha in 400 L water in high-risk wet seasons; repeat every 10–14 days',
     'Knapsack sprayer','$4.50–$6.00 / kg',
     'Farmers World; Agribank dealers','Dow AgroSciences label; CIP Disease Guide'),

    # Black Rot (23)
    (23,'organic','Disease-Free Vines & Careful Curing','Cultural practice',
     'Use only disease-free planting material from clean nursery beds; cure roots properly and inspect before storage, discarding lesioned roots',
     'Post-harvest management','$0 (labour only)',
     'All districts','CIP Sweet Potato Disease Guide'),
    (23,'chemical','No effective post-infection chemical treatment','N/A',
     'No registered fungicide reverses black rot once roots are infected; prevention through clean planting material and storage hygiene is critical',
     'N/A','$0',
     'N/A','CIP Sweet Potato Disease Guide; CABI CPC Ceratocystis entry'),

    # Fusarium Wilt Sweet Potato (24)
    (24,'organic','Resistant Variety & Rotation','Cultural practice',
     'Plant resistant or tolerant varieties; use certified disease-free vines; rotate with non-host crops in affected fields',
     'Field management','$0',
     'All districts','CIP Sweet Potato Disease Guide'),
    (24,'chemical','No highly effective chemical control','N/A',
     'No registered fungicide provides reliable control once established; prevention through resistant varieties and clean planting material is the main defence',
     'N/A','$0',
     'N/A','CIP Sweet Potato Disease Guide; CABI CPC Fusarium entry'),

    # Scurf (25)
    (25,'organic','Clean Planting Material & Storage Conditions','Cultural practice',
     'Plant disease-free vine cuttings from clean nursery stock; rotate fields; store roots in a well-ventilated, moderately dry environment',
     'Field and storage management','$0',
     'All districts','CIP Sweet Potato Disease Guide'),
    (25,'chemical','No chemical control required','N/A',
     'Scurf does not affect internal flesh quality; management is entirely cultural (clean planting material and dry storage)',
     'N/A','$0',
     'N/A','CIP Sweet Potato Disease Guide'),
]

# ─── Build the DB ─────────────────────────────────────────────

def main():
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
        print(f'Removed existing {DB_PATH}')

    conn = sqlite3.connect(DB_PATH)
    conn.executescript(SCHEMA)
    print('Schema created.')

    conn.executemany(
        'INSERT INTO crops (id,name,local_name,description,image_path) VALUES (?,?,?,?,?)',
        CROPS,
    )
    print(f'Inserted {len(CROPS)} crops.')

    diseases_with_phashes = []
    missing_hashes = []
    for row in DISEASES:
        image_paths = row[-1]
        paths = [p for p in image_paths.split(',') if p]
        phashes = []
        for path in paths:
            h = PHASH_CACHE.get(path)
            if h is None:
                missing_hashes.append(path)
            else:
                phashes.append(h)
        diseases_with_phashes.append(row + (','.join(phashes),))
    if missing_hashes:
        print(f'Warning: no cached phash for {len(missing_hashes)} image(s), '
              f'e.g. {missing_hashes[0]!r} — run generate_phashes.py to refresh '
              f'scripts/phash_cache.json.')

    conn.executemany(
        '''INSERT INTO diseases
           (id,crop_id,name,pathogen,plant_part,severity,description,prevention,image_paths,image_phashes)
           VALUES (?,?,?,?,?,?,?,?,?,?)''',
        diseases_with_phashes,
    )
    print(f'Inserted {len(DISEASES)} diseases.')

    conn.executemany(
        'INSERT INTO symptoms (disease_id,description,stage) VALUES (?,?,?)',
        SYMPTOMS,
    )
    print(f'Inserted {len(SYMPTOMS)} symptoms.')

    conn.executemany(
        'INSERT INTO symptom_tags (id,label) VALUES (?,?)',
        SYMPTOM_TAGS,
    )
    print(f'Inserted {len(SYMPTOM_TAGS)} symptom tags.')

    conn.executemany(
        'INSERT INTO disease_symptom_tags (disease_id,tag_id) VALUES (?,?)',
        DISEASE_SYMPTOM_TAGS,
    )
    print(f'Inserted {len(DISEASE_SYMPTOM_TAGS)} disease-symptom tag mappings.')

    conn.executemany(
        '''INSERT INTO treatments
           (disease_id,type,product_name,active_ingredient,dosage,
            application_method,estimated_cost_usd,availability,source)
           VALUES (?,?,?,?,?,?,?,?,?)''',
        TREATMENTS,
    )
    print(f'Inserted {len(TREATMENTS)} treatments.')

    conn.commit()
    conn.close()
    print(f'\n✓ cropguard.db written to {os.path.abspath(DB_PATH)}')
    print('  Copy this file to assets/db/ in your Flutter project.')


if __name__ == '__main__':
    main()
