import 'package:ambrosia/pipeline/explanation_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ExplanationParser();

  test('parses clean JSON with lists', () {
    final e = parser.parse('''
{
  "condition": "A viral fever is an infection your body fights off on its own.",
  "recovery": "Rest and fluids. Take the paracetamol when you feel hot.",
  "avoid": ["Cold drinks", "Skipping meals"],
  "danger_signs": ["Fever above 103F", "Trouble breathing"]
}
''');

    expect(e, isNotNull);
    expect(e!.condition, contains('viral fever'));
    expect(e.avoid, ['Cold drinks', 'Skipping meals']);
    expect(e.dangerSigns, ['Fever above 103F', 'Trouble breathing']);
  });

  test('strips fences and preamble', () {
    final e = parser.parse('''
Here you go:
```json
{"condition": "Mild throat infection", "recovery": "", "avoid": [], "danger_signs": []}
```''');
    expect(e!.condition, 'Mild throat infection');
    expect(e.avoid, isEmpty);
  });

  test('coerces a prose danger_signs string into a single-item list', () {
    final e = parser.parse(
        '{"condition": "", "danger_signs": "Come back if the fever lasts a week"}');
    expect(e!.dangerSigns, ['Come back if the fever lasts a week']);
  });

  test('accepts camelCase dangerSigns fallback', () {
    final e = parser.parse('{"dangerSigns": ["Chest pain"]}');
    expect(e!.dangerSigns, ['Chest pain']);
  });

  test('drops empty list items', () {
    final e = parser.parse('{"avoid": ["Salt", "", "  "]}');
    expect(e!.avoid, ['Salt']);
  });

  test('returns null when there is no JSON', () {
    expect(parser.parse('I could not help with that.'), isNull);
    expect(parser.parse(''), isNull);
  });
}
