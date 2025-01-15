import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genix_reports/zam_gems/invoice.dart';
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

class SalesReport {
  final int saleId;
  final String customerName;
  final double dueAmount;
  final double totalPaid;
  final double balance;
  final double totalCashReceived;
  final double totalCardPayment;
  final double totalChequeAmountReceived;
  final double totalCreditGiven;
  final double totalAdvance;
  final double totalBank;
  final String billX;

  SalesReport({
    required this.saleId,
    required this.customerName,
    required this.dueAmount,
    required this.totalPaid,
    required this.balance,
    required this.totalCashReceived,
    required this.totalCardPayment,
    required this.totalChequeAmountReceived,
    required this.totalCreditGiven,
    required this.totalAdvance,
    required this.totalBank,
    required this.billX,
  });

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    return SalesReport(
      saleId: json['saleId'] as int,
      customerName: json['customerName'] as String,
      dueAmount: (json['dueAmount'] as num).toDouble(),
      totalPaid: (json['totalPaid'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      totalCashReceived: (json['totalCashReceived'] as num).toDouble(),
      totalCardPayment: (json['totalCardPayment'] as num).toDouble(),
      totalChequeAmountReceived:
          (json['totalChequeAmountReceived'] as num).toDouble(),
      totalCreditGiven: (json['totalCreditGiven'] as num).toDouble(),
      totalAdvance: (json['totalAdvance'] as num).toDouble(),
      totalBank: (json['totalBank'] as num).toDouble(),
      billX: json['billX'] as String,
    );
  }
}

class SoldItemsZam extends StatefulWidget {
  // Renamed to SoldItemsReport
  const SoldItemsZam({super.key});

  @override
  State<SoldItemsZam> createState() => _SoldItemsZam();
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

  Future<List<SalesReport>> getDailySales({
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

      final uri = Uri.parse('$baseUrl/dailysales')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> salesJson = json.decode(response.body);
        return salesJson.map((json) => SalesReport.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load sales data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load sales data: $e');
    }
  }
}

class _SoldItemsZam extends State<SoldItemsZam> {
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool showReport = false;
  List<SalesReport> reports = [];
  double totalAmount = 0.0;
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
    if (fromDate == null || toDate == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select dates and location')),
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
      final items = await _apiService.getDailySales(
          startDate: fromDate!, endDate: toDate!, location: _selectedLocation!);

      double total = items.fold(0, (sum, item) => sum + item.totalPaid);

      setState(() {
        reports = items;
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

  Widget _buildReportTable(List<SalesReport> reports) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('')),
          DataColumn(label: Text('Sale ID')),
          DataColumn(label: Text('Salesman Name')),
          DataColumn(label: Text('Invoice Amount')),
        ],
        rows: reports.map((report) {
          return DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.receipt_long, size: 20),
                      onPressed: () {
                        Get.to(
                          () => InvoicePdfViewer(),
                          arguments: {
                            'saleId': report.saleId,
                            'outletDataSource': _selectedLocation!.dPath,
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              DataCell(Text(report.billX)),
              DataCell(Text(report.customerName)),
              DataCell(
                Text(
                  '$currency ${NumberFormat('#,##0.00').format(report.totalPaid)}',
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReportView() {
    if (!showReport || reports.isEmpty) {
      return const Center(
        child: Text('No data available for the selected period'),
      );
    }
    final formatter = NumberFormat("#,##0.00", "en_US");
    final totalSales =
        reports.fold(0.0, (sum, report) => sum + report.totalPaid);

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
                  '${_selectedLocation!.locationName}-${_selectedLocation!.bLocationName} Item Sold Report',
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
          _buildReportTable(reports),
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    if (!showReport || reports.isEmpty) {
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

      const itemsPerPage = 20;
      final chunks = <List<SalesReport>>[];
      for (var i = 0; i < reports.length; i += itemsPerPage) {
        chunks.add(reports.skip(i).take(itemsPerPage).toList());
      }

      for (var i = 0; i < chunks.length; i++) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            build: (context) {
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
                      pw.SizedBox(height: 10),
                      pw.Center(
                        child: pw.Text(
                          'Daily Sales Report',
                          style: pw.TextStyle(font: boldFont, fontSize: 16),
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
                      pw.SizedBox(height: 20),
                    ],
                    pw.Expanded(
                      child: pw.Table.fromTextArray(
                        headers: [
                          'Sale ID',
                          'Salesman',
                          'Invoice Amount',
                          'Cash',
                          'Card',
                          'Cheque',
                          'Credit',
                          'Advance',
                          'Bank'
                        ],
                        data: chunks[i]
                            .map((report) => [
                                  report.billX,
                                  report.customerName,
                                  '$currency ${NumberFormat('#,##0.00').format(report.totalPaid)}',
                                  '$currency ${NumberFormat('#,##0.00').format(report.totalCashReceived)}',
                                  '$currency ${NumberFormat('#,##0.00').format(report.totalCardPayment)}',
                                  '$currency ${NumberFormat('#,##0.00').format(report.totalChequeAmountReceived)}',
                                  '$currency ${NumberFormat('#,##0.00').format(report.totalCreditGiven)}',
                                  '$currency ${NumberFormat('#,##0.00').format(report.totalAdvance)}',
                                  '$currency ${NumberFormat('#,##0.00').format(report.totalBank)}'
                                ])
                            .toList(),
                        headerStyle: pw.TextStyle(font: boldFont, fontSize: 8),
                        cellStyle: pw.TextStyle(font: font, fontSize: 8),
                        cellAlignment: pw.Alignment.centerRight,
                        cellAlignments: {
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.centerLeft
                        },
                      ),
                    ),
                    pw.Text(
                      'Page ${i + 1} of ${chunks.length}',
                      style: pw.TextStyle(font: font, fontSize: 8),
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
            ..download =
                'Items_Sale_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
          html.document.body!.children.add(anchor);
          anchor.click();
          html.document.body!.children.remove(anchor);
          html.Url.revokeObjectUrl(url);
        } else {
          // For desktop web, use Printing package
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save(),
            name:
                'Items_Sale_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
          );
        }
      } else {
        // For native platforms, use Printing package
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Sales_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      print('PDF Generation Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    } finally {
      setState(() => isLoading = false);
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
            IconButton(
              icon: const Icon(
                Icons.power_settings_new,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _handleLogout,
              tooltip: 'Logout',
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
                'Item Invoices',
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
    );
  }
}
