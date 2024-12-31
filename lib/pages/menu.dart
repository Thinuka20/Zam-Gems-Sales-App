import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genix_reports/pages/billdetails.dart';
import 'package:genix_reports/pages/datewise.dart';
import 'package:genix_reports/pages/dashboard.dart';
import 'package:genix_reports/pages/reports.dart';
import 'package:genix_reports/pages/salesreport.dart';
import 'package:genix_reports/pages/salesreport2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';


class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

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
          toolbarHeight: 80,
          actions: [
            // Add logout button
            IconButton(
              icon: const Icon(
                Icons.power_settings_new,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _handleLogout,
              tooltip: 'Logout', // Add tooltip for better UX
            ),
            const SizedBox(width: 16),
          ],
          flexibleSpace: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Main Menu', // or 'Sales Report' for sales page
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 33,
                ),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  Get.to(() => POSDashboard());
                },
                child: Card(
                  color: Colors.white,
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Centers horizontally
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Centers vertically
                      children: [
                        Icon(
                          Icons.dashboard_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Dashboard',
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
                  Get.to(() => const Billdetails());
                },
                child: Card(
                  color: Colors.white,
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Centers horizontally
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Centers vertically
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Bill Details',
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
                  Get.to(() => const Datewise());
                },
                child: Card(
                  color: Colors.white,
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Centers horizontally
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Centers vertically
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
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
              InkWell(
                onTap: () {
                  final loginController = Get.find<LoginController>();
                  final specialType = loginController.specialType;

                  if(specialType == "GEM"){
                    Get.to(() => const SalesReportPage());
                  }else {
                    Get.to(() => const SalesReportPage2());
                  }
                },
                child: Card(
                  color: Colors.white,
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Centers horizontally
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Centers vertically
                      children: [
                        Icon(
                          Icons.location_on_rounded,
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
              GetBuilder<LoginController>(
                builder: (controller) {
                  if (controller.specialType != "GEM") {
                    return Column(
                      children: [
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            Get.to(() => const ReportsMenu());
                          },
                          child: Card(
                            color: Colors.white,
                            child: Container(
                              height: 80,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bar_chart_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Reports',
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
                      ],
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
              const SizedBox(width: 25),
            ],
          ),
        ),
      ),
    );
  }
}
