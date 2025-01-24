import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genix_reports/pages/billdetails.dart';
import 'package:genix_reports/pages/salessummary.dart';
import 'package:genix_reports/pages/solditemsreport.dart';
import 'package:genix_reports/retail/dailyPurchase.dart';
import 'package:genix_reports/retail/dailysales.dart';
import 'package:genix_reports/retail/detailedExpenses.dart';
import 'package:genix_reports/retail/expensesSummary.dart';
import 'package:genix_reports/retail/gpreport.dart';
import 'package:genix_reports/retail/grnreport.dart';
import 'package:genix_reports/retail/salesreport3.dart';
import 'package:genix_reports/retail/salessummaryretail.dart';
import 'package:genix_reports/zam_gems/iteminvoices.dart';
import 'package:genix_reports/zam_gems/solditemsreportZam.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class ReportsMenu extends StatelessWidget {
  // Renamed to ReportsMenu
  const ReportsMenu({Key? key}) : super(key: key);

  void _handleLogout() async {
    final loginController = Get.find<LoginController>();
    await loginController.clearLoginData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                  'Reports',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GetBuilder<LoginController>(
                builder: (controller) {
                  if (controller.specialType == "GEM") {
                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Get.to(() =>
                                const SoldItemsReportZam()); // Navigate to SalesReport
                          },
                          child: Card(
                            color: Colors.white,
                            child: Container(
                              height: 80,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Sold Items',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  } else {
                    return Column(
                      children: [],
                    );
                  }
                },
              ),
              GetBuilder<LoginController>(
                builder: (controller) {
                  if (controller.specialType != "GEM") {
                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Get.to(() =>
                                const SoldItemsReport()); // Navigate to SalesReport
                          },
                          child: Card(
                            color: Colors.white,
                            child: Container(
                              height: 80,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Sold Items',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  } else {
                    return Column(
                      children: [],
                    );
                  }
                },
              ),
              GetBuilder<LoginController>(
                builder: (controller) {
                  if (controller.specialType != "Retail") {
                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Get.to(() =>
                                const SaleSummaryReport()); // Navigate to SoldItemsReport
                          },
                          child: Card(
                            color: Colors.white,
                            child: Container(
                              height: 80,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Sales Summary',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  } else {
                    return Column(
                      children: [],
                    );
                  }
                },
              ),
              GetBuilder<LoginController>(
                builder: (controller) {
                  if (controller.specialType == "Retail") {
                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Get.to(() =>
                            const SaleSummaryRetail()); // Navigate to SoldItemsReport
                          },
                          child: Card(
                            color: Colors.white,
                            child: Container(
                              height: 80,
                              padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Sales Summary',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            Get.to(() =>
                            const DailysalesReport()); // Navigate to SoldItemsReport
                          },
                          child: Card(
                            color: Colors.white,
                            child: Container(
                              height: 80,
                              padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Date Wise Sales',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  } else {
                    return Column(
                      children: [],
                    );
                  }
                },
              ),
              GetBuilder<LoginController>(
                builder: (controller) {
                  if (controller.specialType == "GEM") {
                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Get.to(() =>
                                const SoldItemsZam()); // Navigate to SalesReport
                          },
                          child: Card(
                            color: Colors.white,
                            child: Container(
                              height: 80,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Item Invoices',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  } else {
                    return Column(
                      children: [],
                    );
                  }
                },
              ),
              GetBuilder<LoginController>(
                builder: (controller) {
                  if (controller.specialType == "Retail") {
                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Get.to(() => const SalesReportPage3());
                          },
                          child: Card(
                            color: Colors.white,
                            child: Container(
                              height: 80,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .center, // Centers horizontally
                                crossAxisAlignment: CrossAxisAlignment
                                    .center, // Centers vertically
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Location Wise Sales',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            Get.to(() =>
                                const ExpenseSummary()); // Navigate to SalesReport
                          },
                          child: Card(
                            color: Colors.white,
                            child: Container(
                              height: 80,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Expenses Summary',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            Get.to(() =>
                                const DetailedExpenses()); // Navigate to SalesReport
                          },
                          child: Card(
                            color: Colors.white,
                            child: Container(
                              height: 80,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Detailed Expenses',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            Get.to(() =>
                                const PurchaseReport()); // Navigate to SalesReport
                          },
                          child: Card(
                            color: Colors.white,
                            child: Container(
                              height: 80,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Purchase Report',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            Get.to(() =>
                            const DailyPurchaseReport()); // Navigate to SalesReport
                          },
                          child: Card(
                            color: Colors.white,
                            child: Container(
                              height: 80,
                              padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Date Wise Purchase',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            Get.to(() =>
                                const GPReport()); // Navigate to SalesReport
                          },
                          child: Card(
                            color: Colors.white,
                            child: Container(
                              height: 80,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'GP Report',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  } else {
                    return Column(
                      children: [],
                    );
                  }
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
