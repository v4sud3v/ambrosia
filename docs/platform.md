# Platform decision

**Chosen: Flutter (cross-platform, iOS + Android).**

Doctors in the target setting (Kerala clinics) are split across iOS and
Android, and a single UI codebase lets the record → review → PDF flow ship
to both without duplicating screens.

## Trade-off we're accepting

On-device inference (Whisper STT, Gemma 3 2B INT4) has no pure-Dart story.
Those stages will run through **platform channels** into native inference
backends (e.g. whisper.cpp / MediaPipe LLM Inference on Android, WhisperKit /
MLX on iOS). Flutter owns the UI and orchestration; the heavy models stay
native. This is more glue than a single-platform native app, but keeps the
doctor-facing surface unified.

The non-negotiable rule is unaffected: platform channels are in-process, not
network calls. Nothing leaves the device.

## Known trap: iOS simulator + whisper_ggml

Module 2's STT uses `whisper_ggml`, which pulls in `ffmpeg_kit_flutter_new_min`.
That package's prebuilt `ffmpegkit.framework` ships **no iOS-simulator slice**,
so `Runner` fails to link when building for the simulator ("built for 'iOS'"
while "Building for 'iOS-simulator'"). We never call FFmpeg at runtime (audio
is recorded straight to 16 kHz WAV), but it's a hard build-time dependency.

Consequences for development:
- Real iOS **devices** build fine (device slice is present).
- The **iOS simulator** cannot build once STT is wired in.
- On-device STT is verified on **macOS** instead — hence the `macos/` target.
  `flutter test integration_test/whisper_test.dart -d macos` downloads the
  tiny model once and transcribes a bundled WAV, proving the native path.

If simulator builds become important, options are: exclude the arm64-sim slice
via a Podfile `post_install` and stub FFmpeg, or fork `whisper_ggml` to make
the FFmpeg dependency optional (we only need it for non-WAV input, which we
never produce).

## Gemma weights (Module 3)

Gemma 3 2B INT4 runs via `flutter_gemma` (MediaPipe / LiteRT-LM). The weights
are license-gated (Google's Gemma terms), so they are **not** hardcoded. The
build supplies them as a `.litertlm` URL + token via `--dart-define`:

```
flutter run \
  --dart-define=GEMMA_MODEL_URL=https://.../gemma-3-2b-it-int4.litertlm \
  --dart-define=GEMMA_MODEL_FILE=gemma-3-2b-it-int4.litertlm \
  --dart-define=HF_TOKEN=hf_...
```

Because the weights are gated, on-device Gemma inference was **not** run in the
build sandbox. The extraction prompt + parser (the failure-prone part) are
instead verified against a real local Gemma via `dart run
tool/verify_extraction.dart` (ollama `gemma3:1b`), and the state machine + UI by
unit/widget tests.

## Structure (Flutter)

```
lib/
  main.dart            app entry
  theme/               visual identity
  recorder/            Module 1 — record → local temp WAV     ← built
  pipeline/            Module 2 — Whisper STT → transcript    ← built
                       Module 3 — Gemma → structured plan     ← built
                       Module 4 — Gemma → plain-language      ← built
                       Module 5 — Review Card (edit + confirm) ← built
                       (PDF → share → cleanup later)
ios/ android/          native hosts (whisper.cpp + Gemma/MediaPipe)
macos/                 dev/verification target for on-device inference
integration_test/      on-device STT check (runs real whisper on macOS)
tool/                  verify_extraction.dart / verify_explanation.dart
                       (prompt+parser vs. real Gemma via ollama)
```
