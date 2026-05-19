import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../chat_gpt_page/chat_gpt_page.dart';
import '../home_page/home_page.dart';
import '../lesson_page/lesson_page.dart';
import '../program_page/program_page.dart';
import '../profile_page/profile_page.dart';
import '../../cubits/home_cubit/home_cubit.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
        BlocProvider(
          create: (context) => GetIt.instance<HomeCubit>()..loadHomeData(),
          child: HomePage(onNavigateToTab: navigateToTab),
        ),
        const LessonsPage(),
        const ProgramPage(),
        const ProfilePage(),
        const ChatGptPage(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).navigationBarTheme.backgroundColor ??
                scheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: scheme.primary.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: 'Lesson',
                ),
                NavigationDestination(
                  icon: Icon(Icons.widgets_outlined),
                  selectedIcon: Icon(Icons.widgets_rounded),
                  label: 'Program',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'ChatGPT',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
