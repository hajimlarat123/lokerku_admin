// lib/screens/admin_login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/admin_config.dart';
import 'dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  bool useFirebaseAuth = true; // Toggle between Firebase and local auth

  @override
  void initState() {
    super.initState();
    _loadDefaultCredentials();
  }

  Future<void> _loadDefaultCredentials() async {
    // Load saved credentials untuk memudahkan testing
    Map<String, String> credentials = await AdminConfig.getAdminCredentials();
    setState(() {
      emailController.text = credentials['email']!;
      passwordController.text = credentials['password']!;
    });
  }

  Future<void> _login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String email = emailController.text.trim();
      String password = passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        setState(() => errorMessage = 'Email dan password tidak boleh kosong');
        return;
      }

      bool loginSuccess = false;

      if (useFirebaseAuth) {
        // Try Firebase Authentication first
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          loginSuccess = true;
        } catch (firebaseError) {
          // If Firebase fails, try local credentials
          print('Firebase auth failed: $firebaseError');
          bool isValidLocal = await AdminConfig.validateCredentials(
            email,
            password,
          );
          if (isValidLocal) {
            loginSuccess = true;
          } else {
            throw firebaseError; // Re-throw Firebase error if local also fails
          }
        }
      } else {
        // Use local credentials only
        bool isValidLocal = await AdminConfig.validateCredentials(
          email,
          password,
        );
        if (isValidLocal) {
          loginSuccess = true;
        } else {
          throw Exception('Kredensial tidak valid');
        }
      }

      if (loginSuccess && mounted) {
        // Save successful login credentials
        await AdminConfig.updateAdminCredentials(email, password);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Login gagal: ${_getErrorMessage(e)}';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Email tidak ditemukan';
        case 'wrong-password':
          return 'Password salah';
        case 'invalid-email':
          return 'Format email tidak valid';
        case 'user-disabled':
          return 'Akun telah dinonaktifkan';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan login. Coba lagi nanti';
        default:
          return 'Terjadi kesalahan: ${error.message}';
      }
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Admin'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(useFirebaseAuth ? Icons.cloud : Icons.storage),
            onPressed: () {
              setState(() {
                useFirebaseAuth = !useFirebaseAuth;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    useFirebaseAuth
                        ? 'Menggunakan Firebase Auth'
                        : 'Menggunakan Local Auth',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Admin Loker',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              useFirebaseAuth
                  ? 'Firebase Authentication'
                  : 'Local Authentication',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Admin',
                hintText: 'Masukkan email admin',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Masukkan password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Login', style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () async {
                await AdminConfig.resetToDefault();
                await _loadDefaultCredentials();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kredensial direset ke default'),
                  ),
                );
              },
              child: const Text('Reset ke Default'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
