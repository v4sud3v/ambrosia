// Shared helpers for pulling structured data out of small-LLM output, which
// tends to wrap JSON in ```json fences, add preambles, or trail commentary.
// Used by both the extraction and explanation parsers.

/// Recover the first balanced `{...}` object from surrounding noise.
///
/// Scans brace depth while respecting string literals and escapes, so braces
/// inside quoted values don't end the object early. Returns null if no
/// balanced object is present.
String? recoverJsonObject(String raw) {
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

/// Coerce a JSON value to trimmed text. A list is joined with commas (models
/// sometimes return a list where a string was asked for).
String asText(dynamic value) {
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

/// Coerce a JSON value to a clean list of non-empty strings. A bare string
/// becomes a single-item list (models sometimes return prose instead of a list).
List<String> asStringList(dynamic value) {
  if (value == null) return const [];
  if (value is String) {
    final t = value.trim();
    return t.isEmpty ? const [] : [t];
  }
  if (value is List) {
    return value
        .map(asText)
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }
  final t = value.toString().trim();
  return t.isEmpty ? const [] : [t];
}
