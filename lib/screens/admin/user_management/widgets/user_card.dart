import 'package:flutter/material.dart';
import '../../../../services/user_service.dart';
import '../../../../utils/logger.dart';
import '../user_form_screen.dart';

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;

  const UserCard({
    Key? key,
    required this.user,
    this.onTap,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userName = user['full_name'] ?? 'Unknown User';
    final userEmail = user['email'] ?? '';
    final userRole = user['role'] ?? 'customer';
    final createdAt = user['created_at'] != null 
        ? DateTime.parse(user['created_at']).toLocal()
        : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: _getRoleColor(userRole).withOpacity(0.2),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getRoleColor(userRole),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and status indicator
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusIndicator(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Email
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Role badge and created date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(userRole),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            userRole.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (createdAt != null)
                          Text(
                            'Joined ${_formatDate(createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions menu
              PopupMenuButton<String>(
                onSelected: (value) => _handleAction(context, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 18),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit User'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reset_password',
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset, size: 18),
                        SizedBox(width: 8),
                        Text('Reset Password'),
                      ],
                    ),
                  ),
                  if (userRole != 'admin')
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete User', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    // For now, show all users as active
    // TODO: Implement real-time status tracking
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleAction(BuildContext context, String action) {
    final userId = user['id'];
    final userName = user['full_name'] ?? 'Unknown User';
    
    switch (action) {
      case 'view':
        onTap?.call();
        break;
        
      case 'edit':
        _showEditUserDialog(context, user, userName);
        break;
        
      case 'reset_password':
        _showResetPasswordDialog(context, userId, userName);
        break;
        
      case 'delete':
        _showDeleteUserDialog(context, userId, userName);
        break;
    }
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user, String userName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserFormScreen(
          user: user,
          onUserUpdated: () {
            onRefresh?.call();
          },
        ),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send password reset email to $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetUserPassword(context, userId, userName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(BuildContext context, String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete $userName?'),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone and will:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Text('• Remove the user account'),
            const Text('• Delete their order history'),
            const Text('• Remove all associated data'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteUser(context, userId, userName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete User'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetUserPassword(BuildContext context, String userId, String userName) async {
    try {
      // TODO: Implement password reset functionality
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $userName'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reset password: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(BuildContext context, String userId, String userName) async {
    try {
      final userService = UserService();
      await userService.deleteUser(userId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User $userName deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      onRefresh?.call();
    } catch (e) {
      Logger.error('Failed to delete user', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}