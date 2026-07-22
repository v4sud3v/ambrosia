import 'package:ambrosia/pipeline/extraction_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('embeds the transcript and demands JSON-only output', () {
    const transcript = 'Patient has fever, give paracetamol';
    final prompt = buildExtractionPrompt(transcript);

    expect(prompt, contains(transcript));
    expect(prompt, contains('Output ONLY a single JSON object'));
    // The three required fields are described in the schema.
    expect(prompt, contains('"diagnosis"'));
    expect(prompt, contains('"medicines"'));
    expect(prompt, contains('"follow_up"'));
    // Guards against hallucination.
    expect(prompt.toLowerCase(), contains('do not guess'));
  });
}
