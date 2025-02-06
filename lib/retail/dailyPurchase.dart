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

class DatabaseLocation {
  final int id;
  final String databaseName;
  final String locationName;
  final String bLocationName;
  final String dPath;
  final String? details1;
  final String? details2;

  DatabaseLocation({
    required this.id,
    required this.databaseName,
    required this.locationName,
    required this.bLocationName,
    required this.dPath,
    this.details1,
    this.details2,
  });

  factory DatabaseLocation.fromJson(Map<String, dynamic> json) {
    return DatabaseLocation(
      id: json['id'] as int,
      databaseName: json['databaseName'] as String,
      locationName: json['locationName'] as String,
      bLocationName: json['bLocationName'] as String,
      dPath: json['dPath'] as String,
      details1: json['details1'] as String?,
      details2: json['details2'] as String?,
    );
  }
}

class DailyPurchase {
  final String date;
  final double totalPurchase;
  final double totalCash;
  final double totalCard;
  final double totalCheque;
  final double totalCredit;
  final double totalBank;

  DailyPurchase({
    required this.date,
    required this.totalPurchase,
    required this.totalCash,
    required this.totalCard,
    required this.totalCheque,
    required this.totalCredit,
    required this.totalBank,
  });

  factory DailyPurchase.fromJson(Map<String, dynamic> json) {
    return DailyPurchase(
      date: json['date'] as String? ?? 'Unknown Item',
      totalPurchase: (json['totalPurchase'] as num?)?.toDouble() ?? 0.0,
      totalCash: (json['totalCash'] as num?)?.toDouble() ?? 0.0,
      totalCard: (json['totalCard'] as num?)?.toDouble() ?? 0.0,
      totalCheque: (json['totalCheque'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (json['totalCredit'] as num?)?.toDouble() ?? 0.0,
      totalBank: (json['totalBank'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DailyPurchaseReport extends StatefulWidget {
  // Renamed to SoldItemsReport
  const DailyPurchaseReport({super.key});

  @override
  State<DailyPurchaseReport> createState() => _DailyPurchaseReportState();
}

class ApiService {
  static const String baseUrl = 'http://124.43.70.220:7072/Reports';

  ApiService();

  Future<List<DatabaseLocation>> getLocations() async {
    try {
      final queryParameters = {'connectionString': datasource};

      final uri = Uri.parse('$baseUrl/locations')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> locationsJson = json.decode(response.body);
        return locationsJson
            .map((json) => DatabaseLocation.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load locations: $e');
    }
  }

  Future<List<DailyPurchase>> getDailySales({
    required DateTime startDate,
    required DateTime endDate,
    required DatabaseLocation location,
  }) async {
    try {
      final queryParameters = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'connectionString': location.dPath,
      };

      final uri = Uri.parse('$baseUrl/datewisepurchase')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List<dynamic> itemsJson = json.decode(response.body) as List<dynamic>? ?? [];
        return itemsJson
            .map((json) => DailyPurchase.fromJson(json as Map<String, dynamic>))
            .where((item) => item.date != '') // Filter out invalid items
            .toList();
      } else {
        throw Exception('Failed to load sold items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load sold items: $e');
    }
  }
}

class _DailyPurchaseReportState extends State<DailyPurchaseReport> {
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool showReport = false;
  List<DailyPurchase> salesummary = [];  // List to store items
  double totalAmount = 0.0;  // Total amount variable
  late final ApiService _apiService;
  List<DatabaseLocation> _locations = [];
  DatabaseLocation? _selectedLocation;
  bool _isLoadingLocations = true;

  Future<void> _loadLocations() async {
    try {
      setState(() => _isLoadingLocations = true);
      final locations = await _apiService.getLocations();
      setState(() {
        _locations = locations;
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocations = false);
      if (mounted) {
        // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading locations: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadLocations();
  }


  Future<void> _generateReport() async {
    if (fromDate == null || toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both dates')),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
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
      final items = await _apiService.getDailySales(
          startDate: fromDate!,
          endDate: toDate!,
          location: _selectedLocation!
      );

      // Calculate total amount safely
      double total = 0.0;
      for (var item in items) {
        total += item.totalPurchase;
      }

      setState(() {
        salesummary = items;
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

  Widget _buildLocationDropdown() {
    return DropdownButtonFormField<DatabaseLocation>(
      value: _selectedLocation,
      dropdownColor: Colors.white,
      icon: Icon(
        Icons.arrow_drop_down,
        color: Theme.of(context).primaryColor,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
      ),
      items: _locations.map((location) {
        return DropdownMenuItem<DatabaseLocation>(
          value: location,
          child: Text(
            "${location.locationName}-${location.bLocationName}",
            style: GoogleFonts.poppins(
              color: const Color(0xFF2A2359),
            ),
          ),
        );
      }).toList(),
      onChanged: (DatabaseLocation? newValue) {
        setState(() {
          _selectedLocation = newValue;
        });
      },
    );
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

  Widget _buildReportTable(List<DailyPurchase> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Total Purchase')),
            DataColumn(label: Text('Cash')),
            DataColumn(label: Text('Card')),
            DataColumn(label: Text('Cheque')),
            DataColumn(label: Text('Credit')),
            DataColumn(label: Text('Bank')),
          ],
          rows: items.map((item) {
            return DataRow(cells: [
              DataCell(Text(item.date)),
              DataCell(Text(NumberFormat('#,##0.00').format(item.totalPurchase))),
              DataCell(Text(NumberFormat('#,##0.00').format(item.totalCash))),
              DataCell(Text(NumberFormat('#,##0.00').format(item.totalCard))),
              DataCell(Text(NumberFormat('#,##0.00').format(item.totalCheque))),
              DataCell(Text(NumberFormat('#,##0.00').format(item.totalCredit))),
              DataCell(Text(NumberFormat('#,##0.00').format(item.totalBank))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReportView() {

    if (!showReport || salesummary.isEmpty) {
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
                  '${_selectedLocation!.locationName}-${_selectedLocation!.bLocationName} Date Wise Purchase Summary Report',
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
          _buildReportTable(salesummary),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total Purchase($currency): ${NumberFormat('#,##0.00').format(totalAmount)}',
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
    if (!showReport || salesummary.isEmpty) {
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
      final chunks = <List<DailyPurchase>>[];
      for (var i = 0; i < salesummary.length; i += itemsPerPage) {
        chunks.add(
          salesummary.skip(i).take(itemsPerPage).toList(),
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
                          '${_selectedLocation!.locationName}-${_selectedLocation!.bLocationName} Date Wise Purchase Summary Report',
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
                        headers: ['Date', 'Total Purchase ($currency)', 'Cash ($currency)', 'Card ($currency)', 'Cheque ($currency)', 'Credit ($currency)', 'Bank ($currency)'],
                        data: chunks[i].map((item) => [
                          item.date,
                          NumberFormat('#,##0.00').format(item.totalPurchase),
                          NumberFormat('#,##0.00').format(item.totalCash),
                          NumberFormat('#,##0.00').format(item.totalCard),
                          NumberFormat('#,##0.00').format(item.totalCheque),
                          NumberFormat('#,##0.00').format(item.totalCredit),
                          NumberFormat('#,##0.00').format(item.totalBank),
                        ]).toList(),
                        headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),  // Reduced font size
                        cellStyle: pw.TextStyle(font: font, fontSize: 8),  // Reduced font size
                        headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                        cellHeight: 20,  // Reduced cell height
                        columnWidths: {
                          0: const pw.FlexColumnWidth(1),
                          1: const pw.FlexColumnWidth(1),
                          2: const pw.FlexColumnWidth(1),
                          3: const pw.FlexColumnWidth(1),
                          4: const pw.FlexColumnWidth(1),
                          5: const pw.FlexColumnWidth(1),
                          6: const pw.FlexColumnWidth(1),
                        },
                        cellAlignments: {
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.centerRight,
                          2: pw.Alignment.centerRight,
                          3: pw.Alignment.centerRight,
                          4: pw.Alignment.centerRight,
                          5: pw.Alignment.centerRight,
                          6: pw.Alignment.centerRight,
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
                            'Total Purchase ($currency): ${NumberFormat("#,##0.00").format(totalAmount)}',
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
            ..download = 'DateWise_Purchase_Summary_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
          html.document.body!.children.add(anchor);
          anchor.click();
          html.document.body!.children.remove(anchor);
          html.Url.revokeObjectUrl(url);
        } else {
          // For desktop web, use Printing package
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save(),
            name: 'DateWise_Purchase_Summary_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
          );
        }
      } else {
        // For native platforms, use Printing package
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'DateWise_Purchase_Summary_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
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
                    'Date Wise Purchase Summary',
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
                  const SizedBox(height: 16),
                  // Add Location Dropdown
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildLocationDropdown(),
                        ],
                      ),
                    ),
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
