// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/entry.dart';

class _LegacyWorkRecord {
  final String id;
  final DateTime date;
  final int workMinutes;
  final String remarks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  const _LegacyWorkRecord({
    required this.id,
    required this.date,
    required this.workMinutes,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });
}

class _LegacyTravelRecord {
  final String id;
  final String userId;
  final DateTime date;
  final String fromLocation;
  final String toLocation;
  final int travelMinutes;
  final String remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const _LegacyTravelRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.fromLocation,
    required this.toLocation,
    required this.travelMinutes,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });
}

class _LegacyWorkRecordAdapter extends TypeAdapter<_LegacyWorkRecord> {
  @override
  final int typeId = 2;

  @override
  _LegacyWorkRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return _LegacyWorkRecord(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      workMinutes: fields[2] as int,
      remarks: (fields[3] as String?) ?? '',
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      userId: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, _LegacyWorkRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.workMinutes)
      ..writeByte(3)
      ..write(obj.remarks)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.userId);
  }
}

class _LegacyTravelRecordAdapter extends TypeAdapter<_LegacyTravelRecord> {
  @override
  final int typeId = 1;

  @override
  _LegacyTravelRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return _LegacyTravelRecord(
      id: fields[0] as String,
      userId: fields[3] as String,
      date: fields[4] as DateTime,
      fromLocation: fields[5] as String,
      toLocation: fields[6] as String,
      travelMinutes: fields[7] as int,
      remarks: (fields[8] as String?) ?? '',
      createdAt: fields[1] as DateTime,
      updatedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, _LegacyTravelRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.fromLocation)
      ..writeByte(6)
      ..write(obj.toLocation)
      ..writeByte(7)
      ..write(obj.travelMinutes)
      ..writeByte(8)
      ..write(obj.remarks);
  }
}

class LegacyHiveMigrationService {
  static const String _entriesBoxName = 'entries_cache';
  static const String _workBoxPrefix = 'work_entries_';
  static const String _travelBoxPrefix = 'travel_entries_';
  static const String _prefsKeyPrefix = 'legacy_entries_migrated_';

