import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/user_service.dart';
import 'package:go_router/go_router.dart';

class AdminCheckScreen extends StatefulWidget {
  const AdminCheckScreen({super.key});

  @override
  State<AdminCheckScreen> createState() => _AdminCheckScreenState();
}

class _AdminCheckScreenState extends State<AdminCheckScreen> {
  final UserService _userService = UserService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  String? _userEmail;
  String? _userId;
  Map<String, dynamic>? _userProfile;
  String? _userRole;
  bool? _isAdmin;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      setState(() => _isLoading = true);
      
      // Get current auth user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'No user logged in';
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _userEmail = user.email;
        _userId = user.id;
      });
      
      // Get user profile from database
      _userProfile = await _userService.getCurrentUserProfile();
      
      // Get user role
      _userRole = await _userService.getUserRole();
      
      // Check admin status
      _isAdmin = await _userService.isAdmin();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _makeUserAdmin() async {
    try {
      setState(() => _isLoading = true);
      
      if (_userId == null) {
        throw Exception('No user ID available');
      }
      
      // Update user role in database
      await _supabase
          .from('users')
          .upsert({
            'id': _userId,
            'email': _userEmail,
            'role': 'admin',
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      // Refresh the admin status
      await _checkAdminStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin role granted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to grant admin role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Status Check'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current User Info',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow('Email', _userEmail ?? 'Not logged in'),
                          _buildInfoRow('User ID', _userId ?? 'N/A'),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'Database Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_userProfile != null) ...[
                            _buildInfoRow('Profile Found', '✅ Yes'),
                            _buildInfoRow('Role in DB', _userProfile!['role'] ?? 'null'),
                            _buildInfoRow('Full Name', _userProfile!['full_name'] ?? 'Not set'),
                          ] else
                            _buildInfoRow('Profile Found', '❌ No profile in users table'),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'Admin Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('Current Role', _userRole ?? 'customer'),
                          _buildInfoRow(
                            'Is Admin?',
                            _isAdmin == true ? '✅ Yes' : '❌ No',
                            color: _isAdmin == true ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Error',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_isAdmin != true) ...[
                    Card(
                      color: Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚠️ Not an Admin',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You need admin privileges to access menu and order management.',
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _makeUserAdmin,
                                icon: const Icon(Icons.admin_panel_settings),
                                label: const Text('Grant Admin Role to Current User'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '✅ Admin Access Confirmed',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You have admin privileges. You can now access:',
                            ),
                            const SizedBox(height: 8),
                            const Text('• Menu Management'),
                            const Text('• Order Management'),
                            const Text('• User Management'),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => context.go('/admin'),
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Go to Admin Panel'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _checkAdminStatus,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Status'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
}