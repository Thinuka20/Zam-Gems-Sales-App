import 'dart:html' as html;
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genix_reports/widgets/user_activity_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'dart:math' show pow, log, ln10;
import '../controllers/login_controller.dart';
import 'dart:typed_data';  // For Uint8List

final loginController = Get.find<LoginController>();
final datasource = loginController.datasource;
final currency = loginController.currency;

class SalesSummary {
  final String locationName;
  final double totalIncomeLKR;
  final double cashIncomeLKR;
  final double cardIncomeLKR;
  final double lkr;
  final double usd;
  final double aed;
  final double gbp;
  final double eur;
  final double jpy;
  final double aud;
  final double cad;
  final double chf;
  final double cny;
  final double hkd;
  final double nzd;
  final double sgd;
  final double visaLKR;
  final double masterLKR;
  final double unionPayLKR;
  final double amexLKR;
  final double weChatLKR;

  SalesSummary.fromJson(Map<String, dynamic> json)
      : locationName = json['locationName'] ?? '',
        totalIncomeLKR = (json['totalIncomeLKR'] ?? 0).toDouble(),
        cashIncomeLKR = (json['cashIncomeLKR'] ?? 0).toDouble(),
        cardIncomeLKR = (json['cardIncomeLKR'] ?? 0).toDouble(),
        lkr = (json['lkr'] ?? 0).toDouble(),
        usd = (json['usd'] ?? 0).toDouble(),
        aed = (json['aed'] ?? 0).toDouble(),
        gbp = (json['gbp'] ?? 0).toDouble(),
        eur = (json['eur'] ?? 0).toDouble(),
        jpy = (json['jpy'] ?? 0).toDouble(),
        aud = (json['aud'] ?? 0).toDouble(),
        cad = (json['cad'] ?? 0).toDouble(),
        chf = (json['chf'] ?? 0).toDouble(),
        cny = (json['cny'] ?? 0).toDouble(),
        hkd = (json['hkd'] ?? 0).toDouble(),
        nzd = (json['nzd'] ?? 0).toDouble(),
        sgd = (json['sgd'] ?? 0).toDouble(),
        visaLKR = (json['visaLKR'] ?? 0).toDouble(),
        masterLKR = (json['masterLKR'] ?? 0).toDouble(),
        unionPayLKR = (json['unionPayLKR'] ?? 0).toDouble(),
        amexLKR = (json['amexLKR'] ?? 0).toDouble(),
        weChatLKR = (json['weChatLKR'] ?? 0).toDouble();
}

class SalesReportService {
  final Dio _dio;
  final String baseUrl;

