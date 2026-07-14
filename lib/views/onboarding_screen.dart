import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // --- DATA HALAMAN ONBOARDING (REVISED COPYWRITING & ASSETS) ---
  final List<Map<String, dynamic>> _pages = [
    {
      "title": "Bye-Bye Dompet Kosong",
      "desc":
          "Catat tiap rupiah yang keluar masuk. Nggak ada lagi drama uang jajan habis padahal baru awal bulan.",
      "type": "image",
      "data": "assets/maskot_cewe.png", // Maskot 1 (Cewe)
    },
    {
      "title": "AI Financial Bestie",
      "desc":
          "Sistem Pakar kami siap nge-roasting kalau kamu mulai boros, dan kasih approval kalau emang waktunya self-reward.",
      "type": "image",
      "data": "assets/maskot_cowo.png", // Maskot 2 (Cowo)
    },
    {
      "title": "Wujudin Wishlist-mu",
      "desc":
          "Mau beli tiket konser atau nabung laptop? Bikin target, set deadline, dan biarin kami yang hitung harianmu.",
      "type": "icon", // Halaman terakhir tetap Ikon untuk efek "Launch"
      "data": Icons.rocket_launch_rounded,
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- FUNGSI SELESAI ONBOARDING ---
  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    if (mounted) {
      // Transisi Halus (Fade) menuju layar Login
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Warna latar lebih lembut
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. HEADER (LOGO.PNG KUNCI) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/logo.png', // <--- Logo Proyek
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.blur_on,
                        color: Color(0xFF1565C0)), // Fallback modern
                  ),

                  // Efek menghilang (fade-out) pada tombol Skip saat berada di halaman terakhir
                  AnimatedOpacity(
                    opacity: _currentPage == _pages.length - 1 ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: TextButton(
                      onPressed: _currentPage == _pages.length - 1
                          ? null
                          : _finishOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                      ),
                      child: Text("Lewati",
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. KONTEN GESER (SLIDER) ---
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(), // Efek pantulan modern
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // BAGIAN ILUSTRASI (PENGGUNAAN MASKOT RASTER)
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: AnimatedScale(
                              scale: _currentPage == index ? 1.0 : 0.8,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutBack,
                              child: _buildIllustration(index),
                            ),
                          ),
                        ),

                        // BAGIAN TEKS
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              Text(
                                _pages[index]["title"],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1565C0),
                                    height: 1.2),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _pages[index]["desc"],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // --- 3. NAVIGASI BAWAH (TITIK & TOMBOL) ---
            Container(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
              child: Column(
                children: [
                  // Indikator Titik-Titik (Dots)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF1565C0)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tombol Utama
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _finishOnboarding();
                        } else {
                          _controller.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve:
                                  Curves.easeOutQuint); // Kurva lebih dinamis
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? "MULAI SEKARANG"
                            : "LANJUT",
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk menampilkan Gambar (Maskot) atau Icon dengan ornamen UI
  Widget _buildIllustration(int index) {
    var item = _pages[index];

    if (item['type'] == 'image') {
      // Pembungkus untuk memberikan aksen bayangan lembut di belakang maskot raster
      return Container(
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.08),
            blurRadius: 40,
            spreadRadius: 20,
          )
        ]),
        child: Image.asset(
          item['data'],
          height: 240, // Sedikit lebih besar agar maskot terlihat jelas
          fit: BoxFit.contain,
          // Fallback jika file PNG tidak ditemukan di direktori assets
          errorBuilder: (ctx, err, stack) =>
              _buildIconPlaceholder(Icons.broken_image_rounded),
        ),
      );
    } else {
      return _buildIconPlaceholder(item['data']);
    }
  }

  Widget _buildIconPlaceholder(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(45),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
            ]),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 90, color: const Color(0xFF1565C0)),
    );
  }
}
