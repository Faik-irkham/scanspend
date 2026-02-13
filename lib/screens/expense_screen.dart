// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../services/ocr_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final OcrService _ocrService = OcrService();
  final ImagePicker _picker = ImagePicker();
  final List<Expense> _expenses = [];
  bool _isScanning = false;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  double get _totalExpense =>
      _expenses.fold(0, (sum, item) => sum + item.amount);

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(source: source);
      if (photo == null) return;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: photo.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Sesuaikan Struk',
            toolbarColor: const Color(0xFF6366F1),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Sesuaikan Struk'),
        ],
      );

      if (croppedFile == null) return;

      setState(() => _isScanning = true);
      final result = await _ocrService.scanReceipt(croppedFile.path);
      setState(() => _isScanning = false);

      _showEditDialog(result);
    } catch (e) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Oops! Terjadi kesalahan: $e')));
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Pilih Sumber Gambar",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.indigo[900],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSourceOption(
                  Icons.camera_alt_rounded,
                  "Kamera",
                  ImageSource.camera,
                  const Color(0xFF6366F1),
                ),
                _buildSourceOption(
                  Icons.photo_library_rounded,
                  "Galeri",
                  ImageSource.gallery,
                  const Color(0xFF8B5CF6),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(
    IconData icon,
    String label,
    ImageSource source,
    Color color,
  ) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            Navigator.pop(context);
            _pickAndProcessImage(source);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: color, size: 36),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.indigo[900],
          ),
        ),
      ],
    );
  }

  void _showEditDialog(Map<String, dynamic> result) {
    TextEditingController dateController = TextEditingController(
      text: result['date'],
    );
    TextEditingController amountController = TextEditingController(
      text: result['amount'].toString().split('.')[0],
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Center(
          child: Text(
            "Verifikasi Data",
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Pastikan data yang terbaca sudah sesuai dengan struk Anda.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: "Tanggal",
                hintText: "Contoh: 14 Feb 2026",
                prefixIcon: const Icon(Icons.calendar_today_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              decoration: InputDecoration(
                labelText: "Total Pengeluaran",
                prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                prefixText: "Rp ",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Batal"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (amountController.text.isEmpty) return;
                    setState(() {
                      _expenses.insert(
                        0,
                        Expense(
                          id: DateTime.now().toString(),
                          date: dateController.text,
                          amount: double.tryParse(amountController.text) ?? 0.0,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text("Simpan"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 260.0,
            pinned: true,
            elevation: 0,
            stretch: true,
            backgroundColor: const Color(0xFF4F46E5),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Saldo Pengeluaran",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currencyFormatter.format(_totalExpense),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          "${_expenses.length} Transaksi Terdeteksi",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            title: const Text(
              "ScanSpend",
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Aktivitas Terbaru",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.indigo[900],
                    ),
                  ),
                  Icon(Icons.sort_rounded, color: Colors.indigo[300]),
                ],
              ),
            ),
          ),
          _isScanning
              ? const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(strokeWidth: 3),
                        SizedBox(height: 20),
                        Text(
                          "Menganalisa struk...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _expenses.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildExpenseCard(_expenses[index], index),
                      childCount: _expenses.length,
                    ),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImageSourceActionSheet,
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: const Text(
          "Scan Struk Baru",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.auto_graph_rounded,
              size: 80,
              color: Colors.indigo[100],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Mulai Pantau Pengeluaran",
            style: TextStyle(
              color: Colors.indigo[900],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Scan struk belanjaanmu untuk mencatat otomatis",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.receipt_rounded,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currencyFormatter.format(item.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.indigo[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.date,
                          style: TextStyle(
                            color: Colors.indigo[200],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red[300],
                        size: 20,
                      ),
                    ),
                    onPressed: () => setState(() => _expenses.removeAt(index)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
