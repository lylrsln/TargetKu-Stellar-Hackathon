import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../providers/financial_provider.dart';
import '../providers/auth_provider.dart';
import 'form_transaksi_screen.dart';
import 'target_views.dart';
import 'profile_view.dart';
import 'laporan_view.dart';

// ====================================================
// WIDGET KARTU GRAFIK INTERAKTIF (DINAMIS)
// ====================================================
class AnalitikGrafikCard extends StatefulWidget {
  final List<double> dataPengeluaran;
  final List<double> dataPemasukan;
  final int jumlahHari;

  const AnalitikGrafikCard({
    super.key,
    required this.dataPengeluaran,
    required this.dataPemasukan,
    required this.jumlahHari,
  });

  @override
  State<AnalitikGrafikCard> createState() => _AnalitikGrafikCardState();
}

class _AnalitikGrafikCardState extends State<AnalitikGrafikCard> {
  int _selectedIndex = 0; // 0 = Pengeluaran, 1 = Pemasukan

  @override
  Widget build(BuildContext context) {
    bool isPengeluaran = _selectedIndex == 0;
    List<double> currentData =
        isPengeluaran ? widget.dataPengeluaran : widget.dataPemasukan;
    Color chartColor =
        isPengeluaran ? Colors.red.shade400 : Colors.green.shade400;

    String judulArusKas =
        isPengeluaran ? "Arus Pengeluaran Harian" : "Arus Pemasukan Harian";

    double chartWidth = widget.jumlahHari * 35.0;
    double screenWidth = MediaQuery.of(context).size.width - 80;
    if (chartWidth < screenWidth) chartWidth = screenWidth;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                judulArusKas,
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Container(
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ToggleButtons(
                  isSelected: [_selectedIndex == 0, _selectedIndex == 1],
                  onPressed: (index) => setState(() => _selectedIndex = index),
                  color: Colors.grey,
                  selectedColor: Colors.white,
                  fillColor: _selectedIndex == 0
                      ? Colors.red.shade600
                      : Colors.green.shade600,
                  borderRadius: BorderRadius.circular(10),
                  constraints:
                      const BoxConstraints(minWidth: 50, minHeight: 35),
                  children: const [
                    Icon(Icons.arrow_upward, size: 18),
                    Icon(Icons.arrow_downward, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Geser horizontal untuk melihat tanggal",
            style: TextStyle(
                fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: chartWidth,
              height: 150,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          int day = value.toInt();
                          if (day == 1 ||
                              day % 5 == 0 ||
                              day == widget.jumlahHari) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                "$day",
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.blueGrey.shade400,
                                    fontWeight: FontWeight.w600),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(
                    widget.jumlahHari,
                    (index) {
                      double yValue = (index + 1 < currentData.length)
                          ? currentData[index + 1]
                          : 0.0;
                      return BarChartGroupData(
                        x: index + 1,
                        barRods: [
                          BarChartRodData(
                            toY: yValue,
                            color: chartColor,
                            width: 14,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// WIDGET UTAMA DASHBOARD
// ====================================================
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _selectedIndex = 0;
  DateTime? _lastPressedAt;

  final GlobalKey _keyTips = GlobalKey();
  final GlobalKey _keyNotif = GlobalKey();
  final GlobalKey _keyBulan = GlobalKey();
  final GlobalKey _keyAnalisa = GlobalKey();
  final GlobalKey _keyFab = GlobalKey();
  final GlobalKey _keyHome = GlobalKey();
  final GlobalKey _keyTarget = GlobalKey();
  final GlobalKey _keyLaporan = GlobalKey();
  final GlobalKey _keyAkun = GlobalKey();
  final GlobalKey _keyTx = GlobalKey();
  final GlobalKey _keyGrafik = GlobalKey();

  late TutorialCoachMark tutorialCoachMark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeUser();
      _checkAndShowTutorial();
      Provider.of<FinancialProvider>(context, listen: false).fetchData();
    });
  }

  void _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    bool isWelcomeShown = prefs.getBool('welcome_popup_shown') ?? false;

    if (!isWelcomeShown) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.waving_hand, color: Colors.orange),
                SizedBox(width: 10),
                Text("Selamat Datang!"),
              ],
            ),
            content: const Text(
              "Halo! 👋\n\nTargetKu siap membantumu mengatur keuangan. Mulai dengan mencatat pengeluaran pertamamu ya!",
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0)),
                onPressed: () {
                  Navigator.pop(ctx);
                  prefs.setBool('welcome_popup_shown', true);
                },
                child:
                    const Text("Siap!", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        );
      }
    }
  }

