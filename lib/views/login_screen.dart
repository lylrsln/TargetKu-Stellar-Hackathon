import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'dashboard_view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isObscure = true;
  bool _rememberMe = false;

  // --- VARIABEL BARU UNTUK PESAN ERROR INLINE ---
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // --- LOAD PREFERENCES ---
  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    bool remember = prefs.getBool('remember_me') ?? false;
    if (remember) {
      String savedEmail = prefs.getString('saved_email') ?? "";
      setState(() {
        _rememberMe = true;
        _emailCtrl.text = savedEmail;
      });
    }
  }

  // --- FUNGSI LOGIN ---
  void _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    // Reset pesan error setiap kali tombol ditekan
    setState(() {
      _errorMessage = null;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Email dan Password tidak boleh kosong.";
      });
      return;
    }

    setState(() => _isLoading = true);

    String? error = await Provider.of<AuthProvider>(context, listen: false)
        .login(email, password);

    if (mounted) setState(() => _isLoading = false);

    if (error != null) {
      // Tampilkan error langsung di layar, BUKAN di SnackBar
      if (mounted) {
        setState(() {
          _errorMessage = error;
        });
      }
    } else {
      // 1. Simpan Preferensi "Ingat Saya"
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('saved_email', email);
      } else {
        await prefs.remove('remember_me');
        await prefs.remove('saved_email');
      }

      // 2. Langsung pindah ke Dashboard & hapus history rute
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardView()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- LOGO & HEADER ---
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 45,
                    height: 45,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Selamat Datang!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  "Masuk untuk pantau target keuanganmu",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 40),

                // --- INPUT EMAIL ---
                TextField(
                  controller: _emailCtrl,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(fontSize: 14),
                  // Menghilangkan error message saat user mulai mengetik ulang
                  onChanged: (val) {
                    if (_errorMessage != null)
                      setState(() => _errorMessage = null);
                  },
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle:
                        GoogleFonts.poppins(color: Colors.grey.shade600),
                    hintText: "Contoh: user@email.com",
                    prefixIcon:
                        Icon(Icons.email_outlined, color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFF1565C0), width: 1.5)),
                    disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade100)),
                  ),
                ),
                const SizedBox(height: 20),

                // --- INPUT PASSWORD ---
                TextField(
                  controller: _passCtrl,
                  enabled: !_isLoading,
                  obscureText: _isObscure,
                  style: GoogleFonts.poppins(fontSize: 14),
                  // Menghilangkan error message saat user mulai mengetik ulang
                  onChanged: (val) {
                    if (_errorMessage != null)
                      setState(() => _errorMessage = null);
                  },
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle:
                        GoogleFonts.poppins(color: Colors.grey.shade600),
                    prefixIcon: Icon(Icons.lock_outline_rounded,
                        color: Colors.grey.shade500),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _isObscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.grey.shade500),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: Color(0xFF1565C0), width: 1.5)),
                    disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade100)),
                  ),
                ),
                const SizedBox(height: 12),

                // --- REMEMBER ME & FORGOT PASSWORD ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: const Color(0xFF1565C0),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            side: BorderSide(color: Colors.grey.shade400),
                            onChanged: _isLoading
                                ? null
                                : (val) => setState(() => _rememberMe = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text("Ingat Saya",
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.grey.shade700)),
                      ],
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_emailCtrl.text.trim().isNotEmpty) {
                                Provider.of<AuthProvider>(context,
                                        listen: false)
                                    .resetPassword(_emailCtrl.text.trim());
                                // SnackBar masih cocok untuk notifikasi sukses (Lupa Sandi)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "Tautan reset email telah dikirim!",
                                          style: GoogleFonts.poppins()),
                                      backgroundColor: Colors.green.shade600,
                                      behavior: SnackBarBehavior.floating),
                                );
                              } else {
                                setState(() {
                                  _errorMessage =
                                      "Isi email terlebih dahulu untuk reset sandi!";
                                });
                              }
                            },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text("Lupa Sandi?",
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Spasi sebelum area tombol/error

                // --- BOKS PESAN ERROR INLINE ---
                if (_errorMessage != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              color: Colors.red.shade800,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // --- TOMBOL MASUK ---
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      disabledBackgroundColor:
                          const Color(0xFF1565C0).withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text("Masuk",
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 32),

                // --- TOMBOL DAFTAR ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Belum punya akun? ",
                        style: GoogleFonts.poppins(
                            color: Colors.grey.shade600, fontSize: 13)),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen()));
                            },
                      child: Text("Daftar Sekarang",
                          style: GoogleFonts.poppins(
                              color: const Color(0xFF1565C0),
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
