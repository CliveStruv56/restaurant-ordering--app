import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  // Check current authentication state
  Future<void> checkAuthState() async {
    try {
      final session = _supabase.auth.currentSession;
      Logger.debug('Auth state check: ${session != null ? 'Authenticated' : 'Not authenticated'}');
    } catch (e) {
      Logger.error('Error checking auth state', e);
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      Logger.debug('Attempting user registration');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        phone: phone,
        emailRedirectTo: null, // Disable email confirmation for testing
      );
      Logger.info('User registration successful');
      return response;
    } catch (e) {
      Logger.error('Sign up failed', e);
      
      // Provide more specific error messages
      String errorMessage = 'Registration failed';
      if (e.toString().contains('User already registered')) {
        errorMessage = 'An account with this email already exists';
      } else if (e.toString().contains('Password should be at least')) {
        errorMessage = 'Password must be at least 6 characters long';
      } else if (e.toString().contains('Invalid email')) {
        errorMessage = 'Please enter a valid email address';
      } else if (e.toString().contains('Too many requests')) {
        errorMessage = 'Too many registration attempts. Please try again later';
      } else if (e.toString().contains('Network error')) {
        errorMessage = 'Network error. Please check your connection';
      } else if (e.toString().contains('401')) {
        errorMessage = 'Authentication service error. Please try again';
      }
      
      throw Exception(errorMessage);
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      Logger.debug('Attempting user sign in');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      Logger.info('User sign in successful');
      return response;
    } catch (e) {
      Logger.error('Sign in failed', e);
      
      // Provide more specific error messages
      String errorMessage = 'Authentication failed';
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Invalid email or password';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Please check your email and confirm your account';
      } else if (e.toString().contains('Too many requests')) {
        errorMessage = 'Too many login attempts. Please try again later';
      } else if (e.toString().contains('Network error')) {
        errorMessage = 'Network error. Please check your connection';
      } else if (e.toString().contains('401')) {
        errorMessage = 'Authentication service error. Please try again';
      }
      
      throw Exception(errorMessage);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      Logger.info('User signed out successfully');
    } catch (e) {
      Logger.error('Sign out failed', e);
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      Logger.info('Password reset email sent');
    } catch (e) {
      Logger.error('Password reset failed', e);
      rethrow;
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      Logger.info('Password updated successfully');
    } catch (e) {
      Logger.error('Password update failed', e);
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? email,
    String? phone,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          email: email,
          phone: phone,
          data: data,
        ),
      );
      Logger.info('Profile updated successfully');
    } catch (e) {
      Logger.error('Profile update failed', e);
      rethrow;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange;
  }
} 