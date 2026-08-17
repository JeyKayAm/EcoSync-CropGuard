/// Plain-language definitions for the scientific/technical jargon that
/// appears in sourced disease and treatment content (see
/// [DiagnosticService], `disease_detail_screen.dart`, `treatment_card.dart`).
/// The disease/treatment text itself stays exactly as cited — this is a
/// separate, additive lookup so a reader can ask "what does this mean?"
/// without the app rewording its sources.
class GlossaryTerm {
  final String term;
  final String definition;
  final RegExp pattern;

  const GlossaryTerm({
    required this.term,
    required this.definition,
    required this.pattern,
  });
}

RegExp _word(String stem) => RegExp('\\b$stem\\w*\\b', caseSensitive: false);

RegExp _exact(String literal) => RegExp('\\b$literal\\b');

final List<GlossaryTerm> kGlossaryTerms = [
  // ─── Plant-pathology jargon ───────────────────────────────────
  GlossaryTerm(
    term: 'Bactericide',
    definition: 'A chemical product used to kill or control a bacterial disease.',
    pattern: _word('bactericide'),
  ),
  GlossaryTerm(
    term: 'Carcinogenic',
    definition: 'Capable of causing cancer.',
    pattern: _word('carcinogenic'),
  ),
  GlossaryTerm(
    term: 'Chlorotic',
    definition: 'Yellowing of leaf or plant tissue, usually from a lack of chlorophyll caused by disease or stress.',
    pattern: _word('chlorotic'),
  ),
  GlossaryTerm(
    term: 'Defoliation',
    definition: 'Loss of leaves from a plant.',
    pattern: _word('defoliat'),
  ),
  GlossaryTerm(
    term: 'Exudate',
    definition: 'A liquid that oozes out of an infected plant part.',
    pattern: _word('exudat'),
  ),
  GlossaryTerm(
    term: 'Foliar',
    definition: 'Relating to leaves — a "foliar spray" is applied to the leaves.',
    pattern: _word('foliar'),
  ),
  GlossaryTerm(
    term: 'Fungicide',
    definition: 'A chemical product used to kill or control a fungal disease.',
    pattern: _word('fungicide'),
  ),
  GlossaryTerm(
    term: 'Inoculum',
    definition: 'The disease-causing material (spores, bacteria, etc.) that starts a new infection.',
    pattern: _word('inoculum'),
  ),
  GlossaryTerm(
    term: 'Internodes',
    definition: "The sections of a plant's stem between one leaf joint and the next.",
    pattern: _word('internode'),
  ),
  GlossaryTerm(
    term: 'Lodging',
    definition: "When a plant falls over or collapses, often because disease has weakened its stem.",
    pattern: _word('lodg'),
  ),
  GlossaryTerm(
    term: 'Oomycete',
    definition: "A fungus-like organism that causes plant disease, though it isn't a true fungus.",
    pattern: _word('oomycete'),
  ),
  GlossaryTerm(
    term: 'Photosynthetic',
    definition: 'Relating to how a plant uses sunlight to make its own food.',
    pattern: _word('photosynthet'),
  ),
  GlossaryTerm(
    term: 'Pith',
    definition: "The soft tissue in the centre of a plant's stem.",
    pattern: _exact('pith'),
  ),
  GlossaryTerm(
    term: 'Pustules',
    definition: 'Small raised bumps on a leaf surface where fungal spores break through.',
    pattern: _word('pustule'),
  ),
  GlossaryTerm(
    term: 'Rogue out',
    definition: 'A farming term meaning to find and remove/destroy diseased or unwanted plants from a field.',
    pattern: _word('rogu'),
  ),
  GlossaryTerm(
    term: 'Satellite RNA / helper virus',
    definition: 'A secondary virus-like agent that can only spread with the help of another specific virus already present in the plant.',
    pattern: RegExp(r'\bsatellite RNA\b|\bhelper virus\b', caseSensitive: false),
  ),
  GlossaryTerm(
    term: 'Sclerotia',
    definition: 'Hard, dark survival structures a fungus forms, sometimes in place of normal grain.',
    pattern: _word('sclerot'),
  ),
  GlossaryTerm(
    term: 'Senescence',
    definition: 'The natural ageing and dying-back of plant tissue.',
    pattern: _word('senescen'),
  ),
  GlossaryTerm(
    term: 'Sporulation',
    definition: 'The process by which a fungus produces and releases spores (its "seeds") that spread the disease.',
    pattern: _word('sporulat'),
  ),
  GlossaryTerm(
    term: 'Systemic',
    definition: 'Spreading through the whole plant internally, rather than staying in one spot.',
    pattern: _word('systemic'),
  ),
  GlossaryTerm(
    term: 'Tobamovirus',
    definition: 'A group of plant viruses that includes Tobacco Mosaic Virus.',
    pattern: _word('tobamovirus'),
  ),
  GlossaryTerm(
    term: 'Vascular',
    definition: "Relating to the tissue that carries water and nutrients through a plant, like its internal plumbing.",
    pattern: _word('vascular'),
  ),
  GlossaryTerm(
    term: 'Vector',
    definition: 'An insect or other organism that carries and spreads a disease from plant to plant.',
    pattern: _word('vector'),
  ),

  // ─── Units, formulation & growth-stage codes ───────────────────
  GlossaryTerm(
    term: 'kg/ha',
    definition: 'Kilograms per hectare — the standard way to state how much product to spread over a field.',
    pattern: _exact('kg/ha'),
  ),
  GlossaryTerm(
    term: 'L/ha',
    definition: 'Litres per hectare — the same idea as kg/ha, for liquid products.',
    pattern: _exact('L/ha'),
  ),
  GlossaryTerm(
    term: 'g/L',
    definition: 'Grams per litre — how much active chemical is dissolved in each litre of spray water.',
    pattern: _exact('g/L'),
  ),
  GlossaryTerm(
    term: 'WP',
    definition: 'Wettable Powder — a powder formulation that is mixed with water before spraying.',
    pattern: _exact('WP'),
  ),
  GlossaryTerm(
    term: 'EC',
    definition: 'Emulsifiable Concentrate — a liquid formulation that mixes into water before spraying.',
    pattern: _exact('EC'),
  ),
  GlossaryTerm(
    term: 'SC',
    definition: 'Suspension Concentrate — a liquid formulation with fine particles suspended in it, mixed with water before spraying.',
    pattern: _exact('SC'),
  ),
  GlossaryTerm(
    term: 'WG',
    definition: 'Water-dispersible Granule — small granules that dissolve in water before spraying.',
    pattern: _exact('WG'),
  ),
  GlossaryTerm(
    term: 'Growth stage codes (V6, VT, R1...)',
    definition: "Standard codes for a maize plant's growth stage — \"V\" numbers count leaves grown so far, \"R\" marks the reproductive/grain-filling stage — used to say exactly when to apply a treatment.",
    pattern: RegExp(r'\bV[0-9]{1,2}\b|\bVT\b|\bR[0-9]\b'),
  ),
  GlossaryTerm(
    term: 'NPK',
    definition: 'Nitrogen, Phosphorus, Potassium — the three main nutrients in a general-purpose fertilizer.',
    pattern: _exact('NPK'),
  ),
  GlossaryTerm(
    term: 'IPM',
    definition: 'Integrated Pest Management — using several methods together (not just chemicals) to control pests and disease.',
    pattern: _exact('IPM'),
  ),

  // ─── Institutional / source acronyms ───────────────────────────
  GlossaryTerm(
    term: 'AGRITEX',
    definition: "Zimbabwe's government agricultural extension service — who a farmer can consult for professional advice.",
    pattern: _exact('AGRITEX'),
  ),
  GlossaryTerm(
    term: 'FAO',
    definition: 'Food and Agriculture Organization of the United Nations.',
    pattern: _exact('FAO'),
  ),
  GlossaryTerm(
    term: 'CIMMYT',
    definition: 'International Maize and Wheat Improvement Center.',
    pattern: _exact('CIMMYT'),
  ),
  GlossaryTerm(
    term: 'CABI',
    definition: 'A global agricultural science organisation that publishes crop protection research (the "CPC", Crop Protection Compendium).',
    pattern: _exact('CABI'),
  ),
  GlossaryTerm(
    term: 'ICRISAT',
    definition: 'International Crops Research Institute for the Semi-Arid Tropics.',
    pattern: _exact('ICRISAT'),
  ),
  GlossaryTerm(
    term: 'CORESTA',
    definition: 'A global cooperation centre for tobacco research.',
    pattern: _exact('CORESTA'),
  ),
  GlossaryTerm(
    term: 'CIP',
    definition: 'International Potato Center.',
    pattern: _exact('CIP'),
  ),
  GlossaryTerm(
    term: 'TRB',
    definition: 'Tobacco Research Board (Zimbabwe).',
    pattern: _exact('TRB'),
  ),
  GlossaryTerm(
    term: 'ZFC',
    definition: 'Zimbabwe Fertilizer Company.',
    pattern: _exact('ZFC'),
  ),
]..sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));

List<GlossaryTerm> findGlossaryMatches(String text) =>
    kGlossaryTerms.where((g) => g.pattern.hasMatch(text)).toList();
