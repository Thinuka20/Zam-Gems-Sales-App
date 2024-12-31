import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genix_reports/pages/billdetails.dart';
import 'package:genix_reports/pages/salessummary.dart';
import 'package:genix_reports/pages/solditemsreport.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class ReportsMenu extends StatelessWidget {  // Renamed to ReportsMenu
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
                'Reports',
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
                  Get.to(() => const SoldItemsReport());  // Navigate to SoldItemsReport
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
              InkWell(
                onTap: () {
                  Get.to(() => const SaleSummaryReport());  // Navigate to SalesReport
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
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}