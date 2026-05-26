import 'package:get_it/get_it.dart';
import 'package:learn_flutter/features/domain/usecases/program_usecase.dart';
import 'package:learn_flutter/features/domain/usecases/src/lesson_usecase.dart';
import 'package:learn_flutter/features/domain/usecases/src/chat/chat_usecase.dart';
import '../../domain/usecases/usecase.dart';
import '../../domain/usecases/src/profile/profile_usecase.dart' as profile_uc;

Future<void> registerUseCaseDI(GetIt sl) async {
  sl.registerFactory<DemoUsecase>(
    () => DemoUsecase(repository: sl.get()),
  );

  sl.registerFactory<profile_uc.ProfileUsecase>(
    () => profile_uc.ProfileUsecase(repository: sl.get()),
  );

  sl.registerFactory<ProgramUsecase>(
    () => ProgramUsecase(repository: sl.get()),
  );

  sl.registerFactory<LessonUseCase>(
    () => LessonUseCase(repository: sl.get()),
  );

  sl.registerFactory<ChatUsecase>(
    () => ChatUsecase(repository: sl.get()),
  );
}
