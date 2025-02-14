import 'package:flutter/material.dart';
import 'package:genix_reports/skynet_pro_hotel/customerchecking.dart';
import 'package:genix_reports/widgets/user_activity_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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

class CurrentBookedRoom {
  final int bookTransId;
  final String name;
  final int roomId;
  final int bookingId;
  final String bookingStatus;
  final double total;
  final String room;
  final String basis;
  final String agent;

  CurrentBookedRoom({
    required this.bookTransId,
    required this.name,
    required this.roomId,
    required this.bookingId,
    required this.bookingStatus,
    required this.total,
    required this.room,
    required this.basis,
    required this.agent,
  });

  factory CurrentBookedRoom.fromJson(Map<String, dynamic> json) {
    return CurrentBookedRoom(
      bookTransId: json['bookTransID'],
      name: json['name'],
      roomId: json['roomID'],
      bookingId: json['fK_BookingID'],
      bookingStatus: json['bookingStatus'],
      total: json['total'].toDouble(),
      room: json['room'],
      basis: json['basis'],
      agent: json['agent'],
    );
  }
}

class RoomDetails {
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

  RoomDetails({
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

  factory RoomDetails.fromJson(Map<String, dynamic> json) {
    return RoomDetails(
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

class CurrentRoomBookings extends StatefulWidget {
  const CurrentRoomBookings({super.key});

  @override
  State<CurrentRoomBookings> createState() => _CurrentRoomBookingsState();
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

  Future<List<CurrentBookedRoom>> getCurrentBookings({
    required DateTime date,
    required DatabaseLocation location,
  }) async {
    try {
      final queryParameters = {
        'startDate': DateFormat('yyyy-MM-dd').format(date),
        'connectionString': location.dPath,
      };

      final uri = Uri.parse('$baseUrl/currentbookedrooms')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List<dynamic> bookingsJson = json.decode(response.body);
        return bookingsJson
            .map((json) => CurrentBookedRoom.fromJson(json))
            .where(
                (booking) => booking.bookingStatus.toLowerCase() != 'cancelled')
            .toList();
      } else {
        throw Exception('Failed to load bookings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load bookings: $e');
    }
  }

  Future<List<RoomDetails>> getAllRooms({
    required DatabaseLocation location,
  }) async {
    try {
      final queryParameters = {
        'connectionString': location.dPath,
      };

      final uri = Uri.parse('$baseUrl/getallrooms')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List<dynamic> roomsJson = json.decode(response.body);
        return roomsJson.map((json) => RoomDetails.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load rooms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load rooms: $e');
    }
  }
}

class _CurrentRoomBookingsState extends State<CurrentRoomBookings> {
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  List<CurrentBookedRoom> bookings = [];
  bool showNavigationButtons = false;
  bool showCards = false;
  List<RoomDetails> allRooms = [];
  late final ApiService _apiService;
  List<DatabaseLocation> _locations = [];
  DatabaseLocation? _selectedLocation;
  bool _isLoadingLocations = true;
  bool showLocationDropdown = true; // New state variable

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading locations: $e')),
        );
      }
    }
  }

  Future<void> _fetchRoomsAndBookings() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Fetch both rooms and bookings in parallel
      final Future<List<RoomDetails>> roomsFuture = _apiService.getAllRooms(
        location: _selectedLocation!,
      );

      final Future<List<CurrentBookedRoom>> bookingsFuture =
          _apiService.getCurrentBookings(
        date: selectedDate,
        location: _selectedLocation!,
      );

      final results = await Future.wait([roomsFuture, bookingsFuture]);

      setState(() {
        allRooms = results[0] as List<RoomDetails>;
        bookings = results[1] as List<CurrentBookedRoom>;
        showNavigationButtons = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _generateData() async {
    await _fetchRoomsAndBookings();
    setState(() {
      showCards = true;
      showLocationDropdown = false; // Hide the dropdown after search
    });
  }

  void _resetSearch() {
    setState(() {
      showCards = false;
      showLocationDropdown = true;
      _selectedLocation = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadLocations();
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'checkin':
        return Colors.green[100]!;
      case 'checkout':
        return Colors.red[100]!;
      case 'confirmed':
        return Colors.blue[100]!;
      case 'temporary':
        return Colors.purple[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Future<void> _onRefresh() async {
    await _generateData();
  }

  void _handleLogout() async {
    final loginController = Get.find<LoginController>();
    await loginController.clearLoginData();
  }

  void _navigateDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });
    _fetchRoomsAndBookings();
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

  Widget _buildRoomCard(RoomDetails room) {
    final booking = bookings
        .where((b) =>
            b.roomId == room.roomId &&
            b.bookingStatus.toLowerCase() != 'cancelled')
        .firstOrNull;

    final bool isAvailable = booking == null;

    return InkWell(
      onTap: (booking != null &&
              booking.bookingStatus.toLowerCase() == 'confirmed' &&
              _selectedLocation != null)
          ? () async {
              final result = await Get.to(() => CustomerCheckIn(
                    bookingId: booking.bookingId,
                    dPath: _selectedLocation!.dPath,
                  ));
              if (result == true) {
                _fetchRoomsAndBookings();
              }
            }
          : null,
      child: Card(
        margin: const EdgeInsets.all(4),
        color: booking != null
            ? getStatusColor(booking.bookingStatus)
            : Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Room ${room.roomId} (${room.roomType})',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (booking != null) ...[
                const SizedBox(height: 8),
                Text(
                  booking.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Booking ID: ${booking.bookingId}',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                Text(
                  'Status: ${booking.bookingStatus}',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                Text(
                  'Basis: ${booking.basis}',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                Text(
                  'Agent: ${booking.agent}',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                const Spacer(),
                Text(
                  NumberFormat.currency(
                    symbol: 'Rs.',
                    decimalDigits: 2,
                    locale: 'en_IN',
                  ).format(booking.total),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ] else ...[
                const Spacer(),
                Text(
                  'Available',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  'Room Bookings',
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  child: InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
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
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                        if (showCards) {
                          _fetchRoomsAndBookings();
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selected Date',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                          Text(
                            DateFormat('yyyy-MM-dd').format(selectedDate),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (showLocationDropdown) // Only show location card if showLocationDropdown is true
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
                if (!showCards)
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
                      onPressed: _generateData,
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
                              'View Bookings',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                if (showCards) ...[
                  if (showNavigationButtons)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateDate(-1),
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            label: Text(
                              'Previous Day',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateDate(1),
                            icon: const Icon(Icons.arrow_forward,
                                color: Colors.white),
                            label: Text(
                              'Next Day',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              // Check if device width is less than 600 (typical mobile breakpoint)
                              final isMobile = constraints.maxWidth < 600;

                              return GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isMobile ? 1 : 2,
                                  childAspectRatio: isMobile
                                      ? 1.7
                                      : 1.9, // Adjust aspect ratio for 2 columns
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: allRooms.length,
                                itemBuilder: (context, index) =>
                                    _buildRoomCard(allRooms[index]),
                              );
                            },
                          ),
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
