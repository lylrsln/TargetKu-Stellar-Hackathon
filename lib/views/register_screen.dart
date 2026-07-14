import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'dashboard_view.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController(); // [BARU] Mencegah typo

  bool _isLoading = false;
  bool _isObscure = true;
  bool _isObscureConfirm = true;

  // [KRUSIAL] Bersihkan memori saat widget mati
  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirmPass = _confirmPassCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirmPass.isEmpty) {
      _showSnackbar("Semua kolom harus diisi!", Colors.orange.shade800);
      return;
    }

    if (pass != confirmPass) {
      _showSnackbar("Konfirmasi password tidak cocok!", Colors.orange.shade800);
      return;
    }

    if (pass.length < 6) {
      _showSnackbar("Password minimal 6 karakter!", Colors.orange.shade800);
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    String? error = await auth.register(email, pass, name);

    if (mounted) setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardView()),
            (route) => false);
      }
    } else {
      _showSnackbar("Gagal: $error", Colors.red.shade700);
    }
  }

  void _showSnackbar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- LOGO & HEADER ---
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
                child: Image.asset(
                  'assets/logo.png',
                  width:
                      45, // Ukuran diatur lebih kecil dari diameter (80) agar tidak menabrak batas lingkaran
                  height: 45,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Buat Akun Baru",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                "Lengkapi data diri kamu untuk mulai",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 40),

              // --- INPUT NAMA ---
              TextField(
                controller: _nameCtrl,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _inputDecoration(
                    "Nama Panggilan", Icons.person_outline_rounded),
              ),
              const SizedBox(height: 20),

              // --- INPUT EMAIL ---
              TextField(
                controller: _emailCtrl,
                enabled: !_isLoading,
                keyboardType:
                    TextInputType.emailAddress, // Keyboard khusus email
                style: GoogleFonts.poppins(fontSize: 14),
                decoration:
                    _inputDecoration("Email Aktif", Icons.email_outlined),
              ),
              const SizedBox(height: 20),

              // --- INPUT PASSWORD ---
              TextField(
                controller: _passCtrl,
                enabled: !_isLoading,
                obscureText: _isObscure,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _inputDecoration(
                  "Password",
                  Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _isObscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: Colors.grey.shade500),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- INPUT KONFIRMASI PASSWORD ---
              TextField(
                controller: _confirmPassCtrl,
                enabled: !_isLoading,
                obscureText: _isObscureConfirm,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _inputDecoration(
                  "Ulangi Password",
                  Icons.lock_reset_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _isObscureConfirm
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: Colors.grey.shade500),
                    onPressed: () =>
                        setState(() => _isObscureConfirm = !_isObscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // --- TOMBOL DAFTAR ---
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                      : Text("Daftar Sekarang",
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: Colors.white)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helper untuk styling form agar konsisten dengan LoginScreen
  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: Colors.grey.shade500),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5)),
      disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade100)),
    );
  }
}
