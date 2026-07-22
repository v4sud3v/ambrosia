import 'package:flutter_gemma/flutter_gemma.dart';

import 'extraction.dart';
import 'extraction_parser.dart';
import 'extraction_prompt.dart';
import 'extractor.dart';

/// Real on-device extraction backed by Gemma 3 2B INT4 via `flutter_gemma`
/// (MediaPipe / LiteRT-LM). The weights download once (the one permitted
/// network call) as a `.litertlm` file that works across Android, iOS and
/// desktop; every extraction after that is fully offline.
///
/// The weights are license-gated (Google's Gemma terms), so the URL + token
/// are injected by the build rather than hardcoded here.
class GemmaExtractor implements Extractor {
  GemmaExtractor({
    required this.modelUrl,
    required this.modelFileName,
    this.huggingFaceToken,
    this.maxTokens = 2048,
    this.backend = PreferredBackend.cpu,
    ExtractionParser parser = const ExtractionParser(),
  }) : _parser = parser; // ignore: prefer_initializing_formals

  /// Direct download URL of the Gemma 3 2B INT4 `.litertlm` weights.
  final String modelUrl;

  /// The weights filename, used to check whether they're already installed.
  final String modelFileName;

  /// Token for the gated model host (e.g. HuggingFace); null if the URL is open.
  final String? huggingFaceToken;

  final int maxTokens;
  final PreferredBackend backend;
  final ExtractionParser _parser;

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
  Future<Extraction> extract(String transcript) async {
    if (!FlutterGemma.hasActiveModel()) {
      await _install();
    }

    final model = await FlutterGemma.getActiveModel(
      maxTokens: maxTokens,
      preferredBackend: backend,
    );

    try {
      final chat = await model.createChat();
      await chat.addQueryChunk(
        Message.text(text: buildExtractionPrompt(transcript), isUser: true),
      );
      final response = await chat.generateChatResponse();
      final text = response is TextResponse ? response.token : '';

      final extraction = _parser.parse(text);
      if (extraction == null || extraction.isEmpty) {
        throw const ExtractionException(
          "The model couldn't structure this consultation. Try again.",
        );
      }
      return extraction;
    } finally {
      await model.close();
    }
  }
}
