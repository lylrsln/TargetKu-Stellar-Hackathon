import 'dart:io';
import 'dart:ui' as ui; // DIBUTUHKAN UNTUK RENDER GRAFIK
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // DIBUTUHKAN UNTUK REPAINT BOUNDARY
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../providers/financial_provider.dart';
import '../models/data_model.dart';

class LaporanView extends StatefulWidget {
  const LaporanView({super.key});

  @override
  State<LaporanView> createState() => _LaporanViewState();
}

class _LaporanViewState extends State<LaporanView> {
  String _filter = 'Bulanan';
  int _chartTab = 1; // 0 = Pemasukan, 1 = Pengeluaran
  DateTime _viewedMonth = DateTime.now();

  final List<String> _filterOptions = ['Bulanan', 'Tahunan', 'Semua'];

  // KEY UNTUK MENANGKAP GAMBAR PIE CHART
  final GlobalKey _chartKey = GlobalKey();
  bool _isExporting = false; // Mencegah spam klik tombol download

  void _changeMonth(int offset) {
    setState(() {
      _viewedMonth = DateTime(_viewedMonth.year, _viewedMonth.month + offset);
    });
  }

  void _pickMonthYear() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _viewedMonth,
      firstDate: DateTime(2025),
      lastDate: DateTime(3000),
      initialDatePickerMode: DatePickerMode.year,
      helpText: "PILIH PERIODE LAPORAN",
    );
    if (picked != null) {
      setState(() {
        _viewedMonth = picked;
      });
    }
  }

  String _formatRp(double value) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)
        .format(value);
  }

  // --- FUNGSI EXPORT PDF DIRECT DOWNLOAD & PIE CHART ---
  Future<void> _exportToPDF(List<Transaksi> originalData) async {
    setState(() => _isExporting = true);

    try {
      final pdf = pw.Document();

      // 1. URUTKAN DATA
      List<Transaksi> dataForPdf = List.from(originalData);
      dataForPdf.sort((a, b) => a.tanggal.compareTo(b.tanggal));

      double totalPemasukan = 0;
      double totalPengeluaran = 0;
      double totalPrioritas = 0;
      double totalFleksibel = 0;

      for (var item in dataForPdf) {
        if (item.jenis == 'Pemasukan') {
          totalPemasukan += item.nominal;
        } else {
          totalPengeluaran += item.nominal;
          if (item.isPrioritas) {
            totalPrioritas += item.nominal;
          } else {
            totalFleksibel += item.nominal;
          }
        }
      }
      double sisaSaldo = totalPemasukan - totalPengeluaran;

      String periodeStr = _filter == 'Bulanan'
          ? DateFormat('MMMM yyyy', 'id_ID').format(_viewedMonth)
          : (_filter == 'Tahunan'
              ? DateFormat('yyyy', 'id_ID').format(_viewedMonth)
              : "Semua Waktu");

      // 2. CAPTURE GRAFIK (Jika ada di layar)
      pw.MemoryImage? pdfChartImage;
      if (_chartKey.currentContext != null) {
        try {
          RenderRepaintBoundary boundary = _chartKey.currentContext!
              .findRenderObject() as RenderRepaintBoundary;
          ui.Image image =
              await boundary.toImage(pixelRatio: 3.0); // Resolusi tinggi
          ByteData? byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            pdfChartImage = pw.MemoryImage(byteData.buffer.asUint8List());
          }
        } catch (e) {
          debugPrint("Gagal menangkap gambar grafik: $e");
          // Lanjut walau gagal, jangan hancurkan proses PDF
        }
      }

      // 3. BUAT HALAMAN PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                  level: 0,
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Laporan Keuangan",
                            style: pw.TextStyle(
                                fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.Text("Periode: $periodeStr",
                            style: const pw.TextStyle(
                                fontSize: 12, color: PdfColors.grey700)),
                      ])),
              pw.SizedBox(height: 10),
              pw.Text(
                  "Dicetak pada: ${DateFormat('dd MMMM yyyy HH:mm').format(DateTime.now())}",
                  style:
                      const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              pw.SizedBox(height: 20),

              // KOTAK RINGKASAN
              pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(8),
                      color: PdfColors.grey100),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("RINGKASAN KEUANGAN",
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Divider(),
                        _buildPdfSummaryRow(
                            "Total Pemasukan", totalPemasukan, PdfColors.green),
                        _buildPdfSummaryRow("Total Pengeluaran",
                            totalPengeluaran, PdfColors.red),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 10),
                          child: _buildPdfSummaryRow("- Prioritas (Wajib)",
                              totalPrioritas, PdfColors.grey700,
                              isSmall: true),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 10),
                          child: _buildPdfSummaryRow("- Fleksibel (Bisa Hemat)",
                              totalFleksibel, PdfColors.grey700,
                              isSmall: true),
                        ),
                        pw.Divider(),
                        pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("SISA SALDO (Netto)",
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 14)),
                              pw.Text(_formatRp(sisaSaldo),
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 14,
                                      color: sisaSaldo >= 0
                                          ? PdfColors.blue
                                          : PdfColors.red)),
                            ])
                      ])),
              pw.SizedBox(height: 20),

              // GRAFIK PDF
              if (pdfChartImage != null) ...[
                pw.Text("Grafik Analisis:",
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Container(
                    height: 200, // Menjaga aspek rasio
                    child: pw.Image(pdfChartImage),
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              pw.Text("Rincian Transaksi",
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              // TABEL TRANSAKSI
              pw.Table.fromTextArray(
                  headers: [
                    "Tanggal",
                    "Nama",
                    "Kategori",
                    "Status",
                    "Masuk",
                    "Keluar"
                  ],
                  data: dataForPdf.map((item) {
                    return [
                      DateFormat('dd/MM').format(item.tanggal),
                      item.nama,
                      item.kategori,
                      item.jenis == 'Pengeluaran'
                          ? (item.isPrioritas ? "Wajib" : "Fleksibel")
                          : "-",
                      item.jenis == 'Pemasukan' ? _formatRp(item.nominal) : "-",
                      item.jenis == 'Pengeluaran'
                          ? _formatRp(item.nominal)
                          : "-",
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.blue800),
                  rowDecoration: const pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColors.grey300, width: 0.5))),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellAlignments: {
                    4: pw.Alignment.centerRight,
                    5: pw.Alignment.centerRight
                  }),
            ];
          },
        ),
      );

      // 4. PENYIMPANAN LANGSUNG (DIRECT DOWNLOAD HACK)
      Directory? directory;
      if (Platform.isAndroid) {
        // PERINGATAN LOGIKA: Rute ini memaksa masuk ke penyimpanan eksternal.
        // Bisa diblokir oleh OS jika permission belum tersetting murni.
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory(); // Fallback aman
        }
      } else {
        // iOS tidak mengizinkan direct file access dengan mudah
        directory = await getApplicationDocumentsDirectory();
      }

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName =
          "Laporan_TargetKu_${periodeStr.replaceAll(' ', '_')}_$timestamp.pdf";

      final path = "${directory!.path}/$fileName";
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("PDF tersimpan di folder Download!\n($fileName)"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Gagal menyimpan PDF. Periksa izin storage! Error: $e"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  pw.Widget _buildPdfSummaryRow(String label, double amount, PdfColor color,
      {bool isSmall = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: isSmall ? 10 : 12)),
          pw.Text(_formatRp(amount),
              style: pw.TextStyle(
                  fontSize: isSmall ? 10 : 12,
                  color: color,
                  fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  void _showEditDeleteDialog(
      BuildContext context, Transaksi item, FinancialProvider fin) {
    final namaCtrl = TextEditingController(text: item.nama);
    final nominalCtrl =
        TextEditingController(text: item.nominal.toInt().toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Opsi Transaksi",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaCtrl,
              decoration: const InputDecoration(
                  labelText: "Nama Transaksi", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nominalCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter()
              ],
              decoration: const InputDecoration(
                  labelText: "Nominal",
                  prefixText: "Rp ",
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (confirmCtx) => AlertDialog(
                        title: const Text("Hapus Permanen?"),
                        content: const Text("Data ini akan hilang."),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(confirmCtx),
                              child: const Text("Batal")),
                          TextButton(
                            onPressed: () {
                              fin.deleteTransaksi(item.id);
                              Navigator.pop(confirmCtx);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Data dihapus"),
                                      backgroundColor: Colors.red));
                            },
                            child: const Text("Ya, Hapus",
                                style: TextStyle(color: Colors.red)),
                          )
                        ],
                      ));
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0)),
            onPressed: () {
              if (namaCtrl.text.isNotEmpty && nominalCtrl.text.isNotEmpty) {
                double val = double.parse(nominalCtrl.text.replaceAll('.', ''));
                fin.updateTransaksi(item.id, namaCtrl.text, val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Perubahan disimpan!"),
                    backgroundColor: Colors.green));
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancialProvider>(
      builder: (context, fin, child) {
        List<Transaksi> filteredList = [];
        if (_filter == 'Bulanan') {
          filteredList = fin.transaksi
              .where((t) =>
                  t.tanggal.month == _viewedMonth.month &&
                  t.tanggal.year == _viewedMonth.year)
              .toList();
        } else if (_filter == 'Tahunan') {
          filteredList = fin.transaksi
              .where((t) => t.tanggal.year == _viewedMonth.year)
              .toList();
        } else {
          filteredList = List.from(fin.transaksi);
        }
        filteredList.sort((a, b) => b.tanggal.compareTo(a.tanggal));

        String jenisChart = _chartTab == 0 ? 'Pemasukan' : 'Pengeluaran';
        var listForChart =
            filteredList.where((t) => t.jenis == jenisChart).toList();
        Map<String, double> chartData = {};
        for (var t in listForChart) {
          if (!chartData.containsKey(t.kategori)) chartData[t.kategori] = 0;
          chartData[t.kategori] = chartData[t.kategori]! + t.nominal;
        }
        double totalChartAmount =
            listForChart.fold(0, (sum, t) => sum + t.nominal);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: Text("Laporan Keuangan",
                style: GoogleFonts.poppins(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              _isExporting
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))))
                  : IconButton(
                      icon: const Icon(Icons.download_rounded,
                          color: Color(0xFF1565C0)),
                      tooltip: "Download PDF Langsung",
                      onPressed: () {
                        if (filteredList.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Data kosong, tidak bisa download!"),
                                  backgroundColor: Colors.orange));
                        } else {
                          _exportToPDF(filteredList);
                        }
                      },
                    )
            ],
          ),
          body: RefreshIndicator(
            color: const Color(0xFF1565C0),
            onRefresh: () async {
              await Provider.of<FinancialProvider>(context, listen: false)
                  .refreshData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_filter == 'Bulanan')
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 15),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.shade100, blurRadius: 5)
                          ]),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                              onPressed: () => _changeMonth(-1),
                              icon: const Icon(Icons.chevron_left_rounded,
                                  size: 30, color: Color(0xFF1565C0))),
                          InkWell(
                            onTap: _pickMonthYear,
                            child: Column(children: [
                              Row(
                                children: [
                                  Text(
                                      DateFormat('MMMM yyyy', 'id_ID')
                                          .format(_viewedMonth),
                                      style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 5),
                                  const Icon(Icons.arrow_drop_down,
                                      size: 20, color: Colors.grey)
                                ],
                              ),
                              const Text("Tekan untuk pilih tahun",
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey))
                            ]),
                          ),
                          IconButton(
                              onPressed: () => _changeMonth(1),
                              icon: const Icon(Icons.chevron_right_rounded,
                                  size: 30, color: Color(0xFF1565C0))),
                        ],
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filter,
                        isExpanded: true,
                        icon: const Icon(Icons.filter_list,
                            color: Color(0xFF1565C0)),
                        items: _filterOptions
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) => setState(() => _filter = val!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      _buildTabButton("Pengeluaran", 1, Colors.red),
                      const SizedBox(width: 10),
                      _buildTabButton("Pemasukan", 0, Colors.green),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // PEMBUNGKUS REPAINT BOUNDARY UNTUK CAPTURE GRAFIK
                  RepaintBoundary(
                    key: _chartKey,
                    child: chartData.isNotEmpty
                        ? Container(
                            height: 220,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      PieChart(PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 30,
                                        sections: chartData.entries.map((e) {
                                          final isLarge =
                                              e.value / totalChartAmount > 0.3;
                                          return PieChartSectionData(
                                              value: e.value,
                                              title:
                                                  "${(e.value / totalChartAmount * 100).toInt()}%",
                                              color:
                                                  _getColorForCategory(e.key),
                                              radius: isLarge ? 50 : 40,
                                              titleStyle: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white));
                                        }).toList(),
                                      )),
                                      Text(
                                          "Total\n${NumberFormat.compactCurrency(locale: 'id', symbol: '').format(totalChartAmount)}",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold))
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 1,
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: chartData.entries
                                        .map((e) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Row(children: [
                                              Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                      color:
                                                          _getColorForCategory(
                                                              e.key),
                                                      shape: BoxShape.circle)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child: Text(e.key,
                                                      style: const TextStyle(
                                                          fontSize: 12),
                                                      overflow: TextOverflow
                                                          .ellipsis))
                                            ])))
                                        .toList(),
                                  ),
                                )
                              ],
                            ),
                          )
                        : Container(
                            height: 150,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20)),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bar_chart,
                                      size: 40, color: Colors.grey.shade300),
                                  const SizedBox(height: 10),
                                  Text("Tidak ada data di periode ini",
                                      style: TextStyle(
                                          color: Colors.grey.shade500))
                                ]),
                          ),
                  ),

                  const SizedBox(height: 25),
                  Text("Rincian Transaksi",
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700])),
                  const SizedBox(height: 10),

                  filteredList.isEmpty
                      ? const Center(
                          child: Padding(
                              padding: EdgeInsets.all(30),
                              child: Text("Data Kosong")))
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final t = filteredList[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  side: BorderSide(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                onTap: () =>
                                    _showEditDeleteDialog(context, t, fin),
                                leading: CircleAvatar(
                                  backgroundColor: t.jenis == 'Pemasukan'
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  child: Icon(
                                      t.jenis == 'Pemasukan'
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: t.jenis == 'Pemasukan'
                                          ? Colors.green
                                          : Colors.red,
                                      size: 20),
                                ),
                                title: Text(t.nama,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                    "${DateFormat('dd MMM yyyy').format(t.tanggal)} • ${t.kategori}"),
                                trailing: Text(
                                    NumberFormat.currency(
                                            locale: 'id',
                                            symbol: '',
                                            decimalDigits: 0)
                                        .format(t.nominal),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: t.jenis == 'Pemasukan'
                                            ? Colors.green
                                            : Colors.red)),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String label, int index, Color color) {
    bool isActive = _chartTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _chartTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: isActive ? color : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: isActive ? color : Colors.grey.shade300)),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Color _getColorForCategory(String kategori) {
    int hash = kategori.hashCode;
    return Color((hash & 0xFFFFFF).toInt()).withOpacity(1.0).withAlpha(255);
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
