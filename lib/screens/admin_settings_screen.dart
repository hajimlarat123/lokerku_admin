// lib/screens/admin_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/admin_config.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _currentPasswordController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentCredentials();
  }

  Future<void> _loadCurrentCredentials() async {
    String currentEmail = await AdminConfig.getCurrentAdminEmail();
    setState(() {
      _newEmailController.text = currentEmail;
    });
  }

  Future<void> _updateLocalCredentials() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Password konfirmasi tidak cocok';
        _successMessage = null;
      });
      return;
    }

    if (_newPasswordController.text.isNotEmpty &&
        _newPasswordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password minimal 6 karakter';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Validate current password
      Map<String, String> credentials = await AdminConfig.getAdminCredentials();
      if (_currentPasswordController.text != credentials['password']) {
        setState(() {
          _errorMessage = 'Password lama tidak benar';
          _isLoading = false;
        });
        return;
      }

      // Update credentials
      String newEmail = _newEmailController.text.trim();
      String newPassword = _newPasswordController.text.isNotEmpty
          ? _newPasswordController.text
          : credentials['password']!;

      bool success = await AdminConfig.updateAdminCredentials(
        newEmail,
        newPassword,
      );

      if (success) {
        setState(() {
          _successMessage = 'Kredensial berhasil diperbarui';
          _isLoading = false;
        });

        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        setState(() {
          _errorMessage = 'Gagal menyimpan kredensial';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateFirebaseCredentials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Tidak ada user yang login di Firebase';
          _isLoading = false;
        });
        return;
      }

      // Update email if changed
      if (_newEmailController.text.trim() != user.email) {
        await user.updateEmail(_newEmailController.text.trim());
      }

      // Update password if provided
      if (_newPasswordController.text.isNotEmpty) {
        await user.updatePassword(_newPasswordController.text);
      }

      setState(() {
        _successMessage = 'Kredensial Firebase berhasil diperbarui';
        _isLoading = false;
      });

      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal update Firebase: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Admin'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ubah Kredensial Admin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Current Password
            TextField(
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Password Lama',
                hintText: 'Masukkan password saat ini',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showCurrentPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showCurrentPassword = !_showCurrentPassword;
                    });
                  },
                ),
              ),
              obscureText: !_showCurrentPassword,
            ),
            const SizedBox(height: 16),

            // New Email
            TextField(
              controller: _newEmailController,
              decoration: const InputDecoration(
                labelText: 'Email Baru',
                hintText: 'Masukkan email baru',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // New Password
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                hintText: 'Kosongkan jika tidak ingin mengubah',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showNewPassword = !_showNewPassword;
                    });
                  },
                ),
              ),
              obscureText: !_showNewPassword,
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password Baru',
                hintText: 'Ulangi password baru',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                ),
              ),
              obscureText: !_showConfirmPassword,
            ),
            const SizedBox(height: 24),

            // Messages
            if (_errorMessage != null)
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
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateLocalCredentials,
                    icon: const Icon(Icons.storage),
                    label: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update Local'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateFirebaseCredentials,
                    icon: const Icon(Icons.cloud),
                    label: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update Firebase'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reset Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reset Kredensial'),
                      content: const Text(
                        'Apakah Anda yakin ingin mereset kredensial ke default?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await AdminConfig.resetToDefault();
                    await _loadCurrentCredentials();
                    setState(() {
                      _successMessage = 'Kredensial direset ke default';
                      _errorMessage = null;
                    });
                  }
                },
                icon: const Icon(Icons.restore),
                label: const Text('Reset ke Default'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newEmailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
