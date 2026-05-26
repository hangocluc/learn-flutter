import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:learn_flutter/features/data/services/compiler_service.dart';

part 'compiler_cubit_state.dart';

class CompilerCubit extends Cubit<CompilerCubitState> {
  final CompilerService compilerService;

  CompilerCubit({required this.compilerService})
      : super(CompilerCubitInitial());

  Future<void> compileAndRun(String javaCode) async {
    emit(CompilerCubitCompiling());

    try {
      final result = await compilerService.compileAndRun(javaCode);

      if (result.success) {
        emit(CompilerCubitSuccess(
          output: result.output!,
          executionTime: result.executionTime,
        ));
      } else {
        emit(CompilerCubitError(error: result.error!));
      }
    } catch (e) {
      emit(CompilerCubitError(error: e.toString()));
    }
  }

  Future<void> formatCode(String javaCode) async {
    emit(CompilerCubitFormatting());

    try {
      final formattedCode = await compilerService.formatCode(javaCode);

      if (formattedCode != null) {
        emit(CompilerCubitFormatted(formattedCode: formattedCode));
      } else {
        emit(CompilerCubitError(error: 'Failed to format code'));
      }
    } catch (e) {
      emit(CompilerCubitError(error: e.toString()));
    }
  }

  Future<void> validateSyntax(String javaCode) async {
    try {
      final result = await compilerService.validateSyntax(javaCode);

      if (result.isValid) {
        emit(CompilerCubitValid());
      } else {
        emit(CompilerCubitValidationError(errors: result.errors));
      }
    } catch (e) {
      emit(CompilerCubitError(error: e.toString()));
    }
  }

  void reset() {
    emit(CompilerCubitInitial());
  }
}
