import 'constants.dart';

class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  static String? validateLocationName(String? value) {
    final requiredCheck = validateRequired(value, 'Location name');
    if (requiredCheck != null) return requiredCheck;
    
    if (value!.length > AppConstants.maxLocationNameLength) {
      return 'Location name must be less than ${AppConstants.maxLocationNameLength} characters';
    }
    return null;
  }
  
  static String? validateAddress(String? value) {
    final requiredCheck = validateRequired(value, 'Address');
    if (requiredCheck != null) return requiredCheck;
    
    if (value!.length > AppConstants.maxAddressLength) {
      return 'Address must be less than ${AppConstants.maxAddressLength} characters';
    }
    return null;
  }
  
  static String? validateMinutes(String? value) {
    final requiredCheck = validateRequired(value, 'Minutes');
    if (requiredCheck != null) return requiredCheck;
    
    final minutes = int.tryParse(value!);
    if (minutes == null) {
      return 'Please enter a valid number';
    }
    
    if (minutes <= 0) {
      return 'Minutes must be greater than 0';
    }
    
    if (minutes > AppConstants.maxMinutes) {
      return 'Minutes cannot exceed ${AppConstants.maxMinutes} (24 hours)';
    }
    
    return null;
  }
  
  static String? validateInfo(String? value) {
    if (value != null && value.length > AppConstants.maxInfoLength) {
      return 'Additional info must be less than ${AppConstants.maxInfoLength} characters';
    }
    return null;
  }
  
  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Please select a date';
    }
    
    final now = DateTime.now();
    final maxFutureDate = now.add(const Duration(days: 365));
    
    if (date.isAfter(maxFutureDate)) {
      return 'Date cannot be more than 1 year in the future';
    }
    
    return null;
  }
}
