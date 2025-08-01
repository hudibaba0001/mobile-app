import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/contract_settings.dart';

class ContractRepository {
  final Box<ContractSettings> _box;
  final _uuid = const Uuid();

  ContractRepository(this._box);

  /// Get current contract settings for a user
  ContractSettings? getCurrentForUser(String userId) {
    final now = DateTime.now();
    final settings = _box.values
        .where((settings) =>
            settings.userId == userId &&
            settings.effectiveFrom.isBefore(now) &&
            (settings.effectiveTo == null || settings.effectiveTo!.isAfter(now)))
        .toList();
    settings.sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));
    return settings.isNotEmpty ? settings.first : null;
  }

  /// Get contract settings for a user at a specific date
  ContractSettings? getForUserAtDate(String userId, DateTime date) {
    final settings = _box.values
        .where((settings) =>
            settings.userId == userId &&
            settings.effectiveFrom.isBefore(date) &&
            (settings.effectiveTo == null || settings.effectiveTo!.isAfter(date)))
        .toList();
    settings.sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));
    return settings.isNotEmpty ? settings.first : null;
  }

  /// Get all contract settings for a user
  List<ContractSettings> getAllForUser(String userId) {
    return _box.values
        .where((settings) => settings.userId == userId)
        .toList()
      ..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));
  }

  /// Add new contract settings
  Future<ContractSettings> add(ContractSettings settings) async {
    final newSettings = settings.copyWith(id: _uuid.v4());
    await _box.put(newSettings.id, newSettings);
    return newSettings;
  }

  /// Update existing contract settings
  Future<ContractSettings> update(ContractSettings settings) async {
    final updatedSettings = settings.copyWith(
      updatedAt: DateTime.now(),
    );
    await _box.put(settings.id, updatedSettings);
    return updatedSettings;
  }

  /// Delete contract settings
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Close the Hive box
  Future<void> close() async {
    await _box.close();
  }
}