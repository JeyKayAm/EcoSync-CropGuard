# Reference Image Sources

**Status: prototype / proof-of-concept only — not distributed, not shipped.**
Per the project owner (2026-08-02), images from 2026-08-02 onward are sourced
from whatever public page has a correct, verifiable match for the disease,
without formal license clearance — acceptable because this build never
leaves local/demo use. **Before any public release or distribution, redo
this sourcing pass with real license clearance** (see the "Vetted
open-license sources" list below for where to start that pass).

Every entry below still records source + author where available, so a real
clearance pass later doesn't start from zero.

| File | Disease | Source | Author / Copyright | License | Accessed |
|---|---|---|---|---|---|
| `maize/gls_1.jpg`, `gls_2.jpg`, `gls_3.jpg` | Grey Leaf Spot | *(pre-existing, source not recorded)* | — | — | — |
| `maize/nclb_1.jpg`, `nclb_2.jpg`, `nclb_3.jpg` | Northern Corn Leaf Blight | *(pre-existing, source not recorded)* | — | — | — |
| `maize/rust_1.jpg`, `rust_2.jpg`, `rust_3.jpg` | Common Rust | *(pre-existing, source not recorded)* | — | — | — |
| `maize/msv_1.jpg` | Maize Streak Virus | [Infonet Biovision — Maize Streak Virus](https://infonet-biovision.org/PlantHealth/MinorPests/maize-streak-virus) | A. A. Seif, icipe | CC BY-NC-SA ([Infonet Biovision license](https://infonet-biovision.org/license)) | 2026-08-01 |
| `tobacco/tmv_1.jpg` | Tobacco Mosaic Virus | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Tobacco_mosaic_virus_symptoms_tobacco.jpg) | Univ. of Georgia / Bugwood (via Commons) | not cleared — prototype use only | 2026-08-02 |
| `tobacco/black_shank_1.jpg` | Black Shank | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Black_Shank_on_Tobacco_Stem.jpg) | unrecorded | not cleared — prototype use only | 2026-08-02 |
| `tobacco/blue_mould_1.jpg` | Blue Mould | [Wikimedia Commons](https://commons.wikimedia.org/wiki/Category:Peronospora_hyoscyami) (Bulgarian-captioned upload) | unrecorded | not cleared — prototype use only | 2026-08-02 |
| `tobacco/blue_mould_2.jpg` | Blue Mould (underside sporulation) | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Peronospora_hyoscyami_f._sp._tabacina.jpg) | unrecorded | not cleared — prototype use only | 2026-08-02 |
| `tobacco/frogeye_1.jpg`, `frogeye_2.jpg` | Frogeye Leaf Spot | [NC State Extension — Frogeye Leaf Spot of Tobacco](https://content.ces.ncsu.edu/frogeye-leaf-spot-of-tobacco) | NC State Extension | not cleared — prototype use only | 2026-08-02 |
| `groundnuts/rosette_1.jpg`, `rosette_2.jpg` | Groundnut Rosette Virus | [Plantwise factsheet, Malawi 2013](https://factsheetadmin.plantwise.org/Uploads/PDFs/20167800237.pdf) (extracted from PDF) | CABI/Plantwise, Malawi | not cleared — prototype use only | 2026-08-02 |
| `sorghum/ergot_1.jpg` | Sorghum Ergot (honeydew stage) | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Honeydew_stage_of_Ergot.jpg) | unrecorded | not cleared — prototype use only | 2026-08-02 |
| `sorghum/ergot_2.jpg` | Sorghum Ergot (sclerotia) | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Sclerotia_comparison_of_C._sorghi_against_C._africana.png) | unrecorded | not cleared — prototype use only | 2026-08-02 |
| `sorghum/anthracnose_1.jpg` | Anthracnose | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Anthracnose_on_Sweet_sorghum.jpg) | unrecorded | not cleared — prototype use only | 2026-08-02 |
| `sweet_potatoes/black_rot_1.jpg` | Black Rot | [Plantwise factsheet, Sierra Leone 2008](https://factsheetadmin.plantwise.org/Uploads/PDFs/20127801199.pdf) (extracted from PDF; factsheet describes generic "tuber rot", visual match accepted) | CABI/Plantwise, Sierra Leone | not cleared — prototype use only | 2026-08-02 |

## Still missing (placeholder shown in-app)

Maize Stalk Rot; Tobacco Wildfire; Groundnuts Early Leaf Spot, Late Leaf
Spot, Aflatoxin, GRAV; Sorghum Downy Mildew, Head Smut, Leaf Blight; Sweet
Potatoes SPVD, Alternaria Leaf Blight, Fusarium Wilt, Scurf.

Each was attempted and failed on 2026-08-02 across Infonet Biovision (down/
timing out all session), Bugwood (blocked/403), Wikimedia Commons (no field-
symptom photos indexed, only microscopy or none), Plantwise factsheet search
(no matching factsheet found), and relevant university extension sites
(JS-rendered galleries, no static image URLs, or 404). PDF technical
bulletins (ICRISAT) were checked page-by-page where found but contained only
diagrams/microscopy, no field photos.

## Vetted open-license sources for future sourcing passes

- **Infonet Biovision** (infonet-biovision.org) — Africa-focused, CC BY-NC-SA
  on Biovision/icipe-credited photos. Good hit rate for African smallholder
  crops; check each photo's credit line — third-party-credited images on the
  same site are NOT under the open license.
- **Bugwood / IPM Images** (images.bugwood.org, wiki.bugwood.org) — US
  land-grant university consortium; per-photo licensing varies by
  photographer, must check each one. (Note: `wiki.bugwood.org` was blocked
  by this session's domain-safety check — may need direct browser access.)
- **CABI Plantwise Knowledge Bank / Plantwise Plus** — strong disease
  coverage incl. Zimbabwe-relevant crops, but licensing is per-resource and
  often requires a usage request.
- **EPPO Global Database** (gd.eppo.int) — authoritative, but images are
  frequently third-party-credited with restrictive terms; verify per photo.
- **Wikimedia Commons** — every file has an explicit, machine-readable
  license tag, easiest to verify quickly, but coverage of specific crop
  disease *field symptoms* (vs. lab/microscopy shots) is thin.
- **University extension services** (Penn State Extension, UGA Extension,
  CIMMYT/ICRISAT/FAO open-access technical bulletins) — often public domain
  or CC-BY since produced by public institutions; check per publication.

## Explicitly avoided

Pinterest, Getty Images, and ResearchGate were suggested as sources but are
not used: Pinterest/Getty are commercial or user-reposted content without
clear rights to sublicense into a shipped app, and ResearchGate images are
typically bound by the original paper's copyright, not an open license.
