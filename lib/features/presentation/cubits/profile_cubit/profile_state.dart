import '../../../domain/entities/src/profile/profile_entity.dart';
import '../../../domain/entities/src/profile/rank_user_entity.dart';

sealed class ProfileState {}

class ProfileStateInitial extends ProfileState {}

class ProfileStateLoading extends ProfileState {}

class ProfileStateSuccess extends ProfileState {
  final List<ProfileEntity> profileScores;
  final List<RankUserEntity> rankUsers;
  final int userRank;
  final double userScore;
  final int completedQuizzes;

  ProfileStateSuccess({
    required this.profileScores,
    required this.rankUsers,
    required this.userRank,
    required this.userScore,
    required this.completedQuizzes,
  });
}

class ProfileStateFailure extends ProfileState {
  final String message;

  ProfileStateFailure({required this.message});
}
