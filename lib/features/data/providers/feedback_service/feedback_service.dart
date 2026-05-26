// ignore: depend_on_referenced_packages
import 'package:dio/dio.dart';
// ignore: depend_on_referenced_packages
import 'package:retrofit/retrofit.dart';

import '../../../../core/base/src/api_response.dart';
import '../../models/feedback/system_feedback_request_model.dart';
import '../../models/lesson_model/lesson_feedback_request_model.dart';
import '../network_service/src/api_path.dart';

part 'feedback_service.g.dart';

@RestApi()
abstract class FeedbackService {
  factory FeedbackService(Dio dio, {String baseUrl}) = _FeedbackService;

  @POST(FeedbackApiPath.insertLessonFeedback)
  Future<ApiResponse<dynamic>> insertLessonFeedback(
    @Body() LessonFeedbackRequestModel body,
  );

  @POST(FeedbackApiPath.insertSystemFeedback)
  Future<ApiResponse<dynamic>> insertSystemFeedback(
    @Body() SystemFeedbackRequestModel body,
  );
}
