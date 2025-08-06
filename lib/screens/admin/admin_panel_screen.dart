import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/user_service.dart';
import '../../utils/currency.dart';
import 'user_management/user_form_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final UserService _userService = UserService();
  
  bool _isLoading = true;
  bool _isAdmin = false;
  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final isAdmin = await _userService.isAdmin();
      
      if (isAdmin) {
        await _loadAdminData();
      } else {
        // Redirect to home if not admin
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin access required'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAdminData() async {
    try {
      print('[DEBUG AdminPanel] Loading admin data...');
      
      // Load admin data (orders and users)
      final users = await _userService.getAllUsers();
      final orders = await _userService.getAllOrders();
      
      print('[DEBUG AdminPanel] Loaded ${users.length} users and ${orders.length} orders');
      print('[DEBUG AdminPanel] Users: ${users.map((u) => u['full_name']).toList()}');
      
      if (mounted) {
        setState(() {
          _isAdmin = true;
          _allOrders = orders;
          _allUsers = users;
        });
        print('[DEBUG AdminPanel] State updated with new user data');
      }
    } catch (e) {
      print('[ERROR AdminPanel] Failed to load admin data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load admin data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddUserDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserFormScreen(
          onUserCreated: () {
            print('[DEBUG AdminPanel] User created callback triggered, reloading data...');
            _loadAdminData();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('[DEBUG AdminPanel] Manual refresh button pressed');
              _loadAdminData();
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
            tooltip: 'Go to Home',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isAdmin
              ? _buildAdminContent()
              : const Center(child: Text('Access Denied')),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: Colors.red[700],
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on admin panel
              break;
            case 1:
              context.go('/home');
              break;
            case 2:
              context.go('/home?tab=menu');
              break;
            case 3:
              context.go('/home?tab=cart');
              break;
            case 4:
              context.go('/home?tab=profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildAdminContent() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.red[700],
            child: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: 'Dashboard'),
                Tab(text: 'Orders'),
                Tab(text: 'Users'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildDashboard(),
                _buildOrdersTab(),
                _buildUsersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick stats cards
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.shopping_cart, color: Colors.blue, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Total Orders',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${_allOrders.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.people, color: Colors.green, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Total Users',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${_allUsers.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Manage Menu'),
            subtitle: const Text('Add, edit, or remove menu items'),
            onTap: () {
              context.go('/admin/menu');
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Manage Menu Options'),
            subtitle: const Text('Configure sizes, milk types, sides, etc.'),
            onTap: () {
              context.go('/admin/menu-options');
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Manage Orders'),
            subtitle: const Text('View and update order status'),
            onTap: () {
              context.go('/admin/orders');
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Manage Time Slots'),
            subtitle: const Text('Set available pickup and delivery times'),
            onTap: () {
              context.go('/admin/timeslots');
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Restaurant Settings'),
            subtitle: const Text('Configure opening hours and timeslot settings'),
            onTap: () {
              context.go('/admin/restaurant-settings');
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('User Management'),
            subtitle: const Text('Manage customer and staff accounts'),
            onTap: () {
              context.go('/admin/user-management');
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.table_restaurant),
            title: const Text('Table Management'),
            subtitle: const Text('Manage restaurant table layout'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Table management coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Orders',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_allOrders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No orders yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _allOrders.length,
                itemBuilder: (context, index) {
                  final order = _allOrders[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      title: Text('Order #${order['order_number']}'),
                      subtitle: Text(
                        '${order['order_type']} • ${CurrencyUtils.formatPrice(order['total'])}',
                      ),
                      trailing: Chip(
                        label: Text(order['status']),
                        backgroundColor: _getStatusColor(order['status']),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        // TODO: Show order details
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'User Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _showAddUserDialog();
                    },
                    icon: const Icon(Icons.person_add),
                    tooltip: 'Add User',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go('/admin/user-management');
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Manage Users'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Quick stats
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.people, color: Colors.blue, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          '${_allUsers.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Total Users'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Colors.red, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          '${_allUsers.where((u) => u['role'] == 'admin').length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Admins'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Recent users preview
          const Text(
            'Recent Users',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          if (_allUsers.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No users found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Users will appear here once they register',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _allUsers.length > 5 ? 5 : _allUsers.length,
                itemBuilder: (context, index) {
                  final user = _allUsers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRoleColor(user['role']).withOpacity(0.2),
                        child: Text(
                          (user['full_name'] ?? 'U').substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: _getRoleColor(user['role']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(user['full_name'] ?? 'Unknown'),
                      subtitle: Text(user['email']),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user['role']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user['role'].toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      onTap: () {
                        context.go('/admin/user-management');
                      },
                    ),
                  );
                },
              ),
            ),
            
          // View all button
          if (_allUsers.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: OutlinedButton(
                  onPressed: () {
                    context.go('/admin/user-management');
                  },
                  child: Text('View All ${_allUsers.length} Users'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'staff':
        return Colors.orange;
      case 'customer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 