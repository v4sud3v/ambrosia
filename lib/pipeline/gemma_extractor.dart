import 'extraction.dart';
import 'extraction_parser.dart';
import 'extraction_prompt.dart';
import 'extractor.dart';
import 'gemma_engine.dart';

/// Real on-device extraction: prompts the shared [GemmaEngine] and parses its
/// output into a structured [Extraction]. Model management lives in the engine.
class GemmaExtractor implements Extractor {
  GemmaExtractor({
    required GemmaEngine engine,
    ExtractionParser parser = const ExtractionParser(),
  })  : _engine = engine, // ignore: prefer_initializing_formals
        _parser = parser; // ignore: prefer_initializing_formals

  final GemmaEngine _engine;
  final ExtractionParser _parser;

  @override
  Future<bool> isModelReady() => _engine.isModelReady();

  @override
  Future<void> downloadModel() => _engine.downloadModel();

  @override
  Future<Extraction> extract(String transcript) async {
    final raw = await _engine.generate(buildExtractionPrompt(transcript));
    final extraction = _parser.parse(raw);
    if (extraction == null || extraction.isEmpty) {
      throw const ExtractionException(
        "The model couldn't structure this consultation. Try again.",
      );
    }
    return extraction;
  }
}
