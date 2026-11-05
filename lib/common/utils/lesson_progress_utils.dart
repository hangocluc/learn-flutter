import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences_key.dart';
import 'package:learn_flutter/core/storage/storage_manager.dart';
import 'package:learn_flutter/features/data/models/lesson_model/progress_request_model.dart';
import 'package:learn_flutter/features/data/providers/lesson_service/lesson_service.dart';

class LessonProgressUtils {
  const LessonProgressUtils._();

  static Future<String?> _resolveUserId(
    AppSharedPreferences sharedPreferences,
  ) async {
    final fromPrefs =
        sharedPreferences.getString(AppSharedPreferencesKey.userId);
    if (fromPrefs != null && fromPrefs.isNotEmpty) {
      return fromPrefs;
    }
    return StorageManager.getUserId();
  }

  /// Marks a chapter as started (not yet completed).
  static Future<void> markLessonStarted({
    required LessonService lessonService,
    required AppSharedPreferences sharedPreferences,
    required String lessonId,
  }) async {
    try {
      final userId = await _resolveUserId(sharedPreferences);
      if (userId == null || userId.isEmpty) return;

      await lessonService.updateProcess(
        ProgressRequestModel(
          userId: userId,
          lessonId: lessonId,
          status: 0,
          quizStatus: 0,
        ),
      );
    } catch (_) {}
  }

  /// Marks one topic lesson as completed after the user scrolls to the end.
  /// Returns `true` when the backend confirms the progress was saved so the
  /// caller can give feedback or retry on failure.
  static Future<bool> markTopicCompleted({
    required LessonService lessonService,
    required AppSharedPreferences sharedPreferences,
    required String lessonId,
    required String topicId,
  }) async {
    try {
      final userId = await _resolveUserId(sharedPreferences);
      if (userId == null || userId.isEmpty) return false;

      final response = await lessonService.updateProcess(
        ProgressRequestModel(
          userId: userId,
          lessonId: lessonId,
          topicId: topicId,
          status: 1,
          quizStatus: 0,
        ),
      );
      return response.isSuccessResponse;
    } catch (_) {
      return false;
    }
  }

  /// Number of distinct quizzes the user has actually taken (one per chapter).
  ///
  /// A quiz counts as done when the backend has recorded a mark for it
  /// (`quizMarked != null`). The `quizStatus` flag is unreliable here — the API
  /// returns `0`/`-1` even for chapters that already have a graded quiz — so we
  /// rely on the presence of a mark, falling back to a positive `quizStatus`
  /// for any legacy records.
  static int countCompletedQuizzes(List<dynamic> progressItems) {
    final completedChapterIds = <String>{};

    for (final raw in progressItems) {
      if (raw is! Map) continue;
      final item = Map<dynamic, dynamic>.from(raw);

      final quizMarked = item['quizMarked'] ?? item['quiz_marked'];
      final quizStatus = item['quizStatus'] ?? item['quiz_status'];
      final hasTakenQuiz = quizMarked != null || _isPositiveStatus(quizStatus);
      if (!hasTakenQuiz) continue;

      final chapterId = _extractChapterId(item);
      if (chapterId != null && chapterId.isNotEmpty) {
        completedChapterIds.add(chapterId);
      }
    }

    return completedChapterIds.length;
  }

  static String? _extractChapterId(Map<dynamic, dynamic> item) {
    final lessonId = item['lessonId'] ?? item['lesson_id'];
    if (lessonId != null && lessonId.toString().isNotEmpty) {
      return lessonId.toString();
    }

    final lesson = item['lesson'];
    if (lesson is Map) {
      final nestedId = lesson['_id'] ?? lesson['id'];
      if (nestedId != null && nestedId.toString().isNotEmpty) {
        return nestedId.toString();
      }
    }

    return null;
  }

  static bool _isPositiveStatus(dynamic value) {
    if (value == 1 || value == true) return true;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true';
    }
    return false;
  }
}
