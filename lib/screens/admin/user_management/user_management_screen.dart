import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/user_service.dart';
import '../../../utils/logger.dart';
import 'widgets/user_card.dart';
import 'user_form_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String? _selectedRoleFilter;
  String? _selectedStatusFilter;
  
  final List<String> _roleFilters = ['All', 'customer', 'staff', 'admin'];
  final List<String> _statusFilters = ['All', 'active', 'inactive', 'suspended'];

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final isAdmin = await _userService.isAdmin();
      if (!isAdmin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied. Admin privileges required.'),
              backgroundColor: Colors.red,
            ),
          );
          context.go('/admin');
        }
        return;
      }
      
      await _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/admin');
      }
    }
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('[DEBUG UserManagement] Loading users...');
      final users = await _userService.getAllUsers();
      
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
      
      print('[DEBUG UserManagement] Loaded ${users.length} users');
    } catch (e) {
      print('[ERROR UserManagement] Failed to load users: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        // Text search
        final matchesSearch = query.isEmpty ||
            (user['full_name']?.toLowerCase().contains(query) ?? false) ||
            (user['email']?.toLowerCase().contains(query) ?? false);
        
        // Role filter
        final matchesRole = _selectedRoleFilter == null ||
            _selectedRoleFilter == 'All' ||
            user['role'] == _selectedRoleFilter;
        
        // Status filter (for now, assume all users are active)
        final matchesStatus = _selectedStatusFilter == null ||
            _selectedStatusFilter == 'All' ||
            _selectedStatusFilter == 'active';
        
        return matchesSearch && matchesRole && matchesStatus;
      }).toList();
    });
  }

  void _showAddUserDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserFormScreen(
          onUserCreated: () {
            print('[DEBUG UserManagement] User created callback triggered, reloading users...');
            _loadUsers();
          },
        ),
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    // TODO: Navigate to user details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User details for ${user['full_name']} (Coming Soon)'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh Users',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddUserDialog,
            tooltip: 'Add User',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Filter chips
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRoleFilter,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _roleFilters.map((role) => DropdownMenuItem(
                          value: role == 'All' ? null : role,
                          child: Text(role),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRoleFilter = value;
                          });
                          _filterUsers();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _statusFilters.map((status) => DropdownMenuItem(
                          value: status == 'All' ? null : status,
                          child: Text(status),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatusFilter = value;
                          });
                          _filterUsers();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
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
                              _allUsers.isEmpty ? 'No users found' : 'No users match your search',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_allUsers.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _selectedRoleFilter = null;
                                    _selectedStatusFilter = null;
                                  });
                                  _filterUsers();
                                },
                                child: const Text('Clear filters'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return UserCard(
                            user: user,
                            onTap: () => _showUserDetails(user),
                            onRefresh: _loadUsers,
                          );
                        },
                      ),
          ),
        ],
      ),
      
      // Summary bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[100],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${_filteredUsers.length} of ${_allUsers.length} users',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (_filteredUsers.length != _allUsers.length)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedRoleFilter = null;
                    _selectedStatusFilter = null;
                  });
                  _filterUsers();
                },
                child: const Text('Show All'),
              ),
          ],
        ),
      ),
    );
  }
}