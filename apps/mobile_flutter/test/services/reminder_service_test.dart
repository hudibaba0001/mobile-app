import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/services/reminder_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('ReminderService DST-safe daily scheduling', () {
    setUpAll(() {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Stockholm'));
    });

    test('next schedule keeps requested hour across DST fallback boundary', () {
      final now = tz.TZDateTime(tz.local, 2026, 10, 25, 23, 30);

      final scheduled = ReminderService.nextDailyScheduleTime(
        now: now,
        hour: 22,
        minute: 0,
      );

      expect(scheduled.year, 2026);
      expect(scheduled.month, 10);
      expect(scheduled.day, 26);
      expect(scheduled.hour, 22);
      expect(scheduled.minute, 0);
    });
  });
}
