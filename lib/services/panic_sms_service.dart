import 'package:telephony/telephony.dart';

import 'panic_alert_service.dart';

class PanicSmsService {
  PanicSmsService({Telephony? telephony}) : _telephony = telephony;

  Telephony? _telephony;

  Future<bool> sendHelpSms({required List<String> destinationNumbers}) async {
    final destinationCandidates = _destinationCandidates(destinationNumbers);

    if (destinationCandidates.isEmpty) {
      return false;
    }

    try {
      final telephony = _telephony ??= Telephony.instance;
      for (final destinationNumber in destinationCandidates) {
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

  List<String> _destinationCandidates(List<String> rawNumbers) {
    final candidates = <String>[];
    final seen = <String>{};

    for (final rawNumber in rawNumbers) {
      final normalized = rawNumber.trim().replaceAll(RegExp(r'[^\d+]'), '');
      if (normalized.isEmpty) {
        continue;
      }

      final withoutPlus = normalized.startsWith('+')
          ? normalized.substring(1)
          : normalized;

      for (final candidate in [normalized, withoutPlus]) {
        if (candidate.isEmpty || seen.contains(candidate)) {
          continue;
        }
        seen.add(candidate);
        candidates.add(candidate);
      }
    }

    return candidates;
  }
}
