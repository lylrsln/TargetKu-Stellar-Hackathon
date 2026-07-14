import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// [WAJIB] Gunakan FlutterFire CLI untuk meng-generate file ini.
// Jangan pernah menaruh API Key secara hardcode di main.dart!
import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'providers/financial_provider.dart';
import 'views/login_screen.dart';
import 'views/dashboard_view.dart';
import 'views/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 1. INISIALISASI FIREBASE (AMAN & MULTI-PLATFORM) ---
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- 2. FORMAT TANGGAL INDONESIA ---
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // A. Auth Provider (Keamanan & Session)
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // B. Financial Provider (Tarik data finansial setelah Auth siap)
        ChangeNotifierProxyProvider<AuthProvider, FinancialProvider>(
          create: (_) => FinancialProvider(),
          update: (ctx, auth, prev) {
            final provider = prev ?? FinancialProvider();
            // Cegah fetch data jika belum login murni
            if (auth.isLoggedIn && auth.user != null) {
              provider.fetchData();
            }
            return provider;
          },
        ),
      ],
      // [SECURITY: Listener untuk menangkap segala sentuhan layar]
      child: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          return Listener(
            behavior: HitTestBehavior.translucent, // Tangkap semua sentuhan
            onPointerDown: (_) => auth.userActivityDetected(),
            onPointerMove: (_) => auth.userActivityDetected(),
            child: MaterialApp(
              title: 'TargetKu Pro',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme:
                    ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
                useMaterial3: true,
                textTheme: GoogleFonts.poppinsTextTheme(),
                scaffoldBackgroundColor: const Color(0xFFF5F7FA),
                appBarTheme: const AppBarTheme(
                  surfaceTintColor: Colors
                      .transparent, // Mencegah warna AppBar berubah saat di-scroll
                ),
              ),
              home: const AuthWrapper(),
            ),
          );
        },
      ),
    );
  }
}

// --- LOGIKA GATEKEEPER & LIFECYCLE ---
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool? _seenOnboarding;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOnboarding();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // --- LOGIKA BACKGROUND APP (SENTRALISASI KE AUTH PROVIDER) ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (state == AppLifecycleState.resumed) {
      // Delegasikan logika kalkulasi waktu sepenuhnya ke AuthProvider
      // main.dart tidak usah ikut campur menghitung menit/detik.
      auth.checkSessionTimeout();
    }
  }

  void _checkOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
      });
    } catch (e) {
      // Fallback aman jika SharedPreferences gagal dimuat
      setState(() {
        _seenOnboarding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Loading Awal
    if (_seenOnboarding == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1565C0),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // 2. Rute Pengguna Baru -> Tutorial/Onboarding
    if (_seenOnboarding == false) {
      return const OnboardingScreen();
    }

    // 3. Rute Cek Otentikasi
    return Consumer<AuthProvider>(
      builder: (ctx, auth, _) {
        if (auth.isLoggedIn) {
          return const DashboardView();
        }

        // Auto Login Resolver (Misal: App baru dibuka, cek memori token Firebase)
        return FutureBuilder<bool>(
          future: auth.tryAutoLogin(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                ),
              );
            }
            // Jika token tidak ada / sesi habis -> Kembali ke Login
            return const LoginScreen();
          },
        );
      },
    );
  }
}
