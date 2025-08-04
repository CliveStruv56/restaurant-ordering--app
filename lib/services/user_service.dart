import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      Logger.debug('Getting current user profile');
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select('*')
          .eq('id', user.id)
          .single();

      Logger.debug('User profile fetched successfully');
      return response;
    } catch (e) {
      Logger.error('Error fetching user profile', e);
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? fullName,
    String? phone,
    String? address,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (preferences != null) updates['preferences'] = preferences;

      await _supabase
          .from('users')
          .update(updates)
          .eq('id', user.id);
    } catch (e) {
      Logger.error('Error updating user profile', e);
      rethrow;
    }
  }

  // Get user role
  Future<String> getUserRole() async {
    try {
      final profile = await getCurrentUserProfile();
      final role = profile?['role'] ?? 'customer';
      Logger.debug('User role retrieved: $role');
      return role;
    } catch (e) {
      Logger.error('Error getting user role', e);
      return 'customer';
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    try {
      final role = await getUserRole();
      final isAdmin = role == 'admin';
      Logger.info('Admin check: role=$role, isAdmin=$isAdmin');
      return isAdmin;
    } catch (e) {
      Logger.error('Error checking admin status', e);
      return false;
    }
  }

  // Check if user is staff
  Future<bool> isStaff() async {
    final role = await getUserRole();
    return role == 'staff' || role == 'admin';
  }

  // Get user preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?['preferences'] ?? {};
    } catch (e) {
      return {};
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('users')
          .update({'preferences': preferences})
          .eq('id', user.id);
    } catch (e) {
      Logger.error('Error updating user preferences', e);
      rethrow;
    }
  }

  // Get user orders
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching user orders', e);
      return [];
    }
  }

  // Get all orders (admin only)
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final isAdminUser = await isAdmin();
      if (!isAdminUser) throw Exception('Admin access required');

      final response = await _supabase
          .from('orders')
          .select('*, users(full_name, email), order_items(*)')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching all orders', e);
      return [];
    }
  }

  // Get orders by status
  Future<List<Map<String, dynamic>>> getOrdersByStatus(String status) async {
    try {
      final isAdminUser = await isAdmin();
      if (!isAdminUser) throw Exception('Admin access required');

      final response = await _supabase
          .from('orders')
          .select('*, users(full_name, email), order_items(*)')
          .eq('status', status)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching orders by status', e);
      return [];
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final isAdminUser = await isAdmin();
      if (!isAdminUser) throw Exception('Admin access required');

      await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
    } catch (e) {
      Logger.error('Error updating order status', e);
      rethrow;
    }
  }

  // Get order details by ID
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, users(full_name, email), order_items(*)')
          .eq('id', orderId)
          .single();

      return response;
    } catch (e) {
      Logger.error('Error fetching order details', e);
      rethrow;
    }
  }

  // Create user profile if it doesn't exist
  Future<void> createUserProfileIfNotExists() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Check if profile exists
      final existingProfile = await getCurrentUserProfile();
      if (existingProfile != null) return;

      // Create new profile
      await _supabase.from('users').insert({
        'id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
        'role': 'customer',
        'preferences': {},
      });
    } catch (e) {
      Logger.error('Error creating user profile', e);
    }
  }
} 