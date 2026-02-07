import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/calendar/sweden_holidays.dart';

void main() {
  group('SwedenHolidayCalendar', () {
    test('Midsummer Day is Saturday and between Jun 20-26', () {
      final calendar = SwedenHolidayCalendar();

      // Test multiple years
      for (int year = 2020; year <= 2030; year++) {
        final holidays = calendar.holidaysForYear(year);

        // Find Midsummer Day
        final midsummer = holidays.firstWhere(
          (date) => date.month == 6 && date.day >= 20 && date.day <= 26,
          orElse: () =>
              throw Exception('Midsummer Day not found for year $year'),
        );

        // Must be Saturday (weekday 6)
        expect(midsummer.weekday, 6,
            reason: 'Midsummer Day must be Saturday in $year');
        expect(midsummer.day, greaterThanOrEqualTo(20));
        expect(midsummer.day, lessThanOrEqualTo(26));
      }
    });

    test('All Saints Day is Saturday and between Oct 31-Nov 6', () {
      final calendar = SwedenHolidayCalendar();

      // Test multiple years
      for (int year = 2020; year <= 2030; year++) {
        final holidays = calendar.holidaysForYear(year);

        // Find All Saints' Day
        DateTime? allSaints;

        // Check Oct 31
        final oct31 = DateTime(year, 10, 31);
        if (oct31.weekday == 6 && holidays.contains(oct31)) {
          allSaints = oct31;
        } else {
          // Check Nov 1-6
          for (int day = 1; day <= 6; day++) {
            final date = DateTime(year, 11, day);
            if (date.weekday == 6 && holidays.contains(date)) {
              allSaints = date;
              break;
            }
          }
        }

        expect(allSaints, isNotNull,
            reason: 'All Saints Day not found for year $year');
        expect(allSaints!.weekday, 6,
            reason: 'All Saints Day must be Saturday in $year');

        if (allSaints.month == 10) {
          expect(allSaints.day, 31);
        } else {
          expect(allSaints.month, 11);
          expect(allSaints.day, greaterThanOrEqualTo(1));
          expect(allSaints.day, lessThanOrEqualTo(6));
        }
      }
    });

    test('Easter-based holidays are consistent', () {
      final calendar = SwedenHolidayCalendar();

      // Known Easter dates for verification
      // 2024: Easter Sunday = March 31
      // 2025: Easter Sunday = April 20
      final holidays2024 = calendar.holidaysForYear(2024);
      final holidays2025 = calendar.holidaysForYear(2025);

      // 2024: Good Friday = March 29
      expect(holidays2024.contains(DateTime(2024, 3, 29)), isTrue);
      // 2024: Easter Sunday = March 31
      expect(holidays2024.contains(DateTime(2024, 3, 31)), isTrue);
      // 2024: Easter Monday = April 1
      expect(holidays2024.contains(DateTime(2024, 4, 1)), isTrue);

      // 2025: Good Friday = April 18
      expect(holidays2025.contains(DateTime(2025, 4, 18)), isTrue);
      // 2025: Easter Sunday = April 20
      expect(holidays2025.contains(DateTime(2025, 4, 20)), isTrue);
      // 2025: Easter Monday = April 21
      expect(holidays2025.contains(DateTime(2025, 4, 21)), isTrue);
    });

    test('Fixed-date holidays are correct', () {
      final calendar = SwedenHolidayCalendar();
      final holidays2025 = calendar.holidaysForYear(2025);

      expect(holidays2025.contains(DateTime(2025, 1, 1)),
          isTrue); // New Year's Day
      expect(holidays2025.contains(DateTime(2025, 1, 6)), isTrue); // Epiphany
      expect(holidays2025.contains(DateTime(2025, 5, 1)), isTrue); // May Day
      expect(
          holidays2025.contains(DateTime(2025, 6, 6)), isTrue); // National Day
      expect(
          holidays2025.contains(DateTime(2025, 12, 25)), isTrue); // Christmas
      expect(
          holidays2025.contains(DateTime(2025, 12, 26)), isTrue); // Boxing Day
    });

    test('isHoliday returns correct values', () {
      final calendar = SwedenHolidayCalendar();

      // New Year's Day 2025
      expect(calendar.isHoliday(DateTime(2025, 1, 1)), isTrue);

      // Regular weekday
      expect(calendar.isHoliday(DateTime(2025, 1, 2)), isFalse);

      // Regular weekend
      expect(calendar.isHoliday(DateTime(2025, 1, 4)), isFalse); // Saturday
      expect(calendar.isHoliday(DateTime(2025, 1, 5)), isFalse); // Sunday
    });

    test('holidayName returns correct names', () {
      final calendar = SwedenHolidayCalendar();

      expect(calendar.holidayName(DateTime(2025, 1, 1)), 'New Year\'s Day');
      expect(calendar.holidayName(DateTime(2025, 5, 1)), 'May Day');
      expect(calendar.holidayName(DateTime(2025, 6, 6)), 'National Day');
      expect(
          calendar.holidayName(DateTime(2025, 1, 2)), isNull); // Not a holiday
    });
  });
}
