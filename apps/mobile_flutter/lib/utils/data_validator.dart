/// Simple data validation utilities
class DataValidator {
  /// Validate date range
  static List<String> validateDateRange(DateTime startDate, DateTime endDate) {
    final errors = <String>[];

    if (startDate.isAfter(endDate)) {
      errors.add('Start date cannot be after end date');
    }

    if (startDate.isAfter(DateTime.now())) {
      errors.add('Start date cannot be in the future');
    }

    return errors;
  }

  /// Validate filename
  static List<String> validateFileName(String fileName) {
    final errors = <String>[];

    if (fileName.isEmpty) {
      errors.add('Filename cannot be empty');
    }

    if (fileName.contains('/') || fileName.contains('\\')) {
      errors.add('Filename cannot contain path separators');
    }

    return errors;
  }
}
