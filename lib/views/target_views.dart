import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/financial_provider.dart';
import '../models/data_model.dart';

class TargetsView extends StatefulWidget {
  const TargetsView({super.key});

  @override
  State<TargetsView> createState() => _TargetsViewState();
}

class _TargetsViewState extends State<TargetsView> {
  // R1: Klasifikasi Awal Himpunan P (Prioritas/Wajib) dan F (Fleksibel/Jajan)
  final Map<String, bool> _flexStates = {
    'Makan & Minum': true,
    'Transportasi': true,
    'Tagihan/Kuota': true,
    'Biaya Kos': false,
    'Listrik/Air': false,
  };

  @override
  void initState() {
    super.initState();
    _loadFlexStates();
  }

  Future<void> _loadFlexStates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var key in _flexStates.keys) {
        _flexStates[key] = prefs.getBool('flex_$key') ?? _flexStates[key]!;
      }
    });
  }

  Future<void> _saveFlexState(String key, bool isFlex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flex_$key', isFlex);
    setState(() {
      _flexStates[key] = isFlex;
    });
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // FITUR BARU: Dialog Interaktif Sinkronisasi Batas Anggaran Target ke Monitoring Anggaran Dashboard
  void _showBudgetIntegrationDialog(
      BuildContext context,
      FinancialProvider fin,
      String nama,
      double nominal,
      DateTime deadline,
      double defisitBulanan,
      Map<String, double> itemFleksibel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.orange),
              SizedBox(width: 10),
              Text("Optimasi Batas Anggaran",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Untuk mencapai target '$nama', kamu perlu memotong total pengeluaran jajan sebesar ${_formatRp(defisitBulanan)}/bulan.",
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 15),
              const Text(
                "Apakah kamu ingin menetapkan batasan (Budget Limits) harian/bulanan di beranda secara otomatis sesuai rekomendasi pengurangan biaya dari AI?",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                fin.addTarget(nama, nominal, deadline);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      "Target disimpan. Batas anggaran beranda tidak diubah."),
                  backgroundColor: Colors.blueGrey,
                ));
              },
              child: const Text("Abaikan, Atur Manual",
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                itemFleksibel.forEach((kategori, totalLama) {
                  double proporsi = totalLama /
                      itemFleksibel.values.fold(0.0, (sum, v) => sum + v);
                  double jumlahPotong = proporsi * defisitBulanan;
                  double limitBaru = totalLama - jumlahPotong;

                  if (limitBaru < 0) limitBaru = 0;

                  fin.setBudgetLimit(kategori, limitBaru);
                });

                fin.addTarget(nama, nominal, deadline);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      "Target aktif! Batas anggaran monitoring di beranda berhasil disesuaikan otomatis."),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ));
              },
              child: const Text("Terapkan Rekomendasi",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Uji Target AI",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1565C0),
        onRefresh: () async {
          await Provider.of<FinancialProvider>(context, listen: false)
              .refreshData();
        },
        child: Consumer<FinancialProvider>(
          builder: (context, fin, child) {
            bool isSurvivalMode = fin.targets.any((t) => t.progress < 1.0);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (isSurvivalMode)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.warning_amber_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("SURVIVAL MODE: ON",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              SizedBox(height: 4),
                              Text(
                                  "Masih ada wishlist yang belum lunas. Fokus nabung & rem pengeluaran jajan dulu ya, Bestie!",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade900, Colors.blue.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.account_balance_wallet,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Uang Masuk (Gaji/Jatah)",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text(_formatRp(fin.savedIncome),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            _showFinancialProfileDialog(context, fin),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.indigo,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20))),
                        child: const Text("Edit Profil",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    ],
                  ),
                ),
                if (fin.targets.isEmpty)
                  Container(
                    height: 300,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch,
                            size: 80, color: Colors.blue.shade100),
                        const SizedBox(height: 20),
                        Text("Belum ada wishlist impian nih.",
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        const Text(
                            "Klik tombol + di bawah buat nge-spill wishlist barumu.",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: fin.targets.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () => _showTargetDetailDialog(
                            context, fin.targets[index], fin),
                        child:
                            _buildTargetCard(context, fin.targets[index], fin),
                      );
                    },
                  ),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTargetDialog(
            context, Provider.of<FinancialProvider>(context, listen: false)),
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add_chart, color: Colors.white),
        label: const Text("Uji Wishlist Baru",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ===========================================================================
  // IMPLEMENTASI RULE-BASED SYSTEM MULTI-PROBABILITAS DENGAN BATAS HEMAT 10%
  // ===========================================================================
  void _showAddTargetDialog(BuildContext context, FinancialProvider fin) {
    final nameCtrl = TextEditingController();
    final nominalCtrl = TextEditingController();
    DateTime? selectedDate;
    bool isImportant = true;
    bool hasCalculated = false;

    // TANDAI VARIABEL INI DI ATAS builder
    bool useAverageData = false;

    String statusTitle = "";
    String expertDiagnosis = "";
    String solution = "";
    Color statusColor = Colors.grey;
    bool isPossible = false;
    bool requiresHemat = false;
    int probabilitas = 0;

    double totalPemasukan = 0;
    double himpunanP = 0;
    double himpunanF = 0;
    double disposableIncome = 0;
    double sisaBebasReal = 0;
    double targetBulanan = 0;
    double gapDefisit = 0;

    double maxHematF = 0;
    double totalUangKesabaran = 0;
    int hariTersedia = 1;
    double uangTerkumpulAsli = 0;
    double kurangAsli = 0;

    Map<String, double> flexItems = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          void runRuleBasedAnalysis() {
            double hargaBarang = _parse(nominalCtrl.text);

            // Tentukan sumber data berdasarkan pilihan pengguna (Profil vs Riwayat Nyata)
            double activeIncome =
                useAverageData ? fin.avgIncome : fin.savedIncome;
            double activeKos = useAverageData ? fin.avgKos : fin.savedKos;
            double activeListrik =
                useAverageData ? fin.avgListrik : fin.savedListrik;
            double activeMakan = useAverageData ? fin.avgMakan : fin.savedMakan;
            double activeTransport =
                useAverageData ? fin.avgTransport : fin.savedTransport;
            double activeTagihan =
                useAverageData ? fin.avgTagihan : fin.savedTagihan;
            Map<String, double> activeCustom = useAverageData
                ? fin.avgCustomExpenses
                : fin.savedCustomExpenses;

            totalPemasukan = activeIncome;

            himpunanP = (fin.savedIsAnakKos ? (activeKos + activeListrik) : 0);
            flexItems.clear();

            if (_flexStates['Makan & Minum'] == true) {
              flexItems['Makan & Minum'] = activeMakan;
            }
            if (_flexStates['Transportasi'] == true) {
              flexItems['Transportasi'] = activeTransport;
            }
            if (_flexStates['Tagihan/Kuota'] == true) {
              flexItems['Tagihan/Kuota'] = activeTagihan;
            }

            activeCustom.forEach((key, value) {
              if (_flexStates[key] == true) {
                flexItems[key] = value;
              } else {
                himpunanP += value;
              }
            });

            himpunanF = flexItems.values.fold(0.0, (sum, item) => sum + item);

            DateTime start = _normalizeDate(DateTime.now());
            DateTime end = _normalizeDate(selectedDate!);
            hariTersedia = end.difference(start).inDays;
            if (hariTersedia <= 0) hariTersedia = 1;

            double sisaSatu = totalPemasukan - himpunanP;

            double bebanTargetLama = 0;
            for (var t in fin.targets) {
              if (t.progress < 1.0) {
                int sisaWktTargetLama = (t.sisaHari / 30).ceil();
                if (sisaWktTargetLama <= 0) sisaWktTargetLama = 1;
                bebanTargetLama +=
                    (t.nominal - t.terkumpul) / sisaWktTargetLama;
              }
            }

            sisaSatu -= bebanTargetLama;
            disposableIncome = sisaSatu;
            sisaBebasReal = disposableIncome - himpunanF;

            maxHematF = himpunanF * 0.10;
            totalUangKesabaran = sisaBebasReal + maxHematF;

            targetBulanan = (hargaBarang / hariTersedia) * 30;

            uangTerkumpulAsli =
                (sisaBebasReal > 0) ? (sisaBebasReal / 30) * hariTersedia : 0;
            kurangAsli = hargaBarang - uangTerkumpulAsli;
            if (kurangAsli < 0) kurangAsli = 0;

            DateTime tglLunasHemat = start;
            DateTime tglLunasSantai = start;

            if (totalUangKesabaran > 0) {
              int hariHemat = (hargaBarang / (totalUangKesabaran / 30)).ceil();
              tglLunasHemat = start.add(Duration(days: hariHemat));
            }
            if (sisaBebasReal > 0) {
              int hariSantai = (hargaBarang / (sisaBebasReal / 30)).ceil();
              tglLunasSantai = start.add(Duration(days: hariSantai));
            }

            requiresHemat = false;
            gapDefisit = 0;

            if (sisaSatu <= 0 ||
                (sisaBebasReal <= 0 && totalUangKesabaran <= 0)) {
              probabilitas = 0;
            } else if (sisaBebasReal >= hargaBarang && hariTersedia <= 31) {
              probabilitas = 100;
            } else if (sisaBebasReal >= targetBulanan) {
              probabilitas = isImportant ? 95 : 90;
            } else if (totalUangKesabaran >= targetBulanan) {
              probabilitas = isImportant ? 80 : 60;
            } else {
              probabilitas = isImportant ? 40 : 20;
            }

            if (probabilitas == 0) {
              statusTitle = "0% - Mustahil Terwujud";
              statusColor = Colors.red.shade900;
              isPossible = false;
              expertDiagnosis =
                  "Pengeluaranmu berlebihan bahkan melebihi pemasukanmu. Di tanggal yang ditentukan uangnya baru terkumpul Rp0 dan masih kurang ${_formatRp(hargaBarang)}.";
              solution =
                  "Jangan tergiur menggunakan pinjol! Mungkin hari ini kamu akan senang tapi di akhir bulan kamu akan kebingungan untuk membayar pinjol. Kamu perlu benar-benar mengatur keuanganmu dan mulai rutin melakukan pencatatan pemasukan dan pengeluaran.";
            } else if (probabilitas == 20) {
              statusTitle = "20% - Waktu Terlalu Mepet";
              statusColor = Colors.red;
              isPossible = false;
              expertDiagnosis =
                  "Di tanggal yang kamu mau, uangmu baru ngumpul ${_formatRp(uangTerkumpulAsli)}, masih kurang ${_formatRp(kurangAsli)}.";
              solution =
                  "Ini tidak mungkin dilakukan di waktu sesingkat itu. Ikuti saran pergeseran deadline: Nabung ${_formatRp(totalUangKesabaran / 30)} per hari dan geser deadline uang terkumpul untuk beli barang itu ke tanggal ${DateFormat('dd MMMM yyyy').format(tglLunasHemat)}.";
            } else if (probabilitas == 40) {
              statusTitle = "40% - Prioritas Tertunda";
              statusColor = Colors.red;
              isPossible = false;
              expertDiagnosis =
                  "Barang ini wajib, tapi di tanggal yang kamu mau uangmu baru terkumpul ${_formatRp(uangTerkumpulAsli)} (masih kurang ${_formatRp(kurangAsli)}).";
              solution =
                  "Ini tidak mungkin dilakukan di waktu sesingkat itu. Ikuti saran pergeseran deadline: Nabung ${_formatRp(totalUangKesabaran / 30)} per hari dan geser deadline uang terkumpul untuk beli barang itu ke tanggal ${DateFormat('dd MMMM yyyy').format(tglLunasHemat)}.";
            } else if (probabilitas == 60) {
              statusTitle = "60% - Bisa Diakali Tapi Pemborosan";
              statusColor = Colors.orange;
              isPossible = true;
              requiresHemat = true;
              gapDefisit = targetBulanan - sisaBebasReal;
              expertDiagnosis =
                  "Uang kamu ada tapi ini pemborosan. Di tanggal deadline, uangmu baru terkumpul ${_formatRp(uangTerkumpulAsli)}, masih kurang ${_formatRp(kurangAsli)}.";
              solution =
                  "Lebih baik kamu bersabar sedikit dan geser deadlinemu.\n\nOpsi 1: Lakukan penghematan di pengeluaran fleksibel (hemat ${_formatRp(gapDefisit)}/bulan), lalu nabung ${_formatRp(targetBulanan / 30)}/hari.\n\nOpsi 2: Tidak perlu mengurangi biaya pengeluaran fleksibel, cukup menabung ${_formatRp(sisaBebasReal / 30)} per hari tapi geser deadline-nya menjadi ${DateFormat('dd MMMM yyyy').format(tglLunasSantai)}.";
            } else if (probabilitas == 80) {
              statusTitle = "80% - Wajib Penghematan";
              statusColor = Colors.blue;
              isPossible = true;
              requiresHemat = true;
              gapDefisit = targetBulanan - sisaBebasReal;
              expertDiagnosis =
                  "Di tanggal deadline, dana yang ngumpul secara natural baru ${_formatRp(uangTerkumpulAsli)}, masih kurang ${_formatRp(kurangAsli)}.";
              solution =
                  "Kamu bisa membeli ini, hanya saja kamu mungkin harus mengurangi pengeluaranmu. Ikuti saran pengurangan biaya di bawah agar kamu bisa menabung ${_formatRp(targetBulanan / 30)} per hari.\n\nAtau opsi santai: Tidak usah berhemat, cukup nabung ${_formatRp(sisaBebasReal / 30)} per hari tapi geser deadline menjadi ${DateFormat('dd MMMM yyyy').format(tglLunasSantai)}.";
            } else if (probabilitas == 90) {
              statusTitle = "90% - Pikirkan Kembali";
              statusColor = Colors.green;
              isPossible = true;
              expertDiagnosis =
                  "Di tanggal yang ditentukan uangmu akan full terkumpul ${_formatRp(hargaBarang)} tanpa mengganggu uang lainnya.";
              solution =
                  "Kamu bisa membeli ini dengan sisa uangmu (cukup nabung ${_formatRp(targetBulanan / 30)} per hari), tapi karena ini bukan prioritas, mungkin kamu mau memikirkannya kembali.";
            } else if (probabilitas == 95) {
              statusTitle = "95% - Hadiah Kesabaran";
              statusColor = Colors.green;
              isPossible = true;
              expertDiagnosis =
                  "Sisa uangmu aman. Di tanggal yang ditentukan uangnya akan sukses terkumpul ${_formatRp(hargaBarang)} tanpa perlu hemat uang jajan.";
              solution =
                  "Anggap ini sebagai reward dari hasil kesabaranmu. Tidak perlu berhemat, cukup menabung ${_formatRp(targetBulanan / 30)} per hari kamu bisa mendapatkan barang itu!";
            } else if (probabilitas == 100) {
              statusTitle = "100% - Aman Terkendali";
              statusColor = Colors.green.shade700;
              isPossible = true;
              expertDiagnosis =
                  "Kondisi keuanganmu aman banget untuk beli barang itu, uang untuk keperluan sehari-harimu tidak terganggu walaupun kamu menyenangkan dirimu dengan membeli barang itu hari ini.";
              solution =
                  "Gas check out beli barang ini sekarang! Tapi kalau kamu mau mikir-mikir dulu juga bisa, gunakan teknik 24 Jam untuk menentukan apa barang itu kamu butuhkan atau tidak daripada kamu menyesal.";
            }

            setModalState(() => hasCalculated = true);
          }

          void validateInput() {
            if (nameCtrl.text.isEmpty ||
                nominalCtrl.text.isEmpty ||
                selectedDate == null) {
              _showSnack(context, "Harap lengkapi Nama, Harga, dan Deadline.");
              return;
            }
            double harga = _parse(nominalCtrl.text);
            if (harga <= 0) {
              _showSnack(context, "Harga tidak valid!");
              return;
            }

            // CEK: Apakah user memilih Riwayat Asli (useAverageData == true)?
            if (useAverageData && !fin.isHistoryComplete3Months) {
              List<DateTime> missing = fin.missingDates;
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 10),
                      Text("Data Riwayat Belum Lengkap",
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                            "Catatan keuanganmu belum lengkap periode 3 bulan. Analisis AI berdasarkan data riwayat mungkin kurang akurat."),
                        const SizedBox(height: 10),
                        const Text("Beberapa tanggal yang belum terisi:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: missing.length > 5 ? 5 : missing.length,
                            itemBuilder: (context, i) => Text(
                                "- ${DateFormat('dd MMM yyyy').format(missing[i])}"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Ganti ke Profil")),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange),
                        onPressed: () {
                          Navigator.pop(ctx);
                          runRuleBasedAnalysis(); // AI dijalankan setelah user memilih tetap lanjut
                        },
                        child: const Text("Tetap Lanjutkan"))
                  ],
                ),
              );
            } else {
              // Jika pakai Profil atau Riwayat sudah lengkap, langsung jalan
              runRuleBasedAnalysis();
            }
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20),
            child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Sistem Pakar: Reality Check Wishlist",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0))),
                    const SizedBox(height: 5),
                    const Text(
                        "Berdasarkan Probabilitas & Transparansi Cashflow",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 20),
                    _buildField(nameCtrl, "Nama Barang/Wishlist", Icons.flag),
                    _buildMoneyField(nominalCtrl, "Harga Barang"),
                    Container(
                        decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10)),
                        child: SwitchListTile(
                            title: const Text(
                                "Barang ini butuh banget atau cuma FOMO?",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(
                                isImportant
                                    ? "Butuh Banget (Kebutuhan Wajib)"
                                    : "Cuma Keinginan (Bisa Ditunda)",
                                style: const TextStyle(fontSize: 12)),
                            value: isImportant,
                            activeColor: Colors.blue,
                            onChanged: (val) =>
                                setModalState(() => isImportant = val))),

                    const SizedBox(height: 15),

                    // WIDGET BARU: Radio Button Pilihan Sumber Data
                    const Text("Sumber Data Kalkulasi AI",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        children: [
                          RadioListTile<bool>(
                            title: const Text("Profil Keuangan (Rencana)",
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: const Text(
                                "Gunakan budget ideal dari profilmu.",
                                style: TextStyle(fontSize: 11)),
                            value: false,
                            groupValue: useAverageData,
                            activeColor: const Color(0xFF1565C0),
                            onChanged: (val) =>
                                setModalState(() => useAverageData = val!),
                          ),
                          RadioListTile<bool>(
                            title: const Text("Riwayat Asli (Realita)",
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: const Text(
                                "Gunakan rata-rata pengeluaran/pemasukan nyatamu.",
                                style: TextStyle(fontSize: 11)),
                            value: true,
                            groupValue: useAverageData,
                            activeColor: const Color(0xFF1565C0),
                            onChanged: (val) =>
                                setModalState(() => useAverageData = val!),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100));
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            const Icon(Icons.calendar_month,
                                color: Colors.blue),
                            const SizedBox(width: 10),
                            Text(
                                selectedDate == null
                                    ? "Kapan target harus kebeli?"
                                    : DateFormat('dd MMMM yyyy', 'id_ID')
                                        .format(selectedDate!),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))
                          ])),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                            onPressed: () => validateInput(),
                            icon: const Icon(Icons.psychology,
                                color: Colors.white),
                            label: const Text("Minta Roasting & Saran AI",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))))),
                    if (hasCalculated) ...[
                      const SizedBox(height: 25),
                      const Text("Hasil Roasting & Saran Pakar",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              border:
                                  Border.all(color: statusColor, width: 1.5),
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(statusTitle,
                                    style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(expertDiagnosis,
                                    style: const TextStyle(
                                        fontSize: 13, height: 1.4)),
                                const Divider(),
                                Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.assistant_direction,
                                          color: Colors.amber, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(solution,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  fontStyle: FontStyle.italic)))
                                    ])
                              ])),
                      const SizedBox(height: 15),
                      Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300)),
                          child: Column(children: [
                            const Text("Rincian Transparansi Biaya",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            const SizedBox(height: 10),
                            _buildRowDetail(
                                "Uang Masuk", totalPemasukan, Colors.green),
                            _buildRowDetail(
                                "Biaya Wajib", himpunanP, Colors.red,
                                prefix: "- "),
                            const Divider(),
                            _buildRowDetail("Sisa 1 (Setelah wajib)",
                                (totalPemasukan - himpunanP), Colors.black,
                                isBold: true),
                            _buildRowDetail(
                                "Biaya Fleksibel", himpunanF, Colors.orange,
                                prefix: "- "),
                            const Divider(),
                            _buildRowDetail(
                                "Uang Bebas", sisaBebasReal, Colors.blue,
                                isBold: true),
                            if (requiresHemat && isPossible) ...[
                              const SizedBox(height: 5),
                              _buildRowDetail("Uang Hasil Hemat (Maks 10% F)",
                                  maxHematF, Colors.green.shade700,
                                  isBold: true, prefix: "+ "),
                              const Divider(thickness: 1.5),
                              _buildRowDetail("Uang Hasil Kesabaran",
                                  totalUangKesabaran, Colors.purple,
                                  isBold: true, fontSize: 16),
                            ]
                          ])),
                      if (requiresHemat &&
                          isPossible &&
                          (probabilitas == 60 || probabilitas == 80)) ...[
                        const SizedBox(height: 15),
                        Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: Colors.orange.shade200)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("✂️ Rencana Pengurangan Biaya",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange)),
                                  const SizedBox(height: 5),
                                  Text(
                                      "Pengeluaranmu disarankan dikurangi dari ${_formatRp(himpunanF)} jadi tinggal ${_formatRp(himpunanF - gapDefisit)}. Ini rinciannya:",
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 10),
                                  ...flexItems.entries.map((e) {
                                    double proportion = e.value / himpunanF;
                                    double cutAmount = proportion * gapDefisit;
                                    if (cutAmount <= 0)
                                      return const SizedBox.shrink();
                                    double targetBudget = e.value - cutAmount;

                                    return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                  child: Text(e.key,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight
                                                              .bold))),
                                              Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                        "Kurangi ${_formatRp(cutAmount)}",
                                                        style: const TextStyle(
                                                            color: Colors.red,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12)),
                                                    Text(
                                                        "Sisa jatah: ${_formatRp(targetBudget)}",
                                                        style: const TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 10)),
                                                  ])
                                            ]));
                                  })
                                ]))
                      ],
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isPossible
                              ? () {
                                  String namaTarget = nameCtrl.text.trim();
                                  double hargaTarget = _parse(nominalCtrl.text);
                                  DateTime deadlineTarget = selectedDate!;

                                  if (requiresHemat && gapDefisit > 0) {
                                    Navigator.pop(ctx);
                                    _showBudgetIntegrationDialog(
                                        context,
                                        fin,
                                        namaTarget,
                                        hargaTarget,
                                        deadlineTarget,
                                        gapDefisit,
                                        flexItems);
                                  } else {
                                    fin.addTarget(namaTarget, hargaTarget,
                                        deadlineTarget);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                          "Target berhasil disimpan aman terkendali!"),
                                      backgroundColor: Colors.green,
                                    ));
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15)),
                          child: Text(
                              isPossible
                                  ? "Gass Simpan Target"
                                  : "Ikuti Pergeseran Deadline Dulu",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                  ]),
            ),
          );
        });
      },
    );
  }

  void _showFinancialProfileDialog(
      BuildContext context, FinancialProvider fin) {
    final incomeCtrl =
        TextEditingController(text: fin.savedIncome.toStringAsFixed(0));
    final kosCtrl =
        TextEditingController(text: fin.savedKos.toStringAsFixed(0));
    final listrikCtrl =
        TextEditingController(text: fin.savedListrik.toStringAsFixed(0));
    final makanCtrl =
        TextEditingController(text: fin.savedMakan.toStringAsFixed(0));
    final transportCtrl =
        TextEditingController(text: fin.savedTransport.toStringAsFixed(0));
    final tagihanCtrl =
        TextEditingController(text: fin.savedTagihan.toStringAsFixed(0));
    bool isAnakKos = fin.savedIsAnakKos;
    Map<String, double> tempCustomExpenses = Map.from(fin.savedCustomExpenses);

    bool isDefaultProfile = fin.savedIncome == 1500000 &&
        fin.savedMakan == 900000 &&
        fin.savedKos == 500000;

    Widget buildExpenseRow(String label, TextEditingController ctrl,
        String keyName, StateSetter setModalState) {
      bool isFlex = _flexStates[keyName] ?? true;
      return Row(
        children: [
          Expanded(flex: 3, child: _buildMoneyField(ctrl, label)),
          const SizedBox(width: 5),
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: isFlex ? Colors.orange.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: InkWell(
                onTap: () {
                  setModalState(() {
                    _flexStates[keyName] = !isFlex;
                  });
                  _saveFlexState(keyName, !isFlex);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                      child: Text(
                          isFlex
                              ? "Dana Jajan (Bisa dipotong)"
                              : "Dana Wajib (Gak bisa diganggu)",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isFlex
                                  ? Colors.orange.shade800
                                  : Colors.red.shade800))),
                ),
              ),
            ),
          )
        ],
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20),
            child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Spill Kondisi Keuangan Aslimu",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    if (isDefaultProfile)
                      Container(
                          margin: const EdgeInsets.symmetric(vertical: 15),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade200)),
                          child: const Row(children: [
                            Icon(Icons.info, color: Colors.blue),
                            SizedBox(width: 10),
                            Expanded(
                                child: Text(
                                    "Isi data ini sejujur mungkin ya. Kalau bohong, AI-nya bakal halu ngasih saran ke kamu.",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.blue)))
                          ])),
                    const SizedBox(height: 15),
                    _buildMoneyField(incomeCtrl, "Total Uang Masuk Per Bulan"),
                    const SizedBox(height: 20),
                    const Text("Atur Skala Prioritasmu:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue)),
                    const Text(
                        "Nanti AI cuma berani nahan duit dari kategori 'Dana Jajan' kalau kamu maksa beli barang mahal.",
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const Divider(),
                    SwitchListTile(
                        title: const Text("Anak Kos Check (Dana Wajib)"),
                        value: isAnakKos,
                        onChanged: (val) =>
                            setModalState(() => isAnakKos = val),
                        contentPadding: EdgeInsets.zero),
                    if (isAnakKos) ...[
                      buildExpenseRow(
                          "Biaya Kos", kosCtrl, "Biaya Kos", setModalState),
                      buildExpenseRow("Listrik/Air", listrikCtrl, "Listrik/Air",
                          setModalState),
                    ],
                    buildExpenseRow("Makan & Minum", makanCtrl, "Makan & Minum",
                        setModalState),
                    buildExpenseRow("Transportasi", transportCtrl,
                        "Transportasi", setModalState),
                    buildExpenseRow("Kuota/Wifi", tagihanCtrl, "Tagihan/Kuota",
                        setModalState),
                    const SizedBox(height: 15),
                    const Text("Pengeluaran Lain (Bebas)",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 10),
                    ...tempCustomExpenses.entries.map((e) {
                      bool isFlex = _flexStates[e.key] ?? true;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.key,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(_formatRp(e.value),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: isFlex
                                        ? Colors.orange.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8)),
                                child: InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      _flexStates[e.key] = !isFlex;
                                    });
                                    _saveFlexState(e.key, !isFlex);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 17),
                                    child: Center(
                                        child: Text(
                                            isFlex
                                                ? "Dana Jajan"
                                                : "Dana Wajib",
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isFlex
                                                    ? Colors.orange.shade800
                                                    : Colors.red.shade800))),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setModalState(
                                    () => tempCustomExpenses.remove(e.key))),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                        onPressed: () => _showAddCustomExpenseDialog(
                            context,
                            tempCustomExpenses.keys.toList(),
                            (n, a, isFlex) => setModalState(() {
                                  tempCustomExpenses[n] = a;
                                  _saveFlexState(n, isFlex);
                                })),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text("Tambah Pengeluaran Lain")),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: () {
                              fin.updateFinancialProfile(
                                  income: _parse(incomeCtrl.text),
                                  isAnakKos: isAnakKos,
                                  kos: _parse(kosCtrl.text),
                                  listrik: _parse(listrikCtrl.text),
                                  makan: _parse(makanCtrl.text),
                                  transport: _parse(transportCtrl.text),
                                  tagihan: _parse(tagihanCtrl.text),
                                  customExpenses: tempCustomExpenses);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12)),
                            child: const Text("Save Profil Keuangan",
                                style: TextStyle(color: Colors.white)))),
                    const SizedBox(height: 30),
                  ]),
            ),
          );
        });
      },
    );
  }

  void _showAddCustomExpenseDialog(BuildContext context,
      List<String> existingNames, Function(String, double, bool) onAdd) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    bool isFleksibel = true;

    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                    title: const Text("Tambah Pengeluaran",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                              labelText: "Nama (Misal: Skincare)")),
                      const SizedBox(height: 10),
                      _buildMoneyField(amountCtrl, "Nominal per bulan"),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        title: const Text("Sifat Pengeluaran",
                            style: TextStyle(fontSize: 14)),
                        subtitle: Text(
                            isFleksibel
                                ? "Bisa ditahan AI (Jajan)"
                                : "Nggak bisa diganggu gugat",
                            style: TextStyle(
                                fontSize: 11,
                                color: isFleksibel
                                    ? Colors.orange.shade800
                                    : Colors.red)),
                        value: isFleksibel,
                        onChanged: (val) => setState(() => isFleksibel = val),
                        activeColor: Colors.orange,
                        contentPadding: EdgeInsets.zero,
                      )
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Batal")),
                      ElevatedButton(
                          onPressed: () {
                            String newName = nameCtrl.text.trim();
                            if (newName.isEmpty || amountCtrl.text.isEmpty) {
                              _showSnack(
                                  context, "Nama dan nominal wajib diisi!");
                              return;
                            }
                            if (existingNames.contains(newName) ||
                                [
                                  "Biaya Kos",
                                  "Listrik/Air",
                                  "Makan & Minum",
                                  "Transportasi",
                                  "Tagihan/Kuota"
                                ].contains(newName)) {
                              _showSnack(context,
                                  "Kategori '$newName' udah ada! Pakai nama lain dong.");
                              return;
                            }
                            onAdd(
                                newName, _parse(amountCtrl.text), isFleksibel);
                            Navigator.pop(ctx);
                          },
                          child: const Text("Tambah"))
                    ])));
  }

  void _showTargetDetailDialog(
      BuildContext context, TargetModel item, FinancialProvider fin) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Detail Target",
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _rowDetail("Nama Target", item.nama),
                    _rowDetail("Harga Barang", _formatRp(item.nominal)),
                    _rowDetail("Terkumpul", _formatRp(item.terkumpul)),
                    _rowDetail(
                        "Deadline",
                        DateFormat('dd MMMM yyyy', 'id_ID')
                            .format(item.deadline)),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showDeleteConfirm(context, item.id, fin);
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text("Hapus",
                                  style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red)))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showEditTargetDialog(context, item, fin);
                              },
                              icon: const Icon(Icons.edit, color: Colors.white),
                              label: const Text("Edit",
                                  style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue))),
                    ])
                  ]));
        });
  }

  void _showEditTargetDialog(
      BuildContext context, TargetModel item, FinancialProvider fin) {
    final nameCtrl = TextEditingController(text: item.nama);
    final nominalCtrl =
        TextEditingController(text: item.nominal.toStringAsFixed(0));
    DateTime selectedDate = item.deadline;
    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                    title: const Text("Edit Target"),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      _buildField(nameCtrl, "Nama Target", Icons.star),
                      _buildMoneyField(nominalCtrl, "Harga"),
                      const SizedBox(height: 10),
                      InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100));
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          child: Row(children: [
                            const Icon(Icons.calendar_month,
                                color: Colors.blue),
                            const SizedBox(width: 10),
                            Text(DateFormat('dd MMM yyyy').format(selectedDate),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))
                          ]))
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Batal")),
                      ElevatedButton(
                          onPressed: () {
                            fin.deleteTarget(item.id);
                            fin.addTarget(nameCtrl.text,
                                _parse(nominalCtrl.text), selectedDate);
                            Navigator.pop(ctx);
                          },
                          child: const Text("Simpan Perubahan"))
                    ])));
  }

  void _showDeleteConfirm(
      BuildContext context, String id, FinancialProvider fin) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text("Yakin Mau Nyerah?"),
                content: const Text(
                    "Beneran mau hapus wishlist ini? Progress nabungmu batal lho."),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Batal")),
                  ElevatedButton(
                      onPressed: () {
                        fin.deleteTarget(id);
                        Navigator.pop(ctx);
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Hapus",
                          style: TextStyle(color: Colors.white)))
                ]));
  }

  void _showSuccessPopup(BuildContext context, String itemName) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                backgroundColor: Colors.white,
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
                  const SizedBox(height: 20),
                  const Text("TARGET TERCAPAI! 🎉",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange)),
                  const SizedBox(height: 10),
                  Text(
                      "Selamat! Kamu berhasil menabung untuk membeli '$itemName'.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text(
                      "Keren banget Bestie! Konsistensimu luar biasa. Silakan check-out barang impianmu hari ini! 💪",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey))
                ]),
                actions: [
                  ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20))),
                      child: const Text("Mantap!",
                          style: TextStyle(color: Colors.white)))
                ]));
  }

  void _showInputTabungan(
      BuildContext context, TargetModel item, FinancialProvider fin) {
    final ctrl = TextEditingController();
    double sisaDibutuhkan = item.nominal - item.terkumpul;
    if (sisaDibutuhkan <= 0) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
              bool isSaving = false;

              return AlertDialog(
                  title: Text("Nabung ${item.nama}"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Sisa yang dibutuhkan: ${_formatRp(sisaDibutuhkan)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                      const SizedBox(height: 10),
                      TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter()
                          ],
                          decoration: const InputDecoration(
                              labelText: "Nominal Nabung", prefixText: "Rp "))
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: isSaving ? null : () => Navigator.pop(ctx),
                        child: const Text("Batal",
                            style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (ctrl.text.isEmpty) return;
                                setDialogState(() => isSaving = true);

                                double val =
                                    double.parse(ctrl.text.replaceAll('.', ''));
                                double excess = 0;

                                if (val > sisaDibutuhkan) {
                                  excess = val - sisaDibutuhkan;
                                  val = sisaDibutuhkan;
                                }

                                await fin.isiTabunganTarget(item.id, val);

                                if (context.mounted) {
                                  Navigator.pop(ctx);

                                  if (excess > 0) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          "Sisa kembalian ${_formatRp(excess)} tidak dimasukkan agar target nggak meleber."),
                                      backgroundColor: Colors.blue.shade700,
                                      duration: const Duration(seconds: 4),
                                    ));
                                  }

                                  if (item.terkumpul + val >= item.nominal) {
                                    _showSuccessPopup(context, item.nama);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: isSaving
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text("Simpan",
                                style: TextStyle(color: Colors.white)))
                  ]);
            }));
  }

  double _parse(String text) {
    if (text.isEmpty) return 0;
    return double.tryParse(text.replaceAll('.', '')) ?? 0;
  }

  String _formatRp(double val) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)
        .format(val);
  }

  void _showSnack(BuildContext context, String msg) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Row(children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Mohon Perhatikan!")
                ]),
                content: Text(msg),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("OK"))
                ]));
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
            controller: ctrl,
            decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, size: 20),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12))));
  }

  Widget _buildMoneyField(TextEditingController ctrl, String label) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CurrencyInputFormatter()
            ],
            decoration: InputDecoration(
                labelText: label,
                prefixText: "Rp ",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12))));
  }

  Widget _buildRowDetail(String label, double amount, Color color,
      {bool isBold = false, String prefix = "", double fontSize = 14}) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12)),
          Text("$prefix${_formatRp(amount)}",
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize))
        ]));
  }

  Widget _rowDetail(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold))
        ]));
  }

  Widget _buildTargetCard(
      BuildContext context, TargetModel item, FinancialProvider fin) {
    bool isCompleted = item.progress >= 1.0;

    int daysLeft = item.sisaHari;
    if (daysLeft <= 0 && !isCompleted) daysLeft = 1;

    double sisaNominal = item.nominal - item.terkumpul;
    if (sisaNominal < 0) sisaNominal = 0;

    double harian = (daysLeft > 0) ? (sisaNominal / daysLeft) : sisaNominal;
    String textSisaWaktu =
        isCompleted ? "0 Hari lagi (TERCAPAI)" : "$daysLeft Hari lagi";

    return Dismissible(
        key: Key(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white)),
        confirmDismiss: (direction) async {
          _showDeleteConfirm(context, item.id, fin);
          return false;
        },
        child: Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 5,
                      offset: const Offset(0, 3))
                ]),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                    child: Text(item.nama,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16))),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(textSisaWaktu,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? Colors.green : Colors.blue)))
              ]),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                  value: item.progress > 1 ? 1 : item.progress,
                  color: isCompleted ? Colors.green : const Color(0xFF1565C0),
                  backgroundColor: Colors.grey.shade100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(5)),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "Terkumpul: ${_formatRp(item.terkumpul)} / ${_formatRp(item.nominal)}",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    if (isCompleted)
                      const Text(
                          "Yuhuuuuuu, Uangmu udah terkumpul! Cus checkout!",
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green))
                    else
                      Text(
                          "Nabung ${_formatRp(harian)}/hari biar wishlist-mu nyata!",
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange))
                  ],
                ),
                if (!isCompleted)
                  ElevatedButton.icon(
                      onPressed: () => _showInputTabungan(context, item, fin),
                      icon:
                          const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text("Nabung",
                          style: TextStyle(fontSize: 12, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          visualDensity: VisualDensity.compact))
              ])
            ])));
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
