import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:dio/io.dart';
import 'dart:html' as html;
import 'dart:typed_data';  // For Uint8List

import '../controllers/login_controller.dart';

final loginController = Get.find<LoginController>();
final datasource = loginController.datasource;
final currency = loginController.currency;

// Model for the report data
class ConsolidatedReportData {
  final String businessName;
  final String placeName;
  final double totalIncome;
  final double cash;
  final double card;
  final double credit;
  final double advance;

  ConsolidatedReportData({
    required this.businessName,
    required this.placeName,
    required this.totalIncome,
    required this.cash,
    required this.card,
    required this.credit,
    required this.advance,
  });

  factory ConsolidatedReportData.fromJson(Map<String, dynamic> json) {
    return ConsolidatedReportData(
      businessName: json['businessName'] ?? '',
      placeName: json['placeName'] ?? '',
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      cash: (json['cash'] ?? 0).toDouble(),
      card: (json['card'] ?? 0).toDouble(),
      credit: (json['credit'] ?? 0).toDouble(),
      advance: (json['advance'] ?? 0).toDouble(),
    );
  }
}

// API Service
class SalesReportService {
  final Dio _dio;
  final String baseUrl;

  SalesReportService()
      : baseUrl = 'http://124.43.70.220:7072/Reports',
        _dio = Dio(BaseOptions(
          baseUrl: 'http://124.43.70.220:7072/Reports',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
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
  }

  Future<List<ConsolidatedReportData>> getConsolidatedReport(
      DateTime startDate, DateTime endDate, String connectionString) async {
    try {
      if (kDebugMode) {
        print('Fetching consolidated report for dates: $startDate to $endDate');
      }

      final response = await _dio.get(
        '/report',
        queryParameters: {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'connectionString': datasource,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ConsolidatedReportData.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load report data. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getConsolidatedReport: $e');
        if (e is DioException) {
          print('DioError type: ${e.type}');
          print('DioError message: ${e.message}');
          print('DioError response: ${e.response}');
        }
      }
      throw Exception('Error fetching report: $e');
    }
  }
}

class SalesReportPage2 extends StatefulWidget {
  const SalesReportPage2({super.key});



  @override
  SalesReportPageState2 createState() => SalesReportPageState2();
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
      print('Error generating PDF: $e');
      rethrow;
    }
  }
}

class SalesReportPageState2 extends State<SalesReportPage2> with PwaPdfGenerator {
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool showReport = false;
  List<ConsolidatedReportData> reportData = [];
  List<ConsolidatedReportData> filteredData = [];
  final searchController = TextEditingController();
  final _salesReportService = SalesReportService();

