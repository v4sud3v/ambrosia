import 'dart:convert';

import 'extraction.dart';
import 'json_recovery.dart';

/// Turns raw LLM text into a structured [Extraction].
///
/// Small on-device models are messy: they wrap JSON in ```json fences, add a
/// "Here is the JSON:" preamble, trail commentary, or emit a list where a
/// string was asked for. This parser is intentionally tolerant so a usable
/// draft survives that noise — the doctor corrects the rest in review.
class ExtractionParser {
  const ExtractionParser();

  /// Parse [raw]. Returns null if no JSON object can be recovered at all.
  Extraction? parse(String raw) {
    final jsonText = recoverJsonObject(raw);
    if (jsonText == null) return null;

    Map<String, dynamic> map;
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) return null;
      map = decoded;
    } on FormatException {
      return null;
    }

    return Extraction(
      diagnosis: asText(map['diagnosis']),
      medicines: _asMedicines(map['medicines']),
      followUp: asText(map['follow_up'] ?? map['followUp']),
    );
  }

  static List<Medicine> _asMedicines(dynamic value) {
    if (value is! List) return const [];
    final meds = <Medicine>[];
    for (final item in value) {
      if (item is Map) {
        final name = asText(item['name']);
        if (name.isEmpty) continue; // a med with no name is noise
        meds.add(Medicine(
          name: name,
          dosage: asText(item['dosage']),
          frequency: asText(item['frequency']),
          duration: asText(item['duration']),
        ));
      } else if (item is String && item.trim().isNotEmpty) {
        // Model emitted a plain string instead of an object.
        meds.add(Medicine(name: item.trim()));
      }
    }
    return meds;
  }
}
