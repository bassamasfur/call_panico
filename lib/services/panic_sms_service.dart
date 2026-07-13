import 'package:telephony/telephony.dart';

import 'panic_alert_service.dart';

class PanicSmsService {
  PanicSmsService({Telephony? telephony}) : _telephony = telephony;

  Telephony? _telephony;

  Future<bool> sendHelpSms() async {
    final destinationNumbers = _destinationCandidates(
      PanicAlertService.emergencyPhoneNumber,
    );

    try {
      final telephony = _telephony ??= Telephony.instance;
      for (final destinationNumber in destinationNumbers) {
        try {
          await telephony.sendSms(
            to: destinationNumber,
            message: PanicAlertService.emergencySmsMessage,
          );
          return true;
        } catch (_) {
          continue;
        }
      }
    } catch (_) {}

    return false;
  }

  List<String> _destinationCandidates(String rawNumber) {
    final normalized = rawNumber.trim().replaceAll(RegExp(r'[^\d+]'), '');
    if (normalized.isEmpty) {
      return const [];
    }

    final withoutPlus = normalized.startsWith('+')
        ? normalized.substring(1)
        : normalized;

    if (withoutPlus == normalized) {
      return [withoutPlus];
    }

    return [normalized, withoutPlus];
  }
}
