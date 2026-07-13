// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:call_panico/controllers/panic_home_controller.dart';
import 'package:call_panico/main.dart';
import 'package:call_panico/services/panic_permission_service.dart';
import 'package:call_panico/services/voice_detection_service.dart';

class FakePermissionService extends PanicPermissionService {
  @override
  Future<bool> requestEssentialPermissions() async => true;

  @override
  Future<bool> requestMicrophonePermission() async => true;
}

class FakeVoiceDetectionService extends VoiceDetectionService {
  @override
  Future<String?> listenForSpeech({
    Duration listenFor = const Duration(seconds: 6),
    String? localeId = 'es_ES',
  }) async {
    return 'ayuda ahora';
  }
}

void main() {
  testWidgets('simplified home shows toggle and config button', (
    WidgetTester tester,
  ) async {
    final controller = PanicHomeController(
      permissionService: FakePermissionService(),
      voiceDetectionService: FakeVoiceDetectionService(),
    );
    await controller.load();

    await tester.pumpWidget(MyApp(controller: controller));

    expect(find.text('App de Pánico por Voz'), findsOneWidget);
    expect(find.text('Escucha SOS'), findsOneWidget);
    expect(find.text('Configuración SOS'), findsOneWidget);
    expect(find.text('Abrir configuración'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.textContaining('Escucha activada'), findsOneWidget);

    await tester.tap(find.text('Abrir configuración'));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes de emergencia'), findsOneWidget);
    expect(find.text('Frase de emergencia'), findsOneWidget);
    expect(find.text('Editar contactos'), findsOneWidget);

    await tester.tap(find.text('Editar contactos'));
    await tester.pumpAndSettle();

    expect(find.text('Contactos SOS'), findsOneWidget);
    expect(find.text('Lista de contactos'), findsOneWidget);
  });
}
