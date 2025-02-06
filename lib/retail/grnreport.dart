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

class Purchase {
  final DateTime date;
  final int grnId;
  final String invoiceNo;
  final String supplier;
  final int itemId;
  final String itemName;
  final double purPrice;
  final double qty;
  final double subtotal;
  final double discount;
  final double total;
  final double cash;
  final double card;
  final double cheque;
  final double credit;

  Purchase({
    required this.date,
    required this.grnId,
    required this.invoiceNo,
    required this.supplier,
    required this.itemId,
    required this.itemName,
    required this.purPrice,
    required this.qty,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.cash,
    required this.card,
    required this.cheque,
    required this.credit,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      date: DateTime.parse(json['date'].toString()),
      grnId: json['grnId'] as int,
      invoiceNo: json['invoiceno'] as String,
      supplier: json['supplier'] as String,
      itemId: json['itemId'] as int,
      itemName: json['itemname'] as String,
      purPrice: (json['purprice'] as num).toDouble(),
      qty: (json['qty'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      cash: (json['cash'] as num).toDouble(),
      card: (json['card'] as num).toDouble(),
      cheque: (json['cheque'] as num).toDouble(),
      credit: (json['credit'] as num).toDouble(),
    );
  }
}

class PurchaseReport  extends StatefulWidget {
  // Renamed to SoldItemsReport
  const PurchaseReport ({super.key});

  @override
  State<PurchaseReport> createState() => _PurchaseReportState();
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

  Future<List<Purchase>> getPurchases({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParameters = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'connectionString': datasource,
      };

      final uri = Uri.parse('$baseUrl/purchase')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> purchasesJson = json.decode(response.body);
        return purchasesJson
            .map((json) => Purchase.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load purchases: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load purchases: $e');
    }
  }
}

class _PurchaseReportState extends State<PurchaseReport> {
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool showReport = false;
  List<Purchase> purchases = [];
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
      final items = await _apiService.getPurchases(
        startDate: fromDate!,
        endDate: toDate!,
      );

      double total = items.fold(0, (sum, item) => sum + item.total);

      setState(() {
        purchases = items;
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

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  Widget _buildReportTable(List<Purchase> items) {
    // Group items by GRNId
    Map<int, List<Purchase>> groupedItems = {};
    for (var item in items) {
      if (!groupedItems.containsKey(item.grnId)) {
        groupedItems[item.grnId] = [];
      }
      groupedItems[item.grnId]!.add(item);
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
                  _buildHeaderCell('Item ID', width: 80),
                  _buildHeaderCell('Item Name', width: 200),
                  _buildHeaderCell('Unit Price($currency)', width: 120),
                  _buildHeaderCell('Quantity', width: 100),
                  _buildHeaderCell('Subtotal($currency)', width: 120),
                ],
              ),
            ),

            ...groupedItems.entries.map((entry) {
              final grnId = entry.key;
              final groupItems = entry.value;
              final firstItem = groupItems.first;
              final groupTotal = groupItems.fold<double>(
                0,
                    (sum, item) => sum + item.total,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GRN Header
                  Container(
                    width: 620,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GRN No - $grnId              Supplier - ${firstItem.supplier}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Invoice No: ${firstItem.invoiceNo}                Date: ${DateFormat('yyyy-MM-dd').format(firstItem.date)}',
                        ),
                      ],
                    ),
                  ),

                  // Items
                  ...groupItems.map(
                        (item) => Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          _buildCell('${item.itemId}', width: 80),
                          _buildCell(item.itemName, width: 200),
                          _buildCell(
                            NumberFormat('#,##0.00').format(item.purPrice),
                            width: 120,
                            alignment: Alignment.centerRight,
                          ),
                          _buildCell(
                            NumberFormat('#,##0.000').format(item.qty),
                            width: 100,
                            alignment: Alignment.centerRight,
                          ),
                          _buildCell(
                            NumberFormat('#,##0.00').format(item.subtotal),
                            width: 120,
                            alignment: Alignment.centerRight,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // GRN Total
                  Container(
                    width: 620,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.grey.shade50,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Discount: ${NumberFormat('#,##0.00').format(firstItem.discount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'GRN Total($currency): ${NumberFormat('#,##0.00').format(groupTotal)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 620,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (firstItem.cash > 0)
                          Text('Cash: ${NumberFormat('#,##0.00').format(firstItem.cash)}'),
                        if (firstItem.card > 0)
                          Text('Card: ${NumberFormat('#,##0.00').format(firstItem.card)}'),
                        if (firstItem.cheque > 0)
                          Text('Cheque: ${NumberFormat('#,##0.00').format(firstItem.cheque)}'),
                        if (firstItem.credit > 0)
                          Text('Credit: ${NumberFormat('#,##0.00').format(firstItem.credit)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  'Purchase Report - ${_selectedLocation!.locationName}-${_selectedLocation!.bLocationName}',
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
            child: _buildReportTable(purchases),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total Purchases($currency): ${NumberFormat('#,##0.00').format(totalAmount)}',
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

      // Group items by GRNId
      Map<int, List<Purchase>> groupedItems = {};
      for (var item in purchases) {
        if (!groupedItems.containsKey(item.grnId)) {
          groupedItems[item.grnId] = [];
        }
        groupedItems[item.grnId]!.add(item);
      }

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
                      'Purchase Report - ${_selectedLocation!.locationName}-${_selectedLocation!.bLocationName}',
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
            return pw.Container(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'SKYNET Pro Powered By Ceylon Innovation',
                    style: pw.TextStyle(font: font, fontSize: 8),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(font: font, fontSize: 8),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
                cellStyle: pw.TextStyle(font: font, fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                cellHeight: 20,
                headers: ['Item ID', 'Item Name', 'Unit Price($currency)', 'Quantity', 'Subtotal($currency)'],
                columnWidths: {
                  0: const pw.FixedColumnWidth(50),  // Item ID
                  1: const pw.FixedColumnWidth(150), // Item Name
                  2: const pw.FixedColumnWidth(80),  // Unit Price
                  3: const pw.FixedColumnWidth(60),  // Quantity
                  4: const pw.FixedColumnWidth(80),  // Subtotal
                },
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                }, data: [],
              ),

              ...groupedItems.entries.map((entry) {
                final grnId = entry.key;
                final groupItems = entry.value;
                final firstItem = groupItems.first;
                final groupTotal = groupItems.fold<double>(
                  0,
                      (sum, item) => sum + item.total,
                );

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // GRN Header
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'GRN No - $grnId',
                                style: pw.TextStyle(font: boldFont, fontSize: 9),
                              ),
                              pw.Text(
                                'Supplier - ${firstItem.supplier}',
                                style: pw.TextStyle(font: boldFont, fontSize: 9),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 2), // Small spacing between rows
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Invoice No: ${firstItem.invoiceNo}',
                                style: pw.TextStyle(font: font, fontSize: 8),
                              ),
                              pw.Text(
                                'Date: ${DateFormat('yyyy-MM-dd').format(firstItem.date)}',
                                style: pw.TextStyle(font: font, fontSize: 8),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Items
                    ...groupItems.map((item) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 5), // Added padding
                      height: 20, // Increased fixed height
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center, // Center align content vertically
                        children: [
                          pw.Expanded(
                            flex: 1,
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                              child: pw.Text(
                                '${item.itemId}',
                                style: pw.TextStyle(font: font, fontSize: 9),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                              child: pw.Text(
                                item.itemName,
                                style: pw.TextStyle(font: font, fontSize: 9),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                              child: pw.Text(
                                NumberFormat('#,##0.00').format(item.purPrice),
                                style: pw.TextStyle(font: font, fontSize: 9),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                              child: pw.Text(
                                NumberFormat('#,##0.000').format(item.qty),
                                style: pw.TextStyle(font: font, fontSize: 9),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                              child: pw.Text(
                                NumberFormat('#,##0.00').format(item.subtotal),
                                style: pw.TextStyle(font: font, fontSize: 9),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    // GRN Summary
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Column(
                        children: [
                          // GRN Total and Discount Row
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Discount: ${NumberFormat('#,##0.00').format(firstItem.discount)}',
                                style: pw.TextStyle(font: boldFont, fontSize: 9),
                              ),
                              pw.Text(
                                'GRN Total($currency): ${NumberFormat('#,##0.00').format(groupTotal)}',
                                style: pw.TextStyle(font: boldFont, fontSize: 9),
                              ),
                            ],
                          ),

                          // Payment Details Row (if any payment exists)
                          if (firstItem.cash > 0 || firstItem.card > 0 || firstItem.cheque > 0 || firstItem.credit > 0)
                            pw.Container(
                              padding: const pw.EdgeInsets.only(top: 5),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.end,
                                children: [
                                  pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                                    children: [
                                      if (firstItem.cash > 0)
                                        pw.Text(
                                          'Cash: ${NumberFormat('#,##0.00').format(firstItem.cash)}',
                                          style: pw.TextStyle(font: font, fontSize: 8),
                                        ),
                                      if (firstItem.card > 0)
                                        pw.Text(
                                          'Card: ${NumberFormat('#,##0.00').format(firstItem.card)}',
                                          style: pw.TextStyle(font: font, fontSize: 8),
                                        ),
                                      if (firstItem.cheque > 0)
                                        pw.Text(
                                          'Cheque: ${NumberFormat('#,##0.00').format(firstItem.cheque)}',
                                          style: pw.TextStyle(font: font, fontSize: 8),
                                        ),
                                      if (firstItem.credit > 0)
                                        pw.Text(
                                          'Credit: ${NumberFormat('#,##0.00').format(firstItem.credit)}',
                                          style: pw.TextStyle(font: font, fontSize: 8),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 15),
                  ],
                );
              }).toList(),

              // Grand Total
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  color: PdfColors.grey200,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total Purchases ($currency): ${NumberFormat("#,##0.00").format(totalAmount)}',
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
                'Purchase Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
          html.document.body!.children.add(anchor);
          anchor.click();
          html.document.body!.children.remove(anchor);
          html.Url.revokeObjectUrl(url);
        } else {
          // For desktop web, use Printing package
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save(),
            name:
                'Purchase Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
          );
        }
      } else {
        // For native platforms, use Printing package
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name:
              'Purchase Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
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
                        onPressed: _handleLogout,
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // Spacing between rows
                  // Second row with title
                  Text(
                    'Purchase Report',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
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
