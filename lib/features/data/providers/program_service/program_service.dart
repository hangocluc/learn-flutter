import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import 'package:learn_flutter/features/data/models/program_model/program_model.dart';

part 'program_service.g.dart';

@RestApi()
abstract class ProgramService {
  factory ProgramService(Dio dio, {String baseUrl}) = _ProgramService;

  @GET('/api/get-all-in-program')
  Future<List<ProgramModel>> getAllPrograms();
}
