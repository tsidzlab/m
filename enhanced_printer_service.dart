import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart' as intl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:logger/logger.dart';
import '../models/invoice_model.dart';

final printerServiceProvider = Provider((ref) {
  return EnhancedPrinterService();
});

class EnhancedPrinterService {
  final bluetoothPrint = BluetoothPrint.instance;
  final logger = Logger();

  // ===================== PRINTER DISCOVERY =====================

  Future<bool> initializeBluetooth() async {
    try {
      bool? result = await bluetoothPrint.startScan(timeout: const Duration(seconds: 4));
      return result ?? false;
    } catch (e) {
      logger.e('Bluetooth initialization error: $e');
      return false;
    }
  }

  Future<List<BluetoothDevice>> getAvailablePrinters() async {
    try {
      List<BluetoothDevice> devices = [];
      bluetoothPrint.scanResults.listen((List<BluetoothDevice> results) {
        devices = results;
      });
      return devices;
    } catch (e) {
      logger.e('Get printers error: $e');
      return [];
    }
  }

  Future<bool> connectToPrinter(String printerAddress) async {
    try {
      bool? result = await bluetoothPrint.connect(
        BluetoothDevice(address: printerAddress),
      );
      return result ?? false;
    } catch (e) {
      logger.e('Connect to printer error: $e');
      return false;
    }
  }

  Future<bool> disconnectPrinter() async {
    try {
      bool? result = await bluetoothPrint.disconnect();
      return result ?? false;
    } catch (e) {
      logger.e('Disconnect error: $e');
      return false;
    }
  }

  // ===================== INVOICE PRINTING =====================

  Future<void> printInvoice({
    required Invoice invoice,
    required List<InvoiceItem> items,
    String printerWidth = '58', // 58mm or 80mm
  }) async {
    try {
      final bytes = await _generatePrinterBytes(
        invoice: invoice,
        items: items,
        width: int.parse(printerWidth),
      );

      await bluetoothPrint.writeBytes(bytes);
      logger.i('Invoice printed successfully');
    } catch (e) {
      logger.e('Print invoice error: $e');
      rethrow;
    }
  }

  Future<void> printDailyReport({
    required double totalSales,
    required double totalPaid,
    required double outstanding,
    required int invoiceCount,
    required DateTime date,
  }) async {
    try {
      final generator = Generator(PaperSize.mm58, await _getProfile());
      final bytes = <int>[];

      // Header
      bytes += generator.text(
        'حساب اليوم',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );

      bytes += generator.text(
        intl.DateFormat('yyyy-MM-dd HH:mm', 'ar_SA').format(date),
        styles: const PosStyles(align: PosAlign.center),
      );

      bytes += generator.hr();

      // Summary
      bytes += _buildReportLine(
        'إجمالي المبيعات',
        '${totalSales.toStringAsFixed(2)} دج',
        generator,
      );
      bytes += _buildReportLine(
        'المدفوع',
        '${totalPaid.toStringAsFixed(2)} دج',
        generator,
      );
      bytes += _buildReportLine(
        'المعلق',
        '${outstanding.toStringAsFixed(2)} دج',
        generator,
      );
      bytes += _buildReportLine(
        'عدد الفواتير',
        invoiceCount.toString(),
        generator,
      );

      bytes += generator.hr();
      bytes += generator.text(
        'شكراً على تعاملكم معنا',
        styles: const PosStyles(align: PosAlign.center),
      );

      bytes += generator.feed(2);
      bytes += generator.cut();

      await bluetoothPrint.writeBytes(bytes);
      logger.i('Daily report printed successfully');
    } catch (e) {
      logger.e('Print daily report error: $e');
      rethrow;
    }
  }

  // ===================== PDF GENERATION =====================

