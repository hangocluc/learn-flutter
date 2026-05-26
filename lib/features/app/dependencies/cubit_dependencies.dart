import 'package:get_it/get_it.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences.dart';

import '../../presentation/cubits/demo_cubit/demo_cubit.dart';
import '../../presentation/cubits/profile_cubit/profile_cubit.dart';
import '../../presentation/cubits/lesson_cubit/lesson_cubit.dart';
import '../../presentation/cubits/quiz_cubit/quiz_cubit.dart';
import '../../presentation/cubits/chat_cubit/chat_cubit.dart';
import '../../presentation/cubits/program_cubit/program_cubit.dart';
import '../../presentation/cubits/home_cubit/home_cubit.dart';
import '../../domain/usecases/src/profile/profile_usecase.dart' as profile_uc;
import '../../domain/usecases/src/lesson_usecase.dart';
import '../../domain/usecases/program_usecase.dart';
import '../../data/providers/lesson_service/lesson_service.dart';

Future<void> registerCubitDI(GetIt sl) async {
  sl.registerLazySingleton(
    () => DemoCubit(usecase: sl.get(), sharedPreferences: sl.get()),
  );

  sl.registerLazySingleton(
    () => ProfileCubit(usecase: sl.get<profile_uc.ProfileUsecase>()),
  );

  sl.registerFactory<LessonCubit>(
    () => LessonCubit(useCase: sl.get<LessonUseCase>()),
  );

  sl.registerFactory<QuizCubit>(
    () => QuizCubit(
      lessonService: sl.get<LessonService>(),
      sharedPreferences: sl.get<AppSharedPreferences>(),
    ),
  );

  sl.registerFactory<ChatCubit>(
    () => ChatCubit(
      chatUsecase: sl.get(),
      sharedPreferences: sl.get<AppSharedPreferences>(),
    ),
  );

  sl.registerFactory<ProgramCubit>(
    () => ProgramCubit(programUsecase: sl.get<ProgramUsecase>()),
  );

  sl.registerFactory<HomeCubit>(
    () => HomeCubit(
      profileUsecase: sl.get<profile_uc.ProfileUsecase>(),
      lessonUsecase: sl.get<LessonUseCase>(),
      programUsecase: sl.get<ProgramUsecase>(),
      sharedPreferences: sl.get<AppSharedPreferences>(),
    ),
  );
}
