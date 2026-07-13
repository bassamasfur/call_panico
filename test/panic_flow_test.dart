import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:call_panico/controllers/panic_home_controller.dart';
import 'package:call_panico/services/panic_alert_service.dart';
import 'package:call_panico/services/panic_permission_service.dart';
import 'package:call_panico/services/panic_sms_service.dart';
import 'package:call_panico/services/voice_detection_service.dart';

class FakePermissionService extends PanicPermissionService {
  FakePermissionService({
    this.allowEssential = true,
    this.allowMicrophone = true,
  });

  final bool allowEssential;
  final bool allowMicrophone;

  @override
  Future<bool> requestEssentialPermissions() async => allowEssential;

  @override
  Future<bool> requestMicrophonePermission() async => allowMicrophone;
}

class FakeVoiceDetectionService extends VoiceDetectionService {
  FakeVoiceDetectionService(this.result);

  final String? result;

  @override
  Future<void> startBackgroundListening({
    required void Function(String recognizedText, bool isPartial)
    onSpeechResult,
  }) async {}

  @override
  Future<void> stopBackgroundListening() async {}

  @override
  Future<String?> listenForSpeech({
    Duration listenFor = const Duration(seconds: 6),
    String? localeId = 'es_ES',
  }) async {
    return result;
  }
}

class FakeSmsService extends PanicSmsService {
  FakeSmsService();

  bool sent = false;

  @override
  Future<bool> sendHelpSms() async {
    sent = true;
    return true;
  }
}

void main() {
  test('builds emergency alert message with contact list', () {
    final alertService = PanicAlertService();

    final message = alertService.buildEmergencyMessage(
      emergencyPhrase: 'ayuda ahora',
      contacts: ['Ana - 555 0101', 'Luis - 555 0102'],
      timestamp: DateTime(2026, 7, 13, 8, 45),
    );

    expect(message, contains('ALERTA SOS'));
    expect(message, contains('ayuda ahora'));
    expect(message, contains('Ana - 555 0101'));
    expect(message, contains('13/07/2026 08:45'));
  });

  test(
    'controller loads stored values and persists a detected alert',
    () async {
      SharedPreferences.setMockInitialValues({
        'protectionEnabled': false,
        'voiceDetected': false,
        'emergencyPhrase': 'llama ya',
        'sosContacts': ['Ana - 555 0101', 'Luis - 555 0102'],
        'alertHistory': [],
      });

      final smsService = FakeSmsService();
      final controller = PanicHomeController(
        permissionService: FakePermissionService(),
        voiceDetectionService: FakeVoiceDetectionService('llama ya'),
        smsService: smsService,
      );
      await controller.load();

      expect(controller.protectionEnabled, isFalse);
      expect(controller.emergencyPhrase, 'llama ya');
      expect(controller.sosContacts, hasLength(2));

      await controller.setProtectionEnabled(true);
      await controller.processRecognizedSpeech('llama ya');
      await Future<void>.delayed(Duration.zero);

      expect(controller.voiceDetected, isTrue);
      expect(controller.alertHistory, hasLength(1));
      expect(controller.alertHistory.first, contains('llama ya'));
      expect(smsService.sent, isTrue);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getStringList('alertHistory'), isNotNull);
      expect(preferences.getStringList('alertHistory'), hasLength(1));
    },
  );
}
