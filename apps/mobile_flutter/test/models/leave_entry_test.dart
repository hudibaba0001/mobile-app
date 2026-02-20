import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/leave_entry.dart';

void main() {
  group('LeaveEntry.fromJson', () {
    test('parses known LeaveType correctly', () {
      final json = {
        'id': 'l1',
        'date': '2024-05-10T00:00:00.000',
        'type': 'sick',
        'reason': 'Cold',
        'isPaid': true,
        'userId': 'u1',
        'createdAt': '2024-05-09T10:00:00.000',
        'updatedAt': '2024-05-09T10:00:00.000',
      };

      final entry = LeaveEntry.fromJson(json);
      expect(entry.type, LeaveType.sick);
    });

    test('falls back to LeaveType.unpaid for unknown type, does not throw', () {
      final json = {
        'id': 'l2',
        'date': '2024-05-11T00:00:00.000',
        'type': 'unknown_type_from_future',
        'reason': 'Testing fallback',
        'isPaid': false,
        'userId': 'u1',
        'createdAt': '2024-05-09T10:00:00.000',
        'updatedAt': '2024-05-09T10:00:00.000',
      };

      final entry = LeaveEntry.fromJson(json);
      expect(entry.type, LeaveType.unpaid);
    });
  });
}
