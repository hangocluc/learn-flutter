import '../app_shared_preferences/app_shared_preferences.dart';
import '../app_shared_preferences/app_shared_preferences_key.dart';

class ProgramProgressUtils {
  const ProgramProgressUtils._();

  static Future<void> markExplored(
    AppSharedPreferences prefs,
    String? detailId,
  ) async {
    if (detailId == null || detailId.isEmpty) return;

    final current =
        prefs.getStringList(AppSharedPreferencesKey.exploredProgramDetailIds) ??
            [];
    if (current.contains(detailId)) return;

    await prefs.setStringList(
      AppSharedPreferencesKey.exploredProgramDetailIds,
      [...current, detailId],
    );
  }

  static int countExplored(AppSharedPreferences prefs) {
    return prefs
            .getStringList(AppSharedPreferencesKey.exploredProgramDetailIds)
            ?.length ??
        0;
  }
}
