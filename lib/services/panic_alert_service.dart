class PanicAlertService {
  static const String emergencyPhoneNumber = '+56959178040';
  static const String emergencySmsMessage = 'necesito ayuda';

  String buildEmergencyMessage({
    required String emergencyPhrase,
    required List<String> contacts,
    DateTime? timestamp,
  }) {
    final effectiveTimestamp = timestamp ?? DateTime.now();
    final contactList = contacts
        .where((contact) => contact.trim().isNotEmpty)
        .toList(growable: false);
    final contactText = contactList.isEmpty
        ? 'Sin contactos configurados'
        : contactList.join(', ');

    return 'ALERTA SOS: frase "$emergencyPhrase" detectada. '
        'SMS enviado a $emergencyPhoneNumber con el texto "${emergencySmsMessage}". '
        'Contactos: $contactText. Hora: ${_formatTimestamp(effectiveTimestamp)}.';
  }

  String _formatTimestamp(DateTime dateTime) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(dateTime.day)}/${twoDigits(dateTime.month)}/${dateTime.year} '
        '${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
  }
}
