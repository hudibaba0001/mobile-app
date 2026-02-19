import '../models/entry.dart';
import 'entry_filter_spec.dart';

/// Pure entry filtering helper used by History/Reports paths.
class EntryFilter {
  static List<Entry> filterEntries(List<Entry> entries, EntryFilterSpec spec) {
    return entries.where((entry) => matchesEntry(entry, spec)).toList();
  }

  static bool matchesEntry(Entry entry, EntryFilterSpec spec) {
    // Type filter
    if (spec.selectedType != null && entry.type != spec.selectedType) {
      return false;
    }

    // Date range filter (inclusive boundaries)
    if (spec.startDate != null && entry.date.isBefore(spec.startDate!)) {
      return false;
    }
    if (spec.endDate != null && entry.date.isAfter(spec.endDate!)) {
      return false;
    }

    // Search filter (kept identical to History behavior)
    if (spec.hasSearchQuery) {
      final query = spec.normalizedSearchQuery;
      final matchesNotes = entry.notes?.toLowerCase().contains(query) == true;
      final matchesTravelRoute = entry.type == EntryType.travel &&
          ((entry.from?.toLowerCase().contains(query) == true) ||
              (entry.to?.toLowerCase().contains(query) == true));

      if (!matchesNotes && !matchesTravelRoute) {
        return false;
      }
    }

    return true;
  }
}

/// Legacy convenience wrapper used by older call sites.
///
/// Prefer `EntryFilter.filterEntries(entries, spec)` for new code.
List<Entry> filterEntries(
  List<Entry> entries,
  DateTime? startDate,
  DateTime? endDate,
  EntryType? selectedType, {
  String searchQuery = '',
}) {
  return EntryFilter.filterEntries(
    entries,
    EntryFilterSpec(
      startDate: startDate,
      endDate: endDate,
      selectedType: selectedType,
      searchQuery: searchQuery,
    ),
  );
}
