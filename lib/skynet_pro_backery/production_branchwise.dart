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

class productionItem {
  final int productionId;
  final int productionTransId;
  final String itemName;
  final double quantity;
  final double retailPrice;
  final String transferDetails;
  final String toShop;
  final int itemId;

  productionItem({
    required this.productionId,
    required this.productionTransId,
    required this.itemName,
    required this.quantity,
    required this.retailPrice,
    required this.transferDetails,
    required this.toShop,
    required this.itemId,
  });

  factory productionItem.fromJson(Map<String, dynamic> json) {
    return productionItem(
      productionId: json['productionId'] as int? ?? 0,
      productionTransId: json['productionTransId'] as int? ?? 0,
      itemName: json['itemName'] as String? ?? 'Unknown Item',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      retailPrice: (json['retailPrice'] as num?)?.toDouble() ?? 0.0,
      transferDetails: json['transferDetails'] as String? ?? 'Unknown',
      toShop: json['toShop'] as String? ?? 'Unknown',
      itemId: json['itemId'] as int? ?? 0,
    );
  }
}

class productionBranch extends StatefulWidget {
  // Renamed to SoldItemsReport
  const productionBranch({super.key});

  @override
  State<productionBranch> createState() => _productionBranchState();
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

  Future<List<productionItem>> getProductionItems({
    required DateTime startDate,
    required DateTime endDate,
    required DatabaseLocation location,
  }) async {
    try {
      final queryParameters = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'outlet': location.bLocationName,
        'connectionString': datasource,
      };

      final uri = Uri.parse('$baseUrl/transferreport-branch')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List<dynamic> itemsJson =
            json.decode(response.body) as List<dynamic>? ?? [];
        return itemsJson
            .map(
                (json) => productionItem.fromJson(json as Map<String, dynamic>))
            .where((totalProduction) =>
                totalProduction.productionId != 0) // Filter out invalid items
            .toList();
      } else {
        throw Exception('Failed to load sold items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load sold items: $e');
    }
  }
}

class _productionBranchState extends State<productionBranch> {
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool showReport = false;
  List<productionItem> productionItems = []; // List to store items
  double totalAmount = 0.0; // Total amount variable
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
      final items = await _apiService.getProductionItems(
          startDate: fromDate!, endDate: toDate!, location: _selectedLocation!);


