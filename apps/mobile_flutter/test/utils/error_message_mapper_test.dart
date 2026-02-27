import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/l10n/generated/app_localizations_en.dart';
import 'package:myapp/utils/error_message_mapper.dart';

void main() {
  group('ErrorMessageMapper', () {
    test('maps SocketException to offline-friendly message', () {
      final t = AppLocalizationsEn();
      final error = SocketException('Failed host lookup: abc.supabase.co');

      final message = ErrorMessageMapper.userMessage(error, t);

      expect(ErrorMessageMapper.isOfflineError(error), isTrue);
      expect(
        message,
        equals("You're offline. Connect to the internet and try again."),
      );
      expect(message.toLowerCase(), isNot(contains('supabase')));
      expect(message.toLowerCase(), isNot(contains('host lookup')));
    });

    test('maps unknown errors to generic safe message', () {
      final t = AppLocalizationsEn();
      final message = ErrorMessageMapper.userMessage(Exception('boom'), t);

      expect(message, equals('Something went wrong. Please try again.'));
    });
  });
}
