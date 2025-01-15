import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InvoicePdfViewer extends StatefulWidget {
  InvoicePdfViewer({Key? key}) : super(key: key);

  @override
  State<InvoicePdfViewer> createState() => _InvoicePdfViewerState();
}

class _InvoicePdfViewerState extends State<InvoicePdfViewer> {
  late final dynamic saleId;
  late final dynamic outletDataSource;
  Map<String, dynamic>? invoiceData; // Add this
  bool isLoading = true; // Add this
  pw.MemoryImage? cachedTemplate;


  @override
  void initState() {
    super.initState();
    final Map<String, dynamic> args = Get.arguments;
    saleId = args['saleId'];
    outletDataSource = args['outletDataSource'];
    _fetchInvoiceData();
  }

  Future<void> _fetchInvoiceData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://124.43.70.220:7072/Reports/invoice/$saleId?connectionstring=${outletDataSource}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          invoiceData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load invoice');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Get.snackbar('Error', 'Failed to load invoice data');
    }
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    if (invoiceData == null) {
      throw Exception('Invoice data not loaded');
    }

    final mainDetails = invoiceData!['mainDetails'] is List
        ? invoiceData!['mainDetails']
        : [invoiceData!['mainDetails']];
    final paymentDetails = invoiceData!['paymentDetails'];

    double totalAmount = 0;
    double totalAmountLKR = 0;
    for (var item in mainDetails) {
      double amount = double.parse(item['amount'].toString());
      if (item['billType'] != "LKR") {
        double exchangeRate = double.parse(item['exchangeRate'].toString());
        totalAmount += amount / exchangeRate;
        totalAmountLKR += amount;
      } else {
        totalAmountLKR += amount;
      }
    }

    final pdf = pw.Document(
      theme: pw.ThemeData.base().copyWith(
        defaultTextStyle: pw.TextStyle(fontSize: 10),
      ),
    );

    // Load the template image
    final image = await imageFromAssetBundle('assets/bill_template.png');

    final pageFormat = PdfPageFormat.a4.copyWith(
      marginTop: 0,
      marginBottom: 0,
      marginLeft: 0,
      marginRight: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Stack(
            children: [
              pw.SizedBox(
                width: pageFormat.width,
                height: pageFormat.height,
                child: pw.Image(image, fit: pw.BoxFit.cover),
              ),

              // Branch/Outlet (using first item for header details)
              pw.Positioned(
                right: 40,
                top: 150,
                child: pw.Text(
                  mainDetails[0]['outletName'],
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),

              // Invoice Number
              pw.Positioned(
                left: 370,
                top: 197,
                child: pw.Text(
                  mainDetails[0]['billX'].toString(),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),

              // Date
              pw.Positioned(
                left: 470,
                top: 197,
                child: pw.Text(
                  mainDetails[0]['saleDateDate'].toString().split('T')[0],
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),

              // Salesperson
              pw.Positioned(
                right: 25,
                top: 222,
                child: pw.SizedBox(
                  width: 230,
                  child: pw.Text(
                    "Sale By - ${mainDetails[0]['salesman']}",
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
              ),

              // Customer details
              pw.Positioned(
                left: 116,
                top: 162,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      mainDetails[0]['name'],
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Text(
                      mainDetails[0]['phone'],
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Text(
                      mainDetails[0]['email'],
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Invoice items - Updated to show all items
              pw.Positioned(
                left: 50,
                top: 290,
                child: pw.Column(
                  children: [
                    ...mainDetails.map((item) {
                      double amount = double.parse(item['amount'].toString());
                      double itemTotal;

                      if (item['billType'] != "LKR") {
                        double exchangeRate = double.parse(item['exchangeRate'].toString());
                        itemTotal = amount / exchangeRate;
                      } else {
                        itemTotal = amount;
                      }
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Row(
                          children: [
                            pw.SizedBox(
                                width: 72,
                                child: pw.Text(item['itemID'].toString())),
                            pw.SizedBox(
                                width: 35,
                                child: pw.Text(item['quantity'].toString())),
                            pw.SizedBox(
                                width: 240,
                                child: pw.Text(item['description'])),
                            pw.SizedBox(width: 27),
                            pw.SizedBox(
                                width: 30,
                                child: pw.Text(item['weight'].toString())),
                            pw.SizedBox(width: 10),
                            pw.SizedBox(
                              width: 90,
                              child: pw.Text(
                                '${item['billType']} ${NumberFormat('#,##0.00').format(double.parse(itemTotal.toString()))}',
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              // Total in foreign currency (if applicable)
              if (mainDetails[0]['billType'] != "LKR")
                pw.Positioned(
                  right: 40,
                  top: 627,
                  child: pw.Text(
                    '${mainDetails[0]['billType']} ${NumberFormat('#,##0.00').format(totalAmount)}',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                ),

              // Final total
              pw.Positioned(
                right: 40,
                top: 665,
                child: pw.Text(
                  'LKR ${NumberFormat('#,##0.00').format(totalAmountLKR)}',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),

              // Payments
              pw.Positioned(
                left: 350,
                top: 695,
                child: pw.Column(
                  children: [
                    ...paymentDetails
                        .map<pw.Widget>((payment) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                            width: 300,
                            child: pw.Text(
                              '(${payment['currency']} - ${payment['paymentDetails']}) ${NumberFormat('#,##0.00').format(payment['totalPayingAmount'])}',
                            ),
                          ),
                        ],
                      ),
                    ))
                        .toList(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
          toolbarHeight: 120,
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
                'Invoice',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 33,
                ),
              ),
            ],
          ),
        ),
          body: isLoading
              ? const Center(
            child: CircularProgressIndicator(color: Colors.white),
          )
              : Theme(
            data: ThemeData(
              colorScheme: const ColorScheme.dark(
                surface: Colors.transparent,
                onSurface: Colors.transparent,
              ),
            ),
            child: PdfPreview(
              build: (format) => _generatePdf(format),
              allowPrinting: true,
              allowSharing: true,
              initialPageFormat: PdfPageFormat.a4,
              pdfFileName: "zam_gems_invoice.pdf",
              canChangeOrientation: false,
              canChangePageFormat: false,
              previewPageMargin: const EdgeInsets.all(10),
              actions: const [],
              loadingWidget: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ),
    );
  }
}
