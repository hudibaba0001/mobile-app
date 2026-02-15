import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:myapp/models/absence.dart';
import 'package:myapp/models/absence_entry_adapter.dart';
import 'package:myapp/providers/absence_provider.dart';
import 'package:myapp/services/supabase_absence_service.dart';
import 'package:myapp/services/supabase_auth_service.dart';

class MockSupabaseAuthService extends Mock implements SupabaseAuthService {}

class MockSupabaseAbsenceService extends Mock
    implements SupabaseAbsenceService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<AbsenceEntry> box;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('absence_provider_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(AbsenceEntryAdapter());
    }
  });

  setUp(() async {
    box = await Hive.openBox<AbsenceEntry>('absences_cache_test');
  });

  tearDown(() async {
    await box.clear();
    await box.close();
    await Hive.deleteBoxFromDisk('absences_cache_test');
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('loads only active user cached years when switching users', () async {
    final authService = MockSupabaseAuthService();
    final absenceService = MockSupabaseAbsenceService();
    when(authService.currentUser).thenReturn(null);

    await box.put(
      'user_a:abs_2026_a',
      AbsenceEntry(
        id: 'abs_2026_a',
        date: DateTime(2026, 2, 10),
        minutes: 120,
        type: AbsenceType.vacationPaid,
      ),
    );
    await box.put(
      'user_b:abs_2026_b',
      AbsenceEntry(
        id: 'abs_2026_b',
        date: DateTime(2026, 3, 3),
        minutes: 0,
        type: AbsenceType.unpaid,
      ),
    );

    final provider = AbsenceProvider(authService, absenceService);
    await provider.initHive(box);

    await provider.handleAuthUserChanged(
      previousUserId: null,
      currentUserId: 'user_a',
    );
    final userAIds = provider
        .absencesForYear(2026)
        .map((absence) => absence.id)
        .whereType<String>()
        .toList();
    expect(userAIds, ['abs_2026_a']);

    await provider.handleAuthUserChanged(
      previousUserId: 'user_a',
      currentUserId: 'user_b',
    );
    final userBIds = provider
        .absencesForYear(2026)
        .map((absence) => absence.id)
        .whereType<String>()
        .toList();
    expect(userBIds, ['abs_2026_b']);
    expect(userBIds.contains('abs_2026_a'), isFalse);
  });
}
