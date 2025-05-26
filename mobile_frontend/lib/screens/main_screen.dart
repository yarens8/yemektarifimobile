import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'categories_screen.dart';
import 'profile_screen.dart';
import 'ingredient_suggestion_screen.dart';
import 'ai_chat_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Offset _fabOffset = const Offset(0, 0);

  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoriesScreen(),
    IngredientSuggestionScreen(),
    const ProfileScreen(),
  ];

  void _openChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.92,
        child: AIChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.pink,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Ana Sayfa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.category),
                label: 'Kategoriler',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu),
                label: 'Malzemeler',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
        Positioned(
          right: 24 + _fabOffset.dx,
          bottom: 24 + _fabOffset.dy,
          child: Draggable(
            feedback: _buildFab(),
            childWhenDragging: const SizedBox.shrink(),
            onDragEnd: (details) {
              final screenSize = MediaQuery.of(context).size;
              final fabSize = 56.0; // Varsayılan FloatingActionButton boyutu
              final margin = 24.0;

              double newDx = details.offset.dx - margin;
              double newDy = details.offset.dy - margin;

              // Sınırları kontrol et
              if (newDx < 0) newDx = 0;
              if (newDy < 0) newDy = 0;
              if (newDx > screenSize.width - fabSize - margin) newDx = screenSize.width - fabSize - margin;
              if (newDy > screenSize.height - fabSize - margin - 80) newDy = screenSize.height - fabSize - margin - 80;

              setState(() {
                _fabOffset = Offset(newDx, newDy);
              });
            },
            child: _buildFab(),
          ),
        ),
      ],
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      heroTag: 'aiChatFab',
      backgroundColor: Colors.transparent,
      onPressed: _openChat,
      elevation: 6,
      shape: const CircleBorder(),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFFF80AB), Color(0xFFFFB6D5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.smart_toy, size: 32, color: Colors.white),
      ),
    );
  }
}
