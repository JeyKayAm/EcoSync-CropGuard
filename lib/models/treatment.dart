/// A recommended treatment/product for a [Disease]. Every record carries a
/// bibliographic [source] so treatment advice shown in the app stays
/// traceable to the agronomic literature it came from (see SOURCES.md-style
/// attribution in README's Data Sources section).
class Treatment {
  final int id;
  final int diseaseId;
  final String type;          // organic | chemical
  final String productName;
  final String activeIngredient;
  final String dosage;
  final String applicationMethod;
  final String estimatedCostUsd; // e.g. "$3.50 – $5.00 / litre"
  final String availability;     // e.g. "Agribank, Farmers World, local agro-dealers"
  final String source;           // bibliographic source for traceability

  const Treatment({
    required this.id,
    required this.diseaseId,
    required this.type,
    required this.productName,
    required this.activeIngredient,
    required this.dosage,
    required this.applicationMethod,
    required this.estimatedCostUsd,
    required this.availability,
    required this.source,
  });

  factory Treatment.fromMap(Map<String, dynamic> map) => Treatment(
        id: map['id'] as int,
        diseaseId: map['disease_id'] as int,
        type: map['type'] as String,
        productName: map['product_name'] as String,
        activeIngredient: map['active_ingredient'] as String,
        dosage: map['dosage'] as String,
        applicationMethod: map['application_method'] as String,
        estimatedCostUsd: map['estimated_cost_usd'] as String,
        availability: map['availability'] as String,
        source: map['source'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'disease_id': diseaseId,
        'type': type,
        'product_name': productName,
        'active_ingredient': activeIngredient,
        'dosage': dosage,
        'application_method': applicationMethod,
        'estimated_cost_usd': estimatedCostUsd,
        'availability': availability,
        'source': source,
      };
}
