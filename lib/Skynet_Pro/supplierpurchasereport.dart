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

class SupplierPurchase {
  final String supplierName;
  final double totalAmount;

  SupplierPurchase({
    required this.supplierName,
    required this.totalAmount,
  });

  factory SupplierPurchase.fromJson(Map<String, dynamic> json) {
    return SupplierPurchase(
      supplierName: json['supplierName'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }
}

class SupplierPurchaseReport extends StatefulWidget {
  const SupplierPurchaseReport({super.key});

  @override
  State<SupplierPurchaseReport> createState() => _SupplierPurchaseReportState();
}

class ApiService {
  static const String baseUrl = 'http://124.43.70.220:7072/Reports';

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

  Future<List<SupplierPurchase>> getSupplierPurchases({
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

      final uri = Uri.parse('$baseUrl/supplier-purchases')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List<dynamic> purchasesJson = json.decode(response.body);
        return purchasesJson
            .map((json) => SupplierPurchase.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load purchases: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load purchases: $e');
    }
  }
}

class _SupplierPurchaseReportState extends State<SupplierPurchaseReport> {
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool showReport = false;
  List<SupplierPurchase> purchases = [];
  double totalPurchaseAmount = 0.0;
  late final ApiService _apiService;
  List<DatabaseLocation> _locations = [];
  DatabaseLocation? _selectedLocation;
  bool _isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadLocations();
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading locations: $e')),
        );
      }
    }
  }

  Future<void> _generateReport() async {
    if (fromDate == null || toDate == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both dates and a location')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      showReport = false;
    });

    try {
      final items = await _apiService.getSupplierPurchases(
        startDate: fromDate!,
        endDate: toDate!,
        location: _selectedLocation!,
      );

      double total = items.fold(0.0, (sum, item) => sum + item.totalAmount);

      setState(() {
        purchases = items;
        totalPurchaseAmount = total;
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

  Widget _buildReportTable(List<SupplierPurchase> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Supplier Name')),
            DataColumn(label: Text('Total Amount')),
          ],
          rows: items.map((item) {
            return DataRow(cells: [
              DataCell(Text(item.supplierName)),
              DataCell(Text(NumberFormat('#,##0.00').format(item.totalAmount))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _generatePdf() async {
    if (!showReport || purchases.isEmpty) {
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

      const int itemsPerPage = 25;
      final chunks = <List<SupplierPurchase>>[];
      for (var i = 0; i < purchases.length; i += itemsPerPage) {
        chunks.add(purchases.skip(i).take(itemsPerPage).toList());
      }

      for (var i = 0; i < chunks.length; i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Container(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (i == 0) ...[
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [pw.Image(image, width: 100)],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Center(
                        child: pw.Text(
                          '${_selectedLocation!.locationName}-${_selectedLocation!.bLocationName} - Supplier Purchase Report',
                          style: pw.TextStyle(font: boldFont, fontSize: 14),
                        ),
                      ),
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
                    pw.Expanded(
                      child: pw.Table.fromTextArray(
                        headers: ['Supplier Name', 'Total Amount($currency)'],
                        data: chunks[i]
                            .map((item) => [
                                  item.supplierName,
                                  NumberFormat('#,##0.00')
                                      .format(item.totalAmount),
                                ])
                            .toList(),
                        headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
                        cellStyle: pw.TextStyle(font: font, fontSize: 8),
                        headerDecoration:
                            pw.BoxDecoration(color: PdfColors.grey300),
                        cellHeight: 20,
                        columnWidths: {
                          0: const pw.FlexColumnWidth(3),
                          1: const pw.FlexColumnWidth(2),
                        },
                      ),
                    ),
                    if (i == chunks.length - 1) ...[
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Total Purchase ($currency): ${NumberFormat("#,##0.00").format(totalPurchaseAmount)}',
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
        final userAgent = html.window.navigator.userAgent.toLowerCase();
        final isMobile = userAgent.contains('mobile') ||
            userAgent.contains('android') ||
            userAgent.contains('iphone');

        if (isMobile) {
          final bytes = await pdf.save();
          final blob = html.Blob([bytes], 'application/pdf');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement()
            ..href = url
            ..style.display = 'none'
            ..download =
                'Supplier_Purchase_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
          html.document.body!.children.add(anchor);
          anchor.click();
          html.document.body!.children.remove(anchor);
          html.Url.revokeObjectUrl(url);
        } else {
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save(),
            name:
                'Supplier_Purchase_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
          );
        }
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name:
              'Supplier_Purchase_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
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

  Widget _buildReportView() {
    if (!showReport || purchases.isEmpty) {
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
                  '${_selectedLocation!.locationName}-${_selectedLocation!.bLocationName} - Supplier Purchase Report',
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
          _buildReportTable(purchases),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total Purchase ($currency): ${NumberFormat('#,##0.00').format(totalPurchaseAmount)}',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 24),
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
                        onPressed: () async {
                          final loginController = Get.find<LoginController>();
                          await loginController.clearLoginData();
                        },
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Supplier Purchase Summary',
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
            onRefresh: () async {
              if (fromDate != null && toDate != null) {
                await _generateReport();
              }
            },
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
                            onTap: () async {
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
                                          foregroundColor:
                                              const Color(0xFF2A2359),
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => fromDate = picked);
                              }
                            },
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
                            onTap: () async {
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
                                          foregroundColor:
                                              const Color(0xFF2A2359),
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => toDate = picked);
                              }
                            },
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
                                        ? DateFormat('yyyy-MM-dd')
                                            .format(toDate!)
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          if (_isLoadingLocations)
                            const Center(child: CircularProgressIndicator())
                          else
                            DropdownButtonFormField<DatabaseLocation>(
                              value: _selectedLocation,
                              dropdownColor: Colors.white,
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
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
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
                                setState(() => _selectedLocation = newValue);
                              },
                            ),
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
                      icon:
                          const Icon(Icons.picture_as_pdf, color: Colors.white),
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
