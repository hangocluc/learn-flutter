import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/base/base.dart';
import '../../../../core/base/src/base_usecase.dart';
import '../../../domain/usecases/src/lesson_usecase.dart';
import 'lesson_state.dart';

class LessonCubit extends Cubit<LessonState> {
  final LessonUseCase useCase;
  LessonCubit({required this.useCase}) : super(LessonStateInitial());

  Future<void> loadLessons({bool forceRefresh = false}) async {
    if (!forceRefresh && state is LessonStateSuccess) return;
    emit(LessonStateLoading());
    final result = await useCase.call(NoParams());
    result.fold(
      (e) => emit(LessonStateFailure(e.toString())),
      (data) => emit(LessonStateSuccess(data)),
    );
  }
}
