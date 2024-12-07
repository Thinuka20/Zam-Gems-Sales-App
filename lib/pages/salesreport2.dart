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
import '../controllers/login_controller.dart';

final loginController = Get.find<LoginController>();
final currency = loginController.currency;
// Model for the report data
class ConsolidatedReportData {
  final int id;
  final String businessName;
  final String placeName;
  final String details;
  final String totalIncome;
  final String cash;
  final String card;
  final String credit;
  final String advance;

  ConsolidatedReportData({
    required this.id,
    required this.businessName,
    required this.placeName,
    required this.details,
    required this.totalIncome,
    required this.cash,
    required this.card,
    required this.credit,
    required this.advance,
  });

  factory ConsolidatedReportData.fromJson(Map<String, dynamic> json) {
    return ConsolidatedReportData(
      id: json['id'] ?? 0,
      businessName: json['businessName'] ?? '',
      placeName: json['placeName'] ?? '',
      details: json['details'] ?? '',
      totalIncome: json['totalIncome']?.toString() ?? '0.00',
      cash: json['cash']?.toString() ?? '0.00',
      card: json['card']?.toString() ?? '0.00',
      credit: json['credit']?.toString() ?? '0.00',
      advance: json['advance']?.toString() ?? '0.00',
    );
  }
}

// API Service
class SalesReportService {
  final Dio _dio;
  final String baseUrl;

  SalesReportService({String? baseUrl})
  // : baseUrl = baseUrl ?? 'https://10.0.2.2:7153/api/Reports',
      : baseUrl = baseUrl ?? 'http://124.43.70.220:7071/Reports',
        _dio = Dio() {
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );
  }

  Future<List<ConsolidatedReportData>> getConsolidatedReport(
      DateTime startDate, DateTime endDate) async {
    try {
      if (kDebugMode) {
        print('Connecting to: $baseUrl/report');
      }
      String formattedStartDate =
      DateFormat('yyyy-MM-dd 04:00:00').format(startDate);
      String formattedEndDate =
      DateFormat('yyyy-MM-dd 04:00:00').format(endDate);

      if (kDebugMode) {
        print(
            'Request parameters: startDate=$formattedStartDate, endDate=$formattedEndDate');
      }

      final response = await _dio.get(
        '$baseUrl/report',
        queryParameters: {
          'startDate': formattedStartDate,
          'endDate': formattedEndDate,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Connection successful - Data received');
        }
        if (kDebugMode) {
          print(response.data);
        }
        final List<dynamic> data = response.data;
        return data
            .map((json) => ConsolidatedReportData.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load report data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Connection error: $e');
      }
      throw Exception('Error fetching report: $e');
    }
  }
}

class SalesReportPage2 extends StatefulWidget {
  const SalesReportPage2({super.key});

  @override
  SalesReportPage2State createState() => SalesReportPage2State();
}

