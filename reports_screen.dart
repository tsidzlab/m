import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' as intl;
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_providers.dart';
import '../services/report_service.dart';
import 'package:share_plus/share_plus.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime startDate;
  late DateTime endDate;
  String selectedReport = 'monthly';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = now;
  }

  @override
  Widget build(BuildContext context) {
    final monthlyReport = ref.watch(monthlyReportProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير'),
          centerTitle: true,
          elevation: 0,
          bottom: TabBar(
            tabs: [
              Tab(text: 'شهري', icon: const Icon(Icons.calendar_month)),
              Tab(text: 'سنوي', icon: const Icon(Icons.calendar_today)),
              Tab(text: 'عملاء', icon: const Icon(Icons.people)),
              Tab(text: 'مخزون', icon: const Icon(Icons.inventory)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMonthlyReport(monthlyReport),
            _buildYearlyReport(),
            _buildCustomersReport(),
            _buildInventoryReport(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyReport(AsyncValue<dynamic> monthlyReport) {
    return monthlyReport.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('خطأ: $error'),
      ),
      data: (report) => SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Picker
            _buildDateRangePicker(),
            SizedBox(height: 20.sp),

            // Key Metrics
            _buildKeyMetrics(report),
            SizedBox(height: 20.sp),

            // Chart
            _buildSalesChart(report),
            SizedBox(height: 20.sp),

            // Export Options
            _buildExportOptions(),
            SizedBox(height: 20.sp),

            // Details Table
            _buildReportTable(report),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    intl.DateFormat('yyyy-MM-dd').format(startDate),
                  ),
                  onPressed: () => _selectStartDate(context),
                ),
              ),
              Text('إلى', style: TextStyle(fontSize: 14.sp)),
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    intl.DateFormat('yyyy-MM-dd').format(endDate),
                  ),
                  onPressed: () => _selectEndDate(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          Row(
            children: [
              Expanded(
                child: _buildQuickDateButton('هذا الشهر', () {
                  final now = DateTime.now();
                  setState(() {
                    startDate = DateTime(now.year, now.month, 1);
                    endDate = now;
                  });
                }),
              ),
              SizedBox(width: 8.sp),
              Expanded(
                child: _buildQuickDateButton('آخر 30 يوم', () {
                  setState(() {
                    endDate = DateTime.now();
                    startDate = endDate.subtract(const Duration(days: 30));
                  });
                }),
              ),
              SizedBox(width: 8.sp),
              Expanded(
                child: _buildQuickDateButton('هذه السنة', () {
                  final now = DateTime.now();
                  setState(() {
                    startDate = DateTime(now.year, 1, 1);
                    endDate = now;
                  });
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label, style: TextStyle(fontSize: 11.sp)),
    );
  }

  Widget _buildKeyMetrics(dynamic report) {
    final totalSales = report['summary']?['total_sales'] ?? 0.0;
    final totalPaid = report['summary']?['total_paid'] ?? 0.0;
    final outstanding = totalSales - totalPaid;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'إجمالي المبيعات',
                '${totalSales.toStringAsFixed(2)} دج',
                Colors.blue,
              ),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: _buildMetricCard(
                'المتحصل',
                '${totalPaid.toStringAsFixed(2)} دج',
                Colors.green,
              ),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: _buildMetricCard(
                'المعلق',
                '${outstanding.toStringAsFixed(2)} دج',
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 4.sp),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(dynamic report) {
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
            'رسم بياني للمبيعات',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.sp),
          SizedBox(
            height: 200.sp,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateChartSpots(),
                    isCurved: true,
                    color: Colors.blue,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateChartSpots() {
    return List.generate(7, (index) {
      return FlSpot(index.toDouble(), (index + 1) * 1000.0);
    });
  }

  Widget _buildExportOptions() {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'خيارات التصدير',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.sp),
          Row(
            children: [
              Expanded(
                child: _buildExportButton(
                  'PDF',
                  Icons.picture_as_pdf,
                  Colors.red,
                  () => _exportPDF(),
                ),
              ),
              SizedBox(width: 8.sp),
              Expanded(
                child: _buildExportButton(
                  'Excel',
                  Icons.table_chart,
                  Colors.green,
                  () => _exportExcel(),
                ),
              ),
              SizedBox(width: 8.sp),
              Expanded(
                child: _buildExportButton(
                  'مشاركة',
                  Icons.share,
                  Colors.blue,
                  () => _shareReport(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16.sp),
      label: Text(label, style: TextStyle(fontSize: 12.sp)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 10.sp),
      ),
    );
  }

  Widget _buildReportTable(dynamic report) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: DataTable(
        columns: [
          DataColumn(
            label: Text('التاريخ', style: TextStyle(fontSize: 12.sp)),
          ),
          DataColumn(
            label: Text('المبلغ', style: TextStyle(fontSize: 12.sp)),
          ),
          DataColumn(
            label: Text('الحالة', style: TextStyle(fontSize: 12.sp)),
          ),
        ],
        rows: List.generate(
          5,
          (index) => DataRow(
            cells: [
              DataCell(Text(
                intl.DateFormat('yyyy-MM-dd').format(
                  DateTime.now().subtract(Duration(days: index)),
                ),
                style: TextStyle(fontSize: 11.sp),
              )),
              DataCell(Text(
                '1500 دج',
                style: TextStyle(fontSize: 11.sp),
              )),
              DataCell(
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.sp,
                    vertical: 4.sp,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.sp),
                  ),
                  child: Text(
                    'مدفوع',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearlyReport() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64.sp, color: Colors.grey[400]),
          SizedBox(height: 16.sp),
          const Text('التقرير السنوي - قيد الإنشاء'),
        ],
      ),
    );
  }

  Widget _buildCustomersReport() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64.sp, color: Colors.grey[400]),
          SizedBox(height: 16.sp),
          const Text('تقرير العملاء - قيد الإنشاء'),
        ],
      ),
    );
  }

  Widget _buildInventoryReport() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory, size: 64.sp, color: Colors.grey[400]),
          SizedBox(height: 16.sp),
          const Text('تقرير المخزون - قيد الإنشاء'),
        ],
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: endDate,
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
      });
    }
  }

  Future<void> _exportPDF() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري تصدير PDF...')),
    );
  }

  Future<void> _exportExcel() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري تصدير Excel...')),
    );
  }

  Future<void> _shareReport() async {
    try {
      await Share.share(
        'تقرير من ${intl.DateFormat('yyyy-MM-dd').format(startDate)} إلى ${intl.DateFormat('yyyy-MM-dd').format(endDate)}',
        subject: 'تقرير المبيعات',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }
}
