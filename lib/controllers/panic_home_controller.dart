import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/panic_app_model.dart';
import '../services/panic_alert_service.dart';
import '../services/panic_permission_service.dart';
import '../services/panic_sms_service.dart';
import '../services/panic_storage_service.dart';
import '../services/voice_detection_service.dart';

class PanicHomeController extends ChangeNotifier {
  static const Duration _smsCooldown = Duration(seconds: 20);

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
  DateTime? _lastSmsSentAt;

  bool get protectionEnabled => _state.protectionEnabled;
  bool get voiceDetected => _state.voiceDetected;
  String get emergencyPhrase => _state.emergencyPhrase;
  List<String> get emergencyPhrases =>
      List.unmodifiable(_state.emergencyPhrases);
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
    final normalizedValue = _sanitizePhrase(value);
    if (normalizedValue.isEmpty) {
      return;
    }

    final updatedPhrases = [..._state.emergencyPhrases];
    if (updatedPhrases.isEmpty) {
      updatedPhrases.add(normalizedValue);
    } else {
      updatedPhrases[0] = normalizedValue;
    }

    _state = _state.copyWith(
      emergencyPhrase: normalizedValue,
      emergencyPhrases: updatedPhrases,
    );
    _statusMessage = 'Frase actualizada.';
    unawaited(_storageService.saveState(_state));
    notifyListeners();
  }

  void addEmergencyPhrase(String value) {
    final normalizedValue = _sanitizePhrase(value);
    if (normalizedValue.isEmpty) {
      _statusMessage = 'Escribe una frase válida.';
      notifyListeners();
      return;
    }

    final updatedPhrases = [..._state.emergencyPhrases];
    final exists = updatedPhrases.any(
      (phrase) => _normalizeText(phrase) == _normalizeText(normalizedValue),
    );
    if (exists) {
      _statusMessage = 'Esa frase ya está guardada.';
      notifyListeners();
      return;
    }

    updatedPhrases.add(normalizedValue);
    _state = _state.copyWith(emergencyPhrases: updatedPhrases);
    _statusMessage = 'Frase guardada.';
    unawaited(_storageService.saveState(_state));
    notifyListeners();
  }

  void removeEmergencyPhrase(int index) {
    final updatedPhrases = [..._state.emergencyPhrases];
    if (index < 0 ||
        index >= updatedPhrases.length ||
        updatedPhrases.length == 1) {
      return;
    }

    updatedPhrases.removeAt(index);
    final fallbackPrimary = updatedPhrases.first;
    _state = _state.copyWith(
      emergencyPhrase: fallbackPrimary,
      emergencyPhrases: updatedPhrases,
    );
    _statusMessage = 'Frase eliminada.';
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

  void replaceContacts(List<String> values) {
    final cleanedValues = values
        .map(_sanitizePhrase)
        .where((value) => value.isNotEmpty)
        .take(3)
        .toList(growable: false);

    if (cleanedValues.isEmpty) {
      _statusMessage = 'No se importaron contactos válidos.';
      notifyListeners();
      return;
    }

    final updatedContacts = [..._state.sosContacts];
    while (updatedContacts.length < 3) {
      updatedContacts.add('');
    }

    for (var index = 0; index < cleanedValues.length; index++) {
      updatedContacts[index] = cleanedValues[index];
    }

    _state = _state.copyWith(sosContacts: updatedContacts.take(3).toList());
    _statusMessage = 'Contactos importados desde la agenda.';
    unawaited(_storageService.saveState(_state));
    notifyListeners();
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

    final detected = _matchesEmergencyPhrase(recognizedText);

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
    _lastSmsSentAt = null;
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
    if (_isInSmsCooldown()) {
      return;
    }

    final detected = _matchesEmergencyPhrase(recognizedText);

    if (!detected) {
      return;
    }

    final destinationNumbers = _buildSmsDestinationNumbers();
    if (destinationNumbers.isEmpty) {
      _statusMessage =
          'Configura 3 contactos reales desde la agenda antes de enviar SMS.';
      notifyListeners();
      return;
    }

    final smsSent = await _smsService.sendHelpSms(
      destinationNumbers: destinationNumbers,
    );
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
    if (smsSent) {
      _lastSmsSentAt = DateTime.now();
    }
    unawaited(_storageService.saveState(_state));
    notifyListeners();
  }

  bool _matchesEmergencyPhrase(String recognizedText) {
    String normalize(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

    final normalizedRecognition = normalize(recognizedText);
    return _state.emergencyPhrases.any(
      (phrase) => normalizedRecognition.contains(normalize(phrase)),
    );
  }

  bool _isInSmsCooldown() {
    final lastSentAt = _lastSmsSentAt;
    if (lastSentAt == null) {
      return false;
    }

    return DateTime.now().difference(lastSentAt) < _smsCooldown;
  }

  List<String> _buildSmsDestinationNumbers() {
    if (!_hasThreeRealContacts()) {
      return const [];
    }

    final destinationNumbers = <String>[
      PanicAlertService.emergencyPhoneNumber,
      ..._state.sosContacts.map(_extractPhoneNumber),
    ];

    return destinationNumbers.where((number) => number.isNotEmpty).toList();
  }

  bool _hasThreeRealContacts() {
    final defaults = PanicAppModel.defaultSosContacts
        .map(_normalizeText)
        .toSet();

    if (_state.sosContacts.length < 3) {
      return false;
    }

    return _state.sosContacts.take(3).every((contact) {
      final normalizedContact = _normalizeText(contact);
      return normalizedContact.isNotEmpty &&
          !defaults.contains(normalizedContact);
    });
  }

  String _extractPhoneNumber(String contactText) {
    final trimmed = contactText.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final parts = trimmed.split(' - ');
    final phoneText = parts.length > 1 ? parts.last : trimmed;
    return phoneText.replaceAll(RegExp(r'[^\d+]'), '');
  }

  String _sanitizePhrase(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalizeText(String value) {
    return _sanitizePhrase(value).toLowerCase();
  }
}