class SalesReportPage2State extends State<SalesReportPage2> {
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool showReport = false;
  List<ConsolidatedReportData> reportData = [];
  List<ConsolidatedReportData> filteredData = [];
  final searchController = TextEditingController();
  final _salesReportService = SalesReportService();

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
          return data.details.toLowerCase().contains(query);
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
    });

    try {
      final data =
      await _salesReportService.getConsolidatedReport(fromDate!, toDate!);
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
    final Map<String, List<dynamic>> groupedData = {};
    final List<DataRow> rows = [];

    // Group data by place name instead of business name
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

    // Sort place names alphabetically
    final sortedPlaceNames = groupedData.keys.toList()..sort();

    for (var placeName in sortedPlaceNames) {
      final placeData = groupedData[placeName]!;

      // Add place name header row
      rows.add(DataRow(cells: [
        DataCell(Text(placeName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        ...List.generate(5, (index) => const DataCell(Text(''))),
      ]));

      double placeTotalIncome = 0;
      double placeTotalCash = 0;
      double placeTotalCard = 0;
      double placeTotalCredit = 0;
      double placeTotalAdvance = 0;

      // Add rows for each business under this place
      for (var data in placeData) {
        final detailParts = data.details.split('-');
        final displayDetail =
        detailParts.length > 1 ? detailParts[1].trim() : data.details;

        rows.add(DataRow(cells: [
          DataCell(Text(displayDetail)),
          DataCell(Text(data.totalIncome)),
          DataCell(Text(data.cash)),
          DataCell(Text(data.card)),
          DataCell(Text(data.credit)),
          DataCell(Text(data.advance)),
        ]));

        // Add to place totals
        placeTotalIncome += double.parse(data.totalIncome.replaceAll(',', ''));
        placeTotalCash += double.parse(data.cash.replaceAll(',', ''));
        placeTotalCard += double.parse(data.card.replaceAll(',', ''));
        placeTotalCredit += double.parse(data.credit.replaceAll(',', ''));
        placeTotalAdvance += double.parse(data.advance.replaceAll(',', ''));
      }

      // Add place total row
      rows.add(DataRow(
        cells: [
          const DataCell(Text('BUSINESS TOTAL',
              style: TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(NumberFormat('#,##0.00').format(placeTotalIncome),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(NumberFormat('#,##0.00').format(placeTotalCash),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(NumberFormat('#,##0.00').format(placeTotalCard),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(NumberFormat('#,##0.00').format(placeTotalCredit),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(NumberFormat('#,##0.00').format(placeTotalAdvance),
              style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ));

      // Add separator row
      rows.add(DataRow(
        cells: List.generate(6, (index) => const DataCell(
            SizedBox(
                height: 10, // Adjust this value to control the row height
                child: Text('')
            )
        )),
      ));

      // Add to grand totals
      grandTotalIncome += placeTotalIncome;
      grandTotalCash += placeTotalCash;
      grandTotalCard += placeTotalCard;
      grandTotalCredit += placeTotalCredit;
      grandTotalAdvance += placeTotalAdvance;
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
      final pdf = pw.Document();
      final imageBytes = await rootBundle.load('assets/images/skynet_pro.jpg');
      final image = pw.MemoryImage(
        imageBytes.buffer.asUint8List(),
      );

      // Add page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.symmetric(vertical: 50, horizontal: 60), // Adjust margin here
          build: (pw.Context context) {
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
                        width: 150, // Set your desired width
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
                  'Total Sales ($currency)',
                  'Cash ($currency)',
                  'Card ($currency)',
                  'Credit ($currency)',
                  'Advance ($currency)'
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
                mainAxisAlignment: pw
                    .MainAxisAlignment.spaceBetween, // Changed to spaceBetween
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

      // Show PDF preview dialog
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PDF Preview', style: GoogleFonts.poppins()),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PdfPreview(
                    build: (format) => pdf.save(),
                    allowPrinting: true,
                    allowSharing: true,
                    maxPageWidth: 800,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    pdfFileName:
                    'sales_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                  ),
                ),
              ],
            ),
          ),
        ),
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

    // Group data by place name instead of business name
    for (var item in filteredData) {
      if (!groupedData.containsKey(item.businessName)) {
        groupedData[item.businessName] = [];
      }
      groupedData[item.businessName]!.add(item);
    }

    // Track grand totals
    double grandTotalIncome = 0;
    double grandTotalCash = 0;
    double grandTotalCard = 0;
    double grandTotalCredit = 0;
    double grandTotalAdvance = 0;

    // Sort place names alphabetically
    final sortedPlaceNames = groupedData.keys.toList()..sort();

    // Generate rows for each place group
    for (var placeName in sortedPlaceNames) {
      final placeData = groupedData[placeName]!;

      // Add place name header row
      data.add([
        placeName, // Place name in first column
        '',
        '',
        '',
        '',
        '',
      ]);

      double placeTotalIncome = 0;
      double placeTotalCash = 0;
      double placeTotalCard = 0;
      double placeTotalCredit = 0;
      double placeTotalAdvance = 0;

      // Add business data rows for this place
      for (var item in placeData) {
        final detailParts = item.details.split('-');
        final displayDetail =
        detailParts.length > 1 ? detailParts[1].trim() : item.details;
        data.add([
          displayDetail,
          NumberFormat('#,##0.00')
              .format(double.parse(item.totalIncome.replaceAll(',', ''))),
          NumberFormat('#,##0.00')
              .format(double.parse(item.cash.replaceAll(',', ''))),
          NumberFormat('#,##0.00')
              .format(double.parse(item.card.replaceAll(',', ''))),
          NumberFormat('#,##0.00')
              .format(double.parse(item.credit.replaceAll(',', ''))),
          NumberFormat('#,##0.00')
              .format(double.parse(item.advance.replaceAll(',', ''))),
        ]);

        // Add to place totals
        placeTotalIncome += double.parse(item.totalIncome.replaceAll(',', ''));
        placeTotalCash += double.parse(item.cash.replaceAll(',', ''));
        placeTotalCard += double.parse(item.card.replaceAll(',', ''));
        placeTotalCredit += double.parse(item.credit.replaceAll(',', ''));
        placeTotalAdvance += double.parse(item.advance.replaceAll(',', ''));
      }

      // Add place total row
      data.add([
        'BUSINESS TOTAL',
        NumberFormat('#,##0.00').format(placeTotalIncome),
        NumberFormat('#,##0.00').format(placeTotalCash),
        NumberFormat('#,##0.00').format(placeTotalCard),
        NumberFormat('#,##0.00').format(placeTotalCredit),
        NumberFormat('#,##0.00').format(placeTotalAdvance),
      ]);

      // Add empty row as separator
      data.add(['', '', '', '', '', '']);

      // Add to grand totals
      grandTotalIncome += placeTotalIncome;
      grandTotalCash += placeTotalCash;
      grandTotalCard += placeTotalCard;
      grandTotalCredit += placeTotalCredit;
      grandTotalAdvance += placeTotalAdvance;
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
        toolbarHeight: 100,
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
              'Location Wise Sales',
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
                  hintText: 'Search by business name or place',
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
