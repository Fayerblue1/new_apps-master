import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegister = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Proses Login atau Register dengan Supabase Auth
  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    // Sembunyikan keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isRegister) {
        // --- 1. Mode Register ---
        final res = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (!mounted) return;

        if (res.session != null) {
          // Jika Supabase tidak mewajibkan konfirmasi email (auto login)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Pendaftaran berhasil! Selamat datang.'),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        } else {
          // Jika Supabase mewajibkan konfirmasi email
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Pendaftaran Berhasil'),
              content: Text(
                'Tautan konfirmasi telah dikirim ke $email. Silakan periksa kotak masuk atau spam email Anda sebelum login.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _isRegister = false; // Beralih ke form login
                    });
                  },
                  child: const Text('OK, Masuk'),
                ),
              ],
            ),
          );
        }
      } else {
        // --- 2. Mode Login ---
        final res = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (!mounted) return;

        if (res.session != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Login berhasil! Selamat membaca kabar terkini.'),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showFriendlyError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showFriendlyError('Terjadi kesalahan koneksi. Periksa internet Anda.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Menampilkan pesan error yang ramah pengguna
  void _showFriendlyError(String originalMessage) {
    String message = originalMessage;
    final lower = originalMessage.toLowerCase();

    if (lower.contains('invalid login credentials')) {
      message = 'Email atau password salah. Silakan coba lagi.';
    } else if (lower.contains('email not confirmed')) {
      message = 'Email belum dikonfirmasi. Silakan periksa inbox email Anda.';
    } else if (lower.contains('user already registered')) {
      message = 'Email ini sudah terdaftar. Silakan login.';
    } else if (lower.contains('password should be at least')) {
      message = 'Password minimal harus 6 karakter.';
    } else if (lower.contains('network') || lower.contains('socket')) {
      message = 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Navigasi sebagai Tamu (Guest)
  void _skipLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo Koran
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.newspaper_rounded,
                        size: 64,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Judul & Subjudul Form
                  Text(
                    _isRegister ? 'Buat Akun Baru' : 'Selamat Datang!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegister
                        ? 'Daftar untuk menikmati seluruh fitur Kabar'
                        : 'Masuk dengan akun Supabase Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Kolom Input Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'nama@email.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }
                      final emailRegex =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(val.trim())) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Kolom Input Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleAuth(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Minimal 6 karakter',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Password wajib diisi';
                      }
                      if (val.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Tombol Masuk / Daftar
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isRegister ? 'Daftar Sekarang' : 'Masuk',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Toggle Login / Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegister
                            ? 'Sudah punya akun?'
                            : 'Belum punya akun?',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isRegister = !_isRegister;
                                });
                              },
                        child: Text(
                          _isRegister ? 'Masuk' : 'Daftar Akun Baru',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Garis Pemisah "atau"
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'atau',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tombol "Lewati / Masuk sebagai Tamu"
                  OutlinedButton.icon(
                    onPressed: _skipLogin,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Lewati / Masuk sebagai Tamu'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      foregroundColor: Colors.grey.shade800,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
