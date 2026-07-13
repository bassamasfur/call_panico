import 'dart:async';

import 'package:background_stt/background_stt.dart';
import 'package:background_stt/speech_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceDetectionService {
  VoiceDetectionService({
    BackgroundStt? backgroundStt,
    SpeechToText? speechToText,
  }) : _backgroundStt = backgroundStt ?? BackgroundStt(),
       _speechToText = speechToText ?? SpeechToText();

  final BackgroundStt _backgroundStt;
  final SpeechToText _speechToText;

  StreamSubscription<SpeechResult>? _backgroundSubscription;
  bool _backgroundStarted = false;
  bool _speechToTextInitialized = false;

  Future<void> startBackgroundListening({
    required void Function(String recognizedText, bool isPartial)
    onSpeechResult,
  }) async {
    if (!_backgroundStarted) {
      await _backgroundStt.startSpeechListenService;
      _backgroundStarted = true;
    }

    await _backgroundSubscription?.cancel();
    final subscription = _backgroundStt.getSpeechResults();
    subscription.onData((data) {
      final recognizedText = (data.result ?? '').trim();
      if (recognizedText.isNotEmpty) {
        onSpeechResult(recognizedText, data.isPartial ?? false);
      }
    });
    _backgroundSubscription = subscription;
  }

  Future<void> stopBackgroundListening() async {
    await _backgroundSubscription?.cancel();
    _backgroundSubscription = null;

    if (_backgroundStarted) {
      await _backgroundStt.stopSpeechListenService;
      _backgroundStarted = false;
    }
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

    _speechToText.listen(
      listenFor: listenFor,
      partialResults: true,
      localeId: localeId,
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
