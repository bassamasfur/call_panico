import 'package:shared_preferences/shared_preferences.dart';

import '../models/panic_app_model.dart';

class PanicStorageService {
  static const String _protectionEnabledKey = 'protectionEnabled';
  static const String _voiceDetectedKey = 'voiceDetected';
  static const String _emergencyPhraseKey = 'emergencyPhrase';
  static const String _emergencyPhrasesKey = 'emergencyPhrases';
  static const String _sosContactsKey = 'sosContacts';
  static const String _alertHistoryKey = 'alertHistory';

  Future<PanicAppModel> loadState() async {
    final preferences = await SharedPreferences.getInstance();
    final legacyEmergencyPhrase =
        preferences.getString(_emergencyPhraseKey) ?? 'ayuda ahora';
    final storedEmergencyPhrases = preferences.getStringList(
      _emergencyPhrasesKey,
    );
    final emergencyPhrases = _normalizedPhrases(
      storedEmergencyPhrases ?? [legacyEmergencyPhrase],
    );
    final emergencyPhrase =
        preferences.getString(_emergencyPhraseKey) ?? emergencyPhrases.first;

    return PanicAppModel(
      protectionEnabled: preferences.getBool(_protectionEnabledKey) ?? false,
      voiceDetected: preferences.getBool(_voiceDetectedKey) ?? false,
      emergencyPhrase: emergencyPhrase,
      emergencyPhrases: emergencyPhrases,
      sosContacts:
          preferences.getStringList(_sosContactsKey) ??
          PanicAppModel.defaultSosContacts,
      alertHistory: preferences.getStringList(_alertHistoryKey) ?? const [],
    );
  }

  Future<void> saveState(PanicAppModel state) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_protectionEnabledKey, state.protectionEnabled);
    await preferences.setBool(_voiceDetectedKey, state.voiceDetected);
    await preferences.setString(_emergencyPhraseKey, state.emergencyPhrase);
    await preferences.setStringList(
      _emergencyPhrasesKey,
      _normalizedPhrases(state.emergencyPhrases),
    );
    await preferences.setStringList(_sosContactsKey, state.sosContacts);
    await preferences.setStringList(_alertHistoryKey, state.alertHistory);
  }

  List<String> _normalizedPhrases(List<String> phrases) {
    final unique = <String>[];
    for (final phrase in phrases) {
      final normalized = phrase.trim();
      if (normalized.isNotEmpty && !unique.contains(normalized)) {
        unique.add(normalized);
      }
    }

    if (unique.isEmpty) {
      return const ['ayuda ahora'];
    }

    return unique;
  }
}