      // Calculate total amount safely
      double total = 0.0;
      for (var item in items) {
        total += item.retailPrice * item.quantity;
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

  Widget _buildReportTable(List<productionItem> items) {
    // Group items by ProductionId
    Map<int, List<productionItem>> groupedItems = {};
    for (var item in items) {
      if (!groupedItems.containsKey(item.productionId)) {
        groupedItems[item.productionId] = [];
      }
      groupedItems[item.productionId]!.add(item);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade100,
              ),
              child: Row(
                children: [
                  _buildHeaderCell('Receipt No', width: 150),
                  _buildHeaderCell('Sale Type', width: 250),
                  _buildHeaderCell('Price($currency)',
                      width: 150, alignment: Alignment.centerRight),
                  _buildHeaderCell('QTY',
                      width: 150, alignment: Alignment.centerRight),
                  _buildHeaderCell('Total($currency)',
                      width: 150, alignment: Alignment.centerRight),
                ],
              ),
            ),

            // Production groups
            ...groupedItems.entries.map((entry) {
              final productionId = entry.key;
              final groupItems = entry.value;
              final firstItem = groupItems.first;
              final groupTotal = groupItems.fold<double>(
                0,
                (sum, item) => sum + (item.quantity * item.retailPrice),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Production header
                  Container(
                    width: 850, // Total width of all columns
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.grey.shade50,
                    ),
                    child: Text(
                      'Production ID $productionId          From ${firstItem.transferDetails}           To ${firstItem.toShop}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),

                  // Items
                  ...groupItems
                      .map((item) => Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                _buildCell('ItemID ${item.itemId}', width: 150),
                                _buildCell(item.itemName, width: 250),
                                _buildCell(
                                  NumberFormat('#,##0.00')
                                      .format(item.retailPrice),
                                  width: 150,
                                  alignment: Alignment.centerRight,
                                ),
                                _buildCell(
                                  item.quantity.toStringAsFixed(3),
                                  width: 150,
                                  alignment: Alignment.centerRight,
                                ),
                                _buildCell(
                                  NumberFormat('#,##0.00')
                                      .format(item.retailPrice * item.quantity),
                                  width: 150,
                                  alignment: Alignment.centerRight,
                                ),
                              ],
                            ),
                          ))
                      .toList(),

                  // Production total
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.grey.shade100,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 700, // Width of all columns except last
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.centerRight,
                          child: const Text(
                            'Production Transfer Total(LKR)',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        _buildCell(
                          NumberFormat('#,##0.00').format(groupTotal),
                          width: 150,
                          alignment: Alignment.centerRight,
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(
    String text, {
    required double width,
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      alignment: alignment,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCell(
    String text, {
    required double width,
    Alignment alignment = Alignment.centerLeft,
    bool bold = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      alignment: alignment,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
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
                  'Production Issue Report - ${productionItems[0].toShop}',
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
          Container(
            child: _buildReportTable(productionItems),
          ),
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

      Map<int, List<productionItem>> groupedItems = {};
      for (var item in productionItems) {
        if (!groupedItems.containsKey(item.productionId)) {
          groupedItems[item.productionId] = [];
        }
        groupedItems[item.productionId]!.add(item);
      }

      // Create pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginLeft: 15.0,
            marginRight: 15.0,
            marginTop: 15.0,
            marginBottom: 15.0,
          ),
          header: (context) {
            if (context.pageNumber == 1) {
              return pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Image(image, width: 100),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Center(
                    child: pw.Text(
                      'Production Issue Report - ${productionItems[0].toShop}',
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
              );
            }
            return pw.Container();
          },
          footer: (context) {
            List<pw.Widget> footerWidgets = [
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Page ${context.pageNumber} of ${context.pagesCount}',
                      style: pw.TextStyle(font: font, fontSize: 8),
                    ),
                  ],
                ),
              ),
            ];

            if (context.pageNumber == context.pagesCount) {
              footerWidgets.insert(
                0,
                pw.Container(
                  padding: const pw.EdgeInsets.only(left: 10, right: 10),
                  child: pw.Row(
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
                ),
              );
            }

            return pw.Column(
              children: footerWidgets,
            );
          },
          build: (pw.Context context) {
            return [
              ...groupedItems.entries.map((entry) {
                final productionId = entry.key;
                final groupItems = entry.value;
                final firstItem = groupItems.first;
                final groupTotal = groupItems.fold<double>(
                  0,
                  (sum, item) => sum + (item.quantity * item.retailPrice),
                );

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Production header
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 11,
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Row(
                                children: [
                                  pw.Expanded(
                                    flex: 3,
                                    child: pw.Text(
                                      'Production ID $productionId',
                                      style: pw.TextStyle(
                                          font: boldFont, fontSize: 9),
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 4,
                                    child: pw.Text(
                                      'From ${firstItem.transferDetails}',
                                      style: pw.TextStyle(
                                          font: boldFont, fontSize: 9),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 4,
                                    child: pw.Text(
                                      'To ${firstItem.toShop}',
                                      style: pw.TextStyle(
                                          font: boldFont, fontSize: 9),
                                      textAlign: pw.TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table header
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        color: PdfColors.grey200,
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                              flex: 2,
                              child: pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text('Receipt No',
                                      style: pw.TextStyle(
                                          font: boldFont, fontSize: 8)))),
                          pw.Expanded(
                              flex: 3,
                              child: pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text('Sale Type',
                                      style: pw.TextStyle(
                                          font: boldFont, fontSize: 8)))),
                          pw.Expanded(
                              flex: 2,
                              child: pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text('Price($currency)',
                                      style: pw.TextStyle(
                                          font: boldFont, fontSize: 8),
                                      textAlign: pw.TextAlign.right))),
                          pw.Expanded(
                              flex: 2,
                              child: pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text('QTY',
                                      style: pw.TextStyle(
                                          font: boldFont, fontSize: 8),
                                      textAlign: pw.TextAlign.right))),
                          pw.Expanded(
                              flex: 2,
                              child: pw.Padding(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text('Total($currency)',
                                      style: pw.TextStyle(
                                          font: boldFont, fontSize: 8),
                                      textAlign: pw.TextAlign.right))),
                        ],
                      ),
                    ),

                    // Items
                    ...groupItems.map((item) => pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                  flex: 2,
                                  child: pw.Padding(
                                      padding: const pw.EdgeInsets.all(5),
                                      child: pw.Text('ItemID ${item.itemId}',
                                          style: pw.TextStyle(
                                              font: font, fontSize: 8)))),
                              pw.Expanded(
                                  flex: 3,
                                  child: pw.Padding(
                                      padding: const pw.EdgeInsets.all(5),
                                      child: pw.Text(item.itemName,
                                          style: pw.TextStyle(
                                              font: font, fontSize: 8)))),
                              pw.Expanded(
                                  flex: 2,
                                  child: pw.Padding(
                                      padding: const pw.EdgeInsets.all(5),
                                      child: pw.Text(
                                          NumberFormat('#,##0.00')
                                              .format(item.retailPrice),
                                          style: pw.TextStyle(
                                              font: font, fontSize: 8),
                                          textAlign: pw.TextAlign.right))),
                              pw.Expanded(
                                  flex: 2,
                                  child: pw.Padding(
                                      padding: const pw.EdgeInsets.all(5),
                                      child: pw.Text(
                                          item.quantity.toStringAsFixed(3),
                                          style: pw.TextStyle(
                                              font: font, fontSize: 8),
                                          textAlign: pw.TextAlign.right))),
                              pw.Expanded(
                                  flex: 2,
                                  child: pw.Padding(
                                      padding: const pw.EdgeInsets.all(5),
                                      child: pw.Text(
                                          NumberFormat('#,##0.00').format(
                                              item.retailPrice * item.quantity),
                                          style: pw.TextStyle(
                                              font: font, fontSize: 8),
                                          textAlign: pw.TextAlign.right))),
                            ],
                          ),
                        )),

                    // Production total
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 9,
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                'Production Transfer Total($currency)',
                                style:
                                    pw.TextStyle(font: boldFont, fontSize: 8),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                NumberFormat('#,##0.00').format(groupTotal),
                                style:
                                    pw.TextStyle(font: boldFont, fontSize: 8),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                  ],
                );
              }).toList(),

              // Grand total
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total Amount($currency): ${NumberFormat("#,##0.00").format(totalAmount)}',
                      style: pw.TextStyle(font: boldFont, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

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
                'Production Issue Report - ${productionItems[0].toShop}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
          html.document.body!.children.add(anchor);
          anchor.click();
          html.document.body!.children.remove(anchor);
          html.Url.revokeObjectUrl(url);
        } else {
          // For desktop web, use Printing package
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save(),
            name:
                'Production Issue Report - ${productionItems[0].toShop}_${DateFormat('yyyyMMdd').format(DateTime.now())}',
          );
        }
      } else {
        // For native platforms, use Printing package
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Production Issue Report - ${productionItems[0].toShop}_${DateFormat('yyyyMMdd').format(DateTime.now())}',
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
                    'Branch Wise Production Report',
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
