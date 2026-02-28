import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:myapp/models/entry.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/providers/entry_provider.dart';
import 'package:myapp/services/supabase_auth_service.dart';
import 'package:myapp/services/supabase_entry_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _StubAuthService extends Mock
    with ChangeNotifier
    implements SupabaseAuthService {
  User? user;

  @override
  User? get currentUser => user;
}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _RecordingSupabaseEntryService extends SupabaseEntryService {
  _RecordingSupabaseEntryService() : super(supabase: _MockSupabaseClient());

  int getAllEntriesCalls = 0;
  int getEntriesInRangeCalls = 0;
  int? lastLimit;
  DateTime? lastRangeStart;
  DateTime? lastRangeEnd;
  List<Entry> inRangeEntries = <Entry>[];

  @override
  Future<List<Entry>> getAllEntries(
    String userId, {
    int? limit,
    int offset = 0,
  }) async {
    getAllEntriesCalls++;
    lastLimit = limit;
    return <Entry>[];
  }

  @override
  Future<List<Entry>> getEntriesInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    getEntriesInRangeCalls++;
    lastRangeStart = start;
    lastRangeEnd = end;
    return inRangeEntries;
  }
}

Entry _entry({
  required String id,
  required String userId,
  required DateTime date,
}) {
  return Entry(
    id: id,
    userId: userId,
    type: EntryType.work,
    date: date,
    shifts: <Shift>[
      Shift(
        start: DateTime(date.year, date.month, date.day, 8),
        end: DateTime(date.year, date.month, date.day, 16),
      ),
    ],
    createdAt: date,
  );
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _yearStart(DateTime d) => DateTime(d.year, 1, 1);

DateTime _yearEnd(DateTime d) => DateTime(d.year, 12, 31, 23, 59, 59);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('entry_provider_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(EntryAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(EntryTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(ShiftAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(TravelLegAdapter());
    }
  });

  tearDown(() async {
    if (Hive.isBoxOpen('entries_cache')) {
      await Hive.box<Entry>('entries_cache').close();
    }
    await Hive.deleteBoxFromDisk('entries_cache');
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('default load fetches current-year entries via date range', () async {
    final now = DateTime.now();
    final authService = _StubAuthService()..user = _user('user-1');
    final service = _RecordingSupabaseEntryService()
      ..inRangeEntries = <Entry>[
        _entry(
          id: 'entry-1',
          userId: 'user-1',
          date: DateTime(now.year, 2, 3),
        ),
      ];
    final provider = EntryProvider(
      authService,
      supabaseService: service,
      trackingStartDateFetcher: (_) async => null,
    );

    await provider.loadEntries();

    expect(service.getEntriesInRangeCalls, 1);
    expect(service.getAllEntriesCalls, 0);
    expect(service.lastRangeStart, _yearStart(now));
    expect(service.lastRangeEnd, _yearEnd(now));
    expect(provider.entries.length, 1);
  });

  test('default load starts at trackingStartDate when it is later than Jan 1',
      () async {
    final now = DateTime.now();
    final trackingStart = DateTime(now.year, 2, 27);
    final authService = _StubAuthService()..user = _user('user-1');
    final service = _RecordingSupabaseEntryService();
    final provider = EntryProvider(
      authService,
      supabaseService: service,
      trackingStartDateFetcher: (_) async => trackingStart,
    );

    await provider.loadEntries();

    expect(service.getEntriesInRangeCalls, 1);
    expect(service.lastRangeStart, _dateOnly(trackingStart));
    expect(service.lastRangeEnd, _yearEnd(now));
  });

  test('history mode uses bounded latest-entry fetch', () async {
    final authService = _StubAuthService()..user = _user('user-1');
    final service = _RecordingSupabaseEntryService();
    final provider = EntryProvider(
      authService,
      supabaseService: service,
      trackingStartDateFetcher: (_) async => null,
    );

    await provider.loadLatestEntries();

    expect(service.getAllEntriesCalls, 1);
    expect(service.lastLimit, 500);
    expect(service.getEntriesInRangeCalls, 0);
  });

  test('default load is not capped to 500 when current-year dataset is larger',
      () async {
    final now = DateTime.now();
    final authService = _StubAuthService()..user = _user('user-1');
    final service = _RecordingSupabaseEntryService()
      ..inRangeEntries = List<Entry>.generate(
        650,
        (index) => _entry(
          id: 'entry-$index',
          userId: 'user-1',
          date: DateTime(now.year, 1, 1).add(Duration(days: index % 300)),
        ),
      );
    final provider = EntryProvider(
      authService,
      supabaseService: service,
      trackingStartDateFetcher: (_) async => null,
    );

    await provider.loadEntries();

    expect(service.getEntriesInRangeCalls, 1);
    expect(service.getAllEntriesCalls, 0);
    expect(provider.entries.length, 650);
  });
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
