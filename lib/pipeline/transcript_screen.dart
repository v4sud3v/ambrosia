import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'extraction_screen.dart';
import 'transcriber.dart';
import 'transcription_service.dart';
import 'whisper_transcriber.dart';

/// Module 2 UI — runs on-device STT over a recorded WAV and shows the raw
/// transcript. The next stage (extraction) will consume [TranscriptionService.transcript].
class TranscriptScreen extends StatefulWidget {
  const TranscriptScreen({
    super.key,
    required this.audioPath,
    TranscriptionService? service,
  }) : _injectedService = service;

  final String audioPath;
  final TranscriptionService? _injectedService;

  @override
  State<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  late final TranscriptionService _service = widget._injectedService ??
      TranscriptionService(transcriber: _defaultTranscriber());
  late final bool _ownsService = widget._injectedService == null;

  Transcriber _defaultTranscriber() => WhisperTranscriber();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() => _service.run(widget.audioPath);

  @override
  void dispose() {
    if (_ownsService) _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onBack: () => Navigator.of(context).maybePop()),
              const SizedBox(height: 8),
              Expanded(
                child: ListenableBuilder(
                  listenable: _service,
                  builder: (context, _) => _Body(service: _service, onRetry: _run),
                ),
              ),
              const SizedBox(height: 16),
              const _PrivacyFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Back',
        ),
        const SizedBox(width: 12),
        Text('TRANSCRIPT', style: Theme.of(context).textTheme.labelSmall),
        const Spacer(),
        const _OnDeviceChip(),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.service, required this.onRetry});

  final TranscriptionService service;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    switch (service.status) {
      case TranscriptionStatus.idle:
      case TranscriptionStatus.preparingModel:
        return _Working(
          label: 'Setting up the language model',
          detail:
              'A one-time download that runs on first use. It stays on this device.',
        );

      case TranscriptionStatus.transcribing:
        return _Working(
          label: 'Transcribing on device',
          detail: 'Turning the consultation into text.',
          progress: service.progress,
        );

      case TranscriptionStatus.done:
        return _TranscriptView(service: service);

      case TranscriptionStatus.error:
        return _ErrorView(
          message: service.errorMessage ?? 'Something went wrong.',
          onRetry: onRetry,
        );
    }
  }
}

class _Working extends StatelessWidget {
  const _Working({required this.label, required this.detail, this.progress});

  final String label;
  final String detail;

  /// null → indeterminate.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.hairline,
                valueColor: const AlwaysStoppedAnimation(AppColors.teal),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(label, style: text.titleMedium),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(detail, style: text.bodyMedium, textAlign: TextAlign.center),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            Text('${(progress! * 100).round()}%', style: text.labelSmall),
          ],
        ],
      ),
    );
  }
}

class _TranscriptView extends StatelessWidget {
  const _TranscriptView({required this.service});
  final TranscriptionService service;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final transcript = service.transcript!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('What was said', style: text.titleMedium),
            const Spacer(),
            Text(
              '${transcript.processingTime.inSeconds}s on device',
              style: text.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.hairline),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                transcript.text,
                style: text.bodyMedium?.copyWith(
                  color: AppColors.ink,
                  height: 1.5,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExtractionScreen(transcript: transcript.text),
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.teal,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.slate, size: 30),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.teal,
              side: const BorderSide(color: AppColors.teal),
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _OnDeviceChip extends StatelessWidget {
  const _OnDeviceChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 13, color: AppColors.teal),
          const SizedBox(width: 5),
          Text(
            'On device',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.teal,
                  letterSpacing: 0.6,
                ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyFooter extends StatelessWidget {
  const _PrivacyFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1, color: AppColors.hairline),
        const SizedBox(height: 14),
        Text(
          'Transcribed on this device. Nothing is uploaded.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