  void _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSeenTutorial = prefs.getBool('seen_dashboard_v6_full') ?? false;

    if (!hasSeenTutorial) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _initTutorial();
          tutorialCoachMark.show(context: context);
          prefs.setBool('seen_dashboard_v6_full', true);
        }
      });
    }
  }

  void _initTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: [
        _buildTarget(
          _keyNotif,
          "Status & Notifikasi Anggaran",
          "Lonceng ini berfungsi memantau kesehatan keuanganmu. Jika batas anggaran per kategori terlewati atau mendekati limit, peringatan sistem akan langsung muncul di sini.",
          ContentAlign.bottom,
        ),
        _buildTarget(
          _keyTips,
          "Tips Hemat Harian",
          "Komponen ini menyajikan edukasi finansial praktis yang berganti secara dinamis setiap kali aplikasi disegarkan (refresh).",
          ContentAlign.bottom,
        ),
        _buildTarget(
          _keyBulan,
          "Navigasi Laporan Bulanan",
          "Gunakan tombol panah atau ketuk teks bulan untuk beralih dan melihat riwayat keuangan serta sisa saldo pada bulan-bulan sebelumnya.",
          ContentAlign.bottom,
        ),
        _buildTarget(
          _keyGrafik,
          "Visualisasi Arus Kas",
          "Grafik interaktif harian. Kamu bisa mengubah visualisasi antara data Pengeluaran atau Pemasukan harian melalui tombol toggle yang tersedia.",
          ContentAlign.top,
        ),
        _buildTarget(
          _keyAnalisa,
          "Metrik Rata-rata Harian",
          "Memantau seberapa besar laju pengeluaran harianmu secara rata-rata untuk mengukur efisiensi cashflow bulanan.",
          ContentAlign.top,
        ),
        _buildTarget(
          _keyTarget,
          "Monitoring Target Keuangan",
          "Memantau progres pencapaian target/wishlist tabungan secara real-time langsung dari beranda.",
          ContentAlign.top,
        ),
        _buildTarget(
          _keyTx,
          "Histori Transaksi Terakhir",
          "Menampilkan daftar pengeluaran dan pemasukan terbaru. Kamu dapat menghapus riwayat transaksi dengan cara menahan lama (long press) pada baris terkait.",
          ContentAlign.top,
        ),
        _buildTarget(
          _keyFab,
          "Pencatatan Transaksi Baru",
          "Ketuk tombol '+' ini setiap kali kamu melakukan transaksi agar data analisis sistem tetap akurat dan mutakhir.",
          ContentAlign.top,
        ),
      ],
      colorShadow: const Color(0xFF1565C0),
      textSkip: "LEWATI",
      paddingFocus: 8,
      opacityShadow: 0.9,
    );
  }

  TargetFocus _buildTarget(
      GlobalKey key, String title, String desc, ContentAlign align) {
    return TargetFocus(
      identify: title,
      keyTarget: key,
      shape: ShapeLightFocus.RRect,
      radius: 12,
      contents: [
        TargetContent(
          align: align,
          builder: (context, controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18)),
                const SizedBox(height: 8),
                Text(desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, height: 1.4)),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showNotificationPopup(BuildContext context, List<dynamic> listNotif) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.notifications_active, color: Color(0xFF1565C0)),
          SizedBox(width: 10),
          Text("Status Anggaran")
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: listNotif.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "Semua anggaran kategori aman terkendali. Belum ada peringatan limit bulan ini.",
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: listNotif.length,
                  itemBuilder: (c, i) {
                    String type = listNotif[i]['type'] ?? 'info';
                    Color color = type == 'danger'
                        ? Colors.red
                        : (type == 'warning' ? Colors.orange : Colors.green);
                    IconData icon = type == 'danger'
                        ? Icons.error
                        : (type == 'warning'
                            ? Icons.warning
                            : Icons.check_circle);
                    Color bgColor = type == 'danger'
                        ? Colors.red.shade50
                        : (type == 'warning'
                            ? Colors.orange.shade50
                            : Colors.green.shade50);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withOpacity(0.3))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: color, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(listNotif[i]['title']!,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                      fontSize: 13)),
                              const SizedBox(height: 3),
                              Text(listNotif[i]['body']!,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black87)),
                            ],
                          )),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Tutup",
                  style: TextStyle(
                      color: Color(0xFF1565C0), fontWeight: FontWeight.bold)))
        ],
      ),
    );
  }

  void _showProfileImagePreview(BuildContext context, String path) {
    showDialog(
        context: context,
        builder: (ctx) => Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Hero(
                    tag: 'profile_pic',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        File(path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -10,
                    right: -10,
                    child: IconButton(
                      icon: const Icon(Icons.cancel,
                          color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  )
                ],
              ),
            ));
  }

  void _pickMonthYear(BuildContext context, FinancialProvider fin) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fin.selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: "PILIH PERIODE",
    );
    if (picked != null) fin.setMonth(picked);
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour >= 0 && hour < 11) return "Selamat Pagi";
    if (hour >= 11 && hour < 15) return "Selamat Siang";
    if (hour >= 15 && hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  String _formatRp(double value) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)
        .format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FinancialProvider, AuthProvider>(
      builder: (context, fin, auth, child) {
        String namaBulan =
            DateFormat('MMMM yyyy', 'id_ID').format(fin.selectedMonth);
        int hariDalamBulan =
            DateTime(fin.selectedMonth.year, fin.selectedMonth.month + 1, 0)
                .day;

        var notifList = fin.statusAnggaranNotifikasi;
        bool hasWarning = notifList
            .any((n) => n['type'] == 'danger' || n['type'] == 'warning');

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final now = DateTime.now();
            if (_lastPressedAt == null ||
                now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
              _lastPressedAt = now;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Tekan sekali lagi untuk keluar"),
                  duration: Duration(seconds: 2)));
            } else {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FD),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1565C0),
              elevation: 0,
              toolbarHeight: 70,
              titleSpacing: 20,
              title: Row(
                children: [
                  // Ini kode untuk memanggil logo kamu
                  Image.asset(
                    'assets/logo.png',
                    width: 32, // Bisa kamu sesuaikan ukurannya
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text("TargetKu",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                ],
              ),
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                        key: _keyNotif,
                        onPressed: () =>
                            _showNotificationPopup(context, notifList),
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 28)),
                    if (hasWarning || notifList.isNotEmpty)
                      Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  color: hasWarning ? Colors.red : Colors.green,
                                  shape: BoxShape.circle)))
                  ],
                ),
                const SizedBox(width: 10),
              ],
            ),
            body: Column(
              children: [
                Container(
                  color: const Color(0xFF1565C0),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (auth.profilePicPath != null &&
                              File(auth.profilePicPath!).existsSync()) {
                            _showProfileImagePreview(
                                context, auth.profilePicPath!);
                          } else {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ProfileView()));
                          }
                        },
                        child: Hero(
                          tag: 'profile_pic',
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white24,
                            backgroundImage: auth.profilePicPath != null &&
                                    File(auth.profilePicPath!).existsSync()
                                ? FileImage(File(auth.profilePicPath!))
                                : null,
                            child: auth.profilePicPath == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getGreeting(),
                                style: GoogleFonts.poppins(
                                    color: Colors.white70, fontSize: 13)),
                            Text(auth.user?.displayName ?? "User",
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17)),
                          ])
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF1565C0),
                    onRefresh: () async {
                      await Future.wait([auth.reloadUser(), fin.refreshData()]);
                      setState(() {});
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      child: Column(
                        children: [
                          _buildDailyTip(),
                          const SizedBox(height: 20),
                          _buildSummaryCard(
                              context,
                              fin,
                              fin.pemasukanBulanIni,
                              fin.pengeluaranBulanIni,
                              fin.sisaSaldoBulanIni,
                              namaBulan),
                          const SizedBox(height: 20),
                          Container(
                            key: _keyGrafik,
                            child: AnalitikGrafikCard(
                              dataPengeluaran: fin.pengeluaranHarianBulanIni,
                              dataPemasukan: fin.pemasukanHarianBulanIni,
                              jumlahHari: hariDalamBulan,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSimpleAnalisaCard(fin.rataRataHarianBulanIni),
                          const SizedBox(height: 25),
                          _buildCategorySection(context, fin),
                          const SizedBox(height: 25),
                          _buildTargetSection(context, fin),
                          const SizedBox(height: 25),
                          _buildRecentTransactions(context, fin),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: SizedBox(
              key: _keyFab,
              height: 60,
              width: 60,
              child: FloatingActionButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FormTransaksiScreen())),
                backgroundColor: const Color(0xFF1565C0),
                shape: const CircleBorder(),
                elevation: 4,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: BottomAppBar(
              height: 75,
              color: Colors.white,
              surfaceTintColor: Colors.white,
              shape: const CircularNotchedRectangle(),
              notchMargin: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    _buildNavItem(Icons.home_rounded, "Beranda", 0, _keyHome),
                    const SizedBox(width: 4),
                    _buildNavItem(
                        Icons.track_changes_rounded, "Target", 1, _keyTarget)
                  ]),
                  Row(children: [
                    _buildNavItem(
                        Icons.pie_chart_rounded, "Laporan", 2, _keyLaporan),
                    const SizedBox(width: 4),
                    _buildNavItem(Icons.person_rounded, "Akun", 3, _keyAkun)
                  ])
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, FinancialProvider fin,
      double pemasukan, double pengeluaran, double sisa, String namaBulan) {
    return Container(
      key: _keyBulan,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 8))
          ]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
              onPressed: () => fin.changeMonth(-1),
              icon: const Icon(Icons.chevron_left)),
          InkWell(
              onTap: () => _pickMonthYear(context, fin),
              child: Row(children: [
                Text(namaBulan,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(width: 5),
                const Icon(Icons.arrow_drop_down,
                    size: 20, color: Colors.black54)
              ])),
          IconButton(
              onPressed: () => fin.changeMonth(1),
              icon: const Icon(Icons.chevron_right))
        ]),
        const Divider(),
        const Text("Sisa Saldo Bulan Ini",
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        Text(_formatRp(sisa),
            style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: sisa >= 0 ? const Color(0xFF1565C0) : Colors.red)),
        const SizedBox(height: 20),
        Row(children: [
          _summaryItem("Pemasukan", pemasukan, Colors.green),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          _summaryItem("Pengeluaran", pengeluaran, Colors.red)
        ]),
      ]),
    );
  }

  Widget _summaryItem(String label, double amount, Color color) {
    return Expanded(
        child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text(
          NumberFormat.compactCurrency(locale: 'id', symbol: 'Rp')
              .format(amount),
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, fontSize: 15, color: color))
    ]));
  }

  Widget _buildSimpleAnalisaCard(double rataRata) {
    return Container(
        key: _keyAnalisa,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF1565C0)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 8))
            ]),
        child: Row(children: [
          const Icon(Icons.analytics_rounded, color: Colors.white, size: 45),
          const SizedBox(width: 15),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text("Rata-rata Pengeluaran",
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 5),
                Text("${_formatRp(rataRata)} / hari",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold))
              ]))
        ]));
  }

  Widget _buildDailyTip() {
    final List<String> tips = [
      "Bawa botol minum sendiri setiap ke kampus, hemat hingga Rp150.000 per bulan.",
      "Terapkan aturan 24 jam sebelum checkout barang online untuk menghindari impulsive buying.",
      "Sisihkan jatah tabungan di AWAL bulan segera setelah kiriman tiba, jangan tunggu sisa akhir bulan.",
      "Gunakan kupon atau diskon kemahasiswaan khusus saat berlangganan software atau kuota data.",
      "Masak atau bawa bekal mandiri minimal 3 hari seminggu guna meredam bocor halus biaya makan.",
      "Catat pengeluaran maksimal 1 jam setelah transaksi agar kalkulasi anggaran tetap akurat.",
      "Hapus aplikasi marketplace sementara waktu jika target tabunganmu sedang dalam fase kritis.",
      "Kurangi frekuensi nongkrong berbayar di kafe, manfaatkan ruang fasilitas bersama atau wifi kampus.",
    ];
    String randomTip = tips[Random().nextInt(tips.length)];

    return Container(
      key: _keyTips,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade100)),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.savings_rounded,
                color: Colors.orange, size: 24)),
        const SizedBox(width: 15),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Tips Hemat Harian",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                  fontSize: 12)),
          const SizedBox(height: 4),
          Text(randomTip,
              style: TextStyle(
                  fontSize: 13, color: Colors.brown.shade800, height: 1.35))
        ]))
      ]),
    );
  }

  Widget _buildCategorySection(BuildContext context, FinancialProvider fin) {
    var breakdown = fin.pengeluaranPerKategori;
    var allCats = fin.budgetLimits.keys.toSet()..addAll(breakdown.keys);
    var activeCats = allCats.where((k) {
      double spent = breakdown[k] ?? 0;
      double limit = fin.budgetLimits[k] ?? 0;
      return spent > 0 || limit > 0;
    }).toList();

    activeCats.sort((a, b) {
      double progA = (fin.budgetLimits[a] ?? 1) > 0
          ? (breakdown[a] ?? 0) / (fin.budgetLimits[a] ?? 1)
          : ((breakdown[a] ?? 0) > 0 ? 100 : 0);
      double progB = (fin.budgetLimits[b] ?? 1) > 0
          ? (breakdown[b] ?? 0) / (fin.budgetLimits[b] ?? 1)
          : ((breakdown[b] ?? 0) > 0 ? 100 : 0);
      return progB.compareTo(progA);
    });

    var displayKeys = activeCats.take(10).toList();

    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Monitoring Anggaran",
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const Text("(Tekan bar untuk detail & edit)",
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic)),
            ]),
          ),
          TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LaporanView())),
              child: const Text("Detail",
                  style: TextStyle(color: Color(0xFF1565C0))))
        ]),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: const Offset(0, 8))
              ]),
          child: displayKeys.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Text("Data bulan ini bersih dari pengeluaran.",
                        style: TextStyle(
                            color: Colors.grey, fontStyle: FontStyle.italic)),
                  ))
              : Column(
                  children: displayKeys.map((k) {
                    double currentSpent = breakdown[k] ?? 0;
                    double limit = fin.budgetLimits[k] ?? 0;
                    double progress = (limit > 0)
                        ? (currentSpent / limit)
                        : (currentSpent > 0 ? 1.0 : 0.0);
                    double displayProgress = progress > 1.0 ? 1.0 : progress;

                    Color barColor;
                    String statusText;
                    IconData statusIcon;
                    if (limit == 0) {
                      barColor = Colors.blue;
                      statusText = "∞ Tanpa Batas";
                      statusIcon = Icons.info_outline;
                    } else if (progress >= 1.0) {
                      barColor = Colors.red;
                      statusText = "JEBOL!";
                      statusIcon = Icons.warning_amber_rounded;
                    } else if (progress >= 0.7) {
                      barColor = Colors.orange;
                      statusText = "Hati-hati (${(progress * 100).toInt()}%)";
                      statusIcon = Icons.priority_high;
                    } else {
                      barColor = Colors.green;
                      statusText = "Aman";
                      statusIcon = Icons.check_circle_outline;
                    }

                    return InkWell(
                      onTap: () => _showCategoryDetail(context, fin, k,
                          currentSpent, limit, statusText, barColor),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Column(children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(k,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ),
                                Row(children: [
                                  Icon(statusIcon, size: 12, color: barColor),
                                  const SizedBox(width: 4),
                                  Text(statusText,
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: barColor,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text(
                                      "${NumberFormat.compactCurrency(locale: 'id', symbol: '').format(currentSpent)} / ${limit > 0 ? NumberFormat.compactCurrency(locale: 'id', symbol: '').format(limit) : '-'}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ])
                              ]),
                          const SizedBox(height: 5),
                          ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                  value: displayProgress,
                                  minHeight: 8,
                                  color: barColor,
                                  backgroundColor: Colors.grey.shade100))
                        ]),
                      ),
                    );
                  }).toList(),
                ),
        )
      ],
    );
  }

  void _showCategoryDetail(BuildContext context, FinancialProvider fin,
      String category, double spent, double limit, String status, Color color) {
    final limitCtrl =
        TextEditingController(text: limit > 0 ? limit.toInt().toString() : "");
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(Icons.category, color: color, size: 20)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(category,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 16))),
              ]),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.5))),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(status,
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 5),
                              const Divider(),
                              const SizedBox(height: 5),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Terpakai:",
                                        style: TextStyle(fontSize: 12)),
                                    Text(
                                        NumberFormat.currency(
                                                locale: 'id',
                                                symbol: 'Rp ',
                                                decimalDigits: 0)
                                            .format(spent),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold))
                                  ]),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Batas:",
                                        style: TextStyle(fontSize: 12)),
                                    Text(
                                        limit > 0
                                            ? NumberFormat.currency(
                                                    locale: 'id',
                                                    symbol: 'Rp ',
                                                    decimalDigits: 0)
                                                .format(limit)
                                            : "Belum diatur",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: limit > 0
                                                ? Colors.black
                                                : Colors.grey))
                                  ])
                            ])),
                    const SizedBox(height: 20),
                    Text("Ubah Batas Anggaran:",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                        controller: limitCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter()
                        ],
                        decoration: InputDecoration(
                            hintText: "Contoh: 500000",
                            prefixText: "Rp ",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 12))),
                    const SizedBox(height: 5),
                    const Text(
                        "*Kosongkan atau isi 0 jika tidak ingin ada batas.",
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic)),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Batal",
                        style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: () {
                      double newLimit = 0;
                      if (limitCtrl.text.isNotEmpty) {
                        String cleanText = limitCtrl.text
                            .replaceAll('.', '')
                            .replaceAll(',', '');
                        newLimit = double.tryParse(cleanText) ?? 0;
                      }
                      fin.setBudgetLimit(category, newLimit);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Batas $category diperbarui!"),
                          backgroundColor: Colors.green));
                    },
                    child: const Text("Simpan",
                        style: TextStyle(color: Colors.white)))
              ],
            ));
  }

  Widget _buildTargetSection(BuildContext context, FinancialProvider fin) {
    if (fin.targets.isEmpty) return const SizedBox.shrink();
    return Column(key: _keyTarget, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("Target Keuangan",
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        TextButton(
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TargetsView()));
              setState(() => _selectedIndex = 0);
            },
            child: const Text("Detail",
                style: TextStyle(color: Color(0xFF1565C0))))
      ]),
      Column(
          children: fin.targets.take(3).map((item) {
        return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      spreadRadius: 0,
                      offset: const Offset(0, 8))
                ]),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Text(item.nama,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Text("${(item.progress * 100).toInt()}%",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green))
              ]),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                  value: item.progress,
                  color: Colors.green,
                  backgroundColor: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(5)),
              const SizedBox(height: 5),
              Text("Sisa ${item.sisaHari} hari lagi",
                  style: const TextStyle(color: Colors.grey, fontSize: 11))
            ]));
      }).toList())
    ]);
  }

  Widget _buildRecentTransactions(BuildContext context, FinancialProvider fin) {
    var recentTx = fin.transaksiBulanIni.take(5).toList();
    return Column(key: _keyTx, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Transaksi Terakhir",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("(Tekan lama untuk hapus)",
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic))
          ]),
        ),
        TextButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LaporanView())),
            child: const Text("Detail",
                style: TextStyle(color: Color(0xFF1565C0))))
      ]),
      recentTx.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Center(
                  child: Text("Belum ada transaksi di bulan ini",
                      style: TextStyle(color: Colors.grey))))
          : Column(
              children: recentTx.map((tx) {
              bool isIncome = tx.jenis == 'Pemasukan';
              return InkWell(
                  onLongPress: () => _showDeleteDialog(context, tx.id, fin),
                  child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 15,
                                spreadRadius: 0,
                                offset: const Offset(0, 8))
                          ]),
                      child: Row(children: [
                        CircleAvatar(
                            backgroundColor: isIncome
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            child: Icon(
                                isIncome
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isIncome ? Colors.green : Colors.red,
                                size: 20)),
                        const SizedBox(width: 15),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(tx.nama,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              Text(
                                  "${DateFormat('dd MMM').format(tx.tanggal)} • ${tx.kategori}",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey))
                            ])),
                        Text(
                            NumberFormat.compactCurrency(
                                    locale: 'id', symbol: 'Rp')
                                .format(tx.nominal),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isIncome ? Colors.green : Colors.red,
                                fontSize: 14))
                      ])));
            }).toList())
    ]);
  }

  void _showDeleteDialog(
      BuildContext context, String id, FinancialProvider fin) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text("Hapus Transaksi?"),
                content: const Text("Data ini akan hilang permanen."),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Batal")),
                  TextButton(
                      onPressed: () {
                        fin.deleteTransaksi(id);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Transaksi dihapus"),
                                backgroundColor: Colors.red));
                      },
                      child: const Text("Hapus",
                          style: TextStyle(color: Colors.red)))
                ]));
  }

  Widget _buildNavItem(IconData icon, String label, int index, GlobalKey? key) {
    bool isSelected = _selectedIndex == index;

    return InkWell(
      key: key,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () {
        if (_selectedIndex == index) return;
        setState(() => _selectedIndex = index);

        Future.delayed(const Duration(milliseconds: 150), () async {
          if (index == 1) {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TargetsView()));
            setState(() => _selectedIndex = 0);
          } else if (index == 2) {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LaporanView()));
            setState(() => _selectedIndex = 0);
          } else if (index == 3) {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileView()));
            setState(() => _selectedIndex = 0);
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16))
            : const BoxDecoration(color: Colors.transparent),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isSelected ? const Color(0xFF1565C0) : Colors.grey.shade400,
              size: isSelected ? 24 : 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color:
                    isSelected ? const Color(0xFF1565C0) : Colors.grey.shade500,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    double value = double.parse(newText);
    final formatter =
        NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);
    String newString = formatter.format(value);
    return TextEditingValue(
        text: newString,
        selection: TextSelection.collapsed(offset: newString.length));
  }
}
