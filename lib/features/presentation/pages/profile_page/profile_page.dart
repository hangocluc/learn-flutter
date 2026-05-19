import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:learn_java/main.dart';
import 'package:learn_java/common/app_shared_preferences/app_shared_preferences.dart';
import 'package:learn_java/common/app_shared_preferences/app_shared_preferences_key.dart';
import 'package:learn_java/features/presentation/pages/login_page/login_page.dart';
import '../../cubits/profile_cubit/profile_cubit.dart';
import '../../cubits/profile_cubit/profile_state.dart';
import '../../../../common/widget/app_loading_overlay/app_loading_overlay.dart';
import '../../../../common/widget/app_toast/app_toast.dart';
import '../../mapper/profile_mapper.dart';
import '../../widgets/profile_chart/profile_chart_widget.dart';
import '../../widgets/profile_stats/profile_stats_widget.dart';
import '../../widgets/profile_ranking/profile_ranking_widget.dart';
import '../../../data/providers/google_signin_service.dart';
import '../../../../core/storage/storage_manager.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _displayName;
  String? _email;
  String? _photoUrl;
  final cubit = getIt.get<ProfileCubit>();
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserInfo();
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    final storedUserId = await StorageManager.getUserId();
    debugPrint('StorageManager.getUserId (init) -> $storedUserId');
    final String userId = storedUserId ?? "619e1c95b4dcb2278ffc7222";
    debugPrint('ProfilePage using userId (init) -> $userId');
    if (!mounted) return;
    cubit.loadProfileData(userId);
  }

  Future<void> _loadUserInfo() async {
    final info = await GoogleSignInService.getUserInfo();
    if (!mounted) return;
    setState(() {
      _displayName = info?['displayName'] as String?;
      _email = info?['email'] as String?;
      _photoUrl = info?['photoUrl'] as String?;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              try {
                // Sign out Google
                await GoogleSignInService.signOut();
              } catch (_) {}

              // Clear local storages
              try {
                await StorageManager.clearUserData();
              } catch (_) {}
              try {
                final prefs = getIt.get<AppSharedPreferences>();
                await prefs.remove(AppSharedPreferencesKey.userId);
              } catch (_) {}

              if (!mounted) return;
              // Navigate to LoginPage to allow choosing another account
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              final storedUserId = await StorageManager.getUserId();
              debugPrint(
                  'StorageManager.getUserId (appBar refresh) -> $storedUserId');
              final String userId = storedUserId ?? "619e1c95b4dcb2278ffc7222";
              debugPrint(
                  'ProfilePage using userId (appBar refresh) -> $userId');
              if (!mounted) return;
              cubit.refreshData(userId);
            },
          ),
        ],
      ),
      body: BlocListener<ProfileCubit, ProfileState>(
        listener: _listener,
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileStateLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is ProfileStateFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading profile data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadProfileData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is ProfileStateSuccess) {
              return RefreshIndicator(
                onRefresh: () async {
                  final storedUserId = await StorageManager.getUserId();
                  debugPrint(
                      'StorageManager.getUserId (pull-to-refresh) -> $storedUserId');
                  final String userId =
                      storedUserId ?? "619e1c95b4dcb2278ffc7222";
                  debugPrint(
                      'ProfilePage using userId (pull-to-refresh) -> $userId');
                  await context.read<ProfileCubit>().refreshData(userId);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 16),
                      ProfileStatsWidget(
                        userRank: state.userRank,
                        userScore: state.userScore,
                        testCount: state.profileScores.length,
                      ),
                      const SizedBox(height: 16),
                      _buildChartSection(state),
                      const SizedBox(height: 16),
                      ProfileRankingWidget(
                        rankUsers: ProfileMapper.mapRankUserEntitiesToUI(
                            state.rankUsers),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            }

            return const Center(
              child: Text('No data available'),
            );
          },
        ),
      ),
    );
  }

  void _listener(BuildContext context, ProfileState state) {
    switch (state) {
      case ProfileStateInitial():
      case ProfileStateLoading():
        showLoadingOverlay(context);
        break;
      case ProfileStateFailure():
        dismissLoadingOverlay(context);
        showToastError(context, state.message);
        break;
      case ProfileStateSuccess():
        dismissLoadingOverlay(context);
        break;
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[600]!,
            Colors.blue[800]!,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: _photoUrl ?? '',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _displayName ?? 'Flutter Lab User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _email ?? 'user@flutterlab.dev',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(ProfileStateSuccess state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: Colors.blue[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Score History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ProfileChartWidget(
            profiles: ProfileMapper.mapProfileEntitiesToUI(state.profileScores),
          ),
        ],
      ),
    );
  }
}
