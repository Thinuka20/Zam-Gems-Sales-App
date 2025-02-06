import 'package:flutter/material.dart';
import 'package:genix_reports/pages/datewise.dart';
import 'package:genix_reports/skynet_pro_hotel/roomupdate.dart';
import 'package:genix_reports/widgets/user_activity_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../controllers/login_controller.dart';

final loginController = Get.find<LoginController>();
final datasource = loginController.datasource;

class RoomDetailsFull {
  final int roomId;
  final String roomType;
  final String roomFloor;
  final int maximumOccupancy;
  final String roomStatus;
  final DateTime lastCleanedDate;
  final String cleanedBy;
  final String repairsStatus;
  final String comment;
  final String details1;
  final String details2;

  RoomDetailsFull({
    required this.roomId,
    required this.roomType,
    required this.roomFloor,
    required this.maximumOccupancy,
    required this.roomStatus,
    required this.lastCleanedDate,
    required this.cleanedBy,
    required this.repairsStatus,
    required this.comment,
    required this.details1,
    required this.details2,
  });

  factory RoomDetailsFull.fromJson(Map<String, dynamic> json) {
    return RoomDetailsFull(
      roomId: json['roomID'] as int,
      roomType: json['roomType'] as String,
      roomFloor: json['roomFloor'] as String,
      maximumOccupancy: json['maximumOccupancy'] as int,
      roomStatus: json['roomStatus'] as String,
      lastCleanedDate: DateTime.parse(json['lastCleanedDate'] as String),
      cleanedBy: json['cleanedBy'] as String,
      repairsStatus: json['repairsStatus'] as String,
      comment: json['comment'] as String,
      details1: json['details1'] as String,
      details2: json['details2'] as String,
    );
  }
}

class RoomDetailsPage extends StatefulWidget {
  const RoomDetailsPage({
    Key? key,
  }) : super(key: key);

  @override
  State<RoomDetailsPage> createState() => _RoomDetailsPageState();
}

class _RoomDetailsPageState extends State<RoomDetailsPage> {
  bool isLoading = false;
  List<RoomDetailsFull> rooms = [];
  String? errorMessage;
  TextEditingController searchController = TextEditingController();

  void _handleLogout() async {
    final loginController = Get.find<LoginController>();
    await loginController.clearLoginData();
  }

  @override
  void initState() {
    super.initState();
    _loadRoomDetails();
  }

  Future<void> _loadRoomDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final queryParameters = {
        'connectionString': datasource,
      };

      final uri = Uri.parse('http://124.43.70.220:7072/Reports/getallrooms')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> roomsJson = json.decode(response.body);
        setState(() {
          rooms =
              roomsJson.map((json) => RoomDetailsFull.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load room details: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
      await _loadRoomDetails();
  }

  List<RoomDetailsFull> getFilteredRooms() {
    if (searchController.text.isEmpty) {
      return rooms;
    }

    final query = searchController.text.toLowerCase();
    return rooms.where((room) {
      return room.roomType.toLowerCase().contains(query) ||
          room.roomStatus.toLowerCase().contains(query) ||
          room.roomFloor.toLowerCase().contains(query) ||
          room.cleanedBy.toLowerCase().contains(query) ||
          room.roomId.toString().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredRooms = getFilteredRooms();

    return UserActivityWrapper(
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
                  'Housekeeping Manager',
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
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search rooms...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                        ? Center(child: Text(errorMessage!))
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    dataTableTheme: DataTableThemeData(
                                      horizontalMargin: 24,
                                      columnSpacing: 24,
                                    ),
                                  ),
                                  child: DataTable(
                                    showCheckboxColumn: false, // Remove checkboxes
                                    headingRowColor: MaterialStateProperty.all(
                                      Colors.grey[200],
                                    ),
                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          'Room ID',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Room Type',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Room Floor',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Room Status',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Repairs',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows: filteredRooms.map((room) {
                                      Color? rowColor;
                                      switch (room.roomStatus) {
                                        case 'Ready':
                                          rowColor = Colors.white; // Light red for occupied rooms
                                        case 'Occupied':
                                          rowColor = Colors.blue[100]; // Light green for vacant rooms
                                        case 'Reserved':
                                          rowColor = Colors.green[100]; // Light yellow for rooms being cleaned
                                        case 'Not Available':
                                          rowColor = Colors.redAccent[100]; // Light orange for rooms under maintenance
                                        case 'Closed for Maintenance':
                                          rowColor = Colors.yellow[100];
                                        case 'Under Construction':
                                          rowColor = Colors.red[200];
                                        case 'Other':
                                          rowColor = Colors.white; // Grey for out of order rooms
                                      }
                                      return DataRow(
                                        color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                                          // You can also add different colors for selected/hovered states
                                          if (states.contains(MaterialState.selected)) {
                                            return Theme.of(context).colorScheme.primary.withOpacity(0.08);
                                          }
                                          return rowColor; // Return the color we defined based on status
                                        }),
                                        onSelectChanged: (_) async {
                                          final result = await Get.to(
                                                () => HousekeepingManager(),
                                            arguments: {
                                              'roomData': {
                                                'roomId': room.roomId,
                                                'roomType': room.roomType,
                                                'roomFloor': room.roomFloor,
                                                'roomStatus': room.roomStatus,
                                                'maximumOccupancy': room.maximumOccupancy,
                                                'lastCleanedDate': room.lastCleanedDate,
                                                'cleanedBy': room.cleanedBy,
                                                'repairsStatus': room.repairsStatus,
                                                'comment': room.comment,
                                                'details1': room.details1,
                                                'details2': room.details2,
                                                // Add any additional room properties you need to pass
                                              }
                                            },
                                          );

                                          if (result == 'refresh') {
                                            _onRefresh();  // Call your function here
                                          }
                                        },
                                        cells: [
                                          DataCell(
                                            Text(
                                              room.roomId.toString(),
                                              style: GoogleFonts.poppins(),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              room.roomType,
                                              style: GoogleFonts.poppins(),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              room.roomFloor,
                                              style: GoogleFonts.poppins(),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              room.roomStatus,
                                              style: GoogleFonts.poppins(),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              room.repairsStatus,
                                              style: GoogleFonts.poppins(),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
