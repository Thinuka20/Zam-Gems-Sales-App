import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';

class POSDashboard extends StatefulWidget {
  const POSDashboard({Key? key}) : super(key: key);

  @override
  State<POSDashboard> createState() => _POSDashboardState();
}

class _POSDashboardState extends State<POSDashboard> {
  // Test data for real-time sales
  final List<FlSpot> salesData = [
    FlSpot(0, 3),
    FlSpot(1, 4),
    FlSpot(2, 3.5),
    FlSpot(3, 5),
    FlSpot(4, 4.5),
    FlSpot(5, 6),
    FlSpot(6, 5.5),
    FlSpot(7, 7),
  ];

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
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
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
        body: Container(
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopCards(),
                  const SizedBox(height: 20),
                  _buildSalesGrid(),
                  const SizedBox(height: 20),
                  _buildTransactionSummary(),
                  const SizedBox(height: 20),
                  _buildRealTimeChart(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildInfoCard(
            icon: Icons.receipt,
            title: 'Total Invoices',
            value: '51,006',
            color: const Color(0xFF6C63FF),
            lightColor: const Color(0xFFE0F8F2),
            ),
          _buildInfoCard(
            icon: Icons.inventory_2,
            title: 'Total Products',
            value: '120,412',
            color: const Color(0xFF00C48C),
            lightColor: const Color(0xFFE0F8F2),
          ),
          _buildInfoCard(
            icon: Icons.assignment_return,
            title: 'Bill Returns',
            value: '3,637',
            color: const Color(0xFFFF647C),
            lightColor: const Color(0xFFFFE9EC),
          ),
          _buildInfoCard(
            icon: Icons.location_on,
            title: 'Best Outlet',
            value: 'BIA D38',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildSalesCard('Daily Sales', '186.97', 0.3, Colors.orange),
        _buildSalesCard('Weekly Sales', '3,200.65', 0.6, Colors.blue),
        _buildSalesCard('Monthly Sales', '3,200.65', 0.45, Colors.green),
        _buildSalesCard('Yearly Sales', '3,043,787.24', 0.8, Colors.purple),
      ],
    );
  }

  Widget _buildSalesCard(String title, String value, double progress, Color color) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      color: Colors.white,
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
              '\$$value',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSummary() {
    return Card(
      elevation: 4,
      shadowColor: Colors.blue.withOpacity(0.2),
      color: Colors.white,
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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                columns: const [
                  DataColumn(label: Text('Bill Type')),
                  DataColumn(label: Text('Today')),
                  DataColumn(label: Text('Yesterday')),
                  DataColumn(label: Text('Current Month')),
                  DataColumn(label: Text('Previous Month')),
                ],
                rows: [
                  _buildDataRow('INVOICE', '186.97', '3,013.68', '3,200.65', '3,124,865.30'),
                  _buildDataRow('SALES RETURN', '0.00', '0.00', '0.00', '-72,800.77'),
                  _buildDataRow('Total', '186.97', '3,013.68', '3,200.65', '3,052,064.53'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(String type, String today, String yesterday, String currentMonth, String previousMonth) {
    final bool isTotal = type == 'Total';
    final style = TextStyle(
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      color: isTotal ? Colors.blue.shade700 : null,
    );

    return DataRow(cells: [
      DataCell(Text(type, style: style)),
      DataCell(Text(today, style: style)),
      DataCell(Text(yesterday, style: style)),
      DataCell(Text(currentMonth, style: style)),
      DataCell(Text(previousMonth, style: style)),
    ]);
  }

  Widget _buildRealTimeChart() {
    return Card(
      elevation: 4,
      shadowColor: Colors.green.withOpacity(0.2),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real Time Sales',
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
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
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
                      spots: salesData,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}