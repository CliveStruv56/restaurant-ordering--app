import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'menu/menu_screen.dart';
import 'cart/cart_screen.dart';
import 'profile/profile_screen.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';

class MainScreen extends StatefulWidget {
  final String? initialTab;
  
  const MainScreen({super.key, this.initialTab});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final CartService _cartService = CartService();
  final UserService _userService = UserService();
  int _cartItemCount = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    
    // Set initial tab based on parameter
    if (widget.initialTab != null) {
      switch (widget.initialTab) {
        case 'menu':
          _currentIndex = 1;
          break;
        case 'cart':
          _currentIndex = 2;
          break;
        case 'profile':
          _currentIndex = 3;
          break;
        default:
          _currentIndex = 0;
      }
    }
    
    _loadCartItemCount();
    // Listen for cart changes
    _cartService.getCartItems().then((items) {
      // This will trigger a rebuild when cart changes
    });
    // Delay admin check to ensure user is fully loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkAdminStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCartItemCount();
  }

  // Refresh cart count periodically
  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadCartItemCount();
  }

  Future<void> _loadCartItemCount() async {
    try {
      final count = await _cartService.getCartItemCount();
      setState(() {
        _cartItemCount = count;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await _userService.isAdmin();
      setState(() {
        _isAdmin = isAdmin;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  // Key for forcing CartScreen rebuild
  Key _cartScreenKey = UniqueKey();

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      
      // Force CartScreen to rebuild when cart tab is selected
      if (index == 2) {
        _cartScreenKey = UniqueKey();
      }
    });
    
    // Refresh cart count when switching to any tab
    // This ensures cart count is always up to date
    _loadCartItemCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeScreen(),
          MenuScreen(onCartUpdated: _loadCartItemCount),
          CartScreen(
            key: _cartScreenKey,
            onCartUpdated: _loadCartItemCount,
            onSwitchToMenu: () => _onItemTapped(1),
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (_cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_cartItemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
                          onPressed: () {
              context.go('/admin');
            },
              tooltip: 'Admin Panel',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Signed out successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.go('/auth');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sign out failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to the Restaurant App!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ready to order?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Browse our delicious menu and add items to your cart',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentIndex = 1; // Switch to Menu tab
                          });
                        },
                        icon: const Icon(Icons.menu_book),
                        label: const Text('View Menu'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/order-tracking'),
                    icon: const Icon(Icons.track_changes),
                    label: const Text('Track Order'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 3; // Switch to Profile tab
                      });
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('Profile'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
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