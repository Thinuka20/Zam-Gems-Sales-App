import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genix_reports/widgets/user_activity_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../controllers/login_controller.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

final loginController = Get.find<LoginController>();
final currency = loginController.currency;
final datasource = loginController.datasource;

class totalProduction {
  final int itemId;
  final String itemName;
  final double totalQuantity;
  final double averageTotal;

  totalProduction({
    required this.itemId,
    required this.itemName,
    required this.totalQuantity,
    required this.averageTotal,
  });

  factory totalProduction.fromJson(Map<String, dynamic> json) {
    return totalProduction(
      itemId: json['itemId'] as int? ?? 0,
      itemName: json['itemName'] as String? ?? 'Unknown Item',
      totalQuantity: (json['totalQuantity'] as num?)?.toDouble() ?? 0.0,
      averageTotal: (json['averageTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class itemwiseProductionReport extends StatefulWidget {
  // Renamed to SoldItemsReport
  const itemwiseProductionReport({super.key});

  @override
  State<itemwiseProductionReport> createState() => _itemwiseProductionReportState();
}

class ApiService {
  static const String baseUrl = 'http://124.43.70.220:7072/Reports';

  ApiService();

  Future<List<totalProduction>> getSoldItems({
    required DateTime startDate,
    required DateTime endDate,
    required String location,
  }) async {
    try {
      final queryParameters = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'connectionString': location,
      };

      final uri = Uri.parse('$baseUrl/ingredientwise')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List<dynamic> itemsJson = json.decode(response.body) as List<dynamic>? ?? [];
        return itemsJson
            .map((json) => totalProduction.fromJson(json as Map<String, dynamic>))
            .where((totalProduction) => totalProduction.itemId != 0) // Filter out invalid items
            .toList();
      } else {
        throw Exception('Failed to load sold items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load sold items: $e');
    }
  }
}

class _itemwiseProductionReportState extends State<itemwiseProductionReport> {
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool showReport = false;
  List<totalProduction> productionItems = [];  // List to store items
  double totalAmount = 0.0;  // Total amount variable
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
  }


  Future<void> _generateReport() async {
    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both dates')),
      );
      return;
    }

    if (fromDate!.isAfter(toDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('From date must be before To date')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      showReport = false;
    });

    try {
      // Updated API call with named parameters
      final items = await _apiService.getSoldItems(
          startDate: fromDate!,
          endDate: toDate!,
          location: datasource!
      );

      // Calculate total amount safely
      double total = 0.0;
      for (var items in items) {
        total += items.totalQuantity * items.averageTotal;
      }

      setState(() {
        productionItems = items;
        totalAmount = total;
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

  Widget _buildReportTable(List<totalProduction> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Item Id')),
            DataColumn(label: Text('Item Name')),
            DataColumn(label: Text('Issue Quantity')),
            DataColumn(label: Text('Issue Total')),
          ],
          rows: items.map((item) {
            return DataRow(cells: [
              DataCell(Text(item.itemId.toString())),
              DataCell(Text(item.itemName)),
              DataCell(Text(item.totalQuantity.toStringAsFixed(3))),
              DataCell(Text(NumberFormat('#,##0.00').format(item.averageTotal * item.totalQuantity))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReportView() {

    if (!showReport || productionItems.isEmpty) {
      return const Center(
        child: Text('No data available for the selected period'),
      );
    }
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  'Item Wise Production Issue Report',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'From ${DateFormat('MM/dd/yyyy').format(fromDate!)} To ${DateFormat('MM/dd/yyyy').format(toDate!)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _buildReportTable(productionItems),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total Amount($currency): ${NumberFormat('#,##0.00').format(totalAmount)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    if (!showReport || productionItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to generate PDF')),
      );
      return;
    }

    try {
      setState(() => isLoading = true);
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.poppinsRegular();
      final boldFont = await PdfGoogleFonts.poppinsBold();
      final imageBytes = await rootBundle.load('assets/images/skynet_pro.jpg');
      final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

      // Split items into chunks for pagination
      const int itemsPerPage = 35; // Adjust this number based on your needs
      final chunks = <List<totalProduction>>[];
      for (var i = 0; i < productionItems.length; i += itemsPerPage) {
        chunks.add(
          productionItems.skip(i).take(itemsPerPage).toList(),
        );
      }

      // Create pages
      for (var i = 0; i < chunks.length; i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.copyWith(
              marginLeft: 10.0, // Reduced left margin
              marginRight: 10.0, // Reduced right margin
              marginTop: 10.0, // Reduced top margin
              marginBottom: 10.0, // Reduced bottom margin
            ),
            build: (pw.Context context) {
              return pw.Container(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header
                    if (i == 0) ...[
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.Image(image, width: 100),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Center(
                        child: pw.Text(
                          'Item Wise Production Issue Report',
                          style: pw.TextStyle(font: boldFont, fontSize: 14),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'From: ${DateFormat('MM/dd/yyyy').format(fromDate!)}',
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                          pw.Text(
                            'To: ${DateFormat('MM/dd/yyyy').format(toDate!)}',
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                    ],
                    // Table
                    pw.Expanded(
                      child: pw.Table.fromTextArray(
                        headers: ['Item Id', 'Item Name', 'Issue Quantity', 'Issue Total($currency)'],
                        data: chunks[i].map((item) => [
                          item.itemId,
                          item.itemName,
                          item.totalQuantity.toStringAsFixed(3),
                          NumberFormat('#,##0.00').format(item.averageTotal * item.totalQuantity),
                        ]).toList(),
                        headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),  // Reduced font size
                        cellStyle: pw.TextStyle(font: font, fontSize: 8),  // Reduced font size
                        headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                        cellHeight: 20,  // Reduced cell height
                        columnWidths: {
                          0: const pw.FlexColumnWidth(1),  // Item ID
                          1: const pw.FlexColumnWidth(3),  // Item Name
                          2: const pw.FlexColumnWidth(2),  // Quantity
                          3: const pw.FlexColumnWidth(2),  // Price
                        },
                        cellAlignments: {
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.centerLeft,
                          2: pw.Alignment.centerRight,
                          3: pw.Alignment.centerRight,
                        },
                      ),
                    ),

                    // Footer - only show on last page
                    if (i == chunks.length - 1) ...[
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Total Amount($currency): ${NumberFormat("#,##0.00").format(totalAmount)}',
                            style: pw.TextStyle(font: boldFont, fontSize: 10),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'SKYNET Pro Powered By Ceylon Innovation',
                            style: pw.TextStyle(font: font, fontSize: 8),
                          ),
                          pw.Text(
                            'Report Generated at ${DateFormat('MM/dd/yyyy - h:mm a').format(DateTime.now())}',
                            style: pw.TextStyle(font: font, fontSize: 8),
                          ),
                        ],
                      ),
                    ],
                    // Page number
                    pw.Positioned(
                      bottom: 5,
                      right: 5,
                      child: pw.Text(
                        'Page ${i + 1} of ${chunks.length}',
                        style: pw.TextStyle(font: font, fontSize: 8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

      if (kIsWeb) {
        // Check if running on mobile browser
        final userAgent = html.window.navigator.userAgent.toLowerCase();
        final isMobile = userAgent.contains('mobile') ||
            userAgent.contains('android') ||
            userAgent.contains('iphone');

        if (isMobile) {
          // For mobile web, generate and trigger download
          final bytes = await pdf.save();
          final blob = html.Blob([bytes], 'application/pdf');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement()
            ..href = url
            ..style.display = 'none'
            ..download = 'Item_Wise_Production_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
          html.document.body!.children.add(anchor);
          anchor.click();
          html.document.body!.children.remove(anchor);
          html.Url.revokeObjectUrl(url);
        } else {
          // For desktop web, use Printing package
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save(),
            name: 'Item_Wise_Production_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
          );
        }
      } else {
        // For native platforms, use Printing package
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Item_Wise_Production_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
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
                    'Item Wise Production Report',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
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
              physics: const AlwaysScrollableScrollPhysics(),
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
                                        ? DateFormat('yyyy-MM-dd')
                                        .format(fromDate!)
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
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _generatePdf,
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildReportView(),
                  ],
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
