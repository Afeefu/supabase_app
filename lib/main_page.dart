import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_app/categories_screen.dart';
import 'package:supabase_app/profile_screen.dart';
import 'package:supabase_app/shopping_page.dart';
import 'package:supabase_app/wish_list_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final List<Widget> _pages = const [
    ShoppingPage(key: PageStorageKey('home')),
    CategoriesScreen(key: PageStorageKey('categories')),
    WishlistScreen(key: PageStorageKey('wish')),
    ProfileScreen(key: PageStorageKey('profile')),
  ];
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home'.tr,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories'.tr,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Wish'.tr,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile'.tr,
          ),
        ],
      ),
    );
  }
}
