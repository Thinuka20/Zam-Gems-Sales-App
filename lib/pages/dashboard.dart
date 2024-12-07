import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/login_controller.dart';

final loginController = Get.find<LoginController>();
final currency = loginController.currency;

class ApiService {
  static const String baseUrl = 'http://124.43.70.220:7072';

  Future<DashboardResponse> fetchDashboardData() async {
    try {
      final loginController = Get.find<LoginController>();
      final datasource = loginController.datasource;

      final uri = Uri.parse('$baseUrl/Reports/dashboard').replace(
        queryParameters: {'connectionString': datasource},
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return DashboardResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching dashboard data: $e');
    }
  }
}

class DashboardResponse {
  final Map<String, int> hourlySales;
  final SalesSummaryData salesSummary;
  final POSDashboardData posDashboard;
  final SalesAndReturnsData salesAndReturns;

  DashboardResponse({
    required this.hourlySales,
    required this.salesSummary,
    required this.posDashboard,
    required this.salesAndReturns,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      hourlySales: Map<String, int>.from(json['hourlySales']),
      salesSummary: SalesSummaryData.fromJson(json['salesSummary']),
      posDashboard: POSDashboardData.fromJson(json['posDashboard']),
      salesAndReturns: SalesAndReturnsData.fromJson(json['salesAndReturns']),
    );
  }
}

class POSDashboardData {
  final int totalInvoices;
  final int totalProducts;
  final int billReturns;
  final String bestOutlet;
  final double bestOutletSales;

  POSDashboardData({
    required this.totalInvoices,
    required this.totalProducts,
    required this.billReturns,
    required this.bestOutlet,
    required this.bestOutletSales,
  });

  factory POSDashboardData.fromJson(Map<String, dynamic> json) {
    return POSDashboardData(
      totalInvoices: json['totalInvoices'],
      totalProducts: json['totalProducts'],
      billReturns: json['billReturns'],
      bestOutlet: json['bestOutlet'],
      bestOutletSales: double.parse(json['bestOutletSales'].toString()),
    );
  }
}

class SalesSummaryData {
  final double dailySales;
  final double weeklySales;
  final double monthlySales;
  final double yearlySales;

  SalesSummaryData({
    required this.dailySales,
    required this.weeklySales,
    required this.monthlySales,
    required this.yearlySales,
  });

  factory SalesSummaryData.fromJson(Map<String, dynamic> json) {
    return SalesSummaryData(
      dailySales: double.parse(json['dailySales'].toString()),
      weeklySales: double.parse(json['weeklySales'].toString()),
      monthlySales: double.parse(json['monthlySales'].toString()),
      yearlySales: double.parse(json['yearlySales'].toString()),
    );
  }
}

class SalesAndReturnsData {
  final double todaySales;
  final double yesterdaySales;
  final double currentMonthSales;
  final double previousMonthSales;
  final double todayReturns;
  final double yesterdayReturns;
  final double currentMonthReturns;
  final double previousMonthReturns;

  SalesAndReturnsData({
    required this.todaySales,
    required this.yesterdaySales,
    required this.currentMonthSales,
    required this.previousMonthSales,
    required this.todayReturns,
    required this.yesterdayReturns,
    required this.currentMonthReturns,
    required this.previousMonthReturns,
  });

  factory SalesAndReturnsData.fromJson(Map<String, dynamic> json) {
    return SalesAndReturnsData(
      todaySales: double.parse(json['todaySales'].toString()),
      yesterdaySales: double.parse(json['yesterdaySales'].toString()),
      currentMonthSales: double.parse(json['currentMonthSales'].toString()),
      previousMonthSales: double.parse(json['previousMonthSales'].toString()),
      todayReturns: double.parse(json['todayReturns'].toString()),
      yesterdayReturns: double.parse(json['yesterdayReturns'].toString()),
      currentMonthReturns: double.parse(json['currentMonthReturns'].toString()),
      previousMonthReturns:
          double.parse(json['previousMonthReturns'].toString()),
    );
  }
}

class DashboardController extends GetxController {
  final ApiService _apiService = ApiService();
  final _dashboardData = Rx<DashboardResponse?>(null);
  final _isLoading = false.obs;
  final _error = Rx<String?>(null);

  DashboardResponse? get dashboardData => _dashboardData.value;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      _isLoading.value = true;
      _error.value = null;
      _dashboardData.value = await _apiService.fetchDashboardData();
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  List<FlSpot> getHourlySalesSpots() {
    if (_dashboardData.value == null) return [];

    return _dashboardData.value!.hourlySales.entries
        .map((e) => FlSpot(
              double.parse(e.key.split('_')[1]),
              e.value.toDouble(),
            ))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  String formatCurrency(double value) {
    return '$currency ${value.toStringAsFixed(2)}';
  }
}

class CurrencyFormatter {
  static final _lkrFormat = NumberFormat.currency(
    symbol: '$currency ',
    decimalDigits: 2,
  );

  static String format(double value) {
    return _lkrFormat.format(value);
  }
}

class POSDashboard extends StatelessWidget {
  POSDashboard({Key? key}) : super(key: key);

