import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/services/supabase_entry_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeDbState {
  _FakeDbState({
    required this.travelSegments,
  });

  final List<Map<String, dynamic>> travelSegments;
  bool failNextNewTravelInsert = true;
  int rollbackInsertAttempts = 0;
  int deleteCalls = 0;
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient(this.state);

  final _FakeDbState state;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #from) {
      final table = invocation.positionalArguments[0] as String;
      return _FakeSupabaseQueryBuilder(state, table);
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeSupabaseQueryBuilder(this.state, this.table);

  final _FakeDbState state;
  final String table;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #update) {
      return _FakePostgrestFilterBuilder(state, table, op: 'update');
    }
    if (invocation.memberName == #select) {
      return _FakePostgrestFilterBuilder(state, table, op: 'select');
    }
    if (invocation.memberName == #delete) {
      return _FakePostgrestFilterBuilder(state, table, op: 'delete');
    }
    if (invocation.memberName == #insert) {
      final payload = invocation.positionalArguments.first;
      return _FakeInsertBuilder(_handleInsert(payload));
    }
    return super.noSuchMethod(invocation);
  }

  Future<List<Map<String, dynamic>>> _handleInsert(Object payload) async {
    Iterable<Map<String, dynamic>> rows;
    if (payload is List) {
      rows = payload.map((e) => Map<String, dynamic>.from(e as Map));
    } else {
      rows = [Map<String, dynamic>.from(payload as Map)];
    }

    for (final row in rows) {
      if (table == 'travel_segments') {
        final from = row['from_location']?.toString() ?? '';
        if (from == 'New From' && state.failNextNewTravelInsert) {
          state.failNextNewTravelInsert = false;
          throw Exception('forced child insert failure');
        }
        if ((row['id']?.toString() ?? '') == 'old-segment-1') {
          state.rollbackInsertAttempts++;
        }
        state.travelSegments.add(Map<String, dynamic>.from(row));
      }
    }

    return <Map<String, dynamic>>[];
  }
}

class _FakeInsertBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  _FakeInsertBuilder(this._realFuture);

  final Future<dynamic> _realFuture;

  @override
  Stream<dynamic> asStream() => _realFuture.asStream();

  @override
  Future<dynamic> catchError(Function onError,
      {bool Function(Object error)? test}) {
    return _realFuture.catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(dynamic value) onValue,
      {Function? onError}) {
    return _realFuture.then(onValue, onError: onError);
  }

  @override
  Future<dynamic> timeout(Duration timeLimit,
      {FutureOr<dynamic> Function()? onTimeout}) {
    return _realFuture.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<dynamic> whenComplete(FutureOr<void> Function() action) {
    return _realFuture.whenComplete(action);
  }
}

class _FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  _FakePostgrestFilterBuilder(
    this.state,
    this.table, {
    required this.op,
  });

  final _FakeDbState state;
  final String table;
  final String op;
  final Future<List<Map<String, dynamic>>> _completedFuture =
      Future.value(<Map<String, dynamic>>[]);
  int _eqCount = 0;
  String? _filterColumn;
  dynamic _filterValue;

  @override
  Stream<List<Map<String, dynamic>>> asStream() => _completedFuture.asStream();

  @override
  Future<List<Map<String, dynamic>>> catchError(Function onError,
      {bool Function(Object error)? test}) {
    return _completedFuture.catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(
      FutureOr<R> Function(List<Map<String, dynamic>> value) onValue,
      {Function? onError}) {
    return _completedFuture.then(onValue, onError: onError);
  }

  @override
  Future<List<Map<String, dynamic>>> timeout(Duration timeLimit,
      {FutureOr<List<Map<String, dynamic>>> Function()? onTimeout}) {
    return _completedFuture.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<List<Map<String, dynamic>>> whenComplete(
      FutureOr<void> Function() action) {
    return _completedFuture.whenComplete(action);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #eq) {
      _eqCount++;
      _filterColumn = invocation.positionalArguments[0] as String;
      _filterValue = invocation.positionalArguments[1];

      if (op == 'delete') {
        if (table == 'travel_segments' && _filterColumn == 'entry_id') {
          state.deleteCalls++;
          state.travelSegments
              .removeWhere((row) => row['entry_id'] == _filterValue);
        }
        return this;
      }

      if (op == 'update') {
        return this;
      }

      return this;
    }

    if (invocation.memberName == #order && op == 'select') {
      if (table != 'travel_segments') {
        return _FakeListTransformFuture(<Map<String, dynamic>>[]);
      }
      final filtered = state.travelSegments
          .where((row) =>
              _filterColumn == null || row[_filterColumn] == _filterValue)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      return _FakeListTransformFuture(filtered);
    }

    return super.noSuchMethod(invocation);
  }
}

class _FakeListTransformFuture extends Fake
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  _FakeListTransformFuture(List<Map<String, dynamic>> rows)
      : _realFuture = Future.value(rows);

  final Future<List<Map<String, dynamic>>> _realFuture;

  @override
  Stream<List<Map<String, dynamic>>> asStream() => _realFuture.asStream();

  @override
  Future<List<Map<String, dynamic>>> catchError(Function onError,
      {bool Function(Object error)? test}) {
    return _realFuture.catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(
      FutureOr<R> Function(List<Map<String, dynamic>> value) onValue,
      {Function? onError}) {
    return _realFuture.then(onValue, onError: onError);
  }

  @override
  Future<List<Map<String, dynamic>>> timeout(Duration timeLimit,
      {FutureOr<List<Map<String, dynamic>>> Function()? onTimeout}) {
    return _realFuture.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<List<Map<String, dynamic>>> whenComplete(
      FutureOr<void> Function() action) {
    return _realFuture.whenComplete(action);
  }
}

void main() {
  test(
      'updateEntry travel child insert failure attempts rollback reinsertion of previous rows',
      () async {
    final state = _FakeDbState(
      travelSegments: [
        {
          'id': 'old-segment-1',
          'entry_id': 'entry-1',
          'from_location': 'Old From',
          'to_location': 'Old To',
          'travel_minutes': 25,
          'segment_order': 1,
          'total_segments': 1,
          'created_at': DateTime(2026, 3, 1).toIso8601String(),
          'updated_at': DateTime(2026, 3, 1).toIso8601String(),
        }
      ],
    );
    final service = SupabaseEntryService(supabase: _FakeSupabaseClient(state));
    final entry = Entry.makeTravelAtomicFromLeg(
      userId: 'user-1',
      date: DateTime(2026, 3, 10),
      from: 'New From',
      to: 'New To',
      minutes: 30,
      id: 'entry-1',
      createdAt: DateTime(2026, 3, 10),
    );

    await expectLater(
      service.updateEntry(entry),
      throwsA(predicate((error) =>
          error.toString().contains('Update failed; attempted rollback'))),
    );

    expect(state.deleteCalls, 2,
        reason:
            'Second delete clears partially inserted new children before rollback restore');
    expect(state.rollbackInsertAttempts, 1,
        reason: 'Old child row should be reinserted on rollback attempt');
    expect(
      state.travelSegments.where((row) => row['id'] == 'old-segment-1').length,
      1,
    );
    expect(
      state.travelSegments.where((row) => row['from_location'] == 'New From'),
      isEmpty,
      reason: 'Failed new child row must not be persisted',
    );
  });
}
