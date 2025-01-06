import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class CeylonAdaptor {
  final int fieldI1;
  final int itemid;
  final DateTime date;
  final String type;
  final String details;
  final double credit;
  final double debit;
  final double fieldD3;
  final double balance;
  final String itemname;

  CeylonAdaptor({
    required this.fieldI1,
    required this.itemid,
    required this.date,
    required this.type,
    required this.details,
    required this.credit,
    required this.debit,
    required this.fieldD3,
    required this.balance,
    required this.itemname,
  });

  factory CeylonAdaptor.fromJson(Map<String, dynamic> json) {
    return CeylonAdaptor(
      fieldI1: json['fieldI1'] as int? ?? 0,
      itemid: json['itemid'] as int? ?? 0,
      date: DateTime.parse(
          json['date'] as String? ?? DateTime.now().toIso8601String()),
      type: json['type'] as String? ?? '',
      details: json['details'] as String? ?? '',
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
      fieldD3: (json['fieldD3'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      itemname: json['itemname'] as String? ?? '',
    );
  }
}

class items extends StatefulWidget {
  // Renamed to SoldItemsReport
  const items({super.key});

  @override
  State<items> createState() => _ItemsState();
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

  Future<double> getAvailableStock(int itemId, String ldatasource) async {
    try {
      final queryParameters = {
        'itemId': itemId.toString(),
        'connectionString': ldatasource,
      };

      final uri = Uri.parse('$baseUrl/availablestock')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(response.body) as Map<String, dynamic>;
        return (data['quantity'] as num?)?.toDouble() ?? 0.0;
      } else {
        return 0.0; // Return default value on error
      }
    } catch (e) {
      throw Exception('Failed to load available stock: $e');
    }
  }

  Future<List<CeylonAdaptor>> getItemFlow(int itemId, DateTime startDate,
      DateTime endDate, String ldatasource) async {
    try {
      final queryParameters = {
        'itemId': itemId.toString(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'connectionString': ldatasource,
      };

      final uri = Uri.parse('$baseUrl/itemflow')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Decode the response body and handle potential JSON parsing errors
        try {
          final List<dynamic> flowJson =
              json.decode(response.body) as List<dynamic>;
          return flowJson
              .map((json) =>
                  CeylonAdaptor.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (e) {
          print('Error parsing JSON response: $e');
          return [];
        }
      } else {
        print('API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Network Error: $e');
      return [];
    }
  }
}

class _ItemsState extends State<items> {
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool showReport = false;
  final TextEditingController _itemCodeController = TextEditingController();
  double? availableQuantity;
  List<CeylonAdaptor>? itemFlowData;
  List<DatabaseLocation> _locations = [];
  DatabaseLocation? _selectedLocation;
  bool _isLoadingLocations = true;
  late final ApiService _apiService;

  bool isLoadingQuantity = false;
  bool isLoadingFlow = false;
  bool isLoadingPdf = false;

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

  Future<void> _checkAvailableQuantity() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    if (_itemCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item code')),
      );
      return;
    }

    setState(() => isLoadingQuantity = true);
    try {
      final quantity = await _apiService.getAvailableStock(
        int.parse(_itemCodeController.text),
        _selectedLocation!.dPath,
      );
      setState(() {
        availableQuantity = quantity;
        showReport = false;
        itemFlowData = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoadingQuantity = false);
    }
  }

  Future<void> _loadItemFlow() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    if (_itemCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item code')),
      );
      return;
    }

    setState(() => isLoadingFlow = true);
    try {
      final startDate = DateTime(2010, 1, 1);
      final endDate = DateTime.now().add(const Duration(days: 1));

      final data = await _apiService.getItemFlow(
        int.parse(_itemCodeController.text),
        startDate,
        endDate,
        _selectedLocation!.dPath,
      );

      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data found for the selected item')),
        );
      }

      setState(() {
        itemFlowData = data;
        showReport = true;
        availableQuantity = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => isLoadingFlow = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadLocations();
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

  Future<void> _onRefresh() async {
    if (fromDate != null && toDate != null) {
      await _generateReport();
    }
  }

  Future<void> _generateReport() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      showReport = false;
    });
  }

  Future<void> _generatePdf() async {
    if (!showReport || itemFlowData == null || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to generate PDF')),
      );
      return;
    }

    try {
      setState(() => isLoadingPdf = true);

      final pdf = pw.Document();
      final formatter = NumberFormat("#,##0.000", "en_US");

      // Load custom font and image
      final font = await PdfGoogleFonts.poppinsRegular();
      final boldFont = await PdfGoogleFonts.poppinsBold();
      final imageBytes = await rootBundle.load('assets/images/skynet_pro.jpg');
      final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

      // Get item name from the first record
      String itemName =
          itemFlowData!.isNotEmpty ? itemFlowData![0].itemname : '';

      // Split data into chunks for pagination
      const int itemsPerPage = 40;
      final chunks = <List<CeylonAdaptor>>[];
      for (var i = 0; i < itemFlowData!.length; i += itemsPerPage) {
        chunks.add(
          itemFlowData!.skip(i).take(itemsPerPage).toList(),
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
                    // Header - only show on first page
                    if (i == 0) ...[
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.Image(image, width: 100),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        '${_selectedLocation!.locationName}-${_selectedLocation!.bLocationName} Items Flow Report',
                        style: pw.TextStyle(font: boldFont, fontSize: 14),
                      ),
                      pw.Text(
                        'Item ID: ${_itemCodeController.text}',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.Text(
                        'Item Name: $itemName',
                        style: pw.TextStyle(font: font, fontSize: 12),
                      ),
                      pw.SizedBox(height: 20),
                    ],

                    // Table
                    pw.Expanded(
                      child: pw.Table.fromTextArray(
                        headers: [
                          'Transaction Date',
                          'Transaction Type',
                          'Transaction Details',
                          'Credit',
                          'Debit',
                          'Flow Balance'
                        ],
                        data: chunks[i]
                            .map((item) => [
                                  DateFormat('MM/dd/yyyy HH:mm')
                                      .format(item.date),
                                  item.type,
                                  item.details,
                                  formatter.format(item.credit),
                                  formatter.format(item.debit),
                                  formatter.format(item.balance),
                                ])
                            .toList(),
                        headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
                        cellStyle: pw.TextStyle(font: font, fontSize: 9),
                        headerDecoration:
                            pw.BoxDecoration(color: PdfColors.grey300),
                        cellHeight: 25,
                        columnWidths: {
                          0: const pw.FlexColumnWidth(1.9), // Date
                          1: const pw.FlexColumnWidth(2.5), // Type
                          2: const pw.FlexColumnWidth(2.1), // Details
                          3: const pw.FlexColumnWidth(1), // Credit
                          4: const pw.FlexColumnWidth(1), // Debit
                          5: const pw.FlexColumnWidth(1.5), // Balance
                        },
                        cellAlignments: {
                          0: pw.Alignment.centerLeft,
                          1: pw.Alignment.centerLeft,
                          2: pw.Alignment.centerLeft,
                          3: pw.Alignment.centerRight,
                          4: pw.Alignment.centerRight,
                          5: pw.Alignment.centerRight,
                        },
                      ),
                    ),

                    // Footer
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'SKYNET Pro Powered By Ceylon Innovation',
                          style: pw.TextStyle(font: font, fontSize: 8),
                        ),
                        pw.Text(
                          'Page ${i + 1} of ${chunks.length}',
                          style: pw.TextStyle(font: font, fontSize: 8),
                        ),
                      ],
                    ),
                    pw.Text(
                      'Generated: ${DateFormat('MM/dd/yyyy HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(font: font, fontSize: 8),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

      // Handle PDF output based on platform
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
                '${itemName}_Items_Flow_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
          html.document.body!.children.add(anchor);
          anchor.click();
          html.document.body!.children.remove(anchor);
          html.Url.revokeObjectUrl(url);
        } else {
          // For desktop web, use Printing package
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save(),
            name:
                '${itemName}_Items_Flow_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
          );
        }
      } else {
        // For native platforms, use Printing package
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name:
              '${itemName}_Items_Flow_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      print('PDF Generation Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    } finally {
      setState(() => isLoadingPdf = false);
    }
  }

  Widget _buildItemFlowTable() {
    if (itemFlowData == null || itemFlowData!.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final formatter = NumberFormat("#,##0.000", "en_US");

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Transaction Date')),
          DataColumn(label: Text('Transaction Type')),
          DataColumn(label: Text('Transaction Details')),
          DataColumn(label: Text('Credit')),
          DataColumn(label: Text('Debit')),
          DataColumn(label: Text('Flow Balance')),
        ],
        rows: itemFlowData!.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(DateFormat('MM/dd/yyyy HH:mm')
                  .format(item.date))), // Added time
              DataCell(Text(item.type)),
              DataCell(Text(item.details)),
              DataCell(Text(formatter.format(item.credit))),
              DataCell(Text(formatter.format(item.debit))),
              DataCell(Text(formatter.format(item.balance))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReportRow(String description, String value,
      {bool isBold = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                description,
                style: GoogleFonts.poppins(
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
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
              icon: const Icon(Icons.power_settings_new,
                  color: Colors.white, size: 28),
              onPressed: () async {
                final loginController = Get.find<LoginController>();
                await loginController.clearLoginData();
              },
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
                    label: const Text('Back',
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ),
              ),
              Text(
                'Item Details',
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location',
                          style: GoogleFonts.poppins(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      _buildLocationDropdown(),
                      const SizedBox(height: 16),
                      Text('Item Code',
                          style: GoogleFonts.poppins(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _itemCodeController,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Date Range Selection
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          isLoadingQuantity ? null : _checkAvailableQuantity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoadingQuantity
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Item Available Quantity',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoadingFlow ? null : _loadItemFlow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoadingFlow
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Item Flow',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              if (availableQuantity != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Available Quantity',
                            style:
                                GoogleFonts.poppins(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text(
                          availableQuantity!.toStringAsFixed(3),
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (showReport && itemFlowData != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: isLoadingPdf ? null : _generatePdf,
                  icon: isLoadingPdf
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: Text(
                    isLoadingPdf ? 'Generating...' : 'Generate PDF',
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
                const SizedBox(height: 16),
                _buildItemFlowTable(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
