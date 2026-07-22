// Manual verification for Module 4: runs the real explanation prompt through a
// local Gemma (via ollama) and parses the output with the shipping parser.
//
//   ollama pull gemma3:1b
//   dart run tool/verify_explanation.dart
import 'dart:convert';
import 'dart:io';

import 'package:ambrosia/pipeline/explanation_parser.dart';
import 'package:ambrosia/pipeline/explanation_prompt.dart';
import 'package:ambrosia/pipeline/extraction.dart';

const _extraction = Extraction(
  diagnosis: 'Viral fever',
  medicines: [
    Medicine(
      name: 'Paracetamol',
      dosage: '500 mg',
      frequency: 'twice a day',
      duration: '3 days',
    ),
  ],
  followUp: 'Review in 5 days if the fever does not settle',
);

Future<void> main() async {
  final prompt = buildExplanationPrompt(_extraction);

  final client = HttpClient();
  final req =
      await client.postUrl(Uri.parse('http://localhost:11434/api/generate'));
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode({
    'model': 'gemma3:1b',
    'prompt': prompt,
    'stream': false,
    'options': {'temperature': 0},
  }));
  final resp = await req.close();
  final raw = jsonDecode(await resp.transform(utf8.decoder).join())['response']
      as String;
  client.close();

  stdout.writeln('=== RAW GEMMA OUTPUT ===\n$raw\n');

  final explanation = const ExplanationParser().parse(raw);
  stdout.writeln('=== PARSED (via shipping parser) ===');
  if (explanation == null) {
    stdout.writeln('PARSE FAILED — no JSON recovered');
    exitCode = 1;
    return;
  }
  stdout.writeln('condition    : ${explanation.condition}');
  stdout.writeln('recovery     : ${explanation.recovery}');
  stdout.writeln('avoid        : ${explanation.avoid}');
  stdout.writeln('danger_signs : ${explanation.dangerSigns}');
  stdout.writeln('\nisEmpty      : ${explanation.isEmpty}');
}
