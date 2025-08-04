import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/user_service.dart';
import '../../utils/currency.dart';

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
      // Load admin data (orders and users)
      // Note: This would require additional methods in UserService
      setState(() {
        _isAdmin = true;
        _allOrders = []; // TODO: Implement getAllOrders
        _allUsers = []; // TODO: Implement getAllUsers
      });
    } catch (e) {
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
    return Padding(
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
                        const Text(
                          '0', // TODO: Get actual count
                          style: TextStyle(
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
                        const Text(
                          '0', // TODO: Get actual count
                          style: TextStyle(
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
          const Text(
            'All Users',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_allUsers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No users found',
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
                itemCount: _allUsers.length,
                itemBuilder: (context, index) {
                  final user = _allUsers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          (user['full_name'] ?? 'U').substring(0, 1).toUpperCase(),
                        ),
                      ),
                      title: Text(user['full_name'] ?? 'Unknown'),
                      subtitle: Text(user['email']),
                      trailing: Chip(
                        label: Text(user['role']),
                        backgroundColor: _getRoleColor(user['role']),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        // TODO: Show user details and role management
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