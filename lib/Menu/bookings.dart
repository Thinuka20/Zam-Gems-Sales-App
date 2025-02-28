import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genix_reports/pages/billdetails.dart';
import 'package:genix_reports/pages/salessummary.dart';
import 'package:genix_reports/pages/solditemsreport.dart';
import 'package:genix_reports/skynet_pro_backery/production_branchwise.dart';
import 'package:genix_reports/skynet_pro_backery/production_itemwise.dart';
import 'package:genix_reports/skynet_pro_backery/production_total.dart';
import 'package:genix_reports/skynet_pro_hotel/banquetbookings.dart';
import 'package:genix_reports/skynet_pro_hotel/roombookings.dart';
import 'package:genix_reports/widgets/user_activity_wrapper.dart';
import 'package:genix_reports/zam_gems/iteminvoices.dart';
import 'package:genix_reports/zam_gems/solditemsreportZam.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../controllers/login_controller.dart';

class BookingsMenu extends StatelessWidget {
  // Renamed to ReportsMenu
  const BookingsMenu({Key? key}) : super(key: key);

  void _handleLogout() async {
    final loginController = Get.find<LoginController>();
    await loginController.clearLoginData();
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
                    'Bookings',
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
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        Get.to(() =>
                            const CurrentRoomBookings()); // Navigate to SalesReport
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
                                Icons.hotel_rounded,
                                color: Theme.of(context).primaryColor,
                                size: 40,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Rooms',
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
                        const CurrentBanquetBookings()); // Navigate to SalesReport
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
                                Icons.home_work_sharp,
                                color: Theme.of(context).primaryColor,
                                size: 40,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Banquet',
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
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
