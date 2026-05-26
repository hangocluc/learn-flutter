import 'package:get_it/get_it.dart';
import 'package:learn_flutter/features/data/repositories/src/program/program_repository_impl.dart';
import 'package:learn_flutter/features/data/repositories/src/program/program_repository.dart';
import 'package:learn_flutter/features/data/repositories/src/lesson/lesson_repository_impl.dart';
import 'package:learn_flutter/features/domain/repositories/src/lesson/lesson_repository.dart';
import 'package:learn_flutter/features/data/repositories/src/chat/chat_repository_impl.dart';
import 'package:learn_flutter/features/domain/repositories/src/chat/chat_repository.dart';

import '../../data/repositories/src/demo/app_repository_impl.dart';
import '../../data/repositories/src/profile/profile_repository_impl.dart';
import '../../domain/repositories/src/app_repository.dart';
import '../../domain/repositories/src/profile/profile_repository.dart';

Future<void> registerRepositoryDI(GetIt sl) async {
  sl.registerFactory<AppRepository>(
    () => AppRepositoryImpl(appService: sl.get()),
  );

  sl.registerFactory<ProfileRepository>(
    () => ProfileRepositoryImpl(service: sl.get()),
  );

  sl.registerFactory<ProgramRepository>(
    () => ProgramRepositoryImpl(service: sl.get()),
  );

  sl.registerFactory<LessonRepository>(
    () => LessonRepositoryImpl(lessonService: sl.get()),
  );

  sl.registerFactory<ChatRepository>(
    () => ChatRepositoryImpl(chatService: sl.get()),
  );
}
