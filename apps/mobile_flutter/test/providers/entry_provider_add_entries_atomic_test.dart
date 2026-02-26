import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/models/entry.dart';
import 'package:myapp/providers/entry_provider.dart';
import 'package:myapp/services/supabase_auth_service.dart';
import 'package:myapp/services/supabase_entry_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _StubAuthService extends Mock
    with ChangeNotifier
    implements SupabaseAuthService {
  User? user;

  @override
  User? get currentUser => user;
}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _ControlledSupabaseEntryService extends SupabaseEntryService {
  _ControlledSupabaseEntryService({
    required this.failOnAddCall,
    this.failRollback = false,
  }) : super(supabase: _MockSupabaseClient());

  final int failOnAddCall;
  final bool failRollback;
  int addCallCount = 0;
  final List<String> rollbackDeletedIds = [];

  @override
  Future<Entry> addEntry(Entry entry) async {
    addCallCount++;
    if (addCallCount == failOnAddCall) {
      throw Exception('forced failure on insert #$addCallCount');
    }
    return entry.copyWith(id: 'remote-created-$addCallCount');
  }

  @override
  Future<void> deleteEntry(String entryId, String userId) async {
    if (failRollback) {
      throw Exception('forced rollback delete failure for $entryId');
    }
    rollbackDeletedIds.add(entryId);
  }
}

User _user(String id) {
  return User(
    id: id,
    email: '$id@example.com',
    appMetadata: const {},
    userMetadata: const {},
    createdAt: DateTime(2026, 1, 1).toIso8601String(),
    aud: '',
  );
}

Entry _workEntry(String userId, DateTime date, int startHour) {
  return Entry.makeWorkAtomicFromShift(
    userId: userId,
    date: date,
    shift: Shift(
      start: DateTime(date.year, date.month, date.day, startHour, 0),
      end: DateTime(date.year, date.month, date.day, startHour + 1, 0),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
      'addEntries rolls back created remote IDs and avoids partial local commit on mid-batch failure',
      () async {
    final authService = _StubAuthService()..user = _user('user-1');
    final supabaseService = _ControlledSupabaseEntryService(failOnAddCall: 2);
    final provider = EntryProvider(
      authService,
      supabaseService: supabaseService,
    );

    final entries = <Entry>[
      _workEntry('user-1', DateTime(2026, 3, 10), 8),
      _workEntry('user-1', DateTime(2026, 3, 10), 10),
      _workEntry('user-1', DateTime(2026, 3, 10), 12),
    ];

    await expectLater(
      provider.addEntries(entries),
      throwsA(
        predicate(
            (error) => error.toString().contains('rollback was attempted')),
      ),
    );

    expect(supabaseService.addCallCount, 2);
    expect(supabaseService.rollbackDeletedIds, ['remote-created-1']);

    // No partial in-memory commit should happen on failure.
    expect(provider.entries, isEmpty);
    expect(provider.filteredEntries, isEmpty);
  });

  test(
      'addEntries warns when rollback delete fails and still avoids partial local commit',
      () async {
    final authService = _StubAuthService()..user = _user('user-1');
    final supabaseService = _ControlledSupabaseEntryService(
      failOnAddCall: 2,
      failRollback: true,
    );
    final provider = EntryProvider(
      authService,
      supabaseService: supabaseService,
    );

    final entries = <Entry>[
      _workEntry('user-1', DateTime(2026, 3, 11), 8),
      _workEntry('user-1', DateTime(2026, 3, 11), 10),
    ];

    await expectLater(
      provider.addEntries(entries),
      throwsA(
        predicate((error) => error
            .toString()
            .contains('some parts may still be saved remotely')),
      ),
    );

    expect(supabaseService.addCallCount, 2);
    expect(provider.entries, isEmpty);
    expect(provider.filteredEntries, isEmpty);
  });
}
