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
  List<DatabaseLocation> _locations = [];
  DatabaseLocation? _selectedLocation;
  bool _isLoadingLocations = true;
  bool showLocationDropdown = true;
  bool showTable = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      setState(() => _isLoadingLocations = true);

      final queryParameters = {'connectionString': datasource};
      final uri = Uri.parse('http://124.43.70.220:7072/Reports/locations')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> locationsJson = json.decode(response.body);
        setState(() {
          _locations = locationsJson
              .map((json) => DatabaseLocation.fromJson(json))
              .toList();
          _isLoadingLocations = false;
        });
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingLocations = false;
        errorMessage = 'Error loading locations: $e';
      });
    }
  }

  Future<void> _loadRoomDetails() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final queryParameters = {
        'connectionString': _selectedLocation!.dPath,
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
          rooms = roomsJson.map((json) => RoomDetailsFull.fromJson(json)).toList();
          showTable = true;
          showLocationDropdown = false;
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

  void _resetSearch() {
    setState(() {
      showTable = false;
      showLocationDropdown = true;
      _selectedLocation = null;
      searchController.clear();
    });
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

  Future<void> _onRefresh() async {
    if (showTable) {
      await _loadRoomDetails();
    }
  }

  void _handleLogout() async {
    final loginController = Get.find<LoginController>();
    await loginController.clearLoginData();
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
                const SizedBox(height: 8),
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
              if (showLocationDropdown)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
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
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              onPressed: _loadRoomDetails,
                              child: isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Text(
                                'View Rooms',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (showTable) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
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
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _resetSearch,
                        tooltip: 'Reset Search',
                      ),
                    ],
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
                            showCheckboxColumn: false,
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
                                  rowColor = Colors.white;
                                case 'Occupied':
                                  rowColor = Colors.blue[100];
                                case 'Reserved':
                                  rowColor = Colors.green[100];
                                case 'Not Available':
                                  rowColor = Colors.redAccent[100];
                                case 'Closed for Maintenance':
                                  rowColor = Colors.yellow[100];
                                case 'Under Construction':
                                  rowColor = Colors.red[200];
                                case 'Other':
                                  rowColor = Colors.white;
                              }
                              return DataRow(
                                color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Theme.of(context).colorScheme.primary.withOpacity(0.08);
                                  }
                                  return rowColor;
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
                                      }
                                    },
                                  );

                                  if (result == 'refresh') {
                                    _onRefresh();
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
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }
}