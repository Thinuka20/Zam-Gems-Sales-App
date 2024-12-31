import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genix_reports/pages/salesreport.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui' as ui;
import '../controllers/login_controller.dart';

class Billdetails extends StatefulWidget {
  const Billdetails({super.key});



  @override
  State<Billdetails> createState() => _BilldetailsState();
}

class _BilldetailsState extends State<Billdetails> {
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  List<SalesSummary> reportData = [];
  bool showReport = false;

  void _handleLogout() async {
    final loginController = Get.find<LoginController>();
    await loginController.clearLoginData();
  }

  Future<void> _onRefresh() async {
    if (fromDate != null && toDate != null) {
      await _generateReport();
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2A2359),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2A2359),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both dates')),
      );
      return;
    }

    if (fromDate!.year == toDate!.year &&
        fromDate!.month == toDate!.month &&
        fromDate!.day == toDate!.day) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('From date and To date cannot be same')),
      );
      return;
    }

    if (toDate!.isBefore(fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      showReport = false;
    });

    try {
      setState(() {
        showReport = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
          toolbarHeight: 120,
          actions: [
            // Add logout button
            IconButton(
              icon: const Icon(
                Icons.power_settings_new,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _handleLogout,
              tooltip: 'Logout', // Add tooltip for better UX
            ),
            const SizedBox(width: 16),
          ],
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
                'Bill Details',
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
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // Enable scrolling even when content is small
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'From Date',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  fromDate != null
                                      ? DateFormat('yyyy-MM-dd').format(fromDate!)
                                      : 'Select Date',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'To Date',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  toDate != null
                                      ? DateFormat('yyyy-MM-dd').format(toDate!)
                                      : 'Select Date',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _generateReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    'Generate',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (showReport) ...[
                  BillDetailsCharts(
                    fromDate: fromDate!,
                    toDate: toDate!,
                    connectionString: '$datasource',
                  ),
                ],
                // Add a SizedBox to ensure there's always scrollable space
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final loginController = Get.find<LoginController>();
final currency = loginController.currency;

class BillDetailsCharts extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final String connectionString;

  const BillDetailsCharts({
    Key? key,
    required this.fromDate,
    required this.toDate,
    required this.connectionString,
  }) : super(key: key);

  @override
  State<BillDetailsCharts> createState() => _BillDetailsChartsState();
}

class _BillDetailsChartsState extends State<BillDetailsCharts> {
  List<LocationBillSummary> _locationSummaries = [];
  List<DateWiseBillSummary> _dateWiseSummaries = [];
  bool _isLoadingLocation = true;
  bool _isLoadingDateWise = true;
  String? _errorLocation;
  String? _errorDateWise;

  static const String _locationSummaryUrl =
      'http://124.43.70.220:7072/Reports/locationbillsummary';
  static const String _dateWiseSummaryUrl =
      'http://124.43.70.220:7072/Reports/billsummary';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(BillDetailsCharts oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data when dates change
    if (oldWidget.fromDate != widget.fromDate ||
        oldWidget.toDate != widget.toDate ||
        oldWidget.connectionString != widget.connectionString) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    // Reset state and fetch both summaries
    setState(() {
      _isLoadingLocation = true;
      _isLoadingDateWise = true;
      _errorLocation = null;
      _errorDateWise = null;
      // Clear existing data
      _locationSummaries = [];
      _dateWiseSummaries = [];
    });

    await Future.wait([
      _fetchLocationSummary(),
      _fetchDateWiseSummary(),
    ]);
  }

  Future<void> _fetchLocationSummary() async {
    setState(() {
      _isLoadingLocation = true;
      _errorLocation = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '$_locationSummaryUrl?startDate=${widget.fromDate.toIso8601String()}&endDate=${widget.toDate.toIso8601String()}&connectionString=${Uri.encodeComponent(widget.connectionString)}',
        ),
      );

      if (!mounted) return; // Check if widget is still mounted


      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _locationSummaries = data
              .map((json) => LocationBillSummary.fromJson(json))
              .where((summary) => summary.billCount > 0)
              .toList();
          _isLoadingLocation = false;
        });
      } else {
        _handleLocationError(
            'Failed to load location data: ${response.statusCode}');
      }
    } catch (e) {
      _handleLocationError(e.toString());
    }
  }

  Future<void> _fetchDateWiseSummary() async {
    setState(() {
      _isLoadingDateWise = true;
      _errorDateWise = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '$_dateWiseSummaryUrl?startDate=${widget.fromDate.toIso8601String()}&endDate=${widget.toDate.toIso8601String()}&connectionString=${Uri.encodeComponent(widget.connectionString)}',
        ),
      );

      if (!mounted) return; // Check if widget is still mounted

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _dateWiseSummaries =
              data.map((json) => DateWiseBillSummary.fromJson(json)).toList();
          _isLoadingDateWise = false;
        });
      } else {
        _handleDateWiseError(
            'Failed to load date-wise data: ${response.statusCode}');
      }
    } catch (e) {
      _handleDateWiseError(e.toString());
    }
  }

  void _handleLocationError(String errorMessage) {
    setState(() {
      _errorLocation = errorMessage;
      _isLoadingLocation = false;
    });
    print('Location Error: $errorMessage');
  }

  void _handleDateWiseError(String errorMessage) {
    setState(() {
      _errorDateWise = errorMessage;
      _isLoadingDateWise = false;
    });
    print('Date-wise Error: $errorMessage');
  }

  List<PieSection> _getPieSections() {
    if (_locationSummaries.isEmpty) return [];

    final total = _locationSummaries.fold(0, (sum, loc) => sum + loc.billCount);
    final colors = [
      Colors.blue, // Deep blue
      Colors.red, // Bright red
      Colors.green, // Green
      Colors.orange, // Orange
      Colors.purple, // Purple
      Colors.teal, // Teal
      Colors.pink, // Pink
      Colors.amber, // Amber
      Colors.indigo, // Indigo
      Colors.brown, // Brown
      Colors.cyan, // Cyan
      Colors.deepOrange, // Deep orange
      Colors.lightGreen, // Light green
      Colors.deepPurple, // Deep purple
      Colors.lightBlue, // Light blue
      Colors.blueGrey, // Blue grey
      Colors.lime, // Lime
      Colors.yellow[700]!, // Darker yellow for better visibility
      Colors.redAccent, // Red accent
      Colors.indigoAccent, // Indigo accent
    ];

    return _locationSummaries.asMap().entries.map((entry) {
      final percentage = (entry.value.billCount / total) * 100;
      return PieSection(
        percentage,
        colors[entry.key % colors.length],
        entry.value.locationName,
        entry.value.billCount,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Location-wise Pie Chart
        _buildPieChart(),
        // Date-wise Bar Chart
        _buildBarChart(),
      ],
    );
  }

  Widget _buildPieChart() {
    if (_isLoadingLocation) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorLocation != null) {
      return _buildErrorWidget(_errorLocation!, _fetchLocationSummary);
    }

    if (_locationSummaries.isEmpty) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No location data available'),
        ),
      );
    }

    return Pie3DChart(sections: _getPieSections());
  }

  Widget _buildBarChart() {
    if (_isLoadingDateWise) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorDateWise != null) {
      return _buildErrorWidget(_errorDateWise!, _fetchDateWiseSummary);
    }

    if (_dateWiseSummaries.isEmpty) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No date-wise data available'),
        ),
      );
    }

    return DateWiseBarChart(billSummaries: _dateWiseSummaries);
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          )
        ],
      ),
    );
  }
}

