import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/home_cubit/home_cubit.dart';
import '../../cubits/home_cubit/home_state.dart';

class HomePage extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const HomePage({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeStateLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is HomeStateFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<HomeCubit>().refreshData(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => context.read<HomeCubit>().refreshData(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _HeroHeader(onNavigateToTab: onNavigateToTab, state: state)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(child: _ProgressStrip(onNavigateToTab: onNavigateToTab, state: state)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    sliver: SliverToBoxAdapter(child: _QuickActions(onNavigateToTab: onNavigateToTab)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    sliver: SliverToBoxAdapter(child: _RecentActivity(state: state)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    sliver: SliverToBoxAdapter(child: _FeaturedCarousel(state: state)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.onNavigateToTab, required this.state});

  final Function(int)? onNavigateToTab;
  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = state;
    final completedLessons = s is HomeStateSuccess ? s.completedLessons : 0;
    final totalLessons = s is HomeStateSuccess ? s.totalLessons : 0;
    final progress = totalLessons <= 0
        ? 0.0
        : (completedLessons / totalLessons).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary,
              scheme.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.flutter_dash, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Flutter Lab',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ship beautiful UIs. Learn fast. Build confidently.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.92),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.22),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        totalLessons <= 0
                            ? '0%'
                            : '${(progress * 100).round()}%',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _HeroPill(
                        icon: Icons.play_arrow_rounded,
                        label: 'Continue',
                        onTap: () => onNavigateToTab?.call(1),
                      ),
                      _HeroPill(
                        icon: Icons.widgets_rounded,
                        label: 'Programs',
                        onTap: () => onNavigateToTab?.call(2),
                      ),
                      _HeroPill(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        onTap: () => onNavigateToTab?.call(3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.20),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.onNavigateToTab, required this.state});

  final Function(int)? onNavigateToTab;
  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final completedLessons = s is HomeStateSuccess ? s.completedLessons : 0;
    final totalLessons = s is HomeStateSuccess ? s.totalLessons : 0;
    final exploredPrograms = s is HomeStateSuccess ? s.exploredPrograms : 0;
    final totalPrograms = s is HomeStateSuccess ? s.totalPrograms : 0;
    final userScore = s is HomeStateSuccess ? s.userScore : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => onNavigateToTab?.call(1),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _StatChip(
                title: 'Lessons',
                value: '$completedLessons/$totalLessons',
                icon: Icons.menu_book_rounded,
                tint: const Color(0xFF22C55E),
                onTap: () => onNavigateToTab?.call(1),
              ),
              const SizedBox(width: 12),
              _StatChip(
                title: 'Programs',
                value: '$exploredPrograms/$totalPrograms',
                icon: Icons.widgets_rounded,
                tint: const Color(0xFF0EA5E9),
                onTap: () => onNavigateToTab?.call(2),
              ),
              const SizedBox(width: 12),
              _StatChip(
                title: 'Score',
                value: userScore.toStringAsFixed(0),
                icon: Icons.local_fire_department_rounded,
                tint: const Color(0xFFF97316),
                onTap: () => onNavigateToTab?.call(3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.title,
    required this.value,
    required this.icon,
    required this.tint,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tint.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: tint, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNavigateToTab});

  final Function(int)? onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ActionTile(
              title: 'Start learning',
              subtitle: 'Continue your lessons',
              icon: Icons.play_arrow_rounded,
              tint: const Color(0xFF22C55E),
              onTap: () => onNavigateToTab?.call(1),
            ),
            _ActionTile(
              title: 'Programs',
              subtitle: 'Explore examples',
              icon: Icons.widgets_rounded,
              tint: const Color(0xFF0EA5E9),
              onTap: () => onNavigateToTab?.call(2),
            ),
            _ActionTile(
              title: 'Quiz',
              subtitle: 'Test your skills',
              icon: Icons.quiz_rounded,
              tint: const Color(0xFFF97316),
              onTap: () => onNavigateToTab?.call(1),
            ),
            _ActionTile(
              title: 'Profile',
              subtitle: 'Track your score',
              icon: Icons.person_rounded,
              tint: const Color(0xFFEC4899),
              onTap: () => onNavigateToTab?.call(3),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tint.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> activities = [];
    final s = state;
    if (s is HomeStateSuccess) {
      activities = s.recentActivities;
    }
    if (activities.isEmpty) {
      activities = [
        {
          'title': 'No recent activity yet',
          'time': 'Start learning to unlock your timeline',
          'icon': Icons.bolt_rounded,
          'color': const Color(0xFF0EA5E9),
        }
      ];
    }

    final surface = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.7),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < activities.length; i++) ...[
                _ActivityRow(
                  title: activities[i]['title'] as String,
                  time: activities[i]['time'] as String,
                  icon: activities[i]['icon'] as IconData,
                  tint: activities[i]['color'] as Color,
                ),
                if (i < activities.length - 1) const Divider(height: 18),
              ]
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.title,
    required this.time,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String time;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tint.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: tint, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _FeaturedCarousel extends StatelessWidget {
  const _FeaturedCarousel({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final items = <_FeaturedItem>[
      const _FeaturedItem(
        title: 'Flutter Basics',
        subtitle: 'Widgets, build(), hot reload',
        icon: Icons.school_rounded,
        tint: Color(0xFF0EA5E9),
      ),
      const _FeaturedItem(
        title: 'Layouts that pop',
        subtitle: 'Row/Column, Flex, constraints',
        icon: Icons.dashboard_customize_rounded,
        tint: Color(0xFF22C55E),
      ),
      const _FeaturedItem(
        title: 'State management',
        subtitle: 'BLoC patterns for real apps',
        icon: Icons.hub_rounded,
        tint: Color(0xFFEC4899),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _FeaturedCard(item: items[index]),
          ),
        ),
      ],
    );
  }
}

class _FeaturedItem {
  const _FeaturedItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item});

  final _FeaturedItem item;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item.tint.withOpacity(0.16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.tint.withOpacity(0.10),
            surface,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: item.tint.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: item.tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
