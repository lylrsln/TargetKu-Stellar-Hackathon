import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  // --- CONTROLLER (SEKARANG DIKELOLA DENGAN BENAR) ---
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  late TextEditingController _nameCtrl;
  late TextEditingController _emailEditCtrl;

  bool _isObscureOld = true;
  bool _isObscureNew = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailEditCtrl = TextEditingController();
    _loadUserData();
  }

  // [KRUSIAL] Mencegah Memory Leak
  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _nameCtrl.dispose();
    _emailEditCtrl.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameCtrl.text = user.displayName ?? "";
      _emailEditCtrl.text = user.email ?? "";
    }
  }

  // ===========================================================================
  // 1. FITUR FOTO PROFIL
  // ===========================================================================
  void _showFullImage(String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(File(imagePath), fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePhoto(ImageSource source) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final pickedFile = await ImagePicker().pickImage(
          source: source,
          imageQuality: 60); // Dinaikkan sedikit untuk layar modern
      if (pickedFile == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final String newPath = '${directory.path}/profile_${user.uid}.jpg';

      final File newImageFile = File(newPath);
      if (await newImageFile.exists()) {
        await newImageFile.delete();
      }

      await File(pickedFile.path).copy(newPath);

      if (!mounted) return;

      await Provider.of<AuthProvider>(context, listen: false)
          .updateProfilePic(newPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Foto profil diperbarui", style: GoogleFonts.poppins()),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Sistem Gagal: $e", style: GoogleFonts.poppins()),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.camera_alt_rounded,
                      color: Colors.blue.shade600)),
              title: Text("Kamera",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _updatePhoto(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.purple.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.photo_library_rounded,
                      color: Colors.purple.shade600)),
              title: Text("Galeri",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _updatePhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. FITUR GANTI PASSWORD (DIPINDAHKAN KE BOTTOM SHEET AGAR UI CLEAN)
  // ===========================================================================
  void _showChangePasswordSheet() {
    // Reset form
    _oldPassCtrl.clear();
    _newPassCtrl.clear();
    _confirmPassCtrl.clear();
    _isObscureOld = true;
    _isObscureNew = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 20),
              Text("Keamanan Akun",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 5),
              Text("Perbarui kata sandi Anda secara berkala.",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              TextField(
                controller: _oldPassCtrl,
                obscureText: _isObscureOld,
                decoration: _inputDecoration(
                    "Password Lama", Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                          _isObscureOld
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.grey),
                      onPressed: () =>
                          setModalState(() => _isObscureOld = !_isObscureOld),
                    )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPassCtrl,
                obscureText: _isObscureNew,
                decoration: _inputDecoration(
                    "Password Baru", Icons.lock_reset_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                          _isObscureNew
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.grey),
                      onPressed: () =>
                          setModalState(() => _isObscureNew = !_isObscureNew),
                    )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPassCtrl,
                obscureText: true,
                decoration: _inputDecoration(
                    "Ulangi Password Baru", Icons.done_all_rounded),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _executeChangePassword();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: Text("Perbarui Password",
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }

  void _executeChangePassword() async {
    if (_oldPassCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("Semua kolom harus diisi!", style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating));
      return;
    }

    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("Konfirmasi tidak cocok!", style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null)
        throw Exception("Sesi pengguna tidak valid.");

      AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!, password: _oldPassCtrl.text);

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPassCtrl.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Password diperbarui! Silakan login ulang.",
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating));

      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (r) => false);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Gagal: Otentikasi salah atau menggunakan Google Sign-In.",
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Gagal: $e", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await Provider.of<AuthProvider>(context, listen: false).reloadUser();
    _loadUserData();
  }

  // ===========================================================================
  // 3. FITUR HAPUS AKUN
  // ===========================================================================
  void _deleteAccount() async {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Text("Hapus Permanen?",
                style: GoogleFonts.poppins(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Aksi ini tidak dapat dibatalkan. Semua data target dan transaksi Anda akan musnah.",
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 20),
            TextField(
                controller: passCtrl,
                obscureText: true,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _inputDecoration(
                    "Konfirmasi Password", Icons.lock_clock_rounded)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Batal",
                  style: GoogleFonts.poppins(color: Colors.grey.shade600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              if (passCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              _performDelete(passCtrl.text);
            },
            child: Text("Hancurkan Akun",
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }

  void _performDelete(String password) async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!, password: password);
        await user.reauthenticateWithCredential(credential);
        await user.delete();

        if (!mounted) return;
        await Provider.of<AuthProvider>(context, listen: false).logout();

        if (mounted) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (r) => false);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Otentikasi gagal. Jika menggunakan Google Sign-In, sistem ini memerlukan penyesuaian khusus.",
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- WIDGET HELPER ---
  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text("Profil Saya",
            style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF1565C0),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1565C0)))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  children: [
                    // --- 1. UI FOTO PROFIL ---
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (auth.profilePicPath != null &&
                                  File(auth.profilePicPath!).existsSync()) {
                                _showFullImage(auth.profilePicPath!);
                              }
                            },
                            child: Hero(
                              tag: 'profile_pic',
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      )
                                    ]),
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: auth.profilePicPath !=
                                              null &&
                                          File(auth.profilePicPath!)
                                              .existsSync()
                                      ? FileImage(File(auth.profilePicPath!))
                                      : null,
                                  child: auth.profilePicPath == null
                                      ? Icon(Icons.person_rounded,
                                          size: 50, color: Colors.grey.shade400)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFF8F9FD), width: 3),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 18, color: Colors.white),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(user?.displayName ?? "User",
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    Text(user?.email ?? "-",
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 40),

                    // --- 2. FORM DATA DIRI ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Data Akun",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87)),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameCtrl,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: _inputDecoration(
                                "Username", Icons.person_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF1565C0)),
                                  tooltip: "Simpan Nama",
                                  onPressed: () async {
                                    FocusScope.of(context).unfocus();
                                    setState(() => _isLoading = true);
                                    await user?.updateDisplayName(
                                        _nameCtrl.text.trim());
                                    await auth.reloadUser();
                                    setState(() => _isLoading = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  "Username diperbarui",
                                                  style: GoogleFonts.poppins()),
                                              backgroundColor:
                                                  Colors.green.shade600,
                                              behavior:
                                                  SnackBarBehavior.floating));
                                    }
                                  },
                                )),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailEditCtrl,
                            readOnly: true,
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.grey.shade600),
                            decoration: InputDecoration(
                                labelText: "Email Tersimpan",
                                labelStyle: GoogleFonts.poppins(
                                    fontSize: 13, color: Colors.grey.shade500),
                                prefixIcon: Icon(Icons.email_outlined,
                                    color: Colors.grey.shade400, size: 20),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- 3. MENU PENGATURAN LAINNYA ---
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ]),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.security_rounded,
                                    color: Colors.orange.shade700, size: 20)),
                            title: Text("Keamanan & Sandi",
                                style: GoogleFonts.poppins(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                            trailing: const Icon(Icons.chevron_right_rounded,
                                color: Colors.grey),
                            onTap: _showChangePasswordSheet,
                          ),
                          Divider(
                              color: Colors.grey.shade100,
                              height: 1,
                              indent: 60),
                          ListTile(
                            leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.logout_rounded,
                                    color: Colors.red.shade600, size: 20)),
                            title: Text("Keluar Akun",
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red.shade700)),
                            onTap: () async {
                              await auth.logout();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const LoginScreen()),
                                    (r) => false);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- 4. ZONA MERAH (DANGER ZONE) ---
                    TextButton.icon(
                      onPressed: _deleteAccount,
                      icon: Icon(Icons.delete_forever_rounded,
                          color: Colors.red.shade400, size: 18),
                      label: Text("Hapus Akun Secara Permanen",
                          style: GoogleFonts.poppins(
                              color: Colors.red.shade400,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }
}
