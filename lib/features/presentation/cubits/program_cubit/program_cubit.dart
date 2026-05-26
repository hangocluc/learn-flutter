import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_flutter/features/data/entities/program_entity/program_entity.dart';
import 'package:learn_flutter/features/domain/usecases/program_usecase.dart';

part 'program_cubit_state.dart';

class ProgramCubit extends Cubit<ProgramCubitState> {
  final ProgramUsecase programUsecase;

  ProgramCubit({required this.programUsecase}) : super(ProgramCubitInitial());

  Future<void> loadPrograms() async {
    emit(ProgramCubitLoading());

    try {
      final response = await programUsecase.getAllPrograms();

      if (response?.isSuccessResponse == true && response?.data != null) {
        emit(ProgramCubitLoaded(programs: response!.data!));
      } else {
        emit(ProgramCubitError(
            message: response?.message ?? 'Failed to load programs'));
      }
    } catch (e) {
      emit(ProgramCubitError(message: e.toString()));
    }
  }

  void refreshData() {
    loadPrograms();
  }
}
