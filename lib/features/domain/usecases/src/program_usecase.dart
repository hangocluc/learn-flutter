import 'package:dartz/dartz.dart';
import 'package:learn_flutter/features/domain/entities/src/program/program_detail.dart';
import 'package:learn_flutter/features/domain/entities/src/program/program_model.dart';
import 'package:learn_flutter/features/domain/repositories/src/program/program_repository.dart';

class ProgramUsecase {
  final ProgramRepository repository;

  ProgramUsecase({required this.repository});

  Future<Either<Exception, List<ProgramModel>>> getProgram() async {
    try {
      final response = await repository.getPrograms();
      return Right(response);
    } on Exception catch (error) {
      return Left(error);
    }
  }

  Future<Either<Exception, List<ProgramDetail>>> getProgramDetail(
      String programId) async {
    try {
      final response = await repository.getProgramDetail(programId);
      return Right(response);
    } on Exception catch (error) {
      return Left(error);
    }
  }
}
