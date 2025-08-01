import 'package:flutter/foundation.dart';
import '../models/admin_user.dart';
import '../services/admin_api_service.dart';

class AdminUsersViewModel extends ChangeNotifier {
  final AdminApiService _adminApiService;
  
  List<AdminUser>? _users;
  String? _searchQuery;
  String _filterRole = 'All';
  String? _error;
  bool _isLoading = false;

  AdminUsersViewModel(this._adminApiService);

  List<AdminUser>? get users => _users;
  String? get error => _error;
  bool get isLoading => _isLoading;
  String get filterRole => _filterRole;
  String? get searchQuery => _searchQuery;

  void setSearchQuery(String? query) {
    _searchQuery = query?.isEmpty == true ? null : query;
    notifyListeners();
  }

  void setFilterRole(String role) {
    _filterRole = role;
    notifyListeners();
  }

  List<AdminUser> get filteredUsers {
    if (_users == null) return [];
    
    var filteredUsers = _users!;

    // Apply role filter
    if (_filterRole != 'All') {
      filteredUsers = filteredUsers.where((user) {
        // TODO: Implement role-based filtering once roles are added to the model
        return true;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filteredUsers = filteredUsers.where((user) {
        final searchString = [
          user.displayName,
          user.email,
          user.uid,
        ].whereType<String>().join(' ').toLowerCase();
        return searchString.contains(query);
      }).toList();
    }

    return filteredUsers;
  }

  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _adminApiService.fetchUsers();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> disableUser(AdminUser user) async {
    try {
      await _adminApiService.disableUser(user.uid);
      await fetchUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> enableUser(AdminUser user) async {
    try {
      await _adminApiService.enableUser(user.uid);
      await fetchUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(AdminUser user) async {
    try {
      await _adminApiService.deleteUser(user.uid);
      await fetchUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}