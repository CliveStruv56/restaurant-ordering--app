import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  static late String supabaseUrl;
  static late String supabaseAnonKey;
  static late bool debugMode;
  
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      
      supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      debugMode = dotenv.env['DEBUG_MODE'] == 'true';
      
    } catch (e) {
      // Fallback configuration if .env file fails to load
      if (kDebugMode) {
        print('Warning: Could not load .env file ($e), using fallback configuration');
      }
      
      // Use the original hardcoded values as fallback
      supabaseUrl = 'https://maszzmjhnrilkpmelwqv.supabase.co';
      supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hc3p6bWpobnJpbGtwbWVsd3F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM5NTg3NzUsImV4cCI6MjA2OTUzNDc3NX0.sVjpgp06KwEb64xkyfqxntYfIHED3G1DzAQABpdxrEs';
      debugMode = kDebugMode;
    }
    
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Missing Supabase configuration. Please check your environment setup.');
    }
  }
  
  static bool get isDebugMode => debugMode;
}