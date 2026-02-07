import 'package:flutter/foundation.dart';
import 'location.dart';

/// Types of location suggestions
enum SuggestionType {
  /// A location marked as favorite
  favorite,

  /// A recently used location
  recent,

  /// A saved location (not favorite or recent)
  saved,

  /// A custom location entered by the user
  custom,
}

/// A suggestion for location autocomplete
@immutable
class AutocompleteSuggestion {
  /// The text to display as the main suggestion
  final String text;

  /// Additional text to display below the main suggestion
  final String subtitle;

  /// The type of suggestion (favorite, recent, saved, or custom)
  final SuggestionType type;

  /// The associated Location object (null for custom suggestions)
  final Location? location;

  const AutocompleteSuggestion({
    required this.text,
    required this.subtitle,
    required this.type,
    this.location,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutocompleteSuggestion &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          subtitle == other.subtitle &&
          type == other.type &&
          location == other.location;

  @override
  int get hashCode =>
      text.hashCode ^ subtitle.hashCode ^ type.hashCode ^ location.hashCode;
}