class LocationBillSummary {
  final String locationName;
  final int billCount;
  final double totalAmount;

  LocationBillSummary({
    required this.locationName,
    required this.billCount,
    required this.totalAmount,
  });

  factory LocationBillSummary.fromJson(Map<String, dynamic> json) {
    return LocationBillSummary(
      locationName: json['locationName'] ?? 'Unknown',
      billCount: json['billCount'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    );
  }
}

class DateWiseBillSummary {
  final DateTime saleDate;
  final int billCount;
  final double totalAmount;

  DateWiseBillSummary({
    required this.saleDate,
    required this.billCount,
    required this.totalAmount,
  });

  factory DateWiseBillSummary.fromJson(Map<String, dynamic> json) {
    return DateWiseBillSummary(
      saleDate:
      DateTime.parse(json['saleDate'] ?? DateTime.now().toIso8601String()),
      billCount: json['billCount'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
    );
  }
}

class PieSection {
  final double percentage;
  final Color color;
  final String label;
  final int billCount;

  PieSection(this.percentage, this.color, this.label, this.billCount);
}

class Pie3DChart extends StatelessWidget {
  final List<PieSection> sections;

  const Pie3DChart({Key? key, required this.sections}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No of Bills - Outlet wise',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CustomPaint(
                painter: Pie3DPainter(sections),
              ),
            ),
            const SizedBox(height: 20),
            // Wrap legend items in a scrollable container with proper constraints
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height *
                    0.3, // Limit height to 30% of screen
              ),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8, // Reduced spacing
                  runSpacing: 8,
                  children: sections
                      .map((section) => _buildLegendItem(
                    section.label,
                    section.color,
                    section.billCount,
                    section.percentage,
                  ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
      String label, Color color, int billCount, double percentage) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 100,
        maxWidth: 300,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label ($billCount bills - ${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class Pie3DPainter extends CustomPainter {
  final List<PieSection> sections;

  Pie3DPainter(this.sections);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final depthRect =
    Rect.fromCircle(center: center.translate(0, 20), radius: radius);

    double startAngle = -math.pi / 2;

    // Draw 3D effect (sides)
    for (var section in sections) {
      final sweepAngle = (section.percentage / 100) * 2 * math.pi;
      final paint = Paint()
        ..color = section.color.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.arcTo(rect, startAngle, sweepAngle, true);
      path.arcTo(depthRect, startAngle + sweepAngle, -sweepAngle, false);
      path.close();
      canvas.drawPath(path, paint);
      startAngle += sweepAngle;
    }

    // Draw top of pie
    startAngle = -math.pi / 2;
    for (var section in sections) {
      final sweepAngle = (section.percentage / 100) * 2 * math.pi;
      final paint = Paint()
        ..color = section.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Draw percentage text if segment is large enough
      if (section.percentage > 5) {
        final textAngle = startAngle + sweepAngle / 2;
        final x = center.dx + radius * 0.7 * math.cos(textAngle);
        final y = center.dy + radius * 0.7 * math.sin(textAngle);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${section.percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout(
          minWidth: 0,
          maxWidth: size.width,
        );
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Update the DateWiseBarChart class
class DateWiseBarChart extends StatelessWidget {
  final List<DateWiseBillSummary> billSummaries;

  const DateWiseBarChart({
    Key? key,
    required this.billSummaries,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No of Bills - Date wise',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Increased aspect ratio for taller bars
            AspectRatio(
              aspectRatio: 4 / 3, // Modified from 4/3 to 16/9 for taller bars
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(
                    MediaQuery.of(context).size.width * 1,
                    billSummaries.length * 65.0, // Increased spacing between bars
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceEvenly,
                      // Reduced maxY multiplier to make bars taller relative to chart height
                      maxY: billSummaries
                          .map((s) => s.billCount)
                          .reduce(math.max)
                          .toDouble() * 1.2,
                      minY: 0,
                      groupsSpace: 40, // Increased group space
                      barGroups: billSummaries.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.billCount.toDouble(),
                              color: Colors.deepPurple,
                              width: 40, // Adjusted bar width
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                          left: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45, // Increased reserved size
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 70, // Increased for better text visibility
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < billSummaries.length) {
                                final date = billSummaries[value.toInt()].saleDate;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Transform.rotate(
                                    angle: -0.5,
                                    child: Text(
                                      DateFormat('dd MMM yy').format(date),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.all(12), // Increased padding
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${DateFormat('dd MMM yy').format(billSummaries[groupIndex].saleDate)}\n'
                                  'Bills: ${rod.toY.toInt()}\n'
                                  'Amount: ${NumberFormat.currency(symbol: '$currency.').format(billSummaries[groupIndex].totalAmount)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}