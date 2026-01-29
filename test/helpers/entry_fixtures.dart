import 'package:myapp/models/entry.dart';
import 'package:uuid/uuid.dart';

/// Helper to create valid Shift objects
Shift makeShift({
  required DateTime date,
  required String startHHMM,
  required String endHHMM,
  int breakMinutes = 0,
}) {
  final startParts = startHHMM.split(':');
  final endParts = endHHMM.split(':');
  
  final start = DateTime(
    date.year,
    date.month,
    date.day,
    int.parse(startParts[0]),
    int.parse(startParts[1]),
  );
  
  final end = DateTime(
    date.year,
    date.month,
    date.day,
    int.parse(endParts[0]),
    int.parse(endParts[1]),
  );

  return Shift(
    start: start,
    end: end,
    unpaidBreakMinutes: breakMinutes,
  );
}

/// Helper to create an Entry with a single shift
Entry makeWorkEntry({
  required DateTime localDate,
  required String startHHMM,
  required String endHHMM,
  int breakMinutes = 0,
  String userId = 'test-user',
}) {
  final shift = makeShift(
    date: localDate,
    startHHMM: startHHMM,
    endHHMM: endHHMM,
    breakMinutes: breakMinutes,
  );

  return Entry.makeWorkAtomicFromShift(
    userId: userId,
    date: localDate,
    shift: shift,
  );
}

/// Helper to create a Travel Entry
Entry makeTravelEntry({
  required DateTime localDate,
  required int minutes,
  String userId = 'test-user',
}) {
  return Entry.makeTravelAtomicFromLeg(
    userId: userId,
    date: localDate,
    from: 'Home',
    to: 'Work',
    minutes: minutes,
  );
}
