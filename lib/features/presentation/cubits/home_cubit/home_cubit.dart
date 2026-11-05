import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_flutter/features/domain/usecases/src/profile/profile_usecase.dart'
    as profile_uc;
import 'package:learn_flutter/features/domain/usecases/program_usecase.dart';
import 'package:learn_flutter/features/data/models/lesson_model/lesson_model.dart';
import 'package:learn_flutter/features/data/entities/program_entity/program_entity.dart';
import 'package:learn_flutter/features/data/providers/lesson_service/lesson_service.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences_key.dart';
import 'package:learn_flutter/common/utils/lesson_progress_utils.dart';
import 'package:learn_flutter/common/utils/program_progress_utils.dart';
import 'package:learn_flutter/core/storage/storage_manager.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final profile_uc.ProfileUsecase profileUsecase;
  final LessonService lessonService;
  final ProgramUsecase programUsecase;
  final AppSharedPreferences sharedPreferences;

  HomeCubit({
    required this.profileUsecase,
    required this.lessonService,
    required this.programUsecase,
    required this.sharedPreferences,
  }) : super(HomeStateInitial());

  /// Lesson catalog cached across refreshes. The total/topic ids it provides
  /// rarely change within a session, and re-fetching it is the slowest part of
  /// updating the progress count, so we reuse it once loaded.
  List<LessonModel>? _cachedCatalog;

  Future<void> loadHomeData({bool forceRefresh = false}) async {
    if (!forceRefresh && state is HomeStateSuccess) return;

    final HomeStateSuccess? previous = state is HomeStateSuccess
        ? state as HomeStateSuccess
        : null;
    if (previous == null) {
      emit(HomeStateLoading());
    }

    final userId = await _resolveUserId();

    // Start the independent network calls together so the progress count is not
    // blocked behind the profile/programs requests.
    final progressDataFuture = _loadProgressData(userId);
    final programsDataFuture = _loadProgramsData();
    final catalogFuture = _cachedCatalog != null
        ? Future<List<LessonModel>?>.value(_cachedCatalog)
        : _fetchLessonsCatalog();

    final catalog = await catalogFuture;
    if (catalog != null) _cachedCatalog = catalog;

    final totalLessons = catalog != null
        ? _countTotalTopics(catalog)
        : (previous?.totalLessons ?? 0);
    final completedLessons = await _loadCompletedLessons(
      userId,
      catalog,
      fallback: previous?.completedLessons,
    );

    // First emit: surface the fresh progress count immediately, keeping the
    // previously known program/profile values so the number updates without
    // waiting for the slower requests below.
    if (previous != null) {
      emit(HomeStateSuccess(
        completedLessons: completedLessons,
        totalLessons: totalLessons,
        exploredPrograms: previous.exploredPrograms,
        totalPrograms: previous.totalPrograms,
        userScore: previous.userScore,
        userRank: previous.userRank,
        recentActivities: previous.recentActivities,
      ));
    }

    final progressData = await progressDataFuture;
    final programsData = await programsDataFuture;

    final recentActivities =
        progressData['recentActivities'] as List<Map<String, dynamic>>?;

    // Final emit: full data once the remaining requests resolve.
    emit(HomeStateSuccess(
      completedLessons: completedLessons,
      totalLessons: totalLessons,
      exploredPrograms:
          programsData['exploredPrograms'] ?? previous?.exploredPrograms ?? 0,
      totalPrograms:
          programsData['totalPrograms'] ?? previous?.totalPrograms ?? 0,
      userScore: (progressData['userScore'] as double?) ??
          previous?.userScore ??
          0.0,
      userRank:
          (progressData['userRank'] as int?) ?? previous?.userRank ?? 0,
      recentActivities: recentActivities?.isNotEmpty == true
          ? recentActivities!
          : (previous?.recentActivities ?? []),
    ));
  }

  Future<String?> _resolveUserId() async {
    final fromPrefs =
        sharedPreferences.getString(AppSharedPreferencesKey.userId);
    if (fromPrefs != null && fromPrefs.isNotEmpty) {
      return fromPrefs;
    }
    return StorageManager.getUserId();
  }

  Future<List<LessonModel>?> _fetchLessonsCatalog() async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await lessonService
            .getAllLessons()
            .timeout(const Duration(seconds: 15));

        if (response.isSuccessResponse && response.data != null) {
          return response.data!;
        }
      } catch (e) {
        print('HomeCubit: fetch lessons attempt ${attempt + 1} error: $e');
      }

      if (attempt == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }

    return null;
  }

  /// Each API "lesson" is a chapter; count every topic inside as one lesson unit.
  int _countTotalTopics(List<LessonModel> chapters) {
    return chapters.fold<int>(0, (sum, chapter) {
      if (chapter.topics.isNotEmpty) {
        return sum + chapter.topics.length;
      }
      return sum + chapter.totalTopic;
    });
  }

  Set<String> _catalogTopicIds(List<LessonModel> chapters) {
    return chapters
        .expand((chapter) => chapter.topics)
        .map((topic) => topic.sId)
        .where((id) => id != null && id.isNotEmpty)
        .map((id) => id!)
        .toSet();
  }

  /// Counts how many catalog topics the user has finished. The backend stores
  /// each chapter's finished topics inside a `completed` array (one progress
  /// document per chapter), so we union every completed topic id across all
  /// documents and intersect it with the catalog.
  int _countCompletedTopics(
    List<LessonModel> chapters,
    List<dynamic> progressItems,
  ) {
    final completedTopicIds = <String>{};
    final catalogTopicIds = _catalogTopicIds(chapters);

    for (final raw in progressItems) {
      if (raw is! Map) continue;
      final item = Map<dynamic, dynamic>.from(raw);

      for (final topicId in _extractCompletedTopicIds(item)) {
        if (catalogTopicIds.contains(topicId)) {
          completedTopicIds.add(topicId);
        }
      }
    }

    return completedTopicIds.length;
  }

  Future<int> _loadCompletedLessons(
    String? userId,
    List<LessonModel>? catalog, {
    int? fallback,
  }) async {
    if (userId == null || userId.isEmpty) return fallback ?? 0;
    if (catalog == null || catalog.isEmpty) return fallback ?? 0;

    try {
      final response = await lessonService
          .getAllProgress(userId)
          .timeout(const Duration(seconds: 15));

      if (!response.isSuccessResponse || response.data == null) {
        return fallback ?? 0;
      }

      return _countCompletedTopics(catalog, response.data!);
    } catch (e) {
      print('HomeCubit: Completed lessons error: $e');
      return fallback ?? 0;
    }
  }

  /// Topic ids a progress document marks as completed. The backend returns
  /// `completed` as an array of ids (e.g. `["<topicId>"]`), but older records
  /// may use a single string or a populated `{_id: ...}` object, so we
  /// normalize all of those shapes here.
  Iterable<String> _extractCompletedTopicIds(Map<dynamic, dynamic> item) {
    return _normalizeIds(
      item['completed'] ?? item['topicId'] ?? item['topic_id'],
    );
  }

  Iterable<String> _normalizeIds(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.expand(_normalizeIds);
    }
    if (raw is Map) {
      final id = raw['_id'] ?? raw['id'];
      return id == null ? const [] : [id.toString()];
    }
    final value = raw.toString().trim();
    return value.isEmpty ? const [] : [value];
  }

  Future<Map<String, dynamic>> _loadProgressData(String? userId) async {
    double userScore = 0.0;
    int userRank = 0;
    int completedQuizzes = 0;
    List<Map<String, dynamic>> recentActivities = [];

    if (userId != null && userId.isNotEmpty) {
      try {
        final progressResponse = await lessonService
            .getAllProgress(userId)
            .timeout(const Duration(seconds: 15));

        if (progressResponse.isSuccessResponse &&
            progressResponse.data != null) {
          completedQuizzes = LessonProgressUtils.countCompletedQuizzes(
            progressResponse.data!,
          );
        }
      } catch (e) {
        print('HomeCubit: Completed quizzes error: $e');
      }

      // Load profile scores independently so a rank error doesn't zero out score
      try {
        final profileResult = await profileUsecase
            .call(userId)
            .timeout(const Duration(seconds: 5));

        profileResult.fold(
          (exception) {
            print('HomeCubit: Profile data error: $exception');
          },
          (data) {
            userScore = data.fold<double>(0.0, (sum, profile) {
              return sum + profile.mark;
            });
            print('HomeCubit: Profile data - userScore: $userScore');
          },
        );
      } catch (e) {
        print('HomeCubit: Profile score error: $e');
      }

      // Load rank separately — failure here should not affect score display
      try {
        final rankResult = await profileUsecase
            .getProfileRank()
            .timeout(const Duration(seconds: 5));

        rankResult.fold(
          (exception) {
            print('HomeCubit: Rank data error: $exception');
          },
          (data) {
            final userRankAndScore = _findUserRankAndScore(data, userId);
            userRank = userRankAndScore['rank'] as int;
          },
        );
      } catch (e) {
        print('HomeCubit: Rank error: $e');
      }

      if (userScore > 0 || completedQuizzes > 0) {
        recentActivities = [
          {
            'title': 'Total Score: ${userScore.toStringAsFixed(0)} points',
            'time': _quizActivityLabel(completedQuizzes),
            'icon': Icons.star,
            'color': Colors.orange,
          }
        ];
      }
    }

    return {
      'userScore': userScore,
      'userRank': userRank,
      'recentActivities': recentActivities,
    };
  }

  String _quizActivityLabel(int count) {
    if (count == 0) return 'No quizzes completed yet';
    if (count == 1) return '1 quiz completed';
    return '$count quizzes completed';
  }

  Future<Map<String, dynamic>> _loadProgramsData() async {
    try {
      final response = await programUsecase
          .getAllPrograms()
          .timeout(const Duration(seconds: 15));
      if (response?.isSuccessResponse == true && response?.data != null) {
        final programs = response!.data!;
        return {
          'totalPrograms': _countTotalProgramExamples(programs),
          'exploredPrograms': ProgramProgressUtils.countExplored(
            sharedPreferences,
          ),
        };
      }
      print('HomeCubit: Programs data error: ${response?.message}');
      return {'totalPrograms': 0, 'exploredPrograms': 0};
    } catch (e) {
      print('HomeCubit: Programs data timeout/error: $e');
      return {'totalPrograms': 0, 'exploredPrograms': 0};
    }
  }

  /// Each API program is a group; count every example inside (programDetail).
  int _countTotalProgramExamples(List<ProgramEntity> programs) {
    return programs.fold<int>(0, (sum, program) {
      final details = program.programDetails;
      if (details != null && details.isNotEmpty) {
        return sum + details.length;
      }
      return sum;
    });
  }

  Map<String, dynamic> _findUserRankAndScore(
      List<dynamic> rankUsers, String userId) {
    for (int i = 0; i < rankUsers.length; i++) {
      final user = rankUsers[i];
      if (user.toString().contains(userId) ||
          (user is Map && user['userId'] == userId) ||
          (user is Map && user['id'] == userId)) {
        return {
          'rank': i + 1,
          'score': user is Map ? (user['score'] ?? 0.0) : 0.0,
        };
      }
    }
    return {'rank': 0, 'score': 0.0};
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown time';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  void refreshData() {
    loadHomeData(forceRefresh: true);
  }
}
