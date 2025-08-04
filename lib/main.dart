import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'config/app_config.dart';
import 'utils/logger.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/checkout/order_confirmation_screen.dart';
import 'screens/orders/order_tracking_screen.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'screens/admin/menu_management_screen.dart';
import 'screens/admin/menu_item_form_screen.dart';
import 'screens/admin/order_management_screen.dart';
import 'screens/admin/order_details_screen.dart';
import 'screens/admin/admin_check_screen.dart';
import 'screens/admin/restaurant_settings_screen.dart';
import 'screens/admin/timeslot_management_screen.dart';
import 'screens/auth/diagnostic_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await AppConfig.initialize();
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  } catch (e) {
    Logger.error('Failed to initialize app', e);
    runApp(ErrorApp(error: e.toString()));
    return;
  }
  
  runApp(const MyApp());
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Failed to initialize app:\n$error\n\nPlease check your .env file configuration.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/auth',
  redirect: (context, state) {
    if (state.uri.path == '/') {
      return '/auth';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final tab = state.uri.queryParameters['tab'];
        return MainScreen(initialTab: tab);
      },
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/order-confirmation',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OrderConfirmationScreen(orderData: extra);
      },
    ),
    GoRoute(
      path: '/order-tracking',
      builder: (context, state) => const OrderTrackingScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminPanelScreen(),
    ),
    GoRoute(
      path: '/admin/menu',
      builder: (context, state) => const MenuManagementScreen(),
    ),
    GoRoute(
      path: '/admin/menu/add',
      builder: (context, state) => const MenuItemFormScreen(),
    ),
    GoRoute(
      path: '/admin/menu/edit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MenuItemFormScreen(menuItemId: id);
      },
    ),
    GoRoute(
      path: '/admin/orders',
      builder: (context, state) => const OrderManagementScreen(),
    ),
    GoRoute(
      path: '/admin/orders/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return OrderDetailsScreen(orderId: id);
      },
    ),
    GoRoute(
      path: '/diagnostic',
      builder: (context, state) => const DiagnosticScreen(),
    ),
    GoRoute(
      path: '/admin-check',
      builder: (context, state) => const AdminCheckScreen(),
    ),
    GoRoute(
      path: '/admin/restaurant-settings',
      builder: (context, state) => const RestaurantSettingsScreen(),
    ),
    GoRoute(
      path: '/admin/timeslots',
      builder: (context, state) => const TimeslotManagementScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Page Not Found'),
          const SizedBox(height: 16),
          Text('Route: ${state.uri.path}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/auth'),
            child: const Text('Go to Home'),
          ),
        ],
      ),
    ),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Restaurant App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String? _connectionStatus;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthAndConnection();
  }

  Future<void> _checkAuthAndConnection() async {
    try {
      // Check Supabase connection
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      
      setState(() {
        _connectionStatus = '✅ Connected to Supabase!';
      });

      // Check if user is already logged in
      if (session != null && client.auth.currentUser != null) {
        Logger.debug('User session detected, redirecting to home');
        // Add a small delay to ensure the UI is ready
        await Future.delayed(const Duration(milliseconds: 500));
        // Redirect to home screen
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Supabase connection failed: \n${e.toString()}';
      });
    } finally {
      setState(() {
        _isCheckingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking authentication...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Restaurant App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Order food and book tables',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            if (_connectionStatus != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _connectionStatus!,
                  style: TextStyle(
                    color: _connectionStatus!.contains('✅') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Sign In'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        context.go('/register');
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Create Account'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        context.go('/diagnostic');
                      },
                      child: const Text('🔧 Run Diagnostics'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.go('/admin-check');
                      },
                      child: const Text('👤 Check Admin Status'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/home?tab=profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
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
                          context.go('/home?tab=menu');
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
                    onPressed: () => context.go('/home?tab=profile'),
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