import 'package:hive/hive.dart';
import '../models/contract_settings.dart';

abstract class ContractRepository {
  ContractSettings? getSettings();
  Future<void> saveSettings(ContractSettings settings);
  Future<void> close();
}

class HiveContractRepository implements ContractRepository {
  final Box<ContractSettings> _box;

  HiveContractRepository(this._box);

  @override
  ContractSettings? getSettings() {
    try {
      return _box.get('settings');
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveSettings(ContractSettings settings) async {
    await _box.put('settings', settings);
  }

  Future<void> close() async {
    await _box.close();
  }
}