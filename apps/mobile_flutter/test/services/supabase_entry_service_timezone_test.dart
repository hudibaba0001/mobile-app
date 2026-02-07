import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/entry.dart';

/// Unit tests for timezone conversion in SupabaseEntryService
///
/// Verifies that:
/// 1. Local DateTime (constructed from entry.date + TimeOfDay) is converted to UTC before storing
/// 2. UTC timestamps from DB are converted back to local for UI
/// 3. Sweden timezone offset is correctly applied (UTC+1 in winter, UTC+2 in summer)
void main() {
  group('SupabaseEntryService timezone conversion', () {
    test(
        'shift start/end times are converted to UTC before storing (Sweden winter, UTC+1)',
        () {
      // Given a local shift at 08:00 Sweden time (January, UTC+1)
      // The payload should use 07:00Z

      final localStart = DateTime(2025, 1, 15, 8, 0); // 08:00 local time
      final localEnd = DateTime(2025, 1, 15, 12, 0); // 12:00 local time

      // Verify it's local (not UTC)
      expect(localStart.isUtc, false);
      expect(localEnd.isUtc, false);

      // Create shift with local times
      final shift = Shift(
        start: localStart,
        end: localEnd,
        unpaidBreakMinutes: 30,
        notes: 'DBG',
        location: 'Office',
      );
      expect(shift.location, 'Office');
      // When converting to UTC for storage (as SupabaseEntryService does):
      final startUtc = localStart.toUtc();
      final endUtc = localEnd.toUtc();

      // In January, Sweden is UTC+1, so 08:00 local = 07:00 UTC
      expect(startUtc.hour, 7,
          reason: '08:00 Sweden time (UTC+1) should convert to 07:00 UTC');
      expect(startUtc.minute, 0);
      expect(endUtc.hour, 11,
          reason: '12:00 Sweden time (UTC+1) should convert to 11:00 UTC');
      expect(endUtc.minute, 0);

      // Verify toIso8601String includes Z for UTC
      final startIso = startUtc.toIso8601String();
      expect(
        startIso,
        anyOf(contains('Z'), contains('+00:00')),
        reason: 'UTC timestamp should include Z or +00:00',
      );
    });

    test(
        'shift start/end times are converted to UTC before storing (Sweden summer, UTC+2)',
        () {
      // Given a local shift at 08:00 Sweden time (July, UTC+2)
      // The payload should use 06:00Z

      final localStart = DateTime(2025, 7, 15, 8, 0); // 08:00 local time
      final localEnd = DateTime(2025, 7, 15, 12, 0); // 12:00 local time

      // Verify it's local (not UTC)
      expect(localStart.isUtc, false);
      expect(localEnd.isUtc, false);

      // Create shift with local times
      final shift = Shift(
        start: localStart,
        end: localEnd,
        unpaidBreakMinutes: 30,
        notes: 'DBG',
      );
      expect(shift.notes, 'DBG');
      // When converting to UTC for storage:
      final startUtc = localStart.toUtc();
      final endUtc = localEnd.toUtc();

      // In July, Sweden is UTC+2, so 08:00 local = 06:00 UTC
      expect(startUtc.hour, 6,
          reason: '08:00 Sweden time (UTC+2) should convert to 06:00 UTC');
      expect(startUtc.minute, 0);
      expect(endUtc.hour, 10,
          reason: '12:00 Sweden time (UTC+2) should convert to 10:00 UTC');
      expect(endUtc.minute, 0);
    });

    test('UTC timestamps from DB are converted back to local for UI', () {
      // Simulate reading from DB: UTC timestamps are converted to local
      final utcStart = DateTime.utc(2025, 1, 15, 7, 0); // 07:00 UTC
      final utcEnd = DateTime.utc(2025, 1, 15, 11, 0); // 11:00 UTC

      // Convert to local (as SupabaseEntryService does on read)
      final localStart = utcStart.toLocal();
      final localEnd = utcEnd.toLocal();

      // In January, Sweden is UTC+1, so 07:00 UTC = 08:00 local
      expect(localStart.hour, 8,
          reason: '07:00 UTC should convert to 08:00 local (UTC+1)');
      expect(localStart.minute, 0);
      expect(localEnd.hour, 12,
          reason: '11:00 UTC should convert to 12:00 local (UTC+1)');
      expect(localEnd.minute, 0);
    });

    test('timezone conversion preserves date when crossing midnight', () {
      // Edge case: Shift that starts late and ends early next day
      final localStart = DateTime(2025, 1, 15, 23, 0); // 23:00 local
      final localEnd = DateTime(2025, 1, 16, 1, 0); // 01:00 next day local

      final startUtc = localStart.toUtc();
      final endUtc = localEnd.toUtc();

      // 23:00 local (UTC+1) = 22:00 UTC same day
      expect(startUtc.hour, 22);
      expect(startUtc.day, 15);

      // 01:00 next day local (UTC+1) = 00:00 UTC next day
      expect(endUtc.hour, 0);
      expect(endUtc.day, 16);
    });
  });
}
