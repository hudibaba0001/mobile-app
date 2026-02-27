import '../l10n/generated/app_localizations.dart';

class ErrorMessageMapper {
  const ErrorMessageMapper._();

  static bool isOfflineError(Object e) {
    final raw = e.toString().toLowerCase();
    return raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('host lookup') ||
        raw.contains('network is unreachable') ||
        raw.contains('connection refused') ||
        raw.contains('connection reset by peer') ||
        raw.contains('connection closed before full header was received') ||
        raw.contains('clientexception');
  }

  static String userMessage(Object e, AppLocalizations t) {
    if (isOfflineError(e)) {
      return _offlineGenericMessage(t);
    }
    return _isSwedish(t)
        ? 'Nagot gick fel. Forsok igen.'
        : 'Something went wrong. Please try again.';
  }

  static String _offlineGenericMessage(AppLocalizations t) {
    return _isSwedish(t)
        ? 'Du ar offline. Anslut till internet och forsok igen.'
        : "You're offline. Connect to the internet and try again.";
  }

  static bool _isSwedish(AppLocalizations t) =>
      t.localeName.toLowerCase().startsWith('sv');
}
