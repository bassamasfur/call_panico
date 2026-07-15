import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

class VoiceDetectionService {
  VoiceDetectionService({SpeechToText? speechToText})
    : _speechToText = speechToText ?? SpeechToText();

  final SpeechToText _speechToText;

  bool _speechToTextInitialized = false;

  Future<void> startBackgroundListening({
    required void Function(String recognizedText, bool isPartial)
    onSpeechResult,
  }) async {
    final ready = await _ensureInitialized();
    if (!ready) {
      throw StateError('Speech recognition not available');
    }

    await _speechToText.stop();
    await _speechToText.listen(
      listenOptions: SpeechListenOptions(
        partialResults: true,
        localeId: 'es_ES',
        listenFor: Duration(minutes: 10),
        pauseFor: Duration(seconds: 20),
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        onDevice: false,
      ),
      onResult: (result) {
        final spokenText = result.recognizedWords.trim();
        if (spokenText.isNotEmpty) {
          onSpeechResult(spokenText, !result.finalResult);
        }
      },
    );
  }

  Future<void> stopBackgroundListening() async {
    await _speechToText.stop();
  }

  Future<String?> listenForSpeech({
    Duration listenFor = const Duration(seconds: 6),
    String? localeId = 'es_ES',
  }) async {
    final ready = await _ensureInitialized();
    if (!ready) {
      return null;
    }

    final completer = Completer<String?>();
    Timer? timeoutTimer;

    void finish([String? value]) {
      if (completer.isCompleted) {
        return;
      }
      timeoutTimer?.cancel();
      _speechToText.stop();
      completer.complete(value);
    }

    await _speechToText.listen(
      listenOptions: SpeechListenOptions(
        partialResults: true,
        localeId: localeId,
        listenFor: listenFor,
        cancelOnError: true,
        onDevice: false,
        listenMode: ListenMode.confirmation,
      ),
      onResult: (result) {
        final spokenText = result.recognizedWords.trim();
        if (spokenText.isNotEmpty && result.finalResult) {
          finish(spokenText);
        }
      },
    );

    timeoutTimer = Timer(listenFor + const Duration(seconds: 2), () {
      finish(null);
    });

    return completer.future;
  }

  Future<bool> _ensureInitialized() async {
    if (_speechToTextInitialized) {
      return true;
    }

    _speechToTextInitialized = await _speechToText.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _speechToTextInitialized;
  }
}
