import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_flutter/common/utils/lesson_progress_utils.dart';
import 'package:learn_flutter/features/data/providers/lesson_service/lesson_service.dart';
import '../../../domain/entities/src/profile/profile_entity.dart';
import '../../../domain/entities/src/profile/rank_user_entity.dart';
import '../../../domain/usecases/src/profile/profile_usecase.dart'
    as profile_uc;
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final profile_uc.ProfileUsecase usecase;
  final LessonService lessonService;

  ProfileCubit({
    required this.usecase,
    required this.lessonService,
  }) : super(ProfileStateInitial());

  Future<void> loadProfileData(
    String userId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && state is ProfileStateSuccess) return;

    final ProfileStateSuccess? previous = state is ProfileStateSuccess
        ? state as ProfileStateSuccess
        : null;
    if (previous == null) {
      emit(ProfileStateLoading());
    }

    try {
      final completedQuizzesFuture = _loadCompletedQuizzes(userId);
      final results = await Future.wait([
        usecase.call(userId),
        usecase.getProfileRank(),
      ]);
      final completedQuizzes = await completedQuizzesFuture;

      final profileResult = results[0];
      final rankResult = results[1];

      List<ProfileEntity> profileScores = [];
      List<RankUserEntity> rankUsers = [];
      int userRank = 0;
      double userScore = 0.0;
      var hasProfileData = false;
      var hasRankData = false;

      profileResult.fold(
        (exception) {
          if (previous == null) {
            emit(ProfileStateFailure(message: exception.toString()));
          }
        },
        (data) {
          hasProfileData = true;
          profileScores = (data as List<ProfileEntity>)
              .reversed
              .toList(); // Reverse to show latest first
        },
      );

      if (!hasProfileData) {
        if (previous != null) emit(previous);
        return;
      }

      rankResult.fold(
        (exception) {
          if (previous == null) {
            emit(ProfileStateFailure(message: exception.toString()));
          }
        },
        (data) {
          hasRankData = true;
          rankUsers = data as List<RankUserEntity>;
          final userRankAndScore = _findUserRankAndScore(rankUsers, userId);
          userRank = userRankAndScore['rank'] as int;
          userScore = userRankAndScore['score'] as double;
        },
      );

      if (!hasRankData) {
        if (previous != null) emit(previous);
        return;
      }

      emit(ProfileStateSuccess(
        profileScores: profileScores,
        rankUsers: rankUsers,
        userRank: userRank,
        userScore: userScore,
        completedQuizzes: completedQuizzes,
      ));
    } catch (e) {
      log('ProfileCubit error: $e');
      if (previous != null) {
        emit(previous);
        return;
      }
      emit(ProfileStateFailure(message: 'Error loading profile data: $e'));
    }
  }

  Future<int> _loadCompletedQuizzes(String userId) async {
    try {
      final response = await lessonService
          .getAllProgress(userId)
          .timeout(const Duration(seconds: 15));

      if (!response.isSuccessResponse || response.data == null) {
        return 0;
      }

      return LessonProgressUtils.countCompletedQuizzes(response.data!);
    } catch (e) {
      log('ProfileCubit: completed quizzes error: $e');
      return 0;
    }
  }

  Map<String, dynamic> _findUserRankAndScore(
      List<RankUserEntity> rankUsers, String userId) {
    for (int i = 0; i < rankUsers.length; i++) {
      if (rankUsers[i].id == userId) {
        return {
          'rank': i + 1,
          'score': rankUsers[i].mark,
        };
      }
    }
    return {'rank': 0, 'score': 0.0};
  }

  Future<void> refreshData(String userId) async {
    await loadProfileData(userId, forceRefresh: true);
  }
}
