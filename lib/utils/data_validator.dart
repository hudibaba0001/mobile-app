import '../models/travel_time_entry.dart';
import '../models/location.dart';
import 'error_handler.dart';

class DataValidator {
  // Validate TravelTimeEntry
  static List<AppError> validateTravelEntry(TravelTimeEntry entry) {
    final errors = <AppError>[];

    // Validate date
    if (entry.date.isAfter(DateTime.now().add(const Duration(days: 365)))) {
      errors.add(ErrorHandler.handleValidationError(
        'Travel date cannot be more than 1 year in the future'
      ));
    }

    // Validate departure
    if (entry.departure.trim().isEmpty) {
      errors.add(ErrorHandler.handleValidationError(
        'Departure location is required'
      ));
    } else if (entry.departure.length > 200) {
      errors.add(ErrorHandler.handleValidationError(
        'Departure location must be less than 200 characters'
      ));
    }

    // Validate arrival
    if (entry.arrival.trim().isEmpty) {
      errors.add(ErrorHandler.handleValidationError(
        'Arrival location is required'
      ));
    } else if (entry.arrival.length > 200) {
      errors.add(ErrorHandler.handleValidationError(
        'Arrival location must be less than 200 characters'
      ));
    }

    // Validate minutes
    if (entry.minutes <= 0) {
      errors.add(ErrorHandler.handleValidationError(
        'Travel time must be greater than 0 minutes'
      ));
    } else if (entry.minutes > 1440) { // 24 hours
      errors.add(ErrorHandler.handleValidationError(
        'Travel time cannot exceed 24 hours (1440 minutes)'
      ));
    }

    // Validate info (optional field)
    if (entry.info != null && entry.info!.length > 500) {
      errors.add(ErrorHandler.handleValidationError(
        'Additional information must be less than 500 characters'
      ));
    }

    // Validate same departure and arrival
    if (entry.departure.trim().toLowerCase() == entry.arrival.trim().toLowerCase()) {
      errors.add(ErrorHandler.handleValidationError(
        'Departure and arrival locations cannot be the same'
      ));
    }

    return errors;
  }

  // Validate Location
  static List<AppError> validateLocation(Location location) {
    final errors = <AppError>[];

    // Validate name
    if (location.name.trim().isEmpty) {
      errors.add(ErrorHandler.handleValidationError(
        'Location name is required'
      ));
    } else if (location.name.length > 100) {
      errors.add(ErrorHandler.handleValidationError(
        'Location name must be less than 100 characters'
      ));
    }

    // Validate address
    if (location.address.trim().isEmpty) {
      errors.add(ErrorHandler.handleValidationError(
        'Location address is required'
      ));
    } else if (location.address.length > 200) {
      errors.add(ErrorHandler.handleValidationError(
        'Location address must be less than 200 characters'
      ));
    }

    // Validate usage count
    if (location.usageCount < 0) {
      errors.add(ErrorHandler.handleValidationError(
        'Usage count cannot be negative'
      ));
    }

    return errors;
  }

  // Validate date range
  static List<AppError> validateDateRange(DateTime? startDate, DateTime? endDate) {
    final errors = <AppError>[];

    if (startDate == null) {
      errors.add(ErrorHandler.handleValidationError('Start date is required'));
    }

    if (endDate == null) {
      errors.add(ErrorHandler.handleValidationError('End date is required'));
    }

    if (startDate != null && endDate != null) {
      if (startDate.isAfter(endDate)) {
        errors.add(ErrorHandler.handleValidationError(
          'Start date cannot be after end date'
        ));
      }

      final daysDifference = endDate.difference(startDate).inDays;
      if (daysDifference > 365) {
        errors.add(ErrorHandler.handleValidationError(
          'Date range cannot exceed 1 year'
        ));
      }
    }

    return errors;
  }

  // Validate search query
  static List<AppError> validateSearchQuery(String query) {
    final errors = <AppError>[];

    if (query.length > 100) {
      errors.add(ErrorHandler.handleValidationError(
        'Search query must be less than 100 characters'
      ));
    }

    // Check for potentially harmful characters (basic sanitization)
    final dangerousChars = RegExp(r'[<>"&]');
    if (dangerousChars.hasMatch(query)) {
      errors.add(ErrorHandler.handleValidationError(
        'Search query contains invalid characters'
      ));
    }

    return errors;
  }

  // Validate export parameters
  static List<AppError> validateExportParameters({
    required DateTime startDate,
    required DateTime endDate,
    required List<TravelTimeEntry> entries,
  }) {
    final errors = <AppError>[];

    // Validate date range
    errors.addAll(validateDateRange(startDate, endDate));

    // Validate entries
    if (entries.isEmpty) {
      errors.add(ErrorHandler.handleValidationError(
        'No travel entries found for the selected date range'
      ));
    }

    // Check for reasonable export size
    if (entries.length > 10000) {
      errors.add(ErrorHandler.handleValidationError(
        'Export size too large. Please select a smaller date range.'
      ));
    }

    return errors;
  }

  // Sanitize string input
  static String sanitizeString(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .replaceAll(RegExp(r'[<>"&]'), ''); // Remove potentially harmful characters
  }

  // Check if string is safe for storage
  static bool isSafeString(String input) {
    final dangerousChars = RegExp(r'[<>"&]');
    return !dangerousChars.hasMatch(input);
  }

  // Validate file name for export
  static List<AppError> validateFileName(String fileName) {
    final errors = <AppError>[];

    if (fileName.trim().isEmpty) {
      errors.add(ErrorHandler.handleValidationError('File name is required'));
    }

    if (fileName.length > 100) {
      errors.add(ErrorHandler.handleValidationError(
        'File name must be less than 100 characters'
      ));
    }

    // Check for invalid file name characters
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(fileName)) {
      errors.add(ErrorHandler.handleValidationError(
        'File name contains invalid characters'
      ));
    }

    return errors;
  }
}