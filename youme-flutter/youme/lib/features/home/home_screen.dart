import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/wood_bottom_nav.dart';
import '../../core/widgets/tropical_background.dart';
import '../../core/router/app_router.dart';
import '../chats/conversation_list/conversation_list_screen.dart';
import '../contacts/contacts/contacts_screen.dart';
import '../ai/search/ai_search_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _pageTransition;

  static const _pages = [
    ConversationListScreen(),
    ContactsScreen(),
    AiSearchScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageTransition = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pageTransition.forward();
  }

  @override
  void dispose() {
    _pageTransition.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    _pageTransition.reverse().then((_) {
      setState(() => _currentIndex = index);
      _pageTransition.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: TropicalBackground(
        child: FadeTransition(
          opacity: _pageTransition,
          child: IndexedStack(index: _currentIndex, children: _pages),
        ),
      ),
      bottomNavigationBar: WoodBottomNav(currentIndex: _currentIndex, onTap: _onNavTap),
    );
  }
}
