import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_java/features/domain/usecases/src/profile/profile_usecase.dart'
    as profile_uc;
import 'package:learn_java/features/domain/usecases/src/lesson_usecase.dart';
import 'package:learn_java/features/domain/usecases/program_usecase.dart';
import 'package:learn_java/features/domain/entities/src/profile/profile_entity.dart';
import 'package:learn_java/common/app_shared_preferences/app_shared_preferences.dart';
import 'package:learn_java/common/app_shared_preferences/app_shared_preferences_key.dart';
import 'package:learn_java/core/storage/storage_manager.dart';
import '../../../../core/base/src/base_usecase.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final profile_uc.ProfileUsecase profileUsecase;
  final LessonUseCase lessonUsecase;
  final ProgramUsecase programUsecase;
  final AppSharedPreferences sharedPreferences;

  HomeCubit({
    required this.profileUsecase,
    required this.lessonUsecase,
    required this.programUsecase,
    required this.sharedPreferences,
  }) : super(HomeStateInitial());

  Future<void> loadHomeData() async {
    try {
      emit(HomeStateLoading());

      // Get user ID
      String? userId =
          sharedPreferences.get(AppSharedPreferencesKey.userId) as String?;
      if (userId == null || userId.isEmpty) {
        userId = await StorageManager.getUserId();
      }

      if (userId == null || userId.isEmpty) {
        // Use fallback userId
        userId = "680a567eb6e0b313a2ca092b";
        print('HomeCubit: Using fallback userId: $userId');
      }

      // Load data with timeout and fallback
      try {
        final results = await Future.wait([
          _loadProgressData(userId),
          _loadLessonsData(),
          _loadProgramsData(),
        ]).timeout(const Duration(seconds: 10));

        final progressData = results[0];
        final lessonsData = results[1];
        final programsData = results[2];

        emit(HomeStateSuccess(
          completedLessons: progressData['completedLessons'] ?? 0,
          totalLessons: lessonsData['totalLessons'] ?? 0,
          exploredPrograms: programsData['exploredPrograms'] ?? 0,
          totalPrograms: programsData['totalPrograms'] ?? 0,
          userScore: progressData['userScore'] ?? 0.0,
          userRank: progressData['userRank'] ?? 0,
          recentActivities: progressData['recentActivities'] ?? [],
        ));
      } catch (timeoutError) {
        // Show default data on timeout
        print('HomeCubit: API timeout, showing default data');
        emit(HomeStateSuccess(
          completedLessons: 0,
          totalLessons: 0,
          exploredPrograms: 0,
          totalPrograms: 0,
          userScore: 0.0,
          userRank: 0,
          recentActivities: [],
        ));
      }
    } catch (e) {
      // Show default data on any error
      print('HomeCubit: Error loading data: $e');
      emit(HomeStateSuccess(
        completedLessons: 0,
        totalLessons: 0,
        exploredPrograms: 0,
        totalPrograms: 0,
        userScore: 0.0,
        userRank: 0,
        recentActivities: [],
      ));
    }
  }

  Future<Map<String, dynamic>> _loadProgressData(String userId) async {
    try {
      // Load profile scores and rank data with timeout
      final results = await Future.wait([
        profileUsecase.call(userId),
        profileUsecase.getProfileRank(),
      ]).timeout(const Duration(seconds: 5));

      final profileResult = results[0];
      final rankResult = results[1];

      int completedLessons = 0;
      double userScore = 0.0;
      int userRank = 0;
      List<Map<String, dynamic>> recentActivities = [];

      // Count completed lessons and calculate total score from profile scores
      profileResult.fold(
        (exception) {
          print('HomeCubit: Profile data error: $exception');
        },
        (data) {
          completedLessons = data.length;
          // Calculate total score from all profile scores
          userScore = data.fold<double>(0.0, (sum, profile) {
            final p = profile as ProfileEntity;
            return sum + p.mark;
          });
          print(
              'HomeCubit: Profile data - completedLessons: $completedLessons, userScore: $userScore');
          // Create recent activities - show total progress
          if (data.isNotEmpty) {
            recentActivities = [
              {
                'title': 'Total Score: ${userScore.toStringAsFixed(0)} points',
                'time': '${completedLessons} lessons completed',
                'icon': Icons.star,
                'color': Colors.orange,
              }
            ];
          }
        },
      );

      // Get user rank
      rankResult.fold(
        (exception) {
          print('HomeCubit: Rank data error: $exception');
        },
        (data) {
          final userRankAndScore = _findUserRankAndScore(data, userId);
          userRank = userRankAndScore['rank'] as int;
        },
      );

      return {
        'completedLessons': completedLessons,
        'userScore': userScore,
        'userRank': userRank,
        'recentActivities': recentActivities,
      };
    } catch (e) {
      print('HomeCubit: Progress data error: $e');
      return {
        'completedLessons': 0,
        'userScore': 0.0,
        'userRank': 0,
        'recentActivities': [],
      };
    }
  }

  Future<Map<String, dynamic>> _loadLessonsData() async {
    try {
      final response = await lessonUsecase
          .call(NoParams())
          .timeout(const Duration(seconds: 5));
      return response.fold(
        (exception) {
          print('HomeCubit: Lessons data error: $exception');
          return {'totalLessons': 0};
        },
        (data) => {'totalLessons': data.length},
      );
    } catch (e) {
      print('HomeCubit: Lessons data timeout/error: $e');
      return {'totalLessons': 0};
    }
  }

  Future<Map<String, dynamic>> _loadProgramsData() async {
    try {
      final response = await programUsecase
          .getAllPrograms()
          .timeout(const Duration(seconds: 5));
      if (response?.isSuccessResponse == true && response?.data != null) {
        return {
          'totalPrograms': response!.data!.length,
          'exploredPrograms': response
              .data!.length, // For now, assume all programs are explored
        };
      }
      print('HomeCubit: Programs data error: ${response?.message}');
      return {'totalPrograms': 0, 'exploredPrograms': 0};
    } catch (e) {
      print('HomeCubit: Programs data timeout/error: $e');
      return {'totalPrograms': 0, 'exploredPrograms': 0};
    }
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
    loadHomeData();
  }
}
