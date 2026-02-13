import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

class OcrService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<Map<String, dynamic>> scanReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    double? totalAmount;
    String? date;
    List<String> lines = recognizedText.text.split('\n');
    List<Map<String, dynamic>> processedLines = [];

    final negativePattern = RegExp(
      r'(KEMBALI|CHANGE|TUNAI|CASH|PAID|DIBAYAR|TENDERED|NOMOR|TELP)',
    );

    for (int i = 0; i < lines.length; i++) {
      String cleanLine = lines[i].toUpperCase().trim();

      RegExp dateReg = RegExp(r'\d{1,2}[./-]\d{1,2}[./-]\d{2,4}');
      if (date == null && dateReg.hasMatch(cleanLine)) {
        date = _normalizeDate(dateReg.firstMatch(cleanLine)!.group(0)!);
      }

      String digitsOnly = cleanLine
          .replaceAll('RP', '')
          .replaceAll(RegExp(r'[^0-9]'), '');

      if (digitsOnly.isNotEmpty) {
        double? value = double.tryParse(digitsOnly);

        if (value != null && digitsOnly.length >= 4 && digitsOnly.length <= 7) {
          processedLines.add({
            'index': i,
            'text': cleanLine,
            'value': value,
            'isNegative': negativePattern.hasMatch(cleanLine),
          });
        }
      }
    }

    final totalPattern = RegExp(r'(TOTAL|JUMLAH|GRAND|AMOUNT|SUBTOTAL|NET)');

    for (var entry in processedLines.reversed) {
      if (entry['isNegative']) continue;

      if (totalPattern.hasMatch(entry['text'])) {
        totalAmount = entry['value'];
        break;
      }
    }

    if (totalAmount == null && processedLines.isNotEmpty) {
      for (var entry in processedLines.reversed) {
        if (!entry['isNegative']) {
          totalAmount = entry['value'];
          break;
        }
      }
    }

    return {
      'date': date ?? DateFormat('dd MMM yyyy').format(DateTime.now()),
      'amount': totalAmount ?? 0.0,
    };
  }

  String _normalizeDate(String raw) {
    try {
      String clean = raw.replaceAll('.', '/').replaceAll('-', '/');
      List<String> p = clean.split('/');
      DateTime d = DateTime(
        int.parse(p[2].length == 2 ? '20${p[2]}' : p[2]),
        int.parse(p[1]),
        int.parse(p[0]),
      );
      return DateFormat('dd MMM yyyy').format(d);
    } catch (e) {
      return raw;
    }
  }

  void dispose() => _textRecognizer.close();
}
