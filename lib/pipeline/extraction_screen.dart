import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'extraction.dart';
import 'extraction_service.dart';
import 'extractor.dart';
import 'gemma_extractor.dart';

/// Where the shipping build's licensed Gemma weights live. Injected here rather
/// than hardcoded in the engine; a real build sets these to the doctor's
/// provisioned model. Empty by default so misconfiguration fails loudly.
const String kGemmaModelUrl =
    String.fromEnvironment('GEMMA_MODEL_URL', defaultValue: '');
const String kGemmaModelFile = String.fromEnvironment(
  'GEMMA_MODEL_FILE',
  defaultValue: 'gemma-3-2b-it-int4.litertlm',
);
const String kGemmaToken =
    String.fromEnvironment('HF_TOKEN', defaultValue: '');

/// Module 3 UI — runs on-device extraction over a transcript and shows the
/// structured plan. The editable review card (Module 5) will build on this.
class ExtractionScreen extends StatefulWidget {
  const ExtractionScreen({
    super.key,
    required this.transcript,
    ExtractionService? service,
  }) : _injectedService = service;

  final String transcript;
  final ExtractionService? _injectedService;

  @override
  State<ExtractionScreen> createState() => _ExtractionScreenState();
}

class _ExtractionScreenState extends State<ExtractionScreen> {
  late final ExtractionService _service =
      widget._injectedService ?? ExtractionService(extractor: _defaultExtractor());
  late final bool _ownsService = widget._injectedService == null;

  Extractor _defaultExtractor() => GemmaExtractor(
        modelUrl: kGemmaModelUrl,
        modelFileName: kGemmaModelFile,
        huggingFaceToken: kGemmaToken.isEmpty ? null : kGemmaToken,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() => _service.run(widget.transcript);

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
        Text('PLAN', style: Theme.of(context).textTheme.labelSmall),
        const Spacer(),
        const _OnDeviceChip(),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.service, required this.onRetry});
  final ExtractionService service;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    switch (service.status) {
      case ExtractionStatus.idle:
      case ExtractionStatus.preparingModel:
        return const _Working(
          label: 'Setting up the language model',
          detail:
              'A one-time download that runs on first use. It stays on this device.',
        );
      case ExtractionStatus.extracting:
        return const _Working(
          label: 'Reading the plan',
          detail: 'Pulling out diagnosis, medicines and follow-up.',
        );
      case ExtractionStatus.done:
        return _ExtractionView(extraction: service.extraction!);
      case ExtractionStatus.error:
        return _ErrorView(
          message: service.errorMessage ?? 'Something went wrong.',
          onRetry: onRetry,
        );
    }
  }
}

class _Working extends StatelessWidget {
  const _Working({required this.label, required this.detail});
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(AppColors.teal),
            ),
          ),
          const SizedBox(height: 22),
          Text(label, style: text.titleMedium),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(detail, style: text.bodyMedium, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _ExtractionView extends StatelessWidget {
  const _ExtractionView({required this.extraction});
  final Extraction extraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Section(
                label: 'DIAGNOSIS',
                child: _valueText(context, extraction.diagnosis),
              ),
              const SizedBox(height: 14),
              _Section(
                label: 'MEDICINES',
                child: extraction.medicines.isEmpty
                    ? _emptyText(context)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final m in extraction.medicines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _MedicineRow(medicine: m),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 14),
              _Section(
                label: 'FOLLOW-UP',
                child: _valueText(context, extraction.followUp),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Next: plain-language explanation and review.'),
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.teal,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _valueText(BuildContext context, String value) {
    if (value.trim().isEmpty) return _emptyText(context);
    return Text(
      value,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.ink,
            fontSize: 16,
            height: 1.4,
          ),
    );
  }

  Widget _emptyText(BuildContext context) {
    return Text(
      'Not mentioned — add in review',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            fontSize: 14,
          ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MedicineRow extends StatelessWidget {
  const _MedicineRow({required this.medicine});
  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 10),
          child: Icon(Icons.medication_outlined, size: 16, color: AppColors.teal),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medicine.name,
                style: text.bodyMedium
                    ?.copyWith(color: AppColors.ink, fontSize: 16, height: 1.3),
              ),
              if (medicine.summary != medicine.name)
                Text(
                  [medicine.dosage, medicine.frequency, medicine.duration]
                      .where((p) => p.trim().isNotEmpty)
                      .join(' · '),
                  style: text.bodyMedium?.copyWith(fontSize: 13),
                ),
            ],
          ),
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
          'Structured on this device. Nothing is uploaded.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
