import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/data_model.dart';
import '../logic/financial_advisor.dart'; // [WAJIB] Integrasi Sistem Pakar

class FinancialProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- DATA LOKAL ---
  List<Transaksi> _transaksi = [];
  List<TargetModel> _targets = [];

  List<String> _categories = [
    'Makan & Minum',
    'Transportasi',
    'Belanja',
    'Tagihan',
    'Hiburan',
    'Kesehatan',
    'Pendidikan',
    'Tabungan',
    'Lainnya'
  ];

  Map<String, double> _budgetLimits = {};
  DateTime _selectedMonth = DateTime.now();

  // ==========================================================
  // [MEMORY] PROFIL KEUANGAN PENGGUNA
  // ==========================================================
  static const double _defaultIncomeUmpar = 1800000;
  static const double _defaultMakanUmpar = 900000;
  static const double _defaultKosUmpar = 500000;

  double savedIncome = _defaultIncomeUmpar;
  bool savedIsAnakKos = true;
  double savedKos = _defaultKosUmpar;
  double savedListrik = 50000;
  double savedMakan = _defaultMakanUmpar;
  double savedTransport = 150000;
  double savedTagihan = 100000;
  Map<String, double> savedCustomExpenses = {};

  // --- GETTER DASAR ---
  List<Transaksi> get transaksi => _transaksi;
  List<TargetModel> get targets => _targets;
  List<String> get allCategories => _categories;
  DateTime get selectedMonth => _selectedMonth;
  Map<String, double> get budgetLimits => _budgetLimits;
  String? get currentUserId => _auth.currentUser?.uid;

  // --- LETAKKAN GETTER INI DI SINI ---
  bool get isHistoryComplete3Months {
    if (_transaksi.isEmpty) return false;

    // Asumsi: Transaksi terlama berada di index terakhir
    // karena sudah di-fetch dengan orderBy('tanggal', descending: true)
    DateTime transaksiTerlama = _transaksi.last.tanggal;
    DateTime hariIni = DateTime.now();

    int selisihHari = hariIni.difference(transaksiTerlama).inDays;

    // Mengembalikan true jika data sudah terkumpul minimal 90 hari (3 bulan)
    return selisihHari >= 90;
  }

  // Juga tambahkan getter untuk daftar tanggal yang bolong agar bisa tampil di dialog
  List<DateTime> get missingDates {
    List<DateTime> missing = [];
    DateTime now = DateTime.now();
    DateTime ninetyDaysAgo = now.subtract(const Duration(days: 90));

    for (int i = 0; i <= 90; i++) {
      DateTime dateToCheck = ninetyDaysAgo.add(Duration(days: i));
      // Cek apakah ada transaksi di tanggal tersebut
      bool hasData = _transaksi.any((t) =>
          t.tanggal.year == dateToCheck.year &&
          t.tanggal.month == dateToCheck.month &&
          t.tanggal.day == dateToCheck.day);
      if (!hasData) missing.add(dateToCheck);
    }
    return missing;
  }

  double _calculateAverage(bool isIncome, [List<String>? categories]) {
    if (_transaksi.isEmpty) return 0.0;

    DateTime oldest = _transaksi.last.tanggal;
    double months = DateTime.now().difference(oldest).inDays / 30.0;
    if (months < 1.0)
      months = 1.0; // Set minimal 1 bulan agar tidak error dibagi desimal kecil

    double total = 0.0;
    for (var tx in _transaksi) {
      if (isIncome && tx.jenis == 'Pemasukan') {
        total += tx.nominal;
      } else if (!isIncome && tx.jenis == 'Pengeluaran') {
        if (categories == null || categories.contains(tx.kategori)) {
          total += tx.nominal;
        }
      }
    }
    return total / months;
  }

  double get avgIncome => _calculateAverage(true);
  double get avgKos => _calculateAverage(false, ['Biaya Kos']);
  double get avgListrik => _calculateAverage(false, ['Listrik/Air']);
  double get avgMakan => _calculateAverage(false, ['Makan & Minum']);
  double get avgTransport => _calculateAverage(false, ['Transportasi']);
  double get avgTagihan =>
      _calculateAverage(false, ['Tagihan', 'Tagihan/Kuota']);

  Map<String, double> get avgCustomExpenses {
    // Kategori utama dan Tabungan tidak dimasukkan ke dalam custom expenses
    List<String> excludedCats = [
      'Biaya Kos',
      'Listrik/Air',
      'Makan & Minum',
      'Transportasi',
      'Tagihan',
      'Tagihan/Kuota',
      'Tabungan'
    ];
    Map<String, double> result = {};
    if (_transaksi.isEmpty) return result;

    DateTime oldest = _transaksi.last.tanggal;
    double months = DateTime.now().difference(oldest).inDays / 30.0;
    if (months < 1.0) months = 1.0;

    for (var tx in _transaksi) {
      if (tx.jenis == 'Pengeluaran' && !excludedCats.contains(tx.kategori)) {
        result[tx.kategori] = (result[tx.kategori] ?? 0) + tx.nominal;
      }
    }

    result.updateAll((key, value) => value / months);
    return result;
  }

  // ==========================================================
  // [GETTERS KOMPLEKS UNTUK DASHBOARD & ADVISOR]
  // ==========================================================

  List<Transaksi> get transaksiBulanIni {
    return _transaksi
        .where((t) =>
            t.tanggal.month == _selectedMonth.month &&
            t.tanggal.year == _selectedMonth.year)
        .toList();
  }

  double get pemasukanBulanIni {
    return transaksiBulanIni
        .where((t) => t.jenis == 'Pemasukan')
        .fold(0, (sum, item) => sum + item.nominal);
  }

  double get totalTabunganBulanIni {
    // Mengambil total dari history transaksi dengan kategori 'Tabungan' di bulan ini
    return transaksiBulanIni
        .where((t) => t.kategori == 'Tabungan')
        .fold(0, (sum, item) => sum + item.nominal);
  }

  double get pengeluaranBulanIni {
    return transaksiBulanIni
        .where((t) =>
            t.jenis == 'Pengeluaran' &&
            t.kategori != 'Tabungan') // Eksklusi Tabungan
        .fold(0, (sum, item) => sum + item.nominal);
  }

  double get sisaSaldoBulanIni => pemasukanBulanIni - pengeluaranBulanIni;

  double get rataRataHarianBulanIni {
    int currentDay = DateTime.now().month == _selectedMonth.month &&
            DateTime.now().year == _selectedMonth.year
        ? DateTime.now().day
        : DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    return currentDay > 0 ? (pengeluaranBulanIni / currentDay) : 0;
  }

  Map<String, double> get pengeluaranPerKategori {
    return FinancialAdvisor.getCategoryBreakdown(transaksiBulanIni);
  }

  List<double> get pengeluaranHarianBulanIni {
    return FinancialAdvisor.getDailyExpensesForMonth(
        _transaksi, _selectedMonth);
  }

  List<double> get pemasukanHarianBulanIni {
    int daysInMonth =
        DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    List<double> dailyData = List.filled(daysInMonth + 1, 0.0);
    for (var t in transaksiBulanIni) {
      if (t.jenis == 'Pemasukan') {
        if (t.tanggal.day > 0 && t.tanggal.day <= daysInMonth) {
          dailyData[t.tanggal.day] += t.nominal;
        }
      }
    }
    return dailyData;
  }

  List<Map<String, String>> get statusAnggaranNotifikasi {
    return FinancialAdvisor.generateNotifikasi(
        transaksiBulanIni, _budgetLimits, _targets);
  }

  // =========================================
  // 0. FITUR REFRESH
  // =========================================
  Future<void> refreshData() async {
    await fetchData();
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }

  // =========================================
  // 1. UPDATE & SIMPAN PROFIL
  // =========================================
  Future<void> updateFinancialProfile({
    required double income,
    required bool isAnakKos,
    required double kos,
    required double listrik,
    required double makan,
    required double transport,
    required double tagihan,
    required Map<String, double> customExpenses,
  }) async {
    if (currentUserId == null) return;
    String uid = currentUserId!;

    savedIncome = income;
    savedIsAnakKos = isAnakKos;
    savedKos = kos;
    savedListrik = listrik;
    savedMakan = makan;
    savedTransport = transport;
    savedTagihan = tagihan;
    savedCustomExpenses = customExpenses;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('prof_income_$uid', income);
    await prefs.setBool('prof_isAnakKos_$uid', isAnakKos);
    await prefs.setDouble('prof_kos_$uid', kos);
    await prefs.setDouble('prof_listrik_$uid', listrik);
    await prefs.setDouble('prof_makan_$uid', makan);
    await prefs.setDouble('prof_transport_$uid', transport);
    await prefs.setDouble('prof_tagihan_$uid', tagihan);
    await prefs.setString('prof_custom_$uid', jsonEncode(customExpenses));
  }

  Future<void> _loadProfileFromPrefs() async {
    if (currentUserId == null) return;
    String uid = currentUserId!;
    final prefs = await SharedPreferences.getInstance();

    savedIncome = prefs.getDouble('prof_income_$uid') ?? _defaultIncomeUmpar;
    savedIsAnakKos = prefs.getBool('prof_isAnakKos_$uid') ?? true;
    savedKos = prefs.getDouble('prof_kos_$uid') ?? _defaultKosUmpar;
    savedListrik = prefs.getDouble('prof_listrik_$uid') ?? 50000;
    savedMakan = prefs.getDouble('prof_makan_$uid') ?? _defaultMakanUmpar;
    savedTransport = prefs.getDouble('prof_transport_$uid') ?? 150000;
    savedTagihan = prefs.getDouble('prof_tagihan_$uid') ?? 100000;

    String? customJson = prefs.getString('prof_custom_$uid');
    if (customJson != null) {
      Map<String, dynamic> decoded = jsonDecode(customJson);
      savedCustomExpenses =
          decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } else {
      savedCustomExpenses = {};
    }
  }

  // =========================================
  // 2. FETCH DATA (LOAD)
  // =========================================
  Future<void> fetchData() async {
    if (currentUserId == null) return;
    try {
      await _loadProfileFromPrefs();

      final txSnapshot = await _db
          .collection('users')
          .doc(currentUserId)
          .collection('transaksi')
          .orderBy('tanggal', descending: true)
          .get();

      _transaksi =
          txSnapshot.docs.map((doc) => Transaksi.fromFirestore(doc)).toList();

      final catSnapshot = await _db
          .collection('users')
          .doc(currentUserId)
          .collection('categories')
          .get();
      if (catSnapshot.docs.isNotEmpty) {
        List<String> customCats =
            catSnapshot.docs.map((d) => d['name'] as String).toList();
        Set<String> uniqueCats = {..._categories, ...customCats};
        _categories = uniqueCats.toList();
      }

      final targetSnapshot = await _db
          .collection('users')
          .doc(currentUserId)
          .collection('targets')
          .get();

      _targets = targetSnapshot.docs
          .map((doc) => TargetModel.fromFirestore(doc))
          .toList();

      await loadBudgetLimits();
      notifyListeners();
    } catch (e) {
      debugPrint("Error Fetching Data: $e");
    }
  }

  // =========================================
  // 3. CRUD TRANSAKSI (DENGAN OPTIMISTIC UPDATE & ROLLBACK)
  // =========================================
  Future<void> addTransaksi(Transaksi tx) async {
    if (currentUserId == null) return;

    // UI Update instan (Optimistic)
    _transaksi.insert(0, tx);
    notifyListeners();

    try {
      await _db
          .collection('users')
          .doc(currentUserId)
          .collection('transaksi')
          .doc(tx.id)
          .set(tx.toMap());
    } catch (e) {
      // Rollback jika terjadi kegagalan injeksi database
      _transaksi.remove(tx);
      notifyListeners();
      debugPrint("Rollback Transaksi Error: $e");
      rethrow;
    }
  }

  Future<void> deleteTransaksi(String id) async {
    if (currentUserId == null) return;

    final int txIndex = _transaksi.indexWhere((t) => t.id == id);
    if (txIndex == -1) return;
    final Transaksi deletedTx = _transaksi[txIndex];

    _transaksi.removeAt(txIndex);
    notifyListeners();

    try {
      await _db
          .collection('users')
          .doc(currentUserId)
          .collection('transaksi')
          .doc(id)
          .delete();
    } catch (e) {
      _transaksi.insert(txIndex, deletedTx); // Rollback
      notifyListeners();
    }
  }

  Future<void> updateTransaksi(
      String id, String newName, double newNominal) async {
    if (currentUserId == null) return;
    try {
      int index = _transaksi.indexWhere((t) => t.id == id);
      if (index != -1) {
        _transaksi[index] =
            _transaksi[index].copyWith(nama: newName, nominal: newNominal);
        notifyListeners();

        await _db
            .collection('users')
            .doc(currentUserId)
            .collection('transaksi')
            .doc(id)
            .update({'nama': newName, 'nominal': newNominal});
      }
    } catch (e) {
      debugPrint("Gagal Update Transaksi: $e");
    }
  }

  // =========================================
  // 4. KATEGORI & FILTER
  // =========================================
  Future<void> addCategory(String newCat) async {
    if (currentUserId == null) return;
    if (!_categories.contains(newCat)) {
      _categories.add(newCat);
      notifyListeners();
      await _db
          .collection('users')
          .doc(currentUserId)
          .collection('categories')
          .add({'name': newCat});
    }
  }

  void changeMonth(int i) {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + i);
    notifyListeners();
  }

  void setMonth(DateTime date) {
    _selectedMonth = date;
    notifyListeners();
  }

  // =========================================
  // 5. FITUR TARGET (MURNI TANPA DOUBLE COUNTING)
  // =========================================
  Future<void> addTarget(String nama, double nominal, DateTime date) async {
    if (currentUserId == null) return;
    String id = DateTime.now().millisecondsSinceEpoch.toString();

    TargetModel newTarget = TargetModel(
        id: id,
        userId: currentUserId!,
        nama: nama,
        nominal: nominal,
        terkumpul: 0,
        deadline: date);

    _targets.add(newTarget);
    notifyListeners();

    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('targets')
        .doc(id)
        .set(newTarget.toMap());
  }

  Future<void> deleteTarget(String id) async {
    if (currentUserId == null) return;
    _targets.removeWhere((t) => t.id == id);
    notifyListeners();
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('targets')
        .doc(id)
        .delete();
  }

  Future<void> isiTabunganTarget(
      String targetId, double nominalTargetDitekan) async {
    if (currentUserId == null) return;
    int index = _targets.indexWhere((t) => t.id == targetId);
    if (index == -1) return;

    TargetModel target = _targets[index];
    double newTerkumpul = target.terkumpul + nominalTargetDitekan;

    _targets[index] = target.copyWith(terkumpul: newTerkumpul);
    notifyListeners();

    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('targets')
        .doc(targetId)
        .update({'terkumpul': newTerkumpul});

    String txId = DateTime.now().millisecondsSinceEpoch.toString();
    Transaksi tx = Transaksi(
        id: txId,
        userId: currentUserId!,
        nama: "Nabung: ${target.nama}",
        nominal: nominalTargetDitekan,
        jenis: "Pengeluaran",
        kategori: "Tabungan",
        isPrioritas: false,
        tanggal: DateTime.now());

    await addTransaksi(
        tx); // Ini hanya merekam riwayat, TIDAK AKAN loop menggandakan uang lagi
  }

  // =========================================
  // 6. BUDGET LIMITS
  // =========================================
  Future<void> setBudgetLimit(String category, double amount) async {
    if (currentUserId == null) return;
    _budgetLimits[category] = amount;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String uid = currentUserId!;
    await prefs.setDouble('limit_${uid}_$category', amount);
  }

  Future<void> loadBudgetLimits() async {
    if (currentUserId == null) return;
    final prefs = await SharedPreferences.getInstance();
    String uid = currentUserId!;

    _budgetLimits = {};

    for (String cat in _categories) {
      double? savedLimit = prefs.getDouble('limit_${uid}_$cat');
      if (savedLimit != null) {
        _budgetLimits[cat] = savedLimit;
      } else {
        _budgetLimits[cat] = 0;
      }
    }
    notifyListeners();
  }
}
