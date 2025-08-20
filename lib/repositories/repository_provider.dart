import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import '../models/travel_entry.dart';
import '../models/work_entry.dart';
import '../models/contract_settings.dart';
import '../models/leave_entry.dart';
import '../models/location.dart';
import 'travel_repository.dart';
import 'hive_travel_repository.dart';
import 'work_repository.dart';
import 'contract_repository.dart';
import 'leave_repository.dart';
import 'hive_location_repository.dart';

class RepositoryProvider {
  TravelRepository? _travelRepository;
  WorkRepository? _workRepository;
  ContractRepository? _contractRepository;
  LeaveRepository? _leaveRepository;
  HiveLocationRepository? _locationRepository;

  // Getters for repositories
  TravelRepository? get travelRepository => _travelRepository;
  WorkRepository? get workRepository => _workRepository;
  ContractRepository? get contractRepository => _contractRepository;
  LeaveRepository? get leaveRepository => _leaveRepository;
  HiveLocationRepository? get locationRepository => _locationRepository;

  String? _currentUserId;
  Box<TravelEntry>? _travelBox;
  Box<WorkEntry>? _workBox;
  Box<ContractSettings>? _contractBox;
  Box<LeaveEntry>? _leaveBox;
  Box? _appSettingsBox;
  Box<Location>? _locationBox;
  bool _isInitializing = false;

  // Get user-specific box names
  String _getTravelBoxName(String userId) => 'travel_entries_$userId';
  String _getWorkBoxName(String userId) => 'work_entries_$userId';
  String _getContractBoxName(String userId) => 'contract_settings_$userId';
  String _getLeaveBoxName(String userId) => 'leave_entries_$userId';
  String _getAppSettingsBoxName(String userId) => 'app_settings_$userId';
  String _getLocationBoxName(String userId) => '${AppConstants.locationsBox}_$userId';

  /// Initialize all repositories for a specific user
  Future<void> initialize(String userId) async {
    debugPrint('RepositoryProvider.initialize() called with userId: $userId');
    
    if (_currentUserId == userId && _travelBox != null) {
      debugPrint('RepositoryProvider.initialize() - Already initialized for this user, skipping');
      // Already initialized for this user
      return;
    }

    _isInitializing = true; // Set flag

    try {
      // Close existing boxes if switching users
      await dispose();
    } catch (e) {
      debugPrint('RepositoryProvider: Error during dispose: $e');
    }

    _currentUserId = userId;

    if (kIsWeb) {
      // For web, use Hive without path initialization
    } else {
      // For mobile, initialize Hive with app documents directory
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);
    }

    // Register adapters
    Hive.registerAdapter(TravelEntryAdapter());
    Hive.registerAdapter(WorkEntryAdapter());
    Hive.registerAdapter(ContractSettingsAdapter());
    Hive.registerAdapter(LeaveEntryAdapter());
    Hive.registerAdapter(LocationAdapter());

    // Open user-specific boxes
    _travelBox = await Hive.openBox<TravelEntry>(_getTravelBoxName(userId));
    _workBox = await Hive.openBox<WorkEntry>(_getWorkBoxName(userId));
    _contractBox = await Hive.openBox<ContractSettings>(_getContractBoxName(userId));
    _leaveBox = await Hive.openBox<LeaveEntry>(_getLeaveBoxName(userId));
    _appSettingsBox = await Hive.openBox(_getAppSettingsBoxName(userId));
    _locationBox = await Hive.openBox<Location>(_getLocationBoxName(userId));

    // Initialize repositories (assign to private fields)
    _travelRepository = HiveTravelRepository(_travelBox!);
    await _travelRepository!.initialize();
    _workRepository = WorkRepository(_workBox!);
    _contractRepository = HiveContractRepository(_contractBox!);
    _leaveRepository = LeaveRepository(_leaveBox!);
    _locationRepository = HiveLocationRepository(_locationBox!);

    _isInitializing = false; // Reset flag
    debugPrint('RepositoryProvider.initialize() - Completed successfully for user: $userId');
  }

  /// Close all repositories and boxes
  Future<void> dispose() async {
    debugPrint('RepositoryProvider.dispose() called');
    debugPrint('RepositoryProvider.dispose() - _isInitializing: $_isInitializing');
    debugPrint('RepositoryProvider.dispose() - _currentUserId: $_currentUserId');
    
    // Don't dispose during initialization
    if (_isInitializing) {
      debugPrint('RepositoryProvider: Skipping dispose during initialization');
      return;
    }

    // Only dispose if we actually have repositories to dispose
    if (_currentUserId == null) {
      debugPrint('RepositoryProvider: No current user, nothing to dispose');
      return;
    }

    try {
      debugPrint('RepositoryProvider.dispose() - Closing repositories...');
      // Close repositories if they exist
      if (_travelRepository != null) {
        await _travelRepository!.close();
        debugPrint('RepositoryProvider.dispose() - TravelRepository closed');
      }
      if (_workRepository != null) {
        await _workRepository!.close();
        debugPrint('RepositoryProvider.dispose() - WorkRepository closed');
      }
      if (_contractRepository != null) {
        await _contractRepository!.close();
        debugPrint('RepositoryProvider.dispose() - ContractRepository closed');
      }
      if (_leaveRepository != null) {
        await _leaveRepository!.close();
        debugPrint('RepositoryProvider.dispose() - LeaveRepository closed');
      }
      debugPrint('RepositoryProvider.dispose() - Repositories closed successfully');
    } catch (e) {
      debugPrint('RepositoryProvider: Error closing repositories: $e');
    }

    try {
      debugPrint('RepositoryProvider.dispose() - Closing Hive boxes...');
      // Close all Hive boxes
      if (_travelBox != null && _travelBox!.isOpen) {
        await _travelBox!.close();
        debugPrint('RepositoryProvider.dispose() - TravelBox closed');
      }
      if (_workBox != null && _workBox!.isOpen) {
        await _workBox!.close();
        debugPrint('RepositoryProvider.dispose() - WorkBox closed');
      }
      if (_contractBox != null && _contractBox!.isOpen) {
        await _contractBox!.close();
        debugPrint('RepositoryProvider.dispose() - ContractBox closed');
      }
      if (_leaveBox != null && _leaveBox!.isOpen) {
        await _leaveBox!.close();
        debugPrint('RepositoryProvider.dispose() - LeaveBox closed');
      }
      if (_appSettingsBox != null && _appSettingsBox!.isOpen) {
        await _appSettingsBox!.close();
        debugPrint('RepositoryProvider.dispose() - AppSettingsBox closed');
      }
      if (_locationBox != null && _locationBox!.isOpen) {
        await _locationBox!.close();
        debugPrint('RepositoryProvider.dispose() - LocationBox closed');
      }
      debugPrint('RepositoryProvider.dispose() - Hive boxes closed successfully');
    } catch (e) {
      debugPrint('RepositoryProvider: Error closing Hive boxes: $e');
    }

    // Clear references
    debugPrint('RepositoryProvider.dispose() - Clearing references...');
    _travelRepository = null;
    _workRepository = null;
    _contractRepository = null;
    _leaveRepository = null;
    _locationRepository = null;
    _travelBox = null;
    _workBox = null;
    _contractBox = null;
    _leaveBox = null;
    _appSettingsBox = null;
    _locationBox = null;
    _currentUserId = null;
    debugPrint('RepositoryProvider.dispose() - Completed successfully');
  }

  /// Get the current user ID
  String? get currentUserId => _currentUserId;
}
