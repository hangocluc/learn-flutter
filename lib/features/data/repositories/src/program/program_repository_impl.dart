import 'package:learn_flutter/features/data/entities/program_entity/program_entity.dart';
import 'package:learn_flutter/features/data/models/program_model/program_model.dart';
import 'package:learn_flutter/core/base/src/api_response.dart';
import 'package:learn_flutter/features/data/providers/program_service/program_service.dart';
import 'package:learn_flutter/features/data/repositories/src/program/program_repository.dart';

class ProgramRepositoryImpl implements ProgramRepository {
  final ProgramService service;

  ProgramRepositoryImpl({required this.service});

  @override
  Future<ApiResponse<List<ProgramEntity>>?> getAllPrograms() async {
    try {
      final response = await service.getAllPrograms();

      if (response.isNotEmpty) {
        final entities =
            response.map((model) => _mapProgramModelToEntity(model)).toList();
        return ApiResponse(entities, 200, 'Success', true);
      } else {
        return ApiResponse([], 200, 'No programs found', true);
      }
    } catch (error) {
      return ApiResponse(null, 500, error.toString(), false);
    }
  }

  ProgramEntity _mapProgramModelToEntity(ProgramModel model) {
    return ProgramEntity(
      id: model.id,
      name: model.name,
      image: model.image,
      programDetails: model.programDetails
          ?.map((detail) => _mapProgramDetailModelToEntity(detail))
          .toList(),
    );
  }

  ProgramDetailEntity _mapProgramDetailModelToEntity(ProgramDetailModel model) {
    return ProgramDetailEntity(
      id: model.id,
      programId: model.programId,
      title: model.title,
      content: model.content,
      videoUrl: model.videoUrl,
    );
  }
}
