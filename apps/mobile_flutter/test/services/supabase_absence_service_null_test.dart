import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/services/supabase_absence_service.dart';
import 'package:myapp/models/absence.dart';

// Copying fakes from user_red_day_repository_null_test.dart to keep tests isolated
class FakeMaybeSingleFuture extends Fake implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  final Future<Map<String, dynamic>?> _realFuture = Future.value(null);

  @override
  Stream<Map<String, dynamic>?> asStream() => _realFuture.asStream();
  @override
  Future<Map<String, dynamic>?> catchError(Function onError, {bool Function(Object error)? test}) => _realFuture.catchError(onError, test: test);
  @override
  Future<R> then<R>(FutureOr<R> Function(Map<String, dynamic>? value) onValue, {Function? onError}) => _realFuture.then(onValue, onError: onError);
  @override
  Future<Map<String, dynamic>?> timeout(Duration timeLimit, {FutureOr<Map<String, dynamic>?> Function()? onTimeout}) => _realFuture.timeout(timeLimit, onTimeout: onTimeout);
  @override
  Future<Map<String, dynamic>?> whenComplete(FutureOr<void> Function() action) => _realFuture.whenComplete(action);
}

class FakePostgrestTransformBuilder extends Fake implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #maybeSingle) {
      return FakeMaybeSingleFuture();
    }
    return super.noSuchMethod(invocation);
  }
}

class FakePostgrestFilterBuilder extends Fake implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #select) {
      return FakePostgrestTransformBuilder();
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #upsert || invocation.memberName == #insert || invocation.memberName == #update) {
      return FakePostgrestFilterBuilder();
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #from) {
      return FakeSupabaseQueryBuilder();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('SupabaseAbsenceService Null Handling', () {
    test('addAbsence throws Exception when maybeSingle returns null', () async {
      final fakeClient = FakeSupabaseClient();
      final service = SupabaseAbsenceService(supabase: fakeClient);

      final absence = AbsenceEntry(
        date: DateTime.now(),
        minutes: 480,
        type: AbsenceType.sickPaid,
      );

      await expectLater(
        service.addAbsence('test_user', absence),
        throwsA(isA<Exception>().having((e) => e.toString(), 'string', contains('no data returned'))),
      );
    });
  });
}
