import 'package:learn_flutter/features/data/entities/program_entity/program_entity.dart';
import 'package:learn_flutter/core/base/src/api_response.dart';
import 'package:learn_flutter/features/data/repositories/src/program/program_repository.dart';

class ProgramUsecase {
  final ProgramRepository repository;

  ProgramUsecase({required this.repository});

  Future<ApiResponse<List<ProgramEntity>>?> getAllPrograms() async {
    return await repository.getAllPrograms();
  }
}