  void _handleLogout() async {
    final loginController = Get.find<LoginController>();
    await loginController.clearLoginData();
  }

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredData = List.from(reportData);
      } else {
        filteredData = reportData.where((data) {
          return data.businessName.toLowerCase().contains(query);
        }).toList();
      }
    });
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
      final data = await _salesReportService.getConsolidatedReport(
          fromDate!,
          toDate!,
          datasource!
      );

      setState(() {
        reportData = data;
        filteredData = data; // Initialize filtered data
        showReport = true;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }

  List<DataRow> _generateTableRows() {
    final Map<String, List<ConsolidatedReportData>> groupedData = {};
    final List<DataRow> rows = [];

    // Group data by business name
    for (var data in filteredData) {
      if (!groupedData.containsKey(data.businessName)) {
        groupedData[data.businessName] = [];
      }
      groupedData[data.businessName]!.add(data);
    }

    // Calculate grand totals
    double grandTotalIncome = 0;
    double grandTotalCash = 0;
    double grandTotalCard = 0;
    double grandTotalCredit = 0;
    double grandTotalAdvance = 0;

    // Sort business names alphabetically
    final sortedBusinessNames = groupedData.keys.toList()..sort();

    for (var businessName in sortedBusinessNames) {
      final businessData = groupedData[businessName]!;

      // Add business name header row
      rows.add(DataRow(cells: [
        DataCell(Text(businessName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        ...List.generate(5, (index) => const DataCell(Text(''))),
      ]));

      double businessTotalIncome = 0;
      double businessTotalCash = 0;
      double businessTotalCard = 0;
      double businessTotalCredit = 0;
      double businessTotalAdvance = 0;

      // Add rows for each place under this business
      for (var data in businessData) {
        rows.add(DataRow(cells: [
          DataCell(Text(data.placeName)),
          DataCell(Text(NumberFormat('#,##0.00').format(data.totalIncome))),
          DataCell(Text(NumberFormat('#,##0.00').format(data.cash))),
          DataCell(Text(NumberFormat('#,##0.00').format(data.card))),
          DataCell(Text(NumberFormat('#,##0.00').format(data.credit))),
          DataCell(Text(NumberFormat('#,##0.00').format(data.advance))),
        ]));

        // Add to business totals
        businessTotalIncome += data.totalIncome;
        businessTotalCash += data.cash;
        businessTotalCard += data.card;
        businessTotalCredit += data.credit;
        businessTotalAdvance += data.advance;
      }

      // Add business total row
      rows.add(DataRow(
        cells: [
          const DataCell(Text('BUSINESS TOTAL',
              style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(NumberFormat('#,##0.00').format(businessTotalIncome),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(NumberFormat('#,##0.00').format(businessTotalCash),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(NumberFormat('#,##0.00').format(businessTotalCard),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(NumberFormat('#,##0.00').format(businessTotalCredit),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(NumberFormat('#,##0.00').format(businessTotalAdvance),
              style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ));

      // Add separator row
      rows.add(DataRow(
        cells: List.generate(6, (index) => const DataCell(
            SizedBox(height: 10, child: Text(''))
        )),
      ));

      // Add to grand totals
      grandTotalIncome += businessTotalIncome;
      grandTotalCash += businessTotalCash;
      grandTotalCard += businessTotalCard;
      grandTotalCredit += businessTotalCredit;
      grandTotalAdvance += businessTotalAdvance;
    }

    // Add grand total row
    if (rows.isNotEmpty) {
      rows.add(DataRow(
        cells: [
          const DataCell(Text('GRAND TOTAL',
              style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(NumberFormat('#,##0.00').format(grandTotalIncome),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(NumberFormat('#,##0.00').format(grandTotalCash),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(NumberFormat('#,##0.00').format(grandTotalCard),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(NumberFormat('#,##0.00').format(grandTotalCredit),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(NumberFormat('#,##0.00').format(grandTotalAdvance),
              style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ));
    }

    return rows;
  }

  Future<void> _generatePDF() async {
    setState(() => isLoading = true);
    try {
      final filename = 'sales_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

      await PwaPdfGenerator.generateAndDownloadPdf(
        filename: filename,
        generatePdf: () async {
          final pdf = pw.Document();
          final imageBytes = await rootBundle.load('assets/images/skynet_pro.jpg');
          final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

          pdf.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4.landscape,
              margin: const pw.EdgeInsets.symmetric(vertical: 50, horizontal: 60),
              build: (context) {
                return [
                  // Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Image(
                            image,
                            width: 150,
                            fit: pw.BoxFit.contain,
                          ),
                        ],
                      ),
                      pw.Text(
                        'From : ${DateFormat('yyyy-MM-dd').format(fromDate!)} To : ${DateFormat('yyyy-MM-dd').format(toDate!)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'SKYNET Pro Sales Reports',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Table
                  pw.TableHelper.fromTextArray(
                    context: context,
                    headers: [
                      'Location',
                      'Total Sales (LKR)',
                      'Cash (LKR)',
                      'Card (LKR)',
                      'Credit (LKR)',
                      'Advance (LKR)'
                    ],
                    data: _generatePDFData(),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(1.9),
                      2: const pw.FlexColumnWidth(1.6),
                      3: const pw.FlexColumnWidth(1.6),
                      4: const pw.FlexColumnWidth(1.6),
                      5: const pw.FlexColumnWidth(1.6),
                    },
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    cellHeight: 25,
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerRight,
                      2: pw.Alignment.centerRight,
                      3: pw.Alignment.centerRight,
                      4: pw.Alignment.centerRight,
                      5: pw.Alignment.centerRight,
                    },
                  ),

                  // Footer
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'SKYNET PRO Powered By Ceylon Innovations',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ];
              },
            ),
          );

          return pdf.save();
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<List<String>> _generatePDFData() {
    List<List<String>> data = [];
    Map<String, List<ConsolidatedReportData>> groupedData = {};

    // Group data by business name
    for (var item in filteredData) {
      if (!groupedData.containsKey(item.businessName)) {
        groupedData[item.businessName] = [];
      }
      groupedData[item.businessName]!.add(item);
    }

    double grandTotalIncome = 0;
    double grandTotalCash = 0;
    double grandTotalCard = 0;
    double grandTotalCredit = 0;
    double grandTotalAdvance = 0;

    final sortedBusinessNames = groupedData.keys.toList()..sort();

    for (var businessName in sortedBusinessNames) {
      final businessData = groupedData[businessName]!;

      // Add business name header row
      data.add([
        businessName,
        '',
        '',
        '',
        '',
        '',
      ]);

      double businessTotalIncome = 0;
      double businessTotalCash = 0;
      double businessTotalCard = 0;
      double businessTotalCredit = 0;
      double businessTotalAdvance = 0;

      // Add place data rows for this business
      for (var item in businessData) {
        data.add([
          item.placeName,
          NumberFormat('#,##0.00').format(item.totalIncome),
          NumberFormat('#,##0.00').format(item.cash),
          NumberFormat('#,##0.00').format(item.card),
          NumberFormat('#,##0.00').format(item.credit),
          NumberFormat('#,##0.00').format(item.advance),
        ]);

        // Add to business totals
        businessTotalIncome += item.totalIncome;
        businessTotalCash += item.cash;
        businessTotalCard += item.card;
        businessTotalCredit += item.credit;
        businessTotalAdvance += item.advance;
      }

      // Add business total row
      data.add([
        'BUSINESS TOTAL',
        NumberFormat('#,##0.00').format(businessTotalIncome),
        NumberFormat('#,##0.00').format(businessTotalCash),
        NumberFormat('#,##0.00').format(businessTotalCard),
        NumberFormat('#,##0.00').format(businessTotalCredit),
        NumberFormat('#,##0.00').format(businessTotalAdvance),
      ]);

      // Add empty row as separator
      data.add(['', '', '', '', '', '']);

      // Add to grand totals
      grandTotalIncome += businessTotalIncome;
      grandTotalCash += businessTotalCash;
      grandTotalCard += businessTotalCard;
      grandTotalCredit += businessTotalCredit;
      grandTotalAdvance += businessTotalAdvance;
    }

    // Add grand total row
    if (data.isNotEmpty) {
      data.add([
        'GRAND TOTAL',
        NumberFormat('#,##0.00').format(grandTotalIncome),
        NumberFormat('#,##0.00').format(grandTotalCash),
        NumberFormat('#,##0.00').format(grandTotalCard),
        NumberFormat('#,##0.00').format(grandTotalCredit),
        NumberFormat('#,##0.00').format(grandTotalAdvance),
      ]);
    }

    return data;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              'Sales Report',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 33,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
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
                              style:
                              GoogleFonts.poppins(color: Colors.grey[600]),
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
                              style:
                              GoogleFonts.poppins(color: Colors.grey[600]),
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
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by Location',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) => _onSearchChanged(),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 10, // Removes left spacing
                  columnSpacing: 30,
                  columns: const [
                    DataColumn(label: Text('Location')),
                    DataColumn(label: Text('Total Sales (LKR)')),
                    DataColumn(label: Text('Cash (LKR)')),
                    DataColumn(label: Text('Card (LKR)')),
                    DataColumn(label: Text('Credit (LKR)')),
                    DataColumn(label: Text('Advance (LKR)')),
                  ],
                  rows: _generateTableRows(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
