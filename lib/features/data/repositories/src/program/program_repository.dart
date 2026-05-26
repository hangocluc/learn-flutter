import 'package:learn_flutter/features/data/entities/program_entity/program_entity.dart';
import 'package:learn_flutter/core/base/src/api_response.dart';

abstract class ProgramRepository {
  Future<ApiResponse<List<ProgramEntity>>?> getAllPrograms();
}
