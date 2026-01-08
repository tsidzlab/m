import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as excel;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:logger/logger.dart';
import '../models/invoice_model.dart';

final reportServiceProvider = Provider((ref) {
  return ReportService();
});

class ReportService {
  final logger = Logger();
  
  // ===================== DAILY REPORTS =====================

  Future<pw.Document> generateDailyReportPDF({
    required double totalSales,
    required double totalPaid,
    required double outstanding,
    required int invoiceCount,
    required List<Invoice> invoices,
    required DateTime date,
  }) async {
    final doc = pw.Document();

    final arabicFont = await _loadArabicFont();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildReportHeader(date, 'تقرير المبيعات اليومي', arabicFont),
          pw.SizedBox(height: 20),
          
          // Summary Cards
          _buildSummarySection(
            totalSales: totalSales,
            totalPaid: totalPaid,
            outstanding: outstanding,
            invoiceCount: invoiceCount,
            arabicFont: arabicFont,
          ),
          pw.SizedBox(height: 20),
          
          // Invoice Table
          _buildInvoicesTable(invoices, arabicFont),
          pw.SizedBox(height: 20),
          
          // Footer
          _buildReportFooter(arabicFont),
        ],
      ),
    );

    return doc;
  }

  Future<pw.Document> generateMonthlyReportPDF({
    required DateTime startDate,
    required DateTime endDate,
    required double totalSales,
    required double totalDiscount,
    required double totalTax,
    required double totalPaid,
    required double totalOutstanding,
    required int invoiceCount,
    required List<Invoice> invoices,
  }) async {
    final doc = pw.Document();
    final arabicFont = await _loadArabicFont();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          _buildReportHeader(
            startDate,
            'تقرير المبيعات الشهري (${DateFormat('MMMM', 'ar_SA').format(startDate)})',
            arabicFont,
          ),
          pw.SizedBox(height: 20),
          
          _buildMonthlyStats(
            totalSales: totalSales,
            totalDiscount: totalDiscount,
            totalTax: totalTax,
            totalPaid: totalPaid,
            totalOutstanding: totalOutstanding,
            invoiceCount: invoiceCount,
            arabicFont: arabicFont,
          ),
          pw.SizedBox(height: 20),
          
          _buildInvoicesTable(invoices, arabicFont),
        ],
      ),
    );

    return doc;
  }

  Future<pw.Document> generateProfitLossReportPDF({
    required DateTime date,
    required double totalRevenue,
    required double totalExpenses,
    required double totalDiscount,
    required double totalTax,
    required double netProfit,
  }) async {
    final doc = pw.Document();
    final arabicFont = await _loadArabicFont();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildReportHeader(date, 'تقرير الربح والخسارة', arabicFont),
            pw.SizedBox(height: 30),
            
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(10),
                      child: pw.Text(
                        'القيمة',
                        textDirection: pw.TextDirection.rtl,
                        style: pw.TextStyle(font: arabicFont, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(10),
                      child: pw.Text(
                        'البند',
                        textDirection: pw.TextDirection.rtl,
                        style: pw.TextStyle(font: arabicFont, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                _buildProfitLossRow('إجمالي الإيرادات', totalRevenue, arabicFont),
                _buildProfitLossRow('الخصومات', -totalDiscount, arabicFont),
                _buildProfitLossRow('الضريبة', totalTax, arabicFont),
                _buildProfitLossRow('إجمالي المصروفات', -totalExpenses, arabicFont),
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.green100),
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(10),
                      child: pw.Text(
                        '${netProfit.toStringAsFixed(2)} دج',
                        textDirection: pw.TextDirection.rtl,
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(10),
                      child: pw.Text(
                        'الربح الصافي',
                        textDirection: pw.TextDirection.rtl,
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return doc;
  }

  // ===================== EXCEL EXPORT =====================

  Future<File> generateExcelReport({
    required String fileName,
    required List<Invoice> invoices,
    required double totalSales,
    required double totalPaid,
  }) async {
    final ex = excel.Excel.createExcel();
    final sheet = ex['Sheet1'];

    // Headers
    sheet.appendRow([
      'رقم الفاتورة',
      'التاريخ',
      'العميل',
      'المبلغ',
      'الحالة',
      'نوع الدفع',
    ]);

    // Data
    for (final invoice in invoices) {
      sheet.appendRow([
        invoice.invoiceNumber,
        invoice.invoiceDate.toString(),
        invoice.customerId.toString(),
        invoice.totalAmount.toString(),
        invoice.paymentStatus,
        invoice.invoiceType,
      ]);
    }

    // Summary
    sheet.appendRow(['']);
    sheet.appendRow(['الإجمالي', totalSales.toString()]);
    sheet.appendRow(['المدفوع', totalPaid.toString()]);
    sheet.appendRow(['المتبقي', (totalSales - totalPaid).toString()]);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.xlsx');
    
    await file.writeAsBytes(ex.encode()!);
    return file;
  }

  // ===================== PRINTING =====================

  Future<void> printDailyReport({
    required double totalSales,
    required double totalPaid,
    required double outstanding,
    required int invoiceCount,
    required DateTime date,
  }) async {
    final doc = pw.Document();
    final arabicFont = await _loadArabicFont();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          58 * 2.83465, // 58mm width
          double.infinity,
        ),
        build: (context) => pw.Column(
          children: [
            pw.Text(
              'حساب اليوم',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: arabicFont, fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              DateFormat('yyyy-MM-dd', 'ar_SA').format(date),
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: arabicFont, fontSize: 10),
            ),
            pw.Divider(),
            pw.SizedBox(height: 10),
            
            _buildPrintRow('إجمالي المبيعات:', '${totalSales.toStringAsFixed(2)} دج', arabicFont),
            _buildPrintRow('المدفوع:', '${totalPaid.toStringAsFixed(2)} دج', arabicFont),
            _buildPrintRow('المتبقي:', '${outstanding.toStringAsFixed(2)} دج', arabicFont),
            _buildPrintRow('عدد الفواتير:', invoiceCount.toString(), arabicFont),
            
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.Text(
              'شكراً على تعاملكم معنا',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: arabicFont, fontSize: 10),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  // ===================== HELPER METHODS =====================

  pw.Widget _buildReportHeader(
    DateTime date,
    String title,
    pw.Font arabicFont,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(
            font: arabicFont,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          DateFormat('yyyy-MM-dd', 'ar_SA').format(date),
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(font: arabicFont, fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildSummarySection({
    required double totalSales,
    required double totalPaid,
    required double outstanding,
    required int invoiceCount,
    required pw.Font arabicFont,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryCard('إجمالي المبيعات', '${totalSales.toStringAsFixed(2)} دج', PdfColors.blue, arabicFont),
        _buildSummaryCard('المدفوع', '${totalPaid.toStringAsFixed(2)} دج', PdfColors.green, arabicFont),
        _buildSummaryCard('المتبقي', '${outstanding.toStringAsFixed(2)} دج', PdfColors.red, arabicFont),
        _buildSummaryCard('الفواتير', invoiceCount.toString(), PdfColors.orange, arabicFont),
      ],
    );
  }

  pw.Widget _buildSummaryCard(
    String label,
    String value,
    PdfColor color,
    pw.Font arabicFont,
  ) {
    return pw.Container(
      width: 100,
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(font: arabicFont, fontSize: 10),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInvoicesTable(List<Invoice> invoices, pw.Font arabicFont) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(3),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableHeader('الحالة', arabicFont),
            _buildTableHeader('المبلغ', arabicFont),
            _buildTableHeader('التاريخ', arabicFont),
            _buildTableHeader('نوع', arabicFont),
            _buildTableHeader('الرقم', arabicFont),
          ],
        ),
        ...invoices.map((invoice) => pw.TableRow(
          children: [
            _buildTableCell(invoice.paymentStatus, arabicFont),
            _buildTableCell('${invoice.totalAmount.toStringAsFixed(2)} دج', arabicFont),
            _buildTableCell(DateFormat('yyyy-MM-dd').format(invoice.invoiceDate), arabicFont),
            _buildTableCell(invoice.invoiceType, arabicFont),
            _buildTableCell(invoice.invoiceNumber, arabicFont),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text, pw.Font arabicFont) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
          font: arabicFont,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(String text, pw.Font arabicFont) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(font: arabicFont, fontSize: 9),
      ),
    );
  }

  pw.Widget _buildMonthlyStats({
    required double totalSales,
    required double totalDiscount,
    required double totalTax,
    required double totalPaid,
    required double totalOutstanding,
    required int invoiceCount,
    required pw.Font arabicFont,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        _buildStatRow('إجمالي المبيعات', '${totalSales.toStringAsFixed(2)} دج', arabicFont),
        _buildStatRow('الخصومات', '${totalDiscount.toStringAsFixed(2)} دج', arabicFont),
        _buildStatRow('الضريبة', '${totalTax.toStringAsFixed(2)} دج', arabicFont),
        _buildStatRow('المدفوع', '${totalPaid.toStringAsFixed(2)} دج', arabicFont),
        _buildStatRow('المتبقي', '${totalOutstanding.toStringAsFixed(2)} دج', arabicFont),
        _buildStatRow('عدد الفواتير', invoiceCount.toString(), arabicFont),
      ],
    );
  }

  pw.TableRow _buildStatRow(String label, String value, pw.Font arabicFont) {
    return pw.TableRow(
      children: [
        _buildTableCell(value, arabicFont),
        _buildTableCell(label, arabicFont),
      ],
    );
  }

  pw.TableRow _buildProfitLossRow(String label, double value, pw.Font arabicFont) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.all(10),
          child: pw.Text(
            '${value.toStringAsFixed(2)} دج',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(font: arabicFont),
          ),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(10),
          child: pw.Text(
            label,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(font: arabicFont),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPrintRow(String label, String value, pw.Font arabicFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      textDirection: pw.TextDirection.rtl,
      children: [
        pw.Text(
          value,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(font: arabicFont, fontSize: 12),
        ),
        pw.Text(
          label,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(font: arabicFont, fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildReportFooter(pw.Font arabicFont) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Text(
          'تم إنشاء التقرير: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(font: arabicFont, fontSize: 8),
        ),
      ],
    );
  }

  Future<pw.Font> _loadArabicFont() async {
    // يمكن تحميل خط عربي من الأصول أو استخدام خط النظام
    return pw.Font.helveticaBold();
  }
}
