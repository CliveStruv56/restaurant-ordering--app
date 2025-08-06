import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Debug script to check admin status
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const String supabaseUrl = 'https://maszzmjhnrilkpmelwqv.supabase.co';
  const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hc3p6bWpobnJpbGtwbWVsd3F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM5NTg3NzUsImV4cCI6MjA2OTUzNDc3NX0.sVjpgp06KwEb64xkyfqxntYfIHED3G1DzAQABpdxrEs';

  try {
    print('Initializing Supabase...');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    print('✅ Supabase initialized successfully');

    final client = Supabase.instance.client;
    print('✅ Supabase client created');

    // Check current user
    final user = client.auth.currentUser;
    print('Current user: ${user?.email}');
    print('Current user ID: ${user?.id}');

    if (user != null) {
      // Check if user profile exists
      try {
        final response = await client
            .from('users')
            .select('*')
            .eq('id', user.id)
            .single();
        
        print('✅ User profile found:');
        print('  - ID: ${response['id']}');
        print('  - Email: ${response['email']}');
        print('  - Full Name: ${response['full_name']}');
        print('  - Role: ${response['role']}');
        print('  - Created At: ${response['created_at']}');
        
        final role = response['role'] ?? 'customer';
        final isAdmin = role == 'admin';
        print('Is admin: $isAdmin');
        
      } catch (e) {
        print('❌ User profile not found or error: $e');
        print('This means the user profile was not created properly.');
      }
    } else {
      print('❌ No user logged in');
    }

  } catch (e) {
    print('❌ Error: $e');
  }
} 