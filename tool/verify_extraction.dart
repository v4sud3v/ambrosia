// Manual verification for Module 3: runs the real extraction prompt through a
// local Gemma (via ollama) and parses the output with the shipping parser.
// Not part of the app or the test suite — proves the prompt+parser survive a
// real small model's real (messy) output.
//
//   ollama pull gemma3:1b
//   dart run tool/verify_extraction.dart
import 'dart:convert';
import 'dart:io';

import 'package:ambrosia/pipeline/extraction_parser.dart';
import 'package:ambrosia/pipeline/extraction_prompt.dart';

const _transcript =
    "Doctor: So you've had fever and body pain for three days? "
    'Patient: Yes doctor, and a dry cough that keeps me up at night. '
    'Doctor: Alright, your throat is a little red. This looks like a viral '
    'fever, nothing serious. Take paracetamol 500 milligrams twice a day for '
    'three days for the fever. Drink plenty of warm fluids and get rest. '
    "If the fever doesn't settle, come back for a review after five days.";

Future<void> main() async {
  final prompt = buildExtractionPrompt(_transcript);

  final client = HttpClient();
  final req = await client
      .postUrl(Uri.parse('http://localhost:11434/api/generate'));
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

  final extraction = const ExtractionParser().parse(raw);
  stdout.writeln('=== PARSED (via shipping parser) ===');
  if (extraction == null) {
    stdout.writeln('PARSE FAILED — no JSON recovered');
    exitCode = 1;
    return;
  }
  stdout.writeln('diagnosis : ${extraction.diagnosis}');
  stdout.writeln('medicines :');
  for (final m in extraction.medicines) {
    stdout.writeln('  - ${m.summary}');
  }
  stdout.writeln('follow_up : ${extraction.followUp}');
  stdout.writeln('\nisEmpty   : ${extraction.isEmpty}');
}
