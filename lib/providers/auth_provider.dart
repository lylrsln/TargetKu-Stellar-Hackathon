import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- STATUS LOGIN ---
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  // --- PROFILE PICTURE ---
  String? _profilePicPath;
  String? get profilePicPath => _profilePicPath;

  User? get user => _auth.currentUser;

  // --- SESSION MANAGEMENT (MITIGASI TIMER FREEZE) ---
  // Kita ganti Timer dengan komparasi Timestamp statis yang tahan terhadap background OS sleep
  DateTime? _lastActivityTime;
  static const int _sessionTimeoutMinutes =
      5; // Standar Fintech 3-5 Menit (Jangan 1 menit, terlalu mengganggu)

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _isLoggedIn = true;
        _updateActivityTime();
        loadProfilePic();
      } else {
        _isLoggedIn = false;
        _profilePicPath = null;
        _lastActivityTime = null;
      }
      notifyListeners();
    });
  }

  // --- AUTO LOGIN ---
  Future<bool> tryAutoLogin() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _isLoggedIn = true;
      _updateActivityTime();
      await loadProfilePic();
      notifyListeners();
      return true;
    }
    _isLoggedIn = false;
    notifyListeners();
    return false;
  }

  // --- RELOAD USER ---
  Future<void> reloadUser() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
      await loadProfilePic();
      notifyListeners();
    }
  }

  // ===========================================================================
  // MANAJEMEN SESI (KEAMANAN FINANSIAL MURNI)
  // ===========================================================================

  // Panggil ini setiap ada interaksi di UI (GestureDetector/Listener di main.dart)
  void userActivityDetected() {
    if (_isLoggedIn) {
      _updateActivityTime();
    }
  }

  void _updateActivityTime() {
    _lastActivityTime = DateTime.now();
  }

  // Panggil ini saat aplikasi masuk ke Resumed/Foreground (didChangeAppLifecycleState)
  void checkSessionTimeout() {
    if (!_isLoggedIn || _lastActivityTime == null) return;

    final now = DateTime.now();
    final difference = now.difference(_lastActivityTime!).inMinutes;

    if (difference >= _sessionTimeoutMinutes) {
      debugPrint("Sesi Berakhir (Timeout: $difference menit). Auto Logout.");
      logout();
    } else {
      _updateActivityTime(); // Refresh sesi jika masih valid
    }
  }

  // ===========================================================================
  // OPERASI AUTHENTICATION
  // ===========================================================================

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Email tidak terdaftar di sistem.';
      if (e.code == 'wrong-password') return 'Kata sandi tidak sesuai.';
      if (e.code == 'invalid-email') return 'Format email tidak valid.';
      if (e.code == 'invalid-credential')
        return 'Kredensial salah atau kadaluarsa.';
      return "Gagal masuk: ${e.message}";
    } catch (e) {
      return "Koneksi terputus atau server bermasalah.";
    }
  }

  Future<String?> register(String email, String password, String name) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      await cred.user?.updateDisplayName(name);
      await cred.user?.reload();

      _isLoggedIn = true;
      _updateActivityTime();
      notifyListeners();

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use')
        return 'Email sudah dipakai akun lain.';
      if (e.code == 'weak-password') return 'Gunakan minimal 6 karakter sandi.';
      return "Gagal daftar: ${e.message}";
    } catch (e) {
      return "Sistem pendaftaran gagal diakses.";
    }
  }

  Future<void> logout() async {
    _lastActivityTime = null;
    await _auth.signOut();
    _isLoggedIn = false;
    _profilePicPath = null;
    notifyListeners();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // ===========================================================================
  // MANAJEMEN FOTO PROFIL (ANTI-SANDBOX ROTATION)
  // ===========================================================================

  Future<void> loadProfilePic() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String key = 'profile_foto_name_${currentUser.uid}';

    // [CRITICAL FIX] Ambil NAMA FILE saja, bukan Absolute Path.
    final String? fileName = prefs.getString(key);

    if (fileName != null) {
      final directory = await getApplicationDocumentsDirectory();
      // Bangun ulang absolute path setiap sesi agar kebal rotasi direktori iOS/Android
      final String fullPath = '${directory.path}/$fileName';

      if (File(fullPath).existsSync()) {
        _profilePicPath = fullPath;
      } else {
        _profilePicPath = null;
      }
    } else {
      _profilePicPath = null;
    }
    notifyListeners();
  }

  Future<void> updateProfilePic(String fullPath) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Ambil nama filenya saja (misal: "profile_ABC123.jpg")
    String fileName = fullPath.split('/').last;

    final prefs = await SharedPreferences.getInstance();
    final String key = 'profile_foto_name_${currentUser.uid}';

    await prefs.setString(
        key, fileName); // Hanya simpan string "profile_ABC123.jpg"
    _profilePicPath = fullPath;
    notifyListeners();
  }
}
