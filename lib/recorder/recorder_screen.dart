import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'audio_backend.dart';
import 'recording_service.dart';

/// Module 1 — the doctor's entry point. Tap to record the consultation; the
/// elapsed time is the hero, and a persistent line reassures that the audio
/// never leaves the device.
class RecorderScreen extends StatefulWidget {
  const RecorderScreen({super.key, RecordingService? service})
      : _injectedService = service;

  /// Tests inject a service backed by a fake; production builds create one.
  final RecordingService? _injectedService;

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  late final RecordingService _service =
      widget._injectedService ?? RecordingService(backend: RecordAudioBackend());
  bool _ownsService = false;

  @override
  void initState() {
    super.initState();
    _ownsService = widget._injectedService == null;
  }

  @override
  void dispose() {
    if (_ownsService) _service.dispose();
    super.dispose();
  }

  Future<void> _onMicTap() async {
    if (_service.isRecording) {
      await _service.stop();
    } else {
      if (_service.status == RecordingStatus.saved ||
          _service.status == RecordingStatus.error) {
        _service.reset();
      }
      await _service.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _service,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
              child: Column(
                children: [
                  const _Header(),
                  Expanded(child: Center(child: _StatusBlock(service: _service))),
                  _MicButton(
                    recording: _service.isRecording,
                    onTap: _onMicTap,
                  ),
                  const SizedBox(height: 28),
                  const _PrivacyFooter(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('AMBROSIA', style: Theme.of(context).textTheme.labelSmall),
        Container(
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
        ),
      ],
    );
  }
}

/// The changing middle of the screen: prompt, live timer, saved state, or error.
class _StatusBlock extends StatelessWidget {
  const _StatusBlock({required this.service});

  final RecordingService service;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    switch (service.status) {
      case RecordingStatus.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ready when you are', style: text.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tap to record the consultation.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        );

      case RecordingStatus.recording:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LiveLabel(),
            const SizedBox(height: 12),
            Text(
              RecordingService.formatDuration(service.elapsed),
              style: text.displayLarge,
            ),
          ],
        );

      case RecordingStatus.saved:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.teal, size: 30),
            const SizedBox(height: 12),
            Text(
              RecordingService.formatDuration(service.elapsed),
              style: text.displayLarge,
            ),
            const SizedBox(height: 8),
            Text('Saved · ready for review', style: text.bodyMedium),
          ],
        );

      case RecordingStatus.error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic_off_outlined,
                color: AppColors.slate, size: 30),
            const SizedBox(height: 12),
            Text(
              service.errorMessage ?? 'Something went wrong.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        );
    }
  }
}

class _LiveLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.amber,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'RECORDING',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.amber,
              ),
        ),
      ],
    );
  }
}

/// The signature element: a calm breathing pulse while the app is listening.
class _MicButton extends StatefulWidget {
  const _MicButton({required this.recording, required this.onTap});

  final bool recording;
  final VoidCallback onTap;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didUpdateWidget(_MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.recording && !reduceMotion) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncPulse();
    const size = 96.0;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 200,
        height: size + 40,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.recording)
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) => CustomPaint(
                    size: const Size(200, 200),
                    painter: _PulsePainter(_pulse.value),
                  ),
                ),
              Semantics(
                button: true,
                label: widget.recording ? 'Stop recording' : 'Start recording',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: widget.recording ? AppColors.amber : AppColors.teal,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.recording
                                ? AppColors.amber
                                : AppColors.teal)
                            .withValues(alpha: 0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.recording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.t);

  /// Animation progress 0→1.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const baseRadius = 48.0;
    // Two rings offset in phase so the breath feels continuous.
    for (final phase in [0.0, 0.5]) {
      final p = (t + phase) % 1.0;
      final radius = baseRadius + p * 52;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.amber.withValues(alpha: (1 - p) * 0.18);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_PulsePainter oldDelegate) => oldDelegate.t != t;
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
          'Audio stays on this device. Nothing is uploaded.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
