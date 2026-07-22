import 'package:flutter_gemma/flutter_gemma.dart';

/// Where the shipping build's licensed Gemma weights live. Injected via
/// `--dart-define` rather than hardcoded, because they're license-gated
/// (Google's Gemma terms). Empty URL by default so misconfiguration fails loud.
const String kGemmaModelUrl =
    String.fromEnvironment('GEMMA_MODEL_URL', defaultValue: '');
const String kGemmaModelFile = String.fromEnvironment(
  'GEMMA_MODEL_FILE',
  defaultValue: 'gemma-3-2b-it-int4.litertlm',
);
const String kGemmaToken =
    String.fromEnvironment('HF_TOKEN', defaultValue: '');

/// The shared engine both LLM stages run on, configured from the build defines.
FlutterGemmaEngine defaultGemmaEngine() => FlutterGemmaEngine(
      modelUrl: kGemmaModelUrl,
      modelFileName: kGemmaModelFile,
      huggingFaceToken: kGemmaToken.isEmpty ? null : kGemmaToken,
    );

/// On-device text-generation engine shared by the extraction (Module 3) and
/// explanation (Module 4) stages — both run the same Gemma 3 2B INT4 weights,
/// so model download/readiness and inference live here once.
abstract class GemmaEngine {
  Future<bool> isModelReady();
  Future<void> downloadModel();

  /// Run a single-turn prompt and return the model's text response.
  Future<String> generate(String prompt);
}

/// Real engine backed by Gemma via `flutter_gemma` (MediaPipe / LiteRT-LM).
///
/// The weights download once (the one permitted network call) as a `.litertlm`
/// file that works across Android, iOS and desktop; every generation after that
/// is fully offline. Weights are license-gated (Google's Gemma terms), so the
/// URL + token are injected by the build rather than hardcoded.
class FlutterGemmaEngine implements GemmaEngine {
  FlutterGemmaEngine({
    required this.modelUrl,
    required this.modelFileName,
    this.huggingFaceToken,
    this.maxTokens = 2048,
    this.backend = PreferredBackend.cpu,
  });

  final String modelUrl;
  final String modelFileName;
  final String? huggingFaceToken;
  final int maxTokens;
  final PreferredBackend backend;

  @override
  Future<bool> isModelReady() => FlutterGemma.isModelInstalled(modelFileName);

  @override
  Future<void> downloadModel() => _install();

  /// Idempotent: downloads only if missing, and always sets the active model.
  Future<void> _install() async {
    await FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm,
    ).fromNetwork(modelUrl, token: huggingFaceToken).install();
  }

  @override
  Future<String> generate(String prompt) async {
    if (!FlutterGemma.hasActiveModel()) {
      await _install();
    }

    final model = await FlutterGemma.getActiveModel(
      maxTokens: maxTokens,
      preferredBackend: backend,
    );
    try {
      final chat = await model.createChat();
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await chat.generateChatResponse();
      return response is TextResponse ? response.token : '';
    } finally {
      await model.close();
    }
  }
}
