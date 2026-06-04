import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _ProcessAudioFileNative = Pointer<Utf8> Function(Pointer<Utf8> path);
typedef _ProcessAudioFileDart = Pointer<Utf8> Function(Pointer<Utf8> path);
typedef _FreeStringNative = Void Function(Pointer<Utf8> value);
typedef _FreeStringDart = void Function(Pointer<Utf8> value);

abstract class AmbrosiaEngine {
  AmbrosiaAudioResult processAudioFile(String path);
}

class AmbrosiaBridge implements AmbrosiaEngine {
  AmbrosiaBridge._(this._library, this._processAudioFile, this._freeString);

  factory AmbrosiaBridge({DynamicLibrary? library}) {
    final engineLibrary = library ?? _openEngineLibrary();

    return AmbrosiaBridge._(
      engineLibrary,
      engineLibrary
          .lookupFunction<_ProcessAudioFileNative, _ProcessAudioFileDart>(
            'AmbrosiaProcessAudioFile',
          ),
      engineLibrary.lookupFunction<_FreeStringNative, _FreeStringDart>(
        'AmbrosiaFreeString',
      ),
    );
  }

  final DynamicLibrary _library;
  final _ProcessAudioFileDart _processAudioFile;
  final _FreeStringDart _freeString;

  @override
  AmbrosiaAudioResult processAudioFile(String path) {
    final nativePath = path.toNativeUtf8();

    try {
      final responsePointer = _processAudioFile(nativePath);
      if (responsePointer == nullptr) {
        throw const AmbrosiaBridgeException('Go engine returned no response');
      }

      try {
        return _parseAudioResult(responsePointer.toDartString());
      } finally {
        _freeString(responsePointer);
      }
    } finally {
      calloc.free(nativePath);
    }
  }

  AmbrosiaAudioResult _parseAudioResult(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      throw const AmbrosiaBridgeException(
        'Go engine returned malformed response',
      );
    }

    final ok = decoded['ok'];
    if (ok is! bool) {
      throw const AmbrosiaBridgeException(
        'Go engine response is missing status',
      );
    }

    if (!ok) {
      final error = decoded['error'];
      if (error is String && error.isNotEmpty) {
        throw AmbrosiaBridgeException(error);
      }
      throw const AmbrosiaBridgeException(
        'Go engine returned an unknown error',
      );
    }

    final message = decoded['message'];
    final bytes = decoded['bytes'];
    if (message is! String || bytes is! int) {
      throw const AmbrosiaBridgeException(
        'Go engine returned incomplete audio result',
      );
    }

    return AmbrosiaAudioResult(message: message, bytes: bytes);
  }

  // Keeps the native library alive for the lifetime of this bridge instance.
  DynamicLibrary get library => _library;

  static DynamicLibrary _openEngineLibrary() {
    if (Platform.isMacOS) {
      final bundledLibrary = File(_macOSBundledLibraryPath());
      if (bundledLibrary.existsSync()) {
        return DynamicLibrary.open(bundledLibrary.path);
      }

      final developmentLibrary = File('macos/Runner/libambrosia_engine.dylib');
      if (developmentLibrary.existsSync()) {
        return DynamicLibrary.open(developmentLibrary.path);
      }

      return DynamicLibrary.open('libambrosia_engine.dylib');
    }
    if (Platform.isLinux) {
      return DynamicLibrary.open('linux/lib/libambrosia_engine.so');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('windows/runner/ambrosia_engine.dll');
    }
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libambrosia_engine.so');
    }
    if (Platform.isIOS) {
      return DynamicLibrary.process();
    }

    throw AmbrosiaBridgeException(
      'Unsupported platform: ${Platform.operatingSystem}',
    );
  }

  static String _macOSBundledLibraryPath() {
    final executable = File(Platform.resolvedExecutable);
    final macOSDirectory = executable.parent;
    final contentsDirectory = macOSDirectory.parent;

    return '${contentsDirectory.path}/Frameworks/libambrosia_engine.dylib';
  }
}

class AmbrosiaAudioResult {
  const AmbrosiaAudioResult({required this.message, required this.bytes});

  final String message;
  final int bytes;
}

class AmbrosiaBridgeException implements Exception {
  const AmbrosiaBridgeException(this.message);

  final String message;

  @override
  String toString() => message;
}
