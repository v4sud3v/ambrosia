import 'dart:convert';

import 'extraction.dart';

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
    final jsonText = _extractJsonObject(raw);
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
      diagnosis: _asText(map['diagnosis']),
      medicines: _asMedicines(map['medicines']),
      followUp: _asText(map['follow_up'] ?? map['followUp']),
    );
  }

  /// Recover the first balanced `{...}` object from surrounding noise.
  ///
  /// Scans brace depth while respecting string literals and escapes, so braces
  /// inside quoted values don't end the object early.
  static String? _extractJsonObject(String raw) {
    final start = raw.indexOf('{');
    if (start == -1) return null;

    var depth = 0;
    var inString = false;
    var escaped = false;

    for (var i = start; i < raw.length; i++) {
      final ch = raw[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == r'\') {
          escaped = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
      } else if (ch == '{') {
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0) return raw.substring(start, i + 1);
      }
    }
    return null; // unbalanced
  }

  /// Coerce a value to text. A list (e.g. multiple diagnoses) is joined.
  static String _asText(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is List) {
      return value
          .map((e) => e is Map ? (e['name'] ?? e.values.first).toString() : '$e')
          .where((s) => s.trim().isNotEmpty)
          .join(', ');
    }
    return value.toString().trim();
  }

  static List<Medicine> _asMedicines(dynamic value) {
    if (value is! List) return const [];
    final meds = <Medicine>[];
    for (final item in value) {
      if (item is Map) {
        final name = _asText(item['name']);
        if (name.isEmpty) continue; // a med with no name is noise
        meds.add(Medicine(
          name: name,
          dosage: _asText(item['dosage']),
          frequency: _asText(item['frequency']),
          duration: _asText(item['duration']),
        ));
      } else if (item is String && item.trim().isNotEmpty) {
        // Model emitted a plain string instead of an object.
        meds.add(Medicine(name: item.trim()));
      }
    }
    return meds;
  }
}
