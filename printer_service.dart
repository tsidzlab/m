import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import '../models/invoice_model.dart';
import 'storage_service.dart';

final printerServiceProvider = Provider((ref) {
  return BluetoothPrinterService();
});

class BluetoothPrinterService {
  final bluetoothPrint = BluetoothPrint.instance;
  final logger = Logger();
  
  bool _connected = false;
  List<BluetoothDevice> _devices = [];

  BluetoothPrinterService() {
    _initializeListener();
  }

  void _initializeListener() {
    bluetoothPrint.onStateChanged().listen((state) {
      logger.i('Bluetooth state: $state');
      _connected = state == BluetoothPrint.CONNECTED;
    });
  }

  // ===================== DEVICE MANAGEMENT =====================

  Future<List<BluetoothDevice>> scanDevices() async {
    try {
      final devices = await bluetoothPrint.getBluetoothDevices();
      _devices = devices;
      return devices;
    } catch (e) {
      logger.e('Failed to scan devices: $e');
      return [];
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      final connected = await bluetoothPrint.connect(device);
      _connected = connected;

      if (connected) {
        await StorageService.setDefaultPrinter(device.name ?? device.address ?? '');
        logger.i('Connected to ${device.name}');
      }

      return connected;
    } catch (e) {
      logger.e('Failed to connect: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await bluetoothPrint.disconnect();
      _connected = false;
      logger.i('Disconnected from printer');
    } catch (e) {
      logger.e('Failed to disconnect: $e');
    }
  }

  bool isConnected() => _connected;

  // ===================== PRINTING =====================

  Future<bool> printInvoice(Invoice invoice) async {
    try {
      final generator = Generator(
        PaperSize.mm58,
        effectiveMaxWidth: 58,
      );

      List<int> bytes = [];

      // Header
      bytes += generator.text(
        'فاتورة مبيعات',
        styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2),
      );

      bytes += generator.hr();

      // Company info (if available)
      bytes += generator.text(
        'متجري التجاري',
        styles: const PosStyles(align: PosAlign.center),
      );

      bytes += generator.emptyLines(1);

      // Invoice details
      bytes += generator.row(
        [
          PosColumn(
            text: 'الرقم:',
            width: 5,
            styles: const PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            text: invoice.invoiceNumber,
            width: 7,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ],
      );

      bytes += generator.row(
        [
          PosColumn(
            text: 'التاريخ:',
            width: 5,
            styles: const PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            text: _formatDate(invoice.invoiceDate),
            width: 7,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ],
      );

      bytes += generator.hr();

      // Items header
      bytes += generator.row(
        [
          PosColumn(text: 'المبلغ', width: 3, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: 'الكمية', width: 2, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: 'السعر', width: 3, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: 'البند', width: 6, styles: const PosStyles(align: PosAlign.right)),
        ],
      );

      bytes += generator.hr();

      // Items
      for (final item in invoice.items) {
        bytes += generator.row(
          [
            PosColumn(
              text: item.lineTotal.toStringAsFixed(0),
              width: 3,
              styles: const PosStyles(align: PosAlign.right),
            ),
            PosColumn(
              text: item.quantity.toStringAsFixed(0),
              width: 2,
              styles: const PosStyles(align: PosAlign.right),
            ),
            PosColumn(
              text: item.unitPrice.toStringAsFixed(0),
              width: 3,
              styles: const PosStyles(align: PosAlign.right),
            ),
            PosColumn(
              text: item.productName,
              width: 6,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ],
        );
      }

      bytes += generator.hr();

      // Summary
      bytes += generator.row(
        [
          PosColumn(text: 'الإجمالي:', width: 7, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(
            text: invoice.subtotal.toStringAsFixed(2),
            width: 5,
            styles: const PosStyles(align: PosAlign.right, height: PosTextSize.size2),
          ),
        ],
      );

      if (invoice.discountAmount > 0) {
        bytes += generator.row(
          [
            PosColumn(text: 'الخصم:', width: 7, styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
              text: '-${invoice.discountAmount.toStringAsFixed(2)}',
              width: 5,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ],
        );
      }

      if (invoice.taxAmount > 0) {
        bytes += generator.row(
          [
            PosColumn(text: 'الضريبة:', width: 7, styles: const PosStyles(align: PosAlign.right)),
            PosColumn(
              text: invoice.taxAmount.toStringAsFixed(2),
              width: 5,
              styles: const PosStyles(align: PosAlign.right),
            ),
          ],
        );
      }

      bytes += generator.hr();

      // Total
      bytes += generator.text(
        'المجموع: ${invoice.totalAmount.toStringAsFixed(2)} دج',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          bold: true,
        ),
      );

      // Payment status
      final paymentText = invoice.isPaid
          ? 'مدفوعة'
          : invoice.isPartiallyPaid
              ? 'مدفوعة جزئياً'
              : 'معلقة';

      bytes += generator.text(
        'الحالة: $paymentText',
        styles: const PosStyles(align: PosAlign.center),
      );

      bytes += generator.emptyLines(1);

      // Footer
      final footer = StorageService.getPrintFooter();
      if (footer != null && footer.isNotEmpty) {
        bytes += generator.text(
          footer,
          styles: const PosStyles(align: PosAlign.center, size: PosTextSize.size1),
        );
      }

      bytes += generator.text(
        'شكراً على تعاملكم معنا',
        styles: const PosStyles(align: PosAlign.center),
      );

      bytes += generator.emptyLines(2);
      bytes += generator.cut();

      // Send to printer
      return await _sendBytes(bytes);
    } catch (e) {
      logger.e('Failed to print invoice: $e');
      return false;
    }
  }

  Future<bool> printReceeipt(String content) async {
    try {
      final generator = Generator(PaperSize.mm58);
      List<int> bytes = [];

      bytes += generator.text(content);
      bytes += generator.cut();

      return await _sendBytes(bytes);
    } catch (e) {
      logger.e('Failed to print receipt: $e');
      return false;
    }
  }

  Future<bool> printQRCode(String data) async {
    try {
      final generator = Generator(PaperSize.mm58);
      List<int> bytes = [];

      bytes += generator.qrcode(data);
      bytes += generator.cut();

      return await _sendBytes(bytes);
    } catch (e) {
      logger.e('Failed to print QR code: $e');
      return false;
    }
  }

  Future<bool> _sendBytes(List<int> bytes) async {
    try {
      if (!_connected) {
        logger.w('Printer not connected');
        return false;
      }

      final result = await bluetoothPrint.writeBytes(bytes);
      logger.i('Print result: $result');
      return result;
    } catch (e) {
      logger.e('Failed to send bytes: $e');
      return false;
    }
  }

  // ===================== HELPER METHODS =====================

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<List<int>> _imageToBytes(img.Image image) async {
    try {
      final generator = Generator(PaperSize.mm58);
      final imageBytes = img.encodePng(image);
      return generator.image(imageBytes);
    } catch (e) {
      logger.e('Failed to convert image: $e');
      return [];
    }
  }
}
