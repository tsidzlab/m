import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' as intl;
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_providers.dart';
import '../services/report_service.dart';
import '../services/printer_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class DailySummaryScreen extends ConsumerStatefulWidget {
  const DailySummaryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends ConsumerState<DailySummaryScreen> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final dailyReport = ref.watch(dailyReportProvider);
    final reportService = ref.watch(reportServiceProvider);
    final printerService = ref.watch(printerServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('حساب اليوم'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printDailyReport(reportService),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareDailyReport(),
          ),
        ],
      ),
      body: dailyReport.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64.sp, color: Colors.red),
              SizedBox(height: 16.sp),
              Text('حدث خطأ: $error'),
            ],
          ),
        ),
        data: (report) => _buildDailySummaryContent(context, report, reportService),
      ),
    );
  }

  Widget _buildDailySummaryContent(
    BuildContext context,
    dynamic report,
    ReportService reportService,
  ) {
    final totalSales = report['summary']['total_sales'] ?? 0.0;
    final totalPaid = report['summary']['total_paid'] ?? 0.0;
    final outstanding = totalSales - totalPaid;
    final invoiceCount = report['invoices']?.length ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.sp),
      child: Column(
        children: [
          // Date Picker
          _buildDatePicker(),
          SizedBox(height: 24.sp),

          // Summary Cards
          _buildSummaryCards(totalSales, totalPaid, outstanding, invoiceCount),
          SizedBox(height: 24.sp),

          // Chart
          _buildChart(totalSales, totalPaid, outstanding),
          SizedBox(height: 24.sp),

          // Action Buttons
          _buildActionButtons(
            context,
            totalSales,
            totalPaid,
            outstanding,
            invoiceCount,
            reportService,
          ),
          SizedBox(height: 24.sp),

          // Invoices List
          if (report['invoices'] != null && report['invoices'].isNotEmpty)
            _buildInvoicesList(report['invoices']),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            intl.DateFormat('yyyy-MM-dd', 'ar_SA').format(selectedDate),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Widget _buildSummaryCards(
    double totalSales,
    double totalPaid,
    double outstanding,
    int invoiceCount,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'إجمالي المبيعات',
                value: '${totalSales.toStringAsFixed(2)} دج',
                color: Colors.blue,
                icon: Icons.trending_up,
              ),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: _buildSummaryCard(
                title: 'المدفوع',
                value: '${totalPaid.toStringAsFixed(2)} دج',
                color: Colors.green,
                icon: Icons.check_circle,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.sp),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'المتبقي',
                value: '${outstanding.toStringAsFixed(2)} دج',
                color: Colors.orange,
                icon: Icons.pending_actions,
              ),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: _buildSummaryCard(
                title: 'الفواتير',
                value: invoiceCount.toString(),
                color: Colors.purple,
                icon: Icons.receipt,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.sp),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.sp),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(double totalSales, double totalPaid, double outstanding) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزيع المبيعات',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.sp),
          SizedBox(
            height: 200.sp,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: totalPaid,
                    title: '${(totalPaid / totalSales * 100).toStringAsFixed(1)}%',
                    color: Colors.green,
                    radius: 60.sp,
                  ),
                  PieChartSectionData(
                    value: outstanding,
                    title: '${(outstanding / totalSales * 100).toStringAsFixed(1)}%',
                    color: Colors.orange,
                    radius: 60.sp,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.sp),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegend('المدفوع', Colors.green),
              _buildLegend('المتبقي', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16.sp,
          height: 16.sp,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.sp),
          ),
        ),
        SizedBox(width: 8.sp),
        Text(label),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    double totalSales,
    double totalPaid,
    double outstanding,
    int invoiceCount,
    ReportService reportService,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _printDailyReport(reportService),
            icon: const Icon(Icons.print),
            label: const Text('طباعة'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.sp),
            ),
          ),
        ),
        SizedBox(width: 12.sp),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _saveDailyReport(reportService),
            icon: const Icon(Icons.save),
            label: const Text('حفظ'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.sp),
            ),
          ),
        ),
        SizedBox(width: 12.sp),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _shareDailyReport(),
            icon: const Icon(Icons.share),
            label: const Text('مشاركة'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.sp),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoicesList(List<dynamic> invoices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'فواتير اليوم',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.sp),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            return Card(
              margin: EdgeInsets.only(bottom: 8.sp),
              child: ListTile(
                title: Text('الفاتورة #${invoice['invoiceNumber']}'),
                subtitle: Text(invoice['invoiceType']),
                trailing: Text(
                  '${invoice['totalAmount']} دج',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _printDailyReport(ReportService reportService) async {
    try {
      final dailyReport = ref.read(dailyReportProvider);
      if (dailyReport.asData != null) {
        final data = dailyReport.asData!.value;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('جاري الطباعة...')),
        );
        // Printing will be handled by the report service
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الطباعة: $e')),
      );
    }
  }

  Future<void> _saveDailyReport(ReportService reportService) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري الحفظ...')),
      );
      // Save functionality
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الحفظ: $e')),
      );
    }
  }

  Future<void> _shareDailyReport() async {
    try {
      final dateStr = intl.DateFormat('yyyy-MM-dd').format(selectedDate);
      await Share.share(
        'حساب اليوم: $dateStr\nجميع البيانات المفصلة متاحة في التطبيق',
        subject: 'حساب اليوم - $dateStr',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في المشاركة: $e')),
      );
    }
  }
}
