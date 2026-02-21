import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/repositories/user_red_day_repository.dart';
import 'package:myapp/models/user_red_day.dart';

// Fakes for Supabase chained methods returning null on .maybeSingle()
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
  // We only implement maybeSingle
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
  group('UserRedDayRepository Null Handling', () {
    test('upsert throws StateError when maybeSingle returns null', () async {
      final fakeClient = FakeSupabaseClient();
      final repository = UserRedDayRepository(supabase: fakeClient);

      final redDay = UserRedDay(
        date: DateTime.now(),
        userId: 'test_user',
        kind: RedDayKind.full,
        source: RedDaySource.manual,
      );

      await expectLater(
        repository.upsert(redDay),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('no data returned'))),
      );
    });
  });
}
