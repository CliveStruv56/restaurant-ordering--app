import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/user_service.dart';
import '../../../utils/logger.dart';

class UserFormScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final VoidCallback? onUserCreated;
  final VoidCallback? onUserUpdated;

  const UserFormScreen({
    Key? key,
    this.user,
    this.onUserCreated,
    this.onUserUpdated,
  }) : super(key: key);

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  
  String _selectedRole = 'customer';
  bool _sendWelcomeEmail = true;
  bool _requirePasswordChange = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  final List<String> _roles = ['customer', 'staff', 'admin'];
  
  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = widget.user;
    _fullNameController = TextEditingController(text: user?['full_name'] ?? '');
    _emailController = TextEditingController(text: user?['email'] ?? '');
    _phoneController = TextEditingController(text: user?['phone'] ?? '');
    _passwordController = TextEditingController();
    
    if (user != null) {
      _selectedRole = user['role'] ?? 'customer';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit User' : 'Add New User'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Full Name
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'Enter user\'s full name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          if (value.trim().length < 2) {
                            return 'Full name must be at least 2 characters';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      
                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address *',
                          hintText: 'Enter email address',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isEditing, // Can't change email when editing
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter phone number (optional)',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (value.length < 10) {
                              return 'Phone number must be at least 10 digits';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Role and Permissions Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Role & Permissions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Role Selection
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'User Role *',
                          prefixIcon: Icon(Icons.admin_panel_settings),
                          border: OutlineInputBorder(),
                        ),
                        items: _roles.map((role) => DropdownMenuItem(
                          value: role,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getRoleColor(role),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(role[0].toUpperCase() + role.substring(1)),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Role descriptions
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Role Permissions:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getRoleDescription(_selectedRole),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Password Section (only for new users)
              if (!_isEditing) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Setup',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Password
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password *',
                            hintText: 'Enter initial password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Options
                        CheckboxListTile(
                          title: const Text('Send welcome email'),
                          subtitle: const Text('Email login credentials to the user'),
                          value: _sendWelcomeEmail,
                          onChanged: (value) {
                            setState(() {
                              _sendWelcomeEmail = value ?? true;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Text('Require password change on first login'),
                          subtitle: const Text('User must change password on first sign-in'),
                          value: _requirePasswordChange,
                          onChanged: (value) {
                            setState(() {
                              _requirePasswordChange = value ?? true;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                ),
                child: Text(_isEditing ? 'Update User' : 'Create User'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'staff':
        return Colors.orange;
      case 'customer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDescription(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Full system access including user management, settings, and all restaurant operations';
      case 'staff':
        return 'Access to order management, menu updates, and customer service features';
      case 'customer':
        return 'Standard user access for placing orders and managing personal account';
      default:
        return 'Unknown role';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing) {
        await _updateUser();
      } else {
        await _createUser();
      }
    } catch (e) {
      Logger.error('Error ${_isEditing ? 'updating' : 'creating'} user', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${_isEditing ? 'updating' : 'creating'} user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createUser() async {
    try {
      print('[DEBUG UserForm] Starting user creation...');
      
      final userId = await _userService.createUser(
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        role: _selectedRole,
      );
      
      print('[DEBUG UserForm] User created with ID: $userId');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${_fullNameController.text} created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
        widget.onUserCreated?.call();
      }
    } catch (e) {
      print('[ERROR UserForm] Failed to create user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateUser() async {
    final userId = widget.user!['id'];
    
    // Update user role if changed
    if (_selectedRole != widget.user!['role']) {
      await _userService.updateUserRole(userId, _selectedRole);
    }
    
    // TODO: Update other user fields when user profile update API is available
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
      widget.onUserUpdated?.call();
    }
  }
}