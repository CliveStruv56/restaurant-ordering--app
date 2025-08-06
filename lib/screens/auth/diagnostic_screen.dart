import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _status = 'Running diagnostics...';
  List<String> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    _addLog('Starting Supabase diagnostics...');
    
    try {
      // Test 1: Check Supabase initialization
      _addLog('1. Checking Supabase initialization...');
      final client = Supabase.instance.client;
      _addLog('✅ Supabase client created successfully');
      
      // Test 2: Check current session
      _addLog('2. Checking current session...');
      final session = client.auth.currentSession;
      final user = client.auth.currentUser;
      _addLog('Session: ${session != null ? 'Active' : 'None'}');
      _addLog('User: ${user?.email ?? 'None'}');
      
      // Test 3: Test database connection
      _addLog('3. Testing database connection...');
      try {
        await client.from('categories').select('count').limit(1);
        _addLog('✅ Database connection successful');
      } catch (e) {
        _addLog('❌ Database connection failed: $e');
      }
      
      // Test 4: Check auth settings
      _addLog('4. Checking auth configuration...');
      try {
        final session = client.auth.currentSession;
        _addLog('✅ Auth configuration OK - Session: ${session != null ? 'Active' : 'None'}');
      } catch (e) {
        _addLog('❌ Auth configuration error: $e');
      }
      
      setState(() {
        _status = 'Diagnostics completed';
      });
      
    } catch (e) {
      _addLog('❌ Diagnostic error: $e');
      setState(() {
        _status = 'Diagnostics failed';
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
  }

  Future<void> _testSignUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _addLog('❌ Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('Testing sign up with: ${_emailController.text}');
      await _authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
      _addLog('✅ Sign up test successful');
    } catch (e) {
      _addLog('❌ Sign up test failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _addLog('❌ Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('Testing sign in with: ${_emailController.text}');
      await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      _addLog('✅ Sign in test successful');
    } catch (e) {
      _addLog('❌ Sign in test failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Diagnostics'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: $_status',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Test inputs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Authentication',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testSignUp,
                            child: const Text('Test Sign Up'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testSignIn,
                            child: const Text('Test Sign In'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Logs
            const Text(
              'Diagnostic Logs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        log,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 