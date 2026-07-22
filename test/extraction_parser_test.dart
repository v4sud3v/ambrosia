import 'package:ambrosia/pipeline/extraction_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ExtractionParser();

  test('parses clean JSON', () {
    final e = parser.parse('''
{
  "diagnosis": "Viral fever",
  "medicines": [
    {"name": "Paracetamol", "dosage": "500 mg", "frequency": "twice daily", "duration": "3 days"}
  ],
  "follow_up": "Review in 5 days"
}
''');

    expect(e, isNotNull);
    expect(e!.diagnosis, 'Viral fever');
    expect(e.medicines.single.name, 'Paracetamol');
    expect(e.medicines.single.summary,
        'Paracetamol · 500 mg · twice daily · 3 days');
    expect(e.followUp, 'Review in 5 days');
  });

  test('strips markdown code fences and a preamble', () {
    final e = parser.parse('''
Sure! Here is the extracted plan:
```json
{"diagnosis": "Tonsillitis", "medicines": [], "follow_up": ""}
```
Hope this helps.''');

    expect(e, isNotNull);
    expect(e!.diagnosis, 'Tonsillitis');
    expect(e.medicines, isEmpty);
  });

  test('ignores braces inside string values', () {
    final e = parser.parse(
        '{"diagnosis": "rash {not json}", "medicines": [], "follow_up": ""}');
    expect(e!.diagnosis, 'rash {not json}');
  });

  test('accepts camelCase followUp as a fallback', () {
    final e = parser.parse('{"diagnosis": "", "followUp": "Return tomorrow"}');
    expect(e!.followUp, 'Return tomorrow');
  });

  test('coerces a diagnosis list into text', () {
    final e = parser.parse(
        '{"diagnosis": ["Fever", "Cough"], "medicines": [], "follow_up": ""}');
    expect(e!.diagnosis, 'Fever, Cough');
  });

  test('handles medicines given as plain strings', () {
    final e = parser.parse(
        '{"diagnosis": "", "medicines": ["Amoxicillin", "  "], "follow_up": ""}');
    expect(e!.medicines.length, 1);
    expect(e.medicines.single.name, 'Amoxicillin');
  });

  test('drops nameless medicine objects', () {
    final e = parser.parse(
        '{"medicines": [{"dosage": "500mg"}, {"name": "Ibuprofen"}]}');
    expect(e!.medicines.length, 1);
    expect(e.medicines.single.name, 'Ibuprofen');
  });

  test('fills missing medicine fields with empty strings', () {
    final e = parser.parse('{"medicines": [{"name": "ORS"}]}');
    final med = e!.medicines.single;
    expect(med.name, 'ORS');
    expect(med.dosage, '');
    expect(med.summary, 'ORS');
  });

  test('returns null when there is no JSON object', () {
    expect(parser.parse('I could not understand the audio.'), isNull);
    expect(parser.parse(''), isNull);
  });

  test('returns null on an unbalanced object', () {
    expect(parser.parse('{"diagnosis": "Fever", "medicines": ['), isNull);
  });

  test('picks the first complete object when trailing junk follows', () {
    final e = parser.parse(
        '{"diagnosis": "Cold", "medicines": [], "follow_up": ""} extra text {oops');
    expect(e!.diagnosis, 'Cold');
  });
}
