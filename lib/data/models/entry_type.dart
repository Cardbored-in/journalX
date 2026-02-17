/// Enum representing different types of entries in the timeline
enum EntryType {
  journal,
  food,
  expense,
  midnightThought,
  spark,
  media,
  dream,
}

/// Extension to provide display names and icons for entry types
extension EntryTypeExtension on EntryType {
  String get displayName {
    switch (this) {
      case EntryType.journal:
        return 'Journal';
      case EntryType.food:
        return 'Food';
      case EntryType.expense:
        return 'Expense';
      case EntryType.midnightThought:
        return 'Midnight Thought';
      case EntryType.spark:
        return 'Spark';
      case EntryType.media:
        return 'Media';
      case EntryType.dream:
        return 'Dream';
    }
  }

  String get icon {
    switch (this) {
      case EntryType.journal:
        return '📝';
      case EntryType.food:
        return '🍽️';
      case EntryType.expense:
        return '💰';
      case EntryType.midnightThought:
        return '🌙';
      case EntryType.spark:
        return '💡';
      case EntryType.media:
        return '🎬';
      case EntryType.dream:
        return '😴';
    }
  }

  String get description {
    switch (this) {
      case EntryType.journal:
        return 'Daily thoughts and reflections';
      case EntryType.food:
        return 'Log your meals';
      case EntryType.expense:
        return 'Track your spending';
      case EntryType.midnightThought:
        return 'Late night ideas and thoughts';
      case EntryType.spark:
        return 'Quick ideas and inspiration';
      case EntryType.media:
        return 'Movies, books, and media';
      case EntryType.dream:
        return 'Record your dreams';
    }
  }
}
