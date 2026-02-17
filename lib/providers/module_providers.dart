import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/app_settings.dart';
import '../data/models/entry_type.dart';
import '../data/database/database_helper.dart';

// Provider for app settings
final settingsProvider = FutureProvider<AppSettings>((ref) async {
  return await DatabaseHelper.instance.getSettings();
});

// Provider for enabled modules
final moduleProvider =
    StateNotifierProvider<ModuleNotifier, Map<EntryType, bool>>((ref) {
  return ModuleNotifier(ref);
});

class ModuleNotifier extends StateNotifier<Map<EntryType, bool>> {
  final Ref ref;

  ModuleNotifier(this.ref)
      : super({
          EntryType.journal: true,
          EntryType.food: true,
          EntryType.expense: true,
          EntryType.midnightThought: true,
          EntryType.spark: true,
          EntryType.media: true,
          EntryType.dream: true,
        }) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.getSettings();
    state = {
      EntryType.journal: settings.moduleJournalEnabled,
      EntryType.food: settings.moduleFoodEnabled,
      EntryType.expense: settings.moduleExpenseEnabled,
      EntryType.midnightThought: settings.moduleMidnightThoughtEnabled,
      EntryType.spark: settings.moduleSparkEnabled,
      EntryType.media: settings.moduleMediaEnabled,
      EntryType.dream: settings.moduleDreamEnabled,
    };
  }

  Future<void> toggleModule(EntryType type, bool enabled) async {
    state = {...state, type: enabled};

    // Persist to database
    final settingKey = _getSettingKey(type);
    await DatabaseHelper.instance.updateSetting(settingKey, enabled ? 1 : 0);
  }

  String _getSettingKey(EntryType type) {
    switch (type) {
      case EntryType.journal:
        return 'moduleJournalEnabled';
      case EntryType.food:
        return 'moduleFoodEnabled';
      case EntryType.expense:
        return 'moduleExpenseEnabled';
      case EntryType.midnightThought:
        return 'moduleMidnightThoughtEnabled';
      case EntryType.spark:
        return 'moduleSparkEnabled';
      case EntryType.media:
        return 'moduleMediaEnabled';
      case EntryType.dream:
        return 'moduleDreamEnabled';
    }
  }

  bool isEnabled(EntryType type) {
    return state[type] ?? true;
  }
}

// Helper to get enabled entry types for FAB
final enabledEntryTypesProvider = Provider<List<EntryType>>((ref) {
  final modules = ref.watch(moduleProvider);
  return EntryType.values.where((type) => modules[type] == true).toList();
});
