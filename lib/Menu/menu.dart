import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genix_reports/Menu/bookings.dart';
import 'package:genix_reports/pages/billdetails.dart';
import 'package:genix_reports/pages/datewise.dart';
import 'package:genix_reports/pages/dashboard.dart';
import 'package:genix_reports/Menu/production.dart';
import 'package:genix_reports/Menu/reports.dart';
import 'package:genix_reports/pages/salesreport.dart';
import 'package:genix_reports/Skynet_Pro/salesreport2.dart';
import 'package:genix_reports/retail/salesreport3.dart';
import 'package:genix_reports/skynet_pro_hotel/roombookings.dart';
import 'package:genix_reports/skynet_pro_hotel/rooms.dart';
import 'package:genix_reports/skynet_pro_hotel/roomupdate.dart';
import 'package:genix_reports/widgets/user_activity_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../pages/items.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

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
          body: SingleChildScrollView(
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
                GetBuilder<LoginController>(
                  builder: (controller) {
                    if (controller.specialType != "Retail" && controller.specialType != "Retail-Pro") {
                      return Column(
                        children: [
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () {
                              final loginController = Get.find<LoginController>();
                              final specialType = loginController.specialType;

                              if (specialType == "GEM") {
                                Get.to(() => const SalesReportPage());
                              } else {
                                Get.to(() => const SalesReportPage2());
                              }
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
                        ],
                      );
                    } else {
                      return Column(
                        children: [],
                      );
                    }
                  },
                ),
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
                const SizedBox(height: 10),
                GetBuilder<LoginController>(
                  builder: (controller) {
                    if (controller.specialType != "GEM") {
                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Get.to(() => const items());
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
                                      Icons.shopping_cart,
                                      color: Theme.of(context).primaryColor,
                                      size: 40,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Audit Items',
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
                    if (controller.specialType == "SKYNET Pro-Bakery") {
                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Get.to(() => const ProductionMenu());
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
                                      Icons.factory,
                                      color: Theme.of(context).primaryColor,
                                      size: 40,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Production',
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
                    if (controller.specialType == "SKYNET Pro-Hotel") {
                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Get.to(() => const BookingsMenu());
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
                                      Icons.bookmark_added_rounded,
                                      color: Theme.of(context).primaryColor,
                                      size: 40,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Bookings',
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
                              Get.to(() => const RoomDetailsPage());
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
                                      Icons.bedroom_parent_outlined,
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
      ),
    );
  }
}
