import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'explainer.dart';
import 'explanation.dart';
import 'explanation_service.dart';
import 'extraction.dart';
import 'gemma_engine.dart';
import 'gemma_explainer.dart';
import 'review_screen.dart';

/// Module 4 UI — turns the structured plan into plain language for the patient.
/// The editable review card (Module 5) and PDF (Module 6) build on this.
class ExplanationScreen extends StatefulWidget {
  const ExplanationScreen({
    super.key,
    required this.extraction,
    ExplanationService? service,
  }) : _injectedService = service;

  final Extraction extraction;
  final ExplanationService? _injectedService;

  @override
  State<ExplanationScreen> createState() => _ExplanationScreenState();
}

class _ExplanationScreenState extends State<ExplanationScreen> {
  late final ExplanationService _service = widget._injectedService ??
      ExplanationService(explainer: _defaultExplainer());
  late final bool _ownsService = widget._injectedService == null;

  Explainer _defaultExplainer() =>
      GemmaExplainer(engine: defaultGemmaEngine());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() => _service.run(widget.extraction);

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
                  builder: (context, _) => _Body(
                    service: _service,
                    extraction: widget.extraction,
                    onRetry: _run,
                  ),
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
        Text('FOR THE PATIENT', style: Theme.of(context).textTheme.labelSmall),
        const Spacer(),
        const _OnDeviceChip(),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.service,
    required this.extraction,
    required this.onRetry,
  });
  final ExplanationService service;
  final Extraction extraction;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    switch (service.status) {
      case ExplanationStatus.idle:
      case ExplanationStatus.preparingModel:
        return const _Working(
          label: 'Setting up the language model',
          detail:
              'A one-time download that runs on first use. It stays on this device.',
        );
      case ExplanationStatus.explaining:
        return const _Working(
          label: 'Putting it in plain words',
          detail: 'Writing an explanation the patient can follow.',
        );
      case ExplanationStatus.done:
        return _ExplanationView(
          explanation: service.explanation!,
          extraction: extraction,
        );
      case ExplanationStatus.error:
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

class _ExplanationView extends StatelessWidget {
  const _ExplanationView({required this.explanation, required this.extraction});
  final Explanation explanation;
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
              if (explanation.condition.trim().isNotEmpty)
                _Prose(
                  icon: Icons.info_outline,
                  title: 'What this is',
                  body: explanation.condition,
                ),
              if (explanation.recovery.trim().isNotEmpty)
                _Prose(
                  icon: Icons.trending_up,
                  title: 'Getting better',
                  body: explanation.recovery,
                ),
              if (explanation.avoid.isNotEmpty)
                _Bullets(
                  icon: Icons.do_not_disturb_on_outlined,
                  title: 'Things to avoid',
                  items: explanation.avoid,
                ),
              if (explanation.dangerSigns.isNotEmpty)
                _Bullets(
                  icon: Icons.warning_amber_rounded,
                  title: 'See a doctor if…',
                  items: explanation.dangerSigns,
                  caution: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReviewScreen(
                extraction: extraction,
                explanation: explanation,
              ),
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
}

class _Prose extends StatelessWidget {
  const _Prose({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: icon, title: title),
          const SizedBox(height: 8),
          Text(
            body,
            style: text.bodyMedium
                ?.copyWith(color: AppColors.ink, fontSize: 17, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({
    required this.icon,
    required this.title,
    required this.items,
    this.caution = false,
  });

  final IconData icon;
  final String title;
  final List<String> items;
  final bool caution;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = caution ? AppColors.amber : AppColors.teal;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: icon, title: title, color: accent),
        const SizedBox(height: 10),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 10),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.ink,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (!caution) {
      return Padding(padding: const EdgeInsets.only(bottom: 22), child: content);
    }
    // Danger signs get a quiet caution frame — the one place the amber earns its keep.
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
      ),
      child: content,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, this.color});
  final IconData icon;
  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.teal;
    return Row(
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: c),
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
          'Written on this device. Nothing is uploaded.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
