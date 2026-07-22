import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'explanation.dart';
import 'extraction.dart';
import 'review_controller.dart';

/// Module 5 — the Review Card. The doctor edits the extracted plan and the
/// plain-language explanation, then confirms. Nothing downstream (PDF, share)
/// may proceed without that confirmation — it's the product's accuracy safety
/// net, so the confirm action is the only way forward from here.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.extraction,
    required this.explanation,
    this.onConfirmed,
    ReviewController? controller,
  }) : _injectedController = controller;

  final Extraction extraction;
  final Explanation explanation;

  /// Called with the doctor-approved result when confirmed. Module 6 (PDF) will
  /// hook in here; until then it defaults to an acknowledgement.
  final void Function(ConfirmedReview review)? onConfirmed;

  final ReviewController? _injectedController;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final ReviewController _c = widget._injectedController ??
      ReviewController(
        extraction: widget.extraction,
        explanation: widget.explanation,
      );
  late final bool _ownsController = widget._injectedController == null;

  @override
  void dispose() {
    if (_ownsController) _c.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final review = _c.confirm();
    if (widget.onConfirmed != null) {
      widget.onConfirmed!(review);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirmed — next: generate the PDF.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onBack: () => Navigator.of(context).maybePop()),
              const SizedBox(height: 14),
              Text(
                'Check and edit before sharing. You have the final say.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _Field(label: 'DIAGNOSIS', controller: _c.diagnosis),
                    const SizedBox(height: 16),
                    _MedicinesSection(controller: _c),
                    const SizedBox(height: 16),
                    _Field(label: 'FOLLOW-UP', controller: _c.followUp),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'WHAT THIS IS',
                      controller: _c.condition,
                      multiline: true,
                    ),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'GETTING BETTER',
                      controller: _c.recovery,
                      multiline: true,
                    ),
                    const SizedBox(height: 16),
                    _ListSection(
                      label: 'THINGS TO AVOID',
                      items: _c.avoid,
                      onAdd: _c.addAvoid,
                      onRemove: _c.removeAvoid,
                    ),
                    const SizedBox(height: 16),
                    _ListSection(
                      label: 'SEE A DOCTOR IF…',
                      items: _c.dangerSigns,
                      onAdd: _c.addDangerSign,
                      onRemove: _c.removeDangerSign,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Confirm & continue'),
              ),
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
        Text('REVIEW', style: Theme.of(context).textTheme.labelSmall),
        const Spacer(),
        const _OnDeviceChip(),
      ],
    );
  }
}

/// A labelled editable text field in a card.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.multiline = false,
  });

  final String label;
  final TextEditingController controller;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: multiline ? 2 : 1,
          maxLines: multiline ? 6 : 1,
          style: const TextStyle(color: AppColors.ink, fontSize: 16, height: 1.4),
          decoration: _fieldDecoration(null),
        ),
      ],
    );
  }
}

InputDecoration _fieldDecoration(String? hint) => InputDecoration(
      isDense: true,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
      ),
    );

class _MedicinesSection extends StatelessWidget {
  const _MedicinesSection({required this.controller});
  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MEDICINES', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        for (var i = 0; i < controller.medicines.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MedicineRow(
              draft: controller.medicines[i],
              onRemove: () => controller.removeMedicine(i),
            ),
          ),
        _AddButton(label: 'Add medicine', onPressed: controller.addMedicine),
      ],
    );
  }
}

class _MedicineRow extends StatelessWidget {
  const _MedicineRow({required this.draft, required this.onRemove});
  final MedicineDraft draft;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: draft.name,
                  style: const TextStyle(color: AppColors.ink, fontSize: 16),
                  decoration: const InputDecoration.collapsed(hintText: 'Medicine name'),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18, color: AppColors.slate),
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const Divider(height: 12, color: AppColors.hairline),
          Row(
            children: [
              _mini(draft.dosage, 'Dose'),
              const SizedBox(width: 8),
              _mini(draft.frequency, 'How often'),
              const SizedBox(width: 8),
              _mini(draft.duration, 'How long'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(TextEditingController c, String hint) => Expanded(
        child: TextField(
          controller: c,
          style: const TextStyle(color: AppColors.ink, fontSize: 13),
          decoration: InputDecoration.collapsed(hintText: hint)
              .copyWith(hintStyle: const TextStyle(color: AppColors.slate, fontSize: 13)),
        ),
      );
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.label,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final List<TextEditingController> items;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: items[i],
                    style: const TextStyle(color: AppColors.ink, fontSize: 15),
                    decoration: _fieldDecoration('Add a point'),
                  ),
                ),
                IconButton(
                  onPressed: () => onRemove(i),
                  icon: const Icon(Icons.close, size: 18, color: AppColors.slate),
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        _AddButton(label: 'Add', onPressed: onAdd),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 18, color: AppColors.teal),
      label: Text(label, style: const TextStyle(color: AppColors.teal)),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
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
