import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/travel_entry.dart';
import '../models/work_entry.dart';
import '../models/contract_settings.dart';
import '../models/leave_entry.dart';
import 'travel_repository.dart';
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

  /// Initialize all repositories
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init(appDir.path);

    // Register adapters
    Hive.registerAdapter(TravelEntryAdapter());
    Hive.registerAdapter(WorkEntryAdapter());
    Hive.registerAdapter(ContractSettingsAdapter());
    Hive.registerAdapter(LeaveEntryAdapter());
    Hive.registerAdapter(LeaveTypeAdapter());

    // Open boxes
    final travelBox = await Hive.openBox<TravelEntry>(_travelBoxName);
    final workBox = await Hive.openBox<WorkEntry>(_workBoxName);
    final contractBox = await Hive.openBox<ContractSettings>(_contractBoxName);
    final leaveBox = await Hive.openBox<LeaveEntry>(_leaveBoxName);

    // Initialize repositories
    travelRepository = TravelRepository(travelBox);
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