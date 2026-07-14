import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/data_model.dart';
import '../providers/financial_provider.dart';

class FormTransaksiScreen extends StatefulWidget {
  const FormTransaksiScreen({super.key});

  @override
  State<FormTransaksiScreen> createState() => _FormTransaksiScreenState();
}

class _FormTransaksiScreenState extends State<FormTransaksiScreen> {
  final _namaCtrl = TextEditingController();
  final _nominalCtrl = TextEditingController();

  String _jenis = 'Pengeluaran';
  String? _kategori;
  bool _isPrioritas = false;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // PERINGATAN ARSITEKTUR:
  // Menyimpan data ini secara lokal di UI adalah Anti-Pattern.
  // Pindahkan list ini ke FinancialProvider di sprint berikutnya agar persisten!
  final List<String> _kategoriPemasukan = [
    'Gaji/Bulanan',
    'Kiriman Orang Tua',
    'Bonus/THR',
    'Hadiah',
    'Jualan/Bisnis',
    'Lainnya'
  ];

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nominalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinancialProvider>(context);
    final List<String> currentCategories =
        _jenis == 'Pemasukan' ? _kategoriPemasukan : provider.allCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          _jenis == 'Pemasukan' ? "Catat Pemasukan" : "Catat Pengeluaran",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. SWITCHER JENIS TRANSAKSI ---
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    _buildTypeButton('Pengeluaran', Colors.red.shade600),
                    _buildTypeButton('Pemasukan', Colors.green.shade600),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- 2. INPUT NOMINAL ---
              Center(
                child: Text("Total Nominal",
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey.shade600)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nominalCtrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter()
                ],
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _jenis == 'Pengeluaran'
                      ? Colors.red.shade600
                      : Colors.green.shade600,
                ),
                decoration: InputDecoration(
                  prefixText: "Rp ",
                  prefixStyle: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                  hintText: "0",
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 36, color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 10),
              Divider(color: Colors.grey.shade200, thickness: 1.5),
              const SizedBox(height: 25),

              // --- 3. PILIH KATEGORI ---
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: currentCategories.contains(_kategori)
                          ? _kategori
                          : null,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      hint: Text("Pilih Kategori",
                          style: GoogleFonts.poppins(fontSize: 14)),
                      items: currentCategories.map((cat) {
                        return DropdownMenuItem(
                            value: cat,
                            child: Text(cat,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 14)));
                      }).toList(),
                      onChanged: (val) => setState(() => _kategori = val),
                      decoration:
                          _inputDecoration("Kategori", Icons.category_outlined),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _showAddCategoryDialog(provider),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Color(0xFF1565C0), size: 28),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // --- 4. CATATAN ---
              TextField(
                controller: _namaCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _inputDecoration(
                    "Catatan (Opsional)", Icons.edit_note_rounded),
              ),
              const SizedBox(height: 20),

              // --- 5. PILIH TANGGAL ---
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020), // Jangan hardcode ke 2025
                    lastDate: DateTime.now().add(const Duration(
                        days: 365)), // Beri ruang untuk target masa depan
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF1565C0),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          color: Colors.grey.shade500),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                            .format(_selectedDate),
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- 6. LOGIKA SISTIF PENGELUARAN ---
              if (_jenis == 'Pengeluaran') ...[
                Text("Sifat Pengeluaran",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87)),
                const SizedBox(height: 12),
                _buildRadioOption(
                  title: "Prioritas / Wajib",
                  subtitle: "Listrik, Air, Kost, dll.",
                  value: true,
                  color: Colors.red.shade50,
                  icon: Icons.lock_outline_rounded,
                ),
                const SizedBox(height: 12),
                _buildRadioOption(
                  title: "Fleksibel / Keinginan",
                  subtitle: "Jajan, Hobi, Hiburan (Bisa ditunda)",
                  value: false,
                  color: Colors.green.shade50,
                  icon: Icons.spa_outlined,
                ),
                const SizedBox(height: 30),
              ],

              // --- 7. TOMBOL SIMPAN ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text("Simpan Transaksi",
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- POPUP TAMBAH KATEGORI ---
  void _showAddCategoryDialog(FinancialProvider provider) {
    final TextEditingController newCatCtrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text("Tambah Kategori $_jenis",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              content: TextField(
                controller: newCatCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Misal: Skincare, Freelance",
                  hintStyle:
                      GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text("Batal",
                        style:
                            GoogleFonts.poppins(color: Colors.grey.shade600))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: () {
                    final newCat = newCatCtrl.text.trim();
                    if (newCat.isNotEmpty) {
                      setState(() {
                        if (_jenis == 'Pemasukan') {
                          if (!_kategoriPemasukan.contains(newCat)) {
                            _kategoriPemasukan.add(newCat);
                          }
                        } else {
                          provider.addCategory(newCat);
                        }
                        _kategori = newCat;
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text("Simpan",
                      style: GoogleFonts.poppins(color: Colors.white)),
                )
              ],
            ));
  }

  // --- LOGIKA PENYIMPANAN ---
  void _saveTransaction() async {
    if (_nominalCtrl.text.isEmpty || _kategori == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Nominal dan Kategori wajib diisi!",
              style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.orange.shade800));
      return;
    }

    // Parsing yang aman untuk mencegah error NaN atau format salah
    String rawInput = _nominalCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    double nominalValue = double.tryParse(rawInput) ?? 0;

    if (nominalValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Nominal tidak valid!", style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.orange.shade800));
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool finalIsPrioritas = (_jenis == 'Pemasukan') ? false : _isPrioritas;

      final newTx = Transaksi(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: "",
        nama:
            _namaCtrl.text.trim().isEmpty ? _kategori! : _namaCtrl.text.trim(),
        nominal: nominalValue,
        jenis: _jenis,
        kategori: _kategori!,
        isPrioritas: finalIsPrioritas,
        tanggal: _selectedDate,
      );

      await Provider.of<FinancialProvider>(context, listen: false)
          .addTransaksi(newTx);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Transaksi berhasil dicatat",
                style: GoogleFonts.poppins()),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.green.shade600));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Sistem Gagal: $e", style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700));
    }
  }

  // --- WIDGET HELPER ---
  Widget _buildTypeButton(String label, Color activeColor) {
    bool isSelected = _jenis == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _jenis = label;
            _kategori = null; // Reset kategori saat pindah tab
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.grey.shade600)),
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required IconData icon,
  }) {
    bool isSelected = _isPrioritas == value;
    return GestureDetector(
      onTap: () => setState(() => _isPrioritas = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(
              color: isSelected
                  ? (value ? Colors.red.shade200 : Colors.green.shade200)
                  : Colors.grey.shade200,
              width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isSelected
                      ? (value ? Colors.red : Colors.green)
                      : Colors.grey.shade400,
                  size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: value ? Colors.red : Colors.green, size: 24),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5)),
    );
  }
}

// CLASS HELPER: FORMAT RUPIAH
// Catatan: Jika class ini sudah ada di file dashboard, Anda harus menghapusnya dari salah satu file,
// atau memindahkannya ke file 'utils/formatters.dart' agar tidak terjadi penumpukan memori.
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String numericString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericString.isEmpty) return newValue.copyWith(text: '');

    double value = double.parse(numericString);

    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    String newText = formatter.format(value).trim();

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
