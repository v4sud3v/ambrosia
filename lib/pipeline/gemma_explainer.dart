import 'explainer.dart';
import 'explanation.dart';
import 'explanation_parser.dart';
import 'explanation_prompt.dart';
import 'extraction.dart';
import 'gemma_engine.dart';

/// Real on-device explanation: prompts the shared [GemmaEngine] with the
/// structured plan and parses the plain-language result. Reuses the same Gemma
/// weights as extraction — model management lives in the engine.
class GemmaExplainer implements Explainer {
  GemmaExplainer({
    required GemmaEngine engine,
    ExplanationParser parser = const ExplanationParser(),
  })  : _engine = engine, // ignore: prefer_initializing_formals
        _parser = parser; // ignore: prefer_initializing_formals

  final GemmaEngine _engine;
  final ExplanationParser _parser;

  @override
  Future<bool> isModelReady() => _engine.isModelReady();

  @override
  Future<void> downloadModel() => _engine.downloadModel();

  @override
  Future<Explanation> explain(Extraction extraction) async {
    final raw = await _engine.generate(buildExplanationPrompt(extraction));
    final explanation = _parser.parse(raw);
    if (explanation == null || explanation.isEmpty) {
      throw const ExplanationException(
        "The model couldn't put this in plain words. Try again.",
      );
    }
    return explanation;
  }
}
