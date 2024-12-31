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

class SoldItem {
  final String itemId;
  final String itemName;
  final double quantity;
  final double price;
  final double total;

  SoldItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.total,
  });
}

class SalesReportData {
  final List<SoldItem> items;
  final double totalAmount;
  final DateTime fromDate;
  final DateTime toDate;
  final String locationName;

  SalesReportData({
    required this.items,
    required this.totalAmount,
    required this.fromDate,
    required this.toDate,
    required this.locationName,
  });
}

class SoldItemsReport extends StatefulWidget {
  // Renamed to SoldItemsReport
  const SoldItemsReport({super.key});

  @override
  State<SoldItemsReport> createState() => _SoldItemsReportState();
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
}

class _SoldItemsReportState extends State<SoldItemsReport> {
  late SalesReportData salesData;

  Widget _buildSummaryRow(String label, double value, {bool isTotal = false}) {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '${formatter.format(value)} $currency',
            style: GoogleFonts.poppins(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;
  bool showReport = false;

  SalesReportData _getSampleData() {
    return SalesReportData(
      items: [
        SoldItem(
          itemId: '1',
          itemName: 'Bag 1 - 1000',
          quantity: 50.000,
          price: 20.00,
          total: 1000.00,
        ),
        SoldItem(
          itemId: '7',
          itemName: 'Lunch pack budget',
          quantity: 18.000,
          price: 360.00,
          total: 6480.00,
        ),
        SoldItem(
          itemId: '14',
          itemName: 'Potion Chicken (K)',
          quantity: 1.000,
          price: 350.00,
          total: 350.00,
        ),
        // Add more sample items here
      ],
      totalAmount: 543473.80,
      fromDate: DateTime(2024, 12, 30),
      toDate: DateTime(2024, 12, 31),
      locationName: 'Green Hut-Kollupitiya',
    );
  }

  List<DatabaseLocation> _locations = [];
  DatabaseLocation? _selectedLocation;
  bool _isLoadingLocations = true;
  late final ApiService _apiService;

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
      // Add your report generation logic here using _selectedLocation
      setState(() {
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

  Widget _buildReportTable(List<SoldItem> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Item ID')),
            DataColumn(label: Text('Item Name')),
            DataColumn(label: Text('Quantity')),
            DataColumn(label: Text('Price')),
            DataColumn(label: Text('Total')),
          ],
          rows: items.map((item) {
            return DataRow(cells: [
              DataCell(Text(item.itemId)),
              DataCell(Text(item.itemName)),
              DataCell(Text(item.quantity.toStringAsFixed(3))),
              DataCell(Text(item.price.toStringAsFixed(2))),
              DataCell(Text(item.total.toStringAsFixed(2))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReportView() {
    final data = _getSampleData();
    final formatter = NumberFormat("#,##0.00", "en_US");

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
                  'Sold Item Report - ${data.locationName}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'From ${DateFormat('MM/dd/yyyy').format(data.fromDate)} To ${DateFormat('MM/dd/yyyy').format(data.toDate)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _buildReportTable(data.items),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total Amount: ${formatter.format(data.totalAmount)} $currency',
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
    if (!showReport || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please generate the report first')),
      );
      return;
    }

    try {
      setState(() => isLoading = true);
      final data = _getSampleData();
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.poppinsRegular();
      final boldFont = await PdfGoogleFonts.poppinsBold();
      final imageBytes = await rootBundle.load('assets/images/skynet_pro.jpg');
      final image = pw.MemoryImage(imageBytes.buffer.asUint8List());

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Container(
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            children: [
                              pw.Image(image, width: 120),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          '${_selectedLocation!.locationName}-${_selectedLocation!.bLocationName} Item Sale Report',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 16,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Container(
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'From: ${DateFormat('MM/dd/yyyy').format(fromDate!)}',
                                style: pw.TextStyle(font: font, fontSize: 12),
                              ),
                              pw.Text(
                                'To: ${DateFormat('MM/dd/yyyy').format(toDate!)}',
                                style: pw.TextStyle(font: font, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 7),
                      ],
                    ),
                  ),
                  // Table
                  pw.Table.fromTextArray(
                    headers: ['Item ID', 'Item Name', 'Quantity', 'Price($currency)', 'Total($currency)'],
                    data: data.items.map((item) => [
                      item.itemId,
                      item.itemName,
                      item.quantity.toStringAsFixed(3),
                      item.price.toStringAsFixed(2),
                      item.total.toStringAsFixed(2),
                    ]).toList(),
                    headerStyle: pw.TextStyle(
                      font: boldFont,
                      fontSize: 12,
                    ),
                    cellStyle: pw.TextStyle(
                      font: font,
                      fontSize: 10,
                    ),
                    headerDecoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    cellHeight: 25,
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.centerRight,
                      3: pw.Alignment.centerRight,
                      4: pw.Alignment.centerRight,
                    },
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total Amount($currency): ${NumberFormat("#,##0.00").format(data.totalAmount)}',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'SKYNET Pro Powered By Ceylon Innovation',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        'Report Generated at ${DateFormat('MM/dd/yyyy - h:mm a').format(DateTime.now())}',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Sales_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );
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
                'Sold Items',
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
