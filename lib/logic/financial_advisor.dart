import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/data_model.dart';

// =========================================================
// 1. MODEL DATA (FAKTA UNTUK SISTEM PAKAR R1-R9)
// =========================================================
class FinancialData {
  String itemName;
  double itemPrice;
  double totalIncome;
  double totalSaldo;
  double himpunanP;
  double himpunanF;
  bool isItemNecessary;

  bool? isAbleToBuy;
  double? rasioPemasukan;
  double? rasioBalance;
  double? kekurangan;
  double? danaTalangan;
  double? sisaPemasukan;
  double? gapTarget;

  FinancialData({
    required this.itemName,
    required this.itemPrice,
    required this.totalIncome,
    required this.totalSaldo,
    required this.himpunanP,
    required this.himpunanF,
    required this.isItemNecessary,
  });
}

// =========================================================
// 2. HASIL DIAGNOSA (OUTPUT)
// =========================================================
class DiagnosisResult {
  List<String> recommendations = [];
  List<String> calculations = [];
  String status = "";

  void addRec(String text) => recommendations.add(text);
  void addCalc(String text) => calculations.add(text);
}

// =========================================================
// 3. CLASS UTAMA: FINANCIAL ADVISOR
// =========================================================
class FinancialAdvisor {
  static String formatRupiah(double number) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return currencyFormatter.format(number);
  }

  // -------------------------------------------------------
  // A. INFERENCE ENGINE (CORE SISTEM PAKAR - RULES R1-R9)
  // -------------------------------------------------------
  static DiagnosisResult runFinancialExpertSystem(FinancialData data) {
    DiagnosisResult result = DiagnosisResult();

    // RULE 1 (R1): Validasi Data Kosong
    if (data.itemPrice <= 0 || data.totalIncome <= 0) {
      result.status = "Data Belum Lengkap";
      result.addRec(
          "Real talk: AI butuh angka yang jelas nih. Isi dulu total uang masuk dan harga barangnya biar bisa dihitung dengan bener.");
      return result;
    }

    // RULE 8 & 9 (Evaluasi Target Tabungan Terhadap Pemasukan)
    data.sisaPemasukan = data.totalIncome - data.himpunanP;

    if (data.itemPrice >= data.totalIncome ||
        data.itemName.contains("Target")) {
      if (data.itemPrice < data.sisaPemasukan!) {
        // RULE 8: Target < Sisa Pendapatan
        result.status = "Aman Terkendali (R8)";
        result.addCalc("Pemasukanmu: ${formatRupiah(data.totalIncome)}");
        result.addCalc(
            "Dipakai Biaya Wajib (Kos/dll): -${formatRupiah(data.himpunanP)}");
        result
            .addCalc("Sisa Uang Bebasmu: ${formatRupiah(data.sisaPemasukan!)}");

        result.addRec(
            "Kondisi keuanganmu aman banget untuk ngejar target ini. Uang untuk keperluan sehari-harimu tidak akan terganggu sama sekali.");
        result.addRec(
            "Saran AI: Gass lanjut nabung! Rencanamu udah sangat realistis.");
      } else {
        // RULE 9: Target >= Sisa Pendapatan
        data.gapTarget = data.itemPrice - data.sisaPemasukan!;
        result.status = "Wajib Puasa Jajan (R9)";
        result.addCalc(
            "Uang Bebas Tersedia: ${formatRupiah(data.sisaPemasukan!)}");
        result.addCalc("Kekurangan Uang: ${formatRupiah(data.gapTarget!)}");

        result.addRec(
            "Real Talk: Target tabunganmu ini lumayan berat. Kamu KEKURANGAN dana sebesar ${formatRupiah(data.gapTarget!)} tiap bulannya.");
        result.addRec(
            "Saran AI: Biar target ini kekejar, kamu WAJIB ngurangin porsi uang jajan/main sebesar kekurangan tersebut. Kalau ngerasa bakal stres ngejalaninnya, mending mundurin aja tanggal targetnya biar lebih santai.");
      }
      return result;
    }

    // RULE 2 & 3 (Evaluasi Pembelian Tunai / Harga Barang Terhadap Saldo)
    if (data.itemPrice < data.totalSaldo) {
      // RULE 2: Uang Cukup
      data.isAbleToBuy = true;
      data.rasioPemasukan = (data.itemPrice / data.totalIncome) * 100;
      data.rasioBalance = (data.itemPrice / data.totalSaldo) * 100;

      result.addCalc(
          "Porsi pengeluaran dari gaji: ${data.rasioPemasukan?.toStringAsFixed(1)}%");

      if (data.isItemNecessary) {
        // RULE 6: Uang Cukup + Penting
        result.status = "Aman Banget (R6)";
        result.addRec(
            "Kondisi keuanganmu aman banget untuk beli barang penting ini. Uang untuk keperluan sehari-harimu dipastikan tidak akan terganggu sama sekali.");
        result.addRec("Saran AI: Gas check out sekarang!");
      } else {
        // RULE 7: Uang Cukup + Tidak Penting
        double ambangBatas = 0.10 * data.totalIncome;
        if (data.rasioPemasukan! > 10.0) {
          result.status = "Red Flag FOMO (R7)";
          result
              .addCalc("Batas Wajar Jajan (10%): ${formatRupiah(ambangBatas)}");
          result.addRec(
              "Uangnya sih emang ada, TAPI ini barangnya nggak wajib. Harganya juga lumayan nguras jatah bulananmu (udah lebih dari 10%). Sayang banget kan kalau uangnya langsung habis gitu aja?");
          result.addRec(
              "Saran AI: Gunakan teknik nunggu 24 Jam! Coba mikir-mikir dulu sehari semalam. Kalau besok masih pengen banget, baru beli. Daripada kamu nyesel di akhir bulan.");
        } else {
          result.status = "Self Reward (Aman)";
          result.addRec(
              "Harganya masih wajar dan nggak merusak pos keuanganmu yang lain.");
          result.addRec(
              "Saran AI: Gas check out! Nggak apa-apa menyenangkan diri sendiri sesekali asal tetap terkontrol.");
        }
      }
    } else {
      // RULE 3: Uang Kurang
      data.isAbleToBuy = false;
      data.kekurangan = data.itemPrice - data.totalIncome;
      if (data.kekurangan! < 0) {
        data.kekurangan = data.itemPrice - data.totalSaldo;
      }

      result
          .addCalc("Uangmu kurang sebesar: ${formatRupiah(data.kekurangan!)}");

      if (data.isItemNecessary) {
        // RULE 4: Uang Kurang + Penting
        data.danaTalangan = data.himpunanF - data.kekurangan!;
        result.status = "Tindakan Darurat (R4)";
        result.addCalc(
            "Jatah Uang Jajan Tersisa: ${formatRupiah(data.himpunanF)}");
        result.addCalc("Sisa Jajan Nanti: ${formatRupiah(data.danaTalangan!)}");

        result.addRec(
            "Ini barang prioritas, TAPI uangmu kurang ${formatRupiah(data.kekurangan!)}. Nggak ada pilihan lain selain berkorban.");
        result.addRec(
            "Solusi AI: Kamu harus motong jatah uang senang-senangmu (jajan/nongkrong) bulan ini untuk nombokin kurangnya. Jangan pakai uang kos/listrik ya!");
      } else {
        // RULE 5: Uang Kurang + Tidak Penting
        result.status = "Ditolak AI (R5)";
        result.addRec(
            "Vonis AI: Udah uangnya nggak cukup, barangnya juga cuma keinginan sesaat doang.");
        result.addRec(
            "Saran AI: Jangan maksain diri. Risiko dompet menjerit jauh lebih besar dari senengnya dapet barang ini. Jangan sampai kamu ngutang atau pakai PayLater buat hal yang nggak perlu!");
      }
    }

    return result;
  }

  // -------------------------------------------------------
  // B. SMART BUDGET RECOMMENDATION
  // -------------------------------------------------------
  static List<String> generateBudgetRecommendations(
      List<Transaksi> transaksi,
      double income,
      double himpunanP,
      double himpunanF,
      List<TargetModel> targets) {
    List<String> suggestions = [];
    bool isSimulationMode = (income <= 0);

    if (isSimulationMode) {
      suggestions.add("**Mode Simulasi**");
      suggestions.add(
          "*(Isi 'Total Pemasukan' di Rincian Keuangan biar hasil tebakan AI lebih akurat)*");
    } else {
      suggestions.add("**Rencana Bertahan Hidup Bulan Ini**");
    }

    double bebanTargetPerBulan = 0;
    if (targets.isNotEmpty) {
      targets.sort((a, b) => a.deadline.compareTo(b.deadline));
      TargetModel topTarget = targets.first;

      double kekurangan = topTarget.nominal - topTarget.terkumpul;
      int sisaBulan = (topTarget.sisaHari / 30).ceil();
      if (sisaBulan <= 0) sisaBulan = 1;

      bebanTargetPerBulan = kekurangan / sisaBulan;

      suggestions.add("--------------------------------------------");
      suggestions.add("**Fokus Utama: ${topTarget.nama}**");
      suggestions.add(
          "**Wajib Disisihkan: ${formatRupiah(bebanTargetPerBulan)} / bulan**");
      suggestions.add("--------------------------------------------");
    }

    if (!isSimulationMode) {
      double sisaPemasukan = income - himpunanP;
      double gapTarget = bebanTargetPerBulan - sisaPemasukan;

      if (gapTarget > 0) {
        suggestions.add("**AWAS: DOMPET MENJERIT (R9)**");
        suggestions.add(
            "Sisa uang bebasmu nggak kuat buat nanggung target tabungan ini.");
        suggestions.add(
            "Tindakan: Kamu HARUS menahan hasrat jajan minimal sebesar **${formatRupiah(gapTarget)}** bulan ini.");
      } else {
        double sisaReal = sisaPemasukan - bebanTargetPerBulan;
        suggestions.add("**STATUS: AMAN JAYA (R8)**");
        suggestions.add(
            "Jatah uang jajan aslimu (setelah dipotong biaya wajib & target nabung): **${formatRupiah(sisaReal)}**");
        suggestions.add(
            "Gunakan uang ini buat senang-senang, tapi jangan sampai bablas ya.");
      }
    }

    return suggestions;
  }

  // -------------------------------------------------------
  // C. FUNGSI ADAPTER
  // -------------------------------------------------------
  static Map<String, dynamic> analisa({
    required double totalPemasukan,
    required double totalPengeluaran,
    required double himpunanP,
    required double himpunanF,
    required List<Transaksi> transaksi,
    required List<TargetModel> targets,
  }) {
    double saldoSaatIni = totalPemasukan - totalPengeluaran;
    double targetBulanan = 0;

    if (targets.isNotEmpty) {
      targets.sort((a, b) => a.deadline.compareTo(b.deadline));
      TargetModel topPriority = targets.first;
      double sisaUangTarget = topPriority.nominal - topPriority.terkumpul;
      int sisaBulan = (topPriority.sisaHari / 30).ceil();
      if (sisaBulan <= 0) sisaBulan = 1;
      targetBulanan = sisaUangTarget / sisaBulan;
    }

    FinancialData fakta = FinancialData(
      itemName: "Beban Target Bulanan",
      itemPrice: targetBulanan > 0 ? targetBulanan : 0,
      totalIncome: totalPemasukan,
      totalSaldo: saldoSaatIni,
      himpunanP: himpunanP,
      himpunanF: himpunanF,
      isItemNecessary: false,
    );

    DiagnosisResult hasilDiagnosa = runFinancialExpertSystem(fakta);

    String pesanUtama = "Data belum cukup buat dianalisis sama AI.";
    if (hasilDiagnosa.recommendations.isNotEmpty) {
      pesanUtama = hasilDiagnosa.recommendations.first;
    }

    List<String> budgetSuggestions = generateBudgetRecommendations(
        transaksi, totalPemasukan, himpunanP, himpunanF, targets);

    return {
      'sisa': saldoSaatIni,
      'ai_message': pesanUtama,
      'status': hasilDiagnosa.status,
      'budget_plan': budgetSuggestions,
    };
  }

  // -------------------------------------------------------
  // D. SISTEM NOTIFIKASI LONCENG
  // -------------------------------------------------------
  static List<Map<String, String>> generateNotifikasi(List<Transaksi> transaksi,
      Map<String, double> budgetLimits, List<TargetModel> targets) {
    List<Map<String, String>> notif = [];
    Map<String, double> spending = {};

    for (var t in transaksi) {
      if (t.jenis == 'Pengeluaran') {
        spending[t.kategori] = (spending[t.kategori] ?? 0) + t.nominal;
      }
    }

    budgetLimits.forEach((kategori, limit) {
      double spent = spending[kategori] ?? 0;
      if (limit > 0) {
        double percentage = spent / limit;
        if (percentage >= 1.0) {
          notif.add({
            'title': '$kategori JEBOL!',
            'body':
                'Udah lewat batas wajar ${formatRupiah(spent - limit)}. Ayo rem uang jajanmu hari ini buat nutupin pos ini!'
          });
        } else if (percentage >= 0.9) {
          notif.add({
            'title': '$kategori Sekarat (90%)',
            'body':
                'Sisa jatah buat $kategori mau habis nih. Tolong ngerem ya, Bestie.'
          });
        }
      }
    });

    for (var t in targets) {
      if (t.progress >= 1.0) {
        notif.add({
          'title': '🎉 Yeay! Target Lunas',
          'body':
              'Uang buat "${t.nama}" udah ngumpul. Langsung check-out sekarang!'
        });
      } else if (t.sisaHari < 7 && t.sisaHari > 0 && t.progress < 0.8) {
        notif.add({
          'title': 'Target ${t.nama} Kritis!',
          'body':
              'Deadline tinggal ${t.sisaHari} hari lagi! Aktifkan mode puasa jajan sekarang.'
        });
      }
    }

    if (notif.isEmpty) {
      notif.add({
        'title': 'Semua Terkendali',
        'body': 'Evaluasi AI: Cashflow-mu bulan ini sehat walafiat. Good job!'
      });
    }

    return notif;
  }

  // -------------------------------------------------------
  // E. HELPER GRAFIK & LAPORAN
  // -------------------------------------------------------
  static List<double> getDailyExpensesForMonth(
      List<Transaksi> transaksi, DateTime selectedMonth) {
    int daysInMonth =
        DateUtils.getDaysInMonth(selectedMonth.year, selectedMonth.month);
    List<double> dailyData = List.filled(daysInMonth + 1, 0.0);

    for (var t in transaksi) {
      if (t.jenis == 'Pengeluaran' &&
          t.tanggal.month == selectedMonth.month &&
          t.tanggal.year == selectedMonth.year) {
        if (t.tanggal.day > 0 && t.tanggal.day <= daysInMonth) {
          dailyData[t.tanggal.day] += t.nominal;
        }
      }
    }
    return dailyData;
  }

  static Map<String, double> getCategoryBreakdown(List<Transaksi> transaksi) {
    Map<String, double> breakdown = {};

    for (var t in transaksi) {
      if (t.jenis == 'Pengeluaran') {
        breakdown[t.kategori] = (breakdown[t.kategori] ?? 0) + t.nominal;
      }
    }

    var sortedKeys = breakdown.keys.toList(growable: false)
      ..sort((k1, k2) => breakdown[k2]!.compareTo(breakdown[k1]!));

    Map<String, double> sortedData = {};
    for (var key in sortedKeys) {
      sortedData[key] = breakdown[key]!;
    }
    return sortedData;
  }
}
