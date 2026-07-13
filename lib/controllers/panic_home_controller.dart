import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/panic_app_model.dart';
import '../services/panic_alert_service.dart';
import '../services/panic_permission_service.dart';
import '../services/panic_sms_service.dart';
import '../services/panic_storage_service.dart';
import '../services/voice_detection_service.dart';

class PanicHomeController extends ChangeNotifier {
  PanicHomeController({
    PanicStorageService? storageService,
    PanicAlertService? alertService,
    PanicPermissionService? permissionService,
    PanicSmsService? smsService,
    VoiceDetectionService? voiceDetectionService,
  }) : _storageService = storageService ?? PanicStorageService(),
       _alertService = alertService ?? PanicAlertService(),
       _permissionService = permissionService ?? PanicPermissionService(),
       _smsService = smsService ?? PanicSmsService(),
       _voiceDetectionService =
           voiceDetectionService ?? VoiceDetectionService(),
       _state = PanicAppModel.initial();

  final PanicStorageService _storageService;
  final PanicAlertService _alertService;
  final PanicPermissionService _permissionService;
  final PanicSmsService _smsService;
  final VoiceDetectionService _voiceDetectionService;
  PanicAppModel _state;
  String? _statusMessage;
  bool _helpSmsSentForThisActivation = false;

  bool get protectionEnabled => _state.protectionEnabled;
  bool get voiceDetected => _state.voiceDetected;
  String get emergencyPhrase => _state.emergencyPhrase;
  List<String> get sosContacts => List.unmodifiable(_state.sosContacts);
  List<String> get alertHistory => List.unmodifiable(_state.alertHistory);
  String? get statusMessage => _statusMessage;
  String get emergencyMessagePreview => _alertService.buildEmergencyMessage(
    emergencyPhrase: _state.emergencyPhrase,
    contacts: _state.sosContacts,
  );

  Future<void> load() async {
    _state = await _storageService.loadState();
    if (_state.protectionEnabled) {
      final started = await _startListening();
      if (!started) {
        _state = _state.copyWith(
          protectionEnabled: false,
          voiceDetected: false,
        );
        _statusMessage = 'No se pudo iniciar la escucha automática.';
      }
    }
    notifyListeners();
  }

  Future<void> requestStartupPermissions() async {
    final permissionsGranted = await _permissionService
        .requestEssentialPermissions();
    if (permissionsGranted) {
      _statusMessage = 'Permisos concedidos. La escucha está lista.';
    } else {
      _statusMessage = 'Concede micrófono y SMS para usar la escucha SOS.';
    }
    notifyListeners();
  }

  Future<void> setProtectionEnabled(bool value) async {
    if (value) {
      final permissionsGranted = await _permissionService
          .requestEssentialPermissions();
      if (!permissionsGranted) {
        _state = _state.copyWith(
          protectionEnabled: false,
          voiceDetected: false,
        );
        _statusMessage =
            'Necesitas dar permisos de micrófono y SMS para activar la escucha.';
        await _storageService.saveState(_state);
        notifyListeners();
        return;
      }

      _helpSmsSentForThisActivation = false;
    }

    _state = _state.copyWith(
      protectionEnabled: value,
      voiceDetected: value ? _state.voiceDetected : false,
    );
    if (value) {
      final started = await _startListening();
      if (started) {
        _statusMessage = 'Escucha activada. La app ya quedó en segundo plano.';
      } else {
        _state = _state.copyWith(
          protectionEnabled: false,
          voiceDetected: false,
        );
        _statusMessage = 'No se pudo iniciar la escucha en segundo plano.';
      }
    } else {
      await _stopListening();
      _statusMessage = 'Escucha desactivada.';
    }
    unawaited(_storageService.saveState(_state));
    notifyListeners();
  }

  void updateEmergencyPhrase(String value) {
    _state = _state.copyWith(emergencyPhrase: value);
    _statusMessage = 'Frase actualizada.';
    unawaited(_storageService.saveState(_state));
    notifyListeners();
  }

  void updateContact(int index, String value) {
    final updatedContacts = [..._state.sosContacts];
    if (index >= 0 && index < updatedContacts.length) {
      updatedContacts[index] = value;
      _state = _state.copyWith(sosContacts: updatedContacts);
      _statusMessage = 'Contacto guardado.';
      unawaited(_storageService.saveState(_state));
      notifyListeners();
    }
  }

  Future<void> testVoiceDetection() async {
    final microphoneGranted = await _permissionService
        .requestMicrophonePermission();
    if (!microphoneGranted) {
      _statusMessage = 'Necesitas permiso de micrófono para probar la voz.';
      notifyListeners();
      return;
    }

    final recognizedText = await _voiceDetectionService.listenForSpeech();
    if (recognizedText == null) {
      _state = _state.copyWith(voiceDetected: false);
      _statusMessage = 'No se detectó ninguna frase.';
      unawaited(_storageService.saveState(_state));
      notifyListeners();
      return;
    }

    final detected = _matchesEmergencyPhrase(
      recognizedText,
      _state.emergencyPhrase,
    );

    if (detected) {
      await processRecognizedSpeech(recognizedText);
      return;
    } else {
      _state = _state.copyWith(voiceDetected: false);
      _statusMessage = 'Se escuchó algo, pero no coincidió con la frase.';
    }

    unawaited(_storageService.saveState(_state));
    notifyListeners();
  }

  Future<bool> _startListening() async {
    try {
      await _voiceDetectionService.startBackgroundListening(
        onSpeechResult: _handleSpeechResult,
      );
      return true;
    } catch (_) {
      _state = _state.copyWith(protectionEnabled: false, voiceDetected: false);
      _statusMessage = 'No se pudo iniciar la escucha en segundo plano.';
      return false;
    }
  }

  Future<void> _stopListening() async {
    await _voiceDetectionService.stopBackgroundListening();
    _helpSmsSentForThisActivation = false;
  }

  Future<void> _handleSpeechResult(
    String recognizedText,
    bool isPartial,
  ) async {
    if (!_state.protectionEnabled || isPartial) {
      return;
    }

    await processRecognizedSpeech(recognizedText);
  }

  Future<void> processRecognizedSpeech(String recognizedText) async {
    if (_helpSmsSentForThisActivation) {
      return;
    }

    final detected = _matchesEmergencyPhrase(
      recognizedText,
      _state.emergencyPhrase,
    );

    if (!detected) {
      return;
    }

    _helpSmsSentForThisActivation = true;
    final smsSent = await _smsService.sendHelpSms();
    final alertMessage = _alertService.buildEmergencyMessage(
      emergencyPhrase: _state.emergencyPhrase,
      contacts: _state.sosContacts,
    );

    _state = _state.copyWith(
      voiceDetected: true,
      alertHistory: [alertMessage, ..._state.alertHistory],
    );
    _statusMessage = smsSent
        ? 'Frase detectada y SMS enviado a ${PanicAlertService.emergencyPhoneNumber}.'
        : 'Frase detectada, pero no se pudo enviar el SMS.';
    unawaited(_storageService.saveState(_state));
    notifyListeners();
  }

  bool _matchesEmergencyPhrase(String recognizedText, String expectedPhrase) {
    String normalize(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

    return normalize(recognizedText).contains(normalize(expectedPhrase));
  }
}
