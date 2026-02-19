import '../models/entry.dart';

/// Immutable filter input used by History and Reports.
///
/// Date range is inclusive:
/// - remove only if entry.date is before [startDate]
/// - remove only if entry.date is after [endDate]
class EntryFilterSpec {
  final DateTime? startDate;
  final DateTime? endDate;
  final EntryType? selectedType;
  final String searchQuery;

  const EntryFilterSpec({
    this.startDate,
    this.endDate,
    this.selectedType,
    this.searchQuery = '',
  });

  String get normalizedSearchQuery => searchQuery.trim().toLowerCase();
  bool get hasSearchQuery => normalizedSearchQuery.isNotEmpty;
}