  SalesReportService()
      : baseUrl = 'http://124.43.70.220:7072/Reports',
        _dio = Dio(BaseOptions(
          baseUrl: 'http://124.43.70.220:7072/Reports',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )) {
    // Only configure IOHttpClientAdapter for non-web platforms
    if (!kIsWeb) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
          (HttpClient client) {
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    // Add logging interceptor for debugging
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  Future<List<SalesSummary>> getSalesSummary(
      DateTime startDate, DateTime endDate) async {
    try {

      final response = await _dio.get(
        '/salessummary',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'connectionString': datasource,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SalesSummary.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load sales summary. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching sales summary: $e');
    }
  }
}

class SalesBarChart extends StatelessWidget {
  final List<SalesSummary> salesData;
  final currencyFormat = NumberFormat("#,##0.00", "en_US");

  SalesBarChart({super.key, required this.salesData});

  double _calculateInterval(double maxValue) {
    if (maxValue <= 0) return 1;

    double interval = maxValue / 5;
    if (interval < 0.1) {
      interval = 0.1;
    }

    double magnitude = pow(10, log(interval) ~/ ln10).toDouble();
    double normalized = interval / magnitude;

    if (normalized < 1.5) {
      normalized = 1;
    } else if (normalized < 3) {
      normalized = 2;
    } else if (normalized < 7) {
      normalized = 5;
    } else {
      normalized = 10;
    }

    return normalized * magnitude;
  }

  BarChartGroupData _generateBarGroup(int x, double value) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: const Color(0xFF2A2359),
          width: 40,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Colors.grey[600],
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    String text;
    if (meta.axisSide == AxisSide.bottom) {
      if (value.toInt() >= 0 && value.toInt() < salesData.length) {
        text = salesData[value.toInt()].locationName;
      } else {
        text = '';
      }
    } else {
      text = '$currency ${currencyFormat.format(value)}';
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: RotatedBox(
        quarterTurns: meta.axisSide == AxisSide.bottom ? 1 : 0,
        child: Text(text, style: style),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = salesData.isEmpty
        ? 0.0
        : salesData
        .map((e) => e.totalIncomeLKR)
        .reduce((a, b) => a > b ? a : b);
    final maxY = maxValue * 1.2;

    // Calculate minimum width based on data points
    final double minWidth = math.max(
      MediaQuery.of(context).size.width,
      salesData.length * 65.0,
    );

    // Calculate responsive height based on screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final double chartHeight = screenHeight * 0.6; // 60% of screen height

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Total Income by Location',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2A2359),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: chartHeight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: minWidth,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24.0),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceEvenly,
                        maxY: maxY,
                        minY: 0,
                        groupsSpace: 40,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.all(12),
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${salesData[groupIndex].locationName}\n',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                    text: '$currency ${currencyFormat.format(rod.toY)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 100,
                              getTitlesWidget: _buildTitles,
                              interval: _calculateInterval(maxY),
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
                              reservedSize: 120,
                              getTitlesWidget: _buildTitles,
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _calculateInterval(maxY),
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                            left: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        barGroups: salesData
                            .asMap()
                            .entries
                            .map((entry) => _generateBarGroup(
                          entry.key,
                          entry.value.totalIncomeLKR,
                        ))
                            .toList(),
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

class LocationDetailsChart extends StatelessWidget {
  final SalesSummary locationData;
  final currencyFormat = NumberFormat("#,##0.00", "en_US");

  LocationDetailsChart({super.key, required this.locationData});

  double _calculateInterval(double maxValue) {
    if (maxValue <= 0) return 1;

    double interval = maxValue / 5;
    if (interval < 0.1) {
      interval = 0.1;
    }

    double magnitude = pow(10, log(interval) ~/ ln10).toDouble();
    double normalized = interval / magnitude;

    if (normalized < 1.5) {
      normalized = 1;
    } else if (normalized < 3) {
      normalized = 2;
    } else if (normalized < 7) {
      normalized = 5;
    } else {
      normalized = 10;
    }

    return normalized * magnitude;
  }

  BarChartGroupData _generateBarGroup(int x, double value, String label) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: const Color(0xFF2A2359),
          width: 40,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Colors.grey[600],
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    final categories = [
      'Total Income',
      'Cash Income',
      'Card Income',
      'LKR',
      'USD',
      'AED',
      'GBP',
      'EUR',
      'JPY',
      'AUD',
      'CAD',
      'CHF',
      'RMB',
      'HKD',
      'NZD',
      'SGD',
      'Visa',
      'Master',
      'Union Pay',
      'Amex',
      'WeChat'
    ];

    String text;
    if (meta.axisSide == AxisSide.bottom) {
      if (value.toInt() >= 0 && value.toInt() < categories.length) {
        text = categories[value.toInt()];
      } else {
        text = '';
      }
    } else {
      text = '$currency ${currencyFormat.format(value)}';
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: RotatedBox(
        quarterTurns: meta.axisSide == AxisSide.bottom ? 1 : 0,
        child: Text(text, style: style),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final values = [
      locationData.totalIncomeLKR,
      locationData.cashIncomeLKR,
      locationData.cardIncomeLKR,
      locationData.lkr,
      locationData.usd,
      locationData.aed,
      locationData.gbp,
      locationData.eur,
      locationData.jpy,
      locationData.aud,
      locationData.cad,
      locationData.chf,
      locationData.cny,
      locationData.hkd,
      locationData.nzd,
      locationData.sgd,
      locationData.visaLKR,
      locationData.masterLKR,
      locationData.unionPayLKR,
      locationData.amexLKR,
      locationData.weChatLKR,
    ];

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final maxY = maxValue * 1.2;

    final categories = [
      'Total Income',
      'Cash Income',
      'Card Income',
      'LKR',
      'USD',
      'AED',
      'GBP',
      'EUR',
      'JPY',
      'AUD',
      'CAD',
      'CHF',
      'RMB',
      'HKD',
      'NZD',
      'SGD',
      'Visa',
      'Master',
      'Union Pay',
      'Amex',
      'WeChat'
    ];

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    locationData.locationName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2A2359),
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: math.max(MediaQuery.of(context).size.width * 0.85,
                      values.length * 65.0),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceEvenly,
                      maxY: maxY,
                      minY: 0,
                      groupsSpace: 40,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.all(12),
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${categories[groupIndex]}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '$currency ${currencyFormat.format(rod.toY)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 100,
                            getTitlesWidget: _buildTitles,
                            interval: _calculateInterval(maxY),
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
                            reservedSize: 120,
                            getTitlesWidget: _buildTitles,
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _calculateInterval(maxY),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                          left: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      barGroups: values
                          .asMap()
                          .entries
                          .map((entry) => _generateBarGroup(
                                entry.key,
                                entry.value,
                                categories[entry.key],
                              ))
                          .toList(),
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

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  SalesReportPageState createState() => SalesReportPageState();
}

mixin PwaPdfGenerator {
  static bool get isPwa {
    if (kIsWeb) {
      // Use matchMedia to detect standalone mode (PWA)
      return html.window.matchMedia('(display-mode: standalone)').matches ||
          html.window.navigator.userAgent.toLowerCase().contains('wv'); // WebView detection
    }
    return false;
  }

  static Future<void> generateAndDownloadPdf({
    required Future<Uint8List> Function() generatePdf,
    required String filename,
  }) async {
    try {
      final bytes = await generatePdf();

      if (isPwa) {
        // PWA mode - force download
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement()
          ..href = url
          ..style.display = 'none'
          ..download = filename;

        html.document.body?.children.add(anchor);

        // Use Future.delayed to ensure the anchor is added before clicking
        await Future.delayed(const Duration(milliseconds: 100));
        anchor.click();

        // Cleanup after a short delay to ensure download starts
        await Future.delayed(const Duration(milliseconds: 100));
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        // Regular web mode - use printing package
        await Printing.layoutPdf(
          onLayout: (format) => Future.value(bytes),
          name: filename,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

class SalesReportPageState extends State<SalesReportPage> with PwaPdfGenerator {
  final SalesReportService _service = SalesReportService();
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

    if (fromDate == toDate) {
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
      final data = await _service.getSalesSummary(fromDate!, toDate!);
      setState(() {
        reportData = data;
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

Future<void> _generatePDF() async {
  setState(() => isLoading = true);
  try {
    final filename = 'sales_report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf';

    await PwaPdfGenerator.generateAndDownloadPdf(
      filename: filename,
      generatePdf: () async {
        final pdf = pw.Document();
        final imageBytes = await rootBundle.load('assets/images/skynet_pro.jpg');
        final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a3.landscape,
            margin: const pw.EdgeInsets.all(40),
            build: (context) {
              return [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(image, width: 100),
                      pw.Text(
                        'Sales Report',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'From: ${DateFormat('yyyy-MM-dd').format(fromDate!)}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          pw.Text(
                            'To: ${DateFormat('yyyy-MM-dd').format(toDate!)}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildPDFTable(),
                pw.Footer(
                  leading: pw.Text(
                    'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  trailing: pw.Text(
                    'SKYNET PRO Powered By Ceylon Innovations',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ];
            },
          ),
        );

        return pdf.save();
      },
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error generating PDF: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => isLoading = false);
  }
}

  pw.Widget _buildPDFTable() {
    return pw.TableHelper.fromTextArray(
      context: null,
      headers: _getHeaders(),
      data: _getPDFData(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 25,
      cellAlignments: Map.fromIterables(
        List<int>.generate(22, (index) => index),
        List<pw.Alignment>.generate(
            22,
            (index) => index == 0
                ? pw.Alignment.centerLeft
                : pw.Alignment.centerRight),
      ),
    );
  }

  List<String> _getHeaders() {
    return [
      'Location',
      'Total Income ($currency)',
      'Cash Income ($currency)',
      'Card Income ($currency)',
      'LKR',
      'USD',
      'AED',
      'GBP',
      'Euro',
      'JPY',
      'AUD',
      'CAD',
      'CHF',
      'RMB',
      'HKD',
      'NZD',
      'SGD',
      'Visa ($currency)',
      'Master ($currency)',
      'Union Pay ($currency)',
      'Amex ($currency)',
      'WeChat ($currency)',
    ];
  }

  List<List<String>> _getPDFData() {
    final List<List<String>> data = reportData
        .map((item) => [
              item.locationName,
              NumberFormat('#,##0.00').format(item.totalIncomeLKR),
              NumberFormat('#,##0.00').format(item.cashIncomeLKR),
              NumberFormat('#,##0.00').format(item.cardIncomeLKR),
              NumberFormat('#,##0.00').format(item.lkr),
              NumberFormat('#,##0.00').format(item.usd),
              NumberFormat('#,##0.00').format(item.aed),
              NumberFormat('#,##0.00').format(item.gbp),
              NumberFormat('#,##0.00').format(item.eur),
              NumberFormat('#,##0.00').format(item.jpy),
              NumberFormat('#,##0.00').format(item.aud),
              NumberFormat('#,##0.00').format(item.cad),
              NumberFormat('#,##0.00').format(item.chf),
              NumberFormat('#,##0.00').format(item.cny),
              NumberFormat('#,##0.00').format(item.hkd),
              NumberFormat('#,##0.00').format(item.nzd),
              NumberFormat('#,##0.00').format(item.sgd),
              NumberFormat('#,##0.00').format(item.visaLKR),
              NumberFormat('#,##0.00').format(item.masterLKR),
              NumberFormat('#,##0.00').format(item.unionPayLKR),
              NumberFormat('#,##0.00').format(item.amexLKR),
              NumberFormat('#,##0.00').format(item.weChatLKR),
            ])
        .toList();

    // Add totals row
    data.add(_calculateTotalsRow());

    return data;
  }

  List<String> _calculateTotalsRow() {
    double totalIncomeLKR = 0;
    double cashIncomeLKR = 0;
    double cardIncomeLKR = 0;
    double lkr = 0;
    double usd = 0;
    double aed = 0;
    double gbp = 0;
    double eur = 0;
    double jpy = 0;
    double aud = 0;
    double cad = 0;
    double chf = 0;
    double cny = 0;
    double hkd = 0;
    double nzd = 0;
    double sgd = 0;
    double visaLKR = 0;
    double masterLKR = 0;
    double unionPayLKR = 0;
    double amexLKR = 0;
    double weChatLKR = 0;

    for (var item in reportData) {
      totalIncomeLKR += item.totalIncomeLKR;
      cashIncomeLKR += item.cashIncomeLKR;
      cardIncomeLKR += item.cardIncomeLKR;
      lkr += item.lkr;
      usd += item.usd;
      aed += item.aed;
      gbp += item.gbp;
      eur += item.eur;
      jpy += item.jpy;
      aud += item.aud;
      cad += item.cad;
      chf += item.chf;
      cny += item.cny;
      hkd += item.hkd;
      nzd += item.nzd;
      sgd += item.sgd;
      visaLKR += item.visaLKR;
      masterLKR += item.masterLKR;
      unionPayLKR += item.unionPayLKR;
      amexLKR += item.amexLKR;
      weChatLKR += item.weChatLKR;
    }

    return [
      'GRAND TOTAL',
      NumberFormat('#,##0.00').format(totalIncomeLKR),
      NumberFormat('#,##0.00').format(cashIncomeLKR),
      NumberFormat('#,##0.00').format(cardIncomeLKR),
      NumberFormat('#,##0.00').format(lkr),
      NumberFormat('#,##0.00').format(usd),
      NumberFormat('#,##0.00').format(aed),
      NumberFormat('#,##0.00').format(gbp),
      NumberFormat('#,##0.00').format(eur),
      NumberFormat('#,##0.00').format(jpy),
      NumberFormat('#,##0.00').format(aud),
      NumberFormat('#,##0.00').format(cad),
      NumberFormat('#,##0.00').format(chf),
      NumberFormat('#,##0.00').format(cny),
      NumberFormat('#,##0.00').format(hkd),
      NumberFormat('#,##0.00').format(nzd),
      NumberFormat('#,##0.00').format(sgd),
      NumberFormat('#,##0.00').format(visaLKR),
      NumberFormat('#,##0.00').format(masterLKR),
      NumberFormat('#,##0.00').format(unionPayLKR),
      NumberFormat('#,##0.00').format(amexLKR),
      NumberFormat('#,##0.00').format(weChatLKR),
    ];
  }

  List<DataRow> _generateTableRows() {
    final List<DataRow> rows = reportData.map((item) {
      return DataRow(
        cells: [
          DataCell(
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) =>
                      LocationDetailsChart(locationData: item),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.locationName,
                    style: const TextStyle(
                      color: Color(0xFF2A2359),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.bar_chart,
                      size: 16, color: Color(0xFF2A2359)),
                ],
              ),
            ),
          ),
          // All other cells are center-aligned with fixed width
          ...[
            // Using spread operator for the remaining cells
            item.totalIncomeLKR,
            item.cashIncomeLKR,
            item.cardIncomeLKR,
            item.lkr,
            item.usd,
            item.aed,
            item.gbp,
            item.eur,
            item.jpy,
            item.aud,
            item.cad,
            item.chf,
            item.cny,
            item.hkd,
            item.nzd,
            item.sgd,
            item.visaLKR,
            item.masterLKR,
            item.unionPayLKR,
            item.amexLKR,
            item.weChatLKR,
          ].map((value) => DataCell(
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          LocationDetailsChart(locationData: item),
                    );
                  },
                  child: Container(
                    alignment: Alignment.centerRight,
                    child: Text(
                      NumberFormat('#,##0.00').format(value),
                      style: const TextStyle(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              )),
        ],
      );
    }).toList();

    // Add total row
    if (reportData.isNotEmpty) {
      rows.add(DataRow(
        cells: _calculateTotalsRow()
            .asMap()
            .map((index, value) => MapEntry(
                  index,
                  DataCell(
                    Container(
                      width: index == 0 ? null : 130,
                      alignment: index == 0
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Text(
                        value,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ))
            .values
            .toList(),
      ));
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return UserActivityWrapper(
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).primaryColor,
            automaticallyImplyLeading: false,
            toolbarHeight: 120,
            flexibleSpace: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // First row with Back and Logout buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        label: const Text(
                          'Back',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.power_settings_new,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _handleLogout,
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // Spacing between rows
                  // Second row with title
                  Text(
                    'Location Wise Sales',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
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
                            'Generate Report',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  if (showReport) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _generatePDF,
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                      label: Text(
                        'Generate PDF',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      child: SalesBarChart(salesData: reportData),
                    ),
                    const SizedBox(height: 24),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        horizontalMargin: 10,
                        columnSpacing: 10,
                        columns: _getHeaders()
                            .map((header) => DataColumn(label: Text(header)))
                            .toList(),
                        rows: _generateTableRows(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
