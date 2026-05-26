import 'package:learn_flutter/features/data/providers/network_service/src/app_service.dart';
import 'package:learn_flutter/features/domain/repositories/repositories.dart';

import '../../../../../core/base/src/api_response.dart';
import '../../../models/models.dart';
import '../../../models/src/user_model.dart';

class AppRepositoryImpl implements AppRepository {
  final AppService appService;

  AppRepositoryImpl({required this.appService});

  @override
  Future<ApiResponse<DemoModel>?> getDemo({String? username}) async {
    try {
      final response = await appService.demo();
      if (response.isSuccessResponse) {
        return response;
      }
      throw Exception(response.message);
    } catch (error) {
      rethrow;
    }
  }

  @override
  Future<ApiResponse?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await appService.login(
        {
          'email': email,
          'password': password,
        },
      );
      if (response.isSuccessResponse) {
        return response;
      }
      throw Exception(response.message);
    } catch (error) {
      rethrow;
    }
  }

  @override
  Future<ApiResponse<UserModel>?> getOrCreateNewUser(UserModel user) async {
    try {
      final response = await appService.getOrCreateNewUser(user);
      if (response.isSuccessResponse) {
        return response;
      }
      throw Exception(response.message);
    } catch (error) {
      rethrow;
    }
  }

  @override
  Future<ApiResponse<UserModel>?> getUserInfo(String gmail) async {
    try {
      final response = await appService.getUserInfo(gmail);
      if (response.isSuccessResponse) {
        return response;
      }
      throw Exception(response.message);
    } catch (error) {
      rethrow;
    }
  }
}
