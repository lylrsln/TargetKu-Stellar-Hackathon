import 'package:cloud_firestore/cloud_firestore.dart';

// =====================================================================
// MODEL TRANSAKSI
// =====================================================================
class Transaksi {
  final String id;
  final String userId;
  final String nama;
  final double nominal;
  final String jenis; // 'Pemasukan' atau 'Pengeluaran'
  final String kategori;
  final bool isPrioritas;
  final DateTime tanggal;

  Transaksi({
    required this.id,
    required this.userId,
    required this.nama,
    required this.nominal,
    required this.jenis,
    required this.kategori,
    required this.isPrioritas,
    required this.tanggal,
  });

  // [WAJIB] copyWith untuk manipulasi state lokal di Provider (Agile Dev)
  Transaksi copyWith({
    String? id,
    String? userId,
    String? nama,
    double? nominal,
    String? jenis,
    String? kategori,
    bool? isPrioritas,
    DateTime? tanggal,
  }) {
    return Transaksi(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nama: nama ?? this.nama,
      nominal: nominal ?? this.nominal,
      jenis: jenis ?? this.jenis,
      kategori: kategori ?? this.kategori,
      isPrioritas: isPrioritas ?? this.isPrioritas,
      tanggal: tanggal ?? this.tanggal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nama': nama,
      'nominal': nominal,
      'jenis': jenis,
      'kategori': kategori,
      'isPrioritas': isPrioritas,
      // Konversi secara aman ke Timestamp
      'tanggal': Timestamp.fromDate(tanggal),
    };
  }

  factory Transaksi.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    return Transaksi(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      nama: data['nama']?.toString() ?? '',
      // [CRITICAL FIX] Bulletproof parsing: Melindungi dari anomali String vs Num di Firestore
      nominal: double.tryParse(data['nominal'].toString()) ?? 0.0,
      jenis: data['jenis']?.toString() ?? 'Pengeluaran',
      kategori: data['kategori']?.toString() ?? 'Lainnya',
      isPrioritas: data['isPrioritas'] is bool ? data['isPrioritas'] : false,
      // [CRITICAL FIX] Validasi tipe data Timestamp untuk mencegah Null/Type Exception
      tanggal: data['tanggal'] is Timestamp
          ? (data['tanggal'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

// =====================================================================
// MODEL TARGET
// =====================================================================
class TargetModel {
  final String id;
  final String userId;
  final String nama;
  final double nominal;
  final double terkumpul;
  final DateTime deadline;

  TargetModel({
    required this.id,
    required this.userId,
    required this.nama,
    required this.nominal,
    required this.terkumpul,
    required this.deadline,
  });

  // [WAJIB] copyWith untuk manipulasi state lokal di Provider
  TargetModel copyWith({
    String? id,
    String? userId,
    String? nama,
    double? nominal,
    double? terkumpul,
    DateTime? deadline,
  }) {
    return TargetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nama: nama ?? this.nama,
      nominal: nominal ?? this.nominal,
      terkumpul: terkumpul ?? this.terkumpul,
      deadline: deadline ?? this.deadline,
    );
  }

  // Hitung Progress (Murni logika matematika data internal, masih bisa ditolerir di DTO)
  double get progress =>
      nominal <= 0 ? 0 : (terkumpul / nominal).clamp(0.0, 1.0);

  // [PERINGATAN ARSITEKTUR]
  // Fungsi 'sisaHari' dan 'saranNabungHarian' sebaiknya dipindah ke FinancialAdvisor
  // agar DTO terisolasi dari 'DateTime.now()'.
  // Namun saya perbaiki normalisasinya jika Anda bersikeras menahannya di sini.
  int get sisaHari {
    final now = DateTime.now();
    // Gunakan normalisasi UTC untuk menghindari anomali geser hari akibat Timezone (WIB/WITA/WIT)
    final dateNow = DateTime.utc(now.year, now.month, now.day);
    final dateDeadline =
        DateTime.utc(deadline.year, deadline.month, deadline.day);

    final difference = dateDeadline.difference(dateNow).inDays;
    return difference < 0 ? 0 : difference;
  }

  double get saranNabungHarian {
    int sisa = sisaHari;
    double kekurangan = nominal - terkumpul;
    // Mencegah nilai negatif dan divisi nol
    if (sisa <= 0 || kekurangan <= 0) return 0.0;
    return kekurangan / sisa;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nama': nama,
      'nominal': nominal,
      'terkumpul': terkumpul,
      'deadline': Timestamp.fromDate(deadline),
    };
  }

  factory TargetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    return TargetModel(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      nama: data['nama']?.toString() ?? '',
      // [CRITICAL FIX] Bulletproof parsing
      nominal: double.tryParse(data['nominal'].toString()) ?? 0.0,
      terkumpul: double.tryParse(data['terkumpul'].toString()) ?? 0.0,
      // [CRITICAL FIX] Validasi tipe data Timestamp
      deadline: data['deadline'] is Timestamp
          ? (data['deadline'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