  final DashboardController controller = Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
          toolbarHeight: 120,
          flexibleSpace: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 24),
                    label: const Text(
                      'Back',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ),
              ),
              Text(
                'Dashboard',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 33,
                ),
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: controller.fetchDashboardData,
          child: Obx(() {
            if (controller.isLoading && controller.dashboardData == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.error != null && controller.dashboardData == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(controller.error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: controller.fetchDashboardData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final dashboardData = controller.dashboardData;
            if (dashboardData == null) {
              return const Center(child: Text('No data available'));
            }

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade50,
                    Colors.white,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopCards(dashboardData.posDashboard),
                      const SizedBox(height: 20),
                      _buildSalesGrid(dashboardData.salesSummary),
                      const SizedBox(height: 20),
                      _buildTransactionSummary(dashboardData.salesAndReturns),
                      const SizedBox(height: 20),
                      _buildHourlySalesChart(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTopCards(POSDashboardData data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildInfoCard(
            icon: Icons.receipt,
            title: 'Total Invoices',
            value: data.totalInvoices.toString(),
            color: const Color(0xFF6C63FF),
            lightColor: const Color(0xFFE0F8F2),
          ),
          _buildInfoCard(
            icon: Icons.inventory_2,
            title: 'Total Products',
            value: data.totalProducts.toString(),
            color: const Color(0xFF00C48C),
            lightColor: const Color(0xFFE0F8F2),
          ),
          _buildInfoCard(
            icon: Icons.assignment_return,
            title: 'Bill Returns',
            value: data.billReturns.toString(),
            color: const Color(0xFFFF647C),
            lightColor: const Color(0xFFFFE9EC),
          ),
          _buildInfoCard(
            icon: Icons.location_on,
            title: 'Best Outlet',
            value: data.bestOutlet,
            subValue: CurrencyFormatter.format(data.bestOutletSales),
            color: const Color(0xFFFFA026),
            lightColor: const Color(0xFFFFF4E8),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color lightColor,
    String? subValue,
  }) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shadowColor: color.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [lightColor, Colors.white],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (subValue != null) ...[
                const SizedBox(height: 4),
                Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesGrid(SalesSummaryData data) {
    // Calculate progress values relative to the highest value
    final maxValue = data.yearlySales; // Using yearly sales as max
    final dailyProgress = maxValue > 0 ? (data.dailySales / maxValue) : 0.0;
    final weeklyProgress = maxValue > 0 ? (data.weeklySales / maxValue) : 0.0;
    final monthlyProgress = maxValue > 0 ? (data.monthlySales / maxValue) : 0.0;
    final yearlyProgress = 1.0; // Always 100% as it's our benchmark

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildSalesCard('Daily Sales', data.dailySales, dailyProgress, Colors.orange),
        _buildSalesCard('Weekly Sales', data.weeklySales, weeklyProgress, Colors.blue),
        _buildSalesCard('Monthly Sales', data.monthlySales, monthlyProgress, Colors.green),
        _buildSalesCard('Yearly Sales', data.yearlySales, yearlyProgress, Colors.purple),
      ],
    );
  }

  Widget _buildSalesCard(String title, double value, double progress, Color color) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              CurrencyFormatter.format(value),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0), // Ensure value is between 0 and 1
              backgroundColor: color.withOpacity(0.1),
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSummary(SalesAndReturnsData data) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.blue.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Summary Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Bill Type')),
                  DataColumn(label: Text('Today')),
                  DataColumn(label: Text('Yesterday')),
                  DataColumn(label: Text('Current Month')),
                  DataColumn(label: Text('Previous Month')),
                ],
                rows: [
                  _buildDataRow(
                    'INVOICE',
                    data.todaySales,
                    data.yesterdaySales,
                    data.currentMonthSales,
                    data.previousMonthSales,
                  ),
                  _buildDataRow(
                    'SALES RETURN',
                    data.todayReturns,
                    data.yesterdayReturns,
                    data.currentMonthReturns,
                    data.previousMonthReturns,
                  ),
                  _buildDataRow(
                    'Total',
                    data.todaySales - data.todayReturns,
                    data.yesterdaySales - data.yesterdayReturns,
                    data.currentMonthSales - data.currentMonthReturns,
                    data.previousMonthSales - data.previousMonthReturns,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(
    String type,
    double today,
    double yesterday,
    double currentMonth,
    double previousMonth, {
    bool isTotal = false,
  }) {
    final style = TextStyle(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      color: isTotal ? Colors.blue.shade700 : null,
    );

    return DataRow(cells: [
      DataCell(Text(type, style: style)),
      DataCell(Text(CurrencyFormatter.format(today), style: style)),
      DataCell(Text(CurrencyFormatter.format(yesterday), style: style)),
      DataCell(Text(CurrencyFormatter.format(currentMonth), style: style)),
      DataCell(Text(CurrencyFormatter.format(previousMonth), style: style)),
    ]);
  }

  Widget _buildHourlySalesChart() {
    return Card(
      elevation: 4,
      color: Colors.white,
      shadowColor: Colors.green.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hourly Sales',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}h',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                        reservedSize: 22,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: controller.getHourlySalesSpots(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                  minX: 0,
                  maxX: 23,
                  minY: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