  Future<void> migrateIfNeeded(String userId) async {
    if (userId.isEmpty) {
      debugPrint('LegacyHiveMigration: skipped (no user)');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final prefsKey = '$_prefsKeyPrefix$userId';
    if (prefs.getBool(prefsKey) == true) {
      debugPrint('LegacyHiveMigration: already migrated for user $userId');
      return;
    }

    _registerLegacyAdapters();

    final workBoxName = '$_workBoxPrefix$userId';
    final travelBoxName = '$_travelBoxPrefix$userId';

    final hasWorkBox = await Hive.boxExists(workBoxName);
    final hasTravelBox = await Hive.boxExists(travelBoxName);

    if (!hasWorkBox && !hasTravelBox) {
      debugPrint('LegacyHiveMigration: no legacy boxes found for $userId');
      await prefs.setBool(prefsKey, true);
      return;
    }

    Box<_LegacyWorkRecord>? workBox;
    Box<_LegacyTravelRecord>? travelBox;
    try {
      if (hasWorkBox) {
        workBox = await Hive.openBox<_LegacyWorkRecord>(workBoxName);
      }
      if (hasTravelBox) {
        travelBox = await Hive.openBox<_LegacyTravelRecord>(travelBoxName);
      }

      final entriesBox = await Hive.openBox<Entry>(_entriesBoxName);
      final existingLegacyIds = entriesBox.values
          .map((e) => e.sourceLegacyId)
          .whereType<String>()
          .toSet();

      var workRecordsRead = 0;
      var travelRecordsRead = 0;
      var atomicEntriesCreated = 0;
      var duplicatesSkipped = 0;

      final entriesToInsert = <String, Entry>{};

      if (workBox != null) {
        for (final key in workBox.keys) {
          final entry = workBox.get(key);
          if (entry == null) continue;
          workRecordsRead++;

          final legacyId = 'work:$key:0';
          if (existingLegacyIds.contains(legacyId)) {
            duplicatesSkipped++;
            continue;
          }

          final converted = _convertWorkRecord(entry, legacyId);
          entriesToInsert[converted.id] = converted;
          existingLegacyIds.add(legacyId);
          atomicEntriesCreated++;
        }
      }

      if (travelBox != null) {
        for (final key in travelBox.keys) {
          final entry = travelBox.get(key);
          if (entry == null) continue;
          travelRecordsRead++;

          final legacyId = 'travel:$key:0';
          if (existingLegacyIds.contains(legacyId)) {
            duplicatesSkipped++;
            continue;
          }

          final converted = _convertTravelRecord(entry, legacyId);
          entriesToInsert[converted.id] = converted;
          existingLegacyIds.add(legacyId);
          atomicEntriesCreated++;
        }
      }

      if (entriesToInsert.isNotEmpty) {
        await entriesBox.putAll(entriesToInsert);
      }

      debugPrint(
          'LegacyHiveMigration: work=$workRecordsRead travel=$travelRecordsRead '
          'atomic=$atomicEntriesCreated skipped=$duplicatesSkipped inserted=${entriesToInsert.length}');

      await prefs.setBool(prefsKey, true);
    } catch (e) {
      debugPrint('LegacyHiveMigration: failed with error: $e');
      rethrow;
    } finally {
      await workBox?.close();
      await travelBox?.close();
    }
  }

  void _registerLegacyAdapters() {
    if (!Hive.isAdapterRegistered(_LegacyTravelRecordAdapter().typeId)) {
      Hive.registerAdapter(_LegacyTravelRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(_LegacyWorkRecordAdapter().typeId)) {
      Hive.registerAdapter(_LegacyWorkRecordAdapter());
    }
  }

  Entry _convertWorkRecord(_LegacyWorkRecord legacy, String sourceLegacyId) {
    final normalizedDate = _dateOnlyUtc(legacy.date);
    final workMinutes = legacy.workMinutes < 0 ? 0 : legacy.workMinutes;
    final start = DateTime.utc(
      normalizedDate.year,
      normalizedDate.month,
      normalizedDate.day,
    );
    final end = start.add(Duration(minutes: workMinutes));
    final remarks = legacy.remarks.trim();

    final shift = Shift(
      start: start,
      end: end,
      unpaidBreakMinutes: 0,
      notes: remarks.isEmpty ? null : remarks,
    );

    return Entry(
      userId: legacy.userId,
      type: EntryType.work,
      date: normalizedDate,
      shifts: [shift],
      notes: remarks.isEmpty ? null : remarks,
      createdAt: legacy.createdAt.toUtc(),
      updatedAt: legacy.updatedAt.toUtc(),
      sourceLegacyId: sourceLegacyId,
    );
  }

  Entry _convertTravelRecord(
      _LegacyTravelRecord legacy, String sourceLegacyId) {
    final normalizedDate = _dateOnlyUtc(legacy.date);
    final minutes = legacy.travelMinutes < 0 ? 0 : legacy.travelMinutes;
    final remarks = legacy.remarks.trim();

    final leg = TravelLeg(
      fromText: legacy.fromLocation,
      toText: legacy.toLocation,
      minutes: minutes,
      source: 'legacy',
    );

    return Entry(
      userId: legacy.userId,
      type: EntryType.travel,
      date: normalizedDate,
      from: legacy.fromLocation,
      to: legacy.toLocation,
      travelMinutes: minutes,
      notes: remarks.isEmpty ? null : remarks,
      createdAt: legacy.createdAt.toUtc(),
      updatedAt: legacy.updatedAt.toUtc(),
      travelLegs: [leg],
      sourceLegacyId: sourceLegacyId,
    );
  }

  DateTime _dateOnlyUtc(DateTime value) {
    return DateTime.utc(value.year, value.month, value.day);
  }
}
