import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Test Supabase connection
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

    // Test basic connection
    try {
      await client.from('categories').select('count').limit(1);
      print('✅ Database connection successful');
    } catch (e) {
      print('❌ Database connection failed: $e');
    }

    // Test auth state
    final session = client.auth.currentSession;
    print('Current session: ${session != null ? 'Active' : 'None'}');

    // Test sign up (this will fail if email already exists, but that's expected)
    try {
      await client.auth.signUp(
        email: 'test@example.com',
        password: 'testpassword123',
      );
      print('✅ Sign up test successful');
    } catch (e) {
      print('⚠️ Sign up test failed (expected if email exists): $e');
    }

  } catch (e) {
    print('❌ Supabase initialization failed: $e');
  }
} 