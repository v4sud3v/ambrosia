import 'dart:convert';

import 'explanation.dart';
import 'json_recovery.dart';

/// Turns raw LLM text into a structured [Explanation], tolerating the same
/// fenced/preamble/list-vs-string messiness as the extraction parser.
class ExplanationParser {
  const ExplanationParser();

  /// Parse [raw]. Returns null if no JSON object can be recovered at all.
  Explanation? parse(String raw) {
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

    return Explanation(
      condition: asText(map['condition']),
      recovery: asText(map['recovery']),
      avoid: asStringList(map['avoid']),
      dangerSigns: asStringList(map['danger_signs'] ?? map['dangerSigns']),
    );
  }
}
