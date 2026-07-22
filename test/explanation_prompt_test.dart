import 'package:ambrosia/pipeline/explanation_prompt.dart';
import 'package:ambrosia/pipeline/extraction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('includes the plan and demands JSON-only plain-language output', () {
    const extraction = Extraction(
      diagnosis: 'Viral fever',
      medicines: [Medicine(name: 'Paracetamol', dosage: '500 mg')],
      followUp: 'Review in 5 days',
    );

    final prompt = buildExplanationPrompt(extraction);

    expect(prompt, contains('Viral fever'));
    expect(prompt, contains('Paracetamol'));
    expect(prompt, contains('Review in 5 days'));
    expect(prompt, contains('Output ONLY a single JSON object'));
    expect(prompt, contains('"danger_signs"'));
    expect(prompt.toLowerCase(), contains('patient'));
  });

  test('notes missing fields rather than leaving blanks', () {
    final prompt = buildExplanationPrompt(const Extraction());
    expect(prompt, contains('(not stated)'));
    expect(prompt, contains('(none noted)'));
  });
}
