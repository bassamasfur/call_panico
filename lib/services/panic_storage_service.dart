import 'package:shared_preferences/shared_preferences.dart';

import '../models/panic_app_model.dart';

class PanicStorageService {
  static const String _protectionEnabledKey = 'protectionEnabled';
  static const String _voiceDetectedKey = 'voiceDetected';
  static const String _emergencyPhraseKey = 'emergencyPhrase';
  static const String _sosContactsKey = 'sosContacts';
  static const String _alertHistoryKey = 'alertHistory';

  Future<PanicAppModel> loadState() async {
    final preferences = await SharedPreferences.getInstance();

    return PanicAppModel(
      protectionEnabled: preferences.getBool(_protectionEnabledKey) ?? false,
      voiceDetected: preferences.getBool(_voiceDetectedKey) ?? false,
      emergencyPhrase:
          preferences.getString(_emergencyPhraseKey) ?? 'ayuda ahora',
      sosContacts:
          preferences.getStringList(_sosContactsKey) ??
          const ['Ana - 555 0101', 'Luis - 555 0102', 'Marta - 555 0103'],
      alertHistory: preferences.getStringList(_alertHistoryKey) ?? const [],
    );
  }

  Future<void> saveState(PanicAppModel state) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_protectionEnabledKey, state.protectionEnabled);
    await preferences.setBool(_voiceDetectedKey, state.voiceDetected);
    await preferences.setString(_emergencyPhraseKey, state.emergencyPhrase);
    await preferences.setStringList(_sosContactsKey, state.sosContacts);
    await preferences.setStringList(_alertHistoryKey, state.alertHistory);
  }
}
