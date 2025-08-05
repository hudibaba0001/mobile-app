import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/travel_entry.dart';
import '../models/work_entry.dart';
import '../models/contract_settings.dart';
import '../models/leave_entry.dart';
import '../location.dart';
import 'travel_repository.dart';
import 'hive_travel_repository.dart';
import 'work_repository.dart';
import 'contract_repository.dart';
import 'leave_repository.dart';

class RepositoryProvider {
  late final TravelRepository travelRepository;
  late final WorkRepository workRepository;
  late final ContractRepository contractRepository;
  late final LeaveRepository leaveRepository;

  static const _travelBoxName = 'travel_entries';
  static const _workBoxName = 'work_entries';
  static const _contractBoxName = 'contract_settings';
  static const _leaveBoxName = 'leave_entries';
  static const _appSettingsBoxName = 'app_settings';
  static const _locationsBoxName = 'locationsBox';

  /// Initialize all repositories
  Future<void> initialize() async {
    if (kIsWeb) {
      // For web, use Hive without path initialization
      Hive.initFlutter();
    } else {
      // For mobile platforms, use path_provider
      try {
        final appDir = await getApplicationDocumentsDirectory();
        Hive.init(appDir.path);
      } catch (e) {
        // Fallback to initFlutter if path_provider fails
        Hive.initFlutter();
      }
    }

    // Register adapters
    Hive.registerAdapter(TravelEntryAdapter());
    Hive.registerAdapter(WorkEntryAdapter());
    Hive.registerAdapter(ContractSettingsAdapter());
    Hive.registerAdapter(LeaveEntryAdapter());
    Hive.registerAdapter(LeaveTypeAdapter());
    Hive.registerAdapter(LocationAdapter());

    // Open boxes
    final travelBox = await Hive.openBox<TravelEntry>(_travelBoxName);
    final workBox = await Hive.openBox<WorkEntry>(_workBoxName);
    final contractBox = await Hive.openBox<ContractSettings>(_contractBoxName);
    final leaveBox = await Hive.openBox<LeaveEntry>(_leaveBoxName);
    final appSettingsBox = await Hive.openBox(_appSettingsBoxName);
    final locationsBox = await Hive.openBox<Location>(_locationsBoxName);

    // Initialize repositories
    travelRepository = HiveTravelRepository();
    await travelRepository.initialize();
    workRepository = WorkRepository(workBox);
    contractRepository = ContractRepository(contractBox);
    leaveRepository = LeaveRepository(leaveBox);
  }

  /// Close all repositories
  Future<void> dispose() async {
    await travelRepository.close();
    await workRepository.close();
    await contractRepository.close();
    await leaveRepository.close();
  }
}