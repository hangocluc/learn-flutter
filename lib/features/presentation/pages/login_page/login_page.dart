import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learn_flutter/main.dart';
import '../../../../core/storage/storage_manager.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences.dart';
import 'package:learn_flutter/common/app_shared_preferences/app_shared_preferences_key.dart';
import '../../../app/routes/src/routes_name.dart';
import '../../../data/models/src/user_model.dart';
import '../../../data/firebase_service/fcm_messaging_service.dart';
import '../../../domain/usecases/src/demo_usecase.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final cubit = getIt.get<DemoUsecase>();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account != null) {
        debugPrint('User signed in: ${account.displayName}, ${account.email}');
        setState(() {
          _isLoading = true;
        });

        final fcmToken = await getIt<FcmMessagingService>().getToken();
        debugPrint('FCM token for BE: $fcmToken');

        final user = UserModel(
          gmail: account.email,
          username: account.displayName,
          imageUrl: account.photoUrl?.toString(),
          tokenDevice: fcmToken ?? 'aa',
        );

        try {
          final result = await cubit.getOrCreateNewUser(user);
          result.fold(
            (error) {
              // Xử lý lỗi
              debugPrint("Login error: $error");
              setState(() {
                _isLoading = false;
              });
            },
            (data) async {
              // Save user data to storage (only when valid)
              final userId = data?.id;
              if (userId != null && userId.isNotEmpty) {
                StorageManager.saveUserId(userId);
                StorageManager.saveUserName(data?.username ?? '');
                StorageManager.saveUserEmail(data?.gmail ?? account.email);
                StorageManager.saveUserImage(data?.imageUrl ?? '');

                // Also persist to AppSharedPreferences for quiz/progress flow
                try {
                  final prefs = getIt.get<AppSharedPreferences>();
                  await prefs.setString(AppSharedPreferencesKey.userId, userId);
                } catch (e) {
                  debugPrint(
                      'Persist userId to AppSharedPreferences failed: $e');
                }
              } else {
                debugPrint(
                    'Login returned empty/invalid userId; skipping persist');
              }

              // Login thành công, navigate đến MainPage
              Navigator.of(context).pushNamedAndRemoveUntil(
                RouteName.main,
                (route) => false,
              );
            },
          );
        } catch (error) {
          debugPrint("Login error: $error");
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        debugPrint("User canceled login");
      }
    } catch (error) {
      // Even if Google Sign In fails, navigate to main page
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteName.main,
        (route) => false,
      );
      debugPrint("Login error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo hoặc icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFF667eea),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Tiêu đề
                  const Text(
                    'Chào mừng!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mô tả
                  const Text(
                    'Đăng nhập để tiếp tục sử dụng ứng dụng',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

                  // Nút đăng nhập Google
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: _isLoading ? null : _handleGoogleSignIn,
                        child: _isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF667eea),
                                    ),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Icon Google
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          'https://developers.google.com/identity/images/g-logo.png',
                                        ),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Đăng nhập với Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Thông tin bổ sung
                  const Text(
                    'Bằng cách đăng nhập, bạn đồng ý với\nĐiều khoản sử dụng và Chính sách bảo mật',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
