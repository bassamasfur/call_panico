class PanicAppModel {
  static const List<String> defaultSosContacts = [
    'Ana - 555 0101',
    'Luis - 555 0102',
    'Marta - 555 0103',
  ];

  const PanicAppModel({
    required this.protectionEnabled,
    required this.voiceDetected,
    required this.emergencyPhrase,
    required this.emergencyPhrases,
    required this.sosContacts,
    required this.alertHistory,
  });

  factory PanicAppModel.initial() {
    return const PanicAppModel(
      protectionEnabled: false,
      voiceDetected: false,
      emergencyPhrase: 'ayuda ahora',
      emergencyPhrases: ['ayuda ahora', 'necesito ayuda'],
      sosContacts: defaultSosContacts,
      alertHistory: [],
    );
  }

  final bool protectionEnabled;
  final bool voiceDetected;
  final String emergencyPhrase;
  final List<String> emergencyPhrases;
  final List<String> sosContacts;
  final List<String> alertHistory;

  PanicAppModel copyWith({
    bool? protectionEnabled,
    bool? voiceDetected,
    String? emergencyPhrase,
    List<String>? emergencyPhrases,
    List<String>? sosContacts,
    List<String>? alertHistory,
  }) {
    return PanicAppModel(
      protectionEnabled: protectionEnabled ?? this.protectionEnabled,
      voiceDetected: voiceDetected ?? this.voiceDetected,
      emergencyPhrase: emergencyPhrase ?? this.emergencyPhrase,
      emergencyPhrases: emergencyPhrases ?? this.emergencyPhrases,
      sosContacts: sosContacts ?? this.sosContacts,
      alertHistory: alertHistory ?? this.alertHistory,
    );
  }
}