  Future<void> printPDF({
    required pw.Document document,
    required String printerName,
  }) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => document.save(),
        name: printerName,
      );
      logger.i('PDF printed successfully');
    } catch (e) {
      logger.e('Print PDF error: $e');
      rethrow;
    }
  }

  Future<File> savePDFToFile({
    required pw.Document document,
    required String fileName,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.pdf');

      final bytes = await document.save();
      await file.writeAsBytes(bytes);

      logger.i('PDF saved to: ${file.path}');
      return file;
    } catch (e) {
      logger.e('Save PDF error: $e');
      rethrow;
    }
  }

  // ===================== SHARING =====================

  Future<void> sharePDF({
    required File file,
    required String subject,
  }) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
      );
      logger.i('PDF shared successfully');
    } catch (e) {
      logger.e('Share PDF error: $e');
      rethrow;
    }
  }

  Future<void> shareReport({
    required String reportText,
    required String subject,
  }) async {
    try {
      await Share.share(
        reportText,
        subject: subject,
      );
      logger.i('Report shared successfully');
    } catch (e) {
      logger.e('Share report error: $e');
      rethrow;
    }
  }

  // ===================== HELPER METHODS =====================

  Future<List<int>> _generatePrinterBytes({
    required Invoice invoice,
    required List<InvoiceItem> items,
    int width = 58,
  }) async {
    final profile = await _getProfile();
    final generator = Generator(width == 58 ? PaperSize.mm58 : PaperSize.mm80, profile);
    final bytes = <int>[];

    // Header
    bytes += generator.text(
      'الفاتورة',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.text(
      'رقم: ${invoice.invoiceNumber}',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.text(
      intl.DateFormat('yyyy-MM-dd HH:mm', 'ar_SA').format(invoice.invoiceDate),
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.hr();

    // Items Header
    bytes += generator.row(
      [
        PosColumn(
          text: 'السعر',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: 'الكمية',
          width: 3,
          styles: const PosStyles(align: PosAlign.center),
        ),
        PosColumn(
          text: 'المنتج',
          width: 5,
          styles: const PosStyles(align: PosAlign.left),
        ),
      ],
    );

    bytes += generator.hr();

    // Items
    for (final item in items) {
      bytes += generator.row(
        [
          PosColumn(
            text: '${item.unitPrice.toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            text: item.quantity.toString(),
            width: 3,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: item.productName,
            width: 5,
            styles: const PosStyles(align: PosAlign.left),
          ),
        ],
      );
    }

    bytes += generator.hr();

    // Summary
    bytes += generator.text(
      'الإجمالي: ${invoice.totalAmount.toStringAsFixed(2)} دج',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.text(
      'المدفوع: ${invoice.paidAmount.toStringAsFixed(2)} دج',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  List<int> _buildReportLine(
    String label,
    String value,
    Generator generator,
  ) {
    return generator.row(
      [
        PosColumn(
          text: value,
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: label,
          width: 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
      ],
    );
  }

  Future<CapabilityProfile> _getProfile() async {
    final profile = await CapabilityProfile.load();
    return profile;
  }

  // ===================== IMAGE PRINTING =====================

  Future<void> printImage(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final generator = Generator(PaperSize.mm58, await _getProfile());
      final bytes = <int>[];

      bytes += generator.imageRaster(image);
      bytes += generator.feed(2);
      bytes += generator.cut();

      await bluetoothPrint.writeBytes(bytes);
      logger.i('Image printed successfully');
    } catch (e) {
      logger.e('Print image error: $e');
      rethrow;
    }
  }

  // ===================== QR CODE PRINTING =====================

  Future<void> printQRCode(String data) async {
    try {
      final generator = Generator(PaperSize.mm58, await _getProfile());
      final bytes = <int>[];

      bytes += generator.qrcode(
        data,
        size: QRSize.size8,
        cor: QRCorrection.H,
      );
      bytes += generator.feed(2);
      bytes += generator.cut();

      await bluetoothPrint.writeBytes(bytes);
      logger.i('QR Code printed successfully');
    } catch (e) {
      logger.e('Print QR Code error: $e');
      rethrow;
    }
  }

  // ===================== DOCUMENT MANAGEMENT =====================

  Future<void> openPDF(File file) async {
    try {
      // TODO: Implement PDF opening functionality
      logger.i('Opening PDF: ${file.path}');
    } catch (e) {
      logger.e('Open PDF error: $e');
      rethrow;
    }
  }

  Future<bool> deletePDF(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        logger.i('PDF deleted: ${file.path}');
        return true;
      }
      return false;
    } catch (e) {
      logger.e('Delete PDF error: $e');
      return false;
    }
  }

  Future<List<File>> getGeneratedPDFs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.pdf'))
          .toList();

      return files;
    } catch (e) {
      logger.e('Get PDFs error: $e');
      return [];
    }
  }

  Future<String> getFileSize(File file) async {
    try {
      final bytes = await file.length();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(2)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
      }
    } catch (e) {
      logger.e('Get file size error: $e');
      return 'Unknown';
    }
  }
}
