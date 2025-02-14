import 'package:flutter/material.dart';
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

class CurrentBookedBanquet {
  final int bookingId;
  final int fkBanId;
  final String name;
  final String banquetTime;
  final String bookingStatus;
  final String partType;
  final String eventName;
  final int gurGuest;
  final int expectedGuest;
  final String initialBookingBy;

  CurrentBookedBanquet({
    required this.bookingId,
    required this.fkBanId,
    required this.name,
    required this.banquetTime,
    required this.bookingStatus,
    required this.partType,
    required this.eventName,
    required this.gurGuest,
    required this.expectedGuest,
    required this.initialBookingBy,
  });

  factory CurrentBookedBanquet.fromJson(Map<String, dynamic> json) {
    print('Parsing JSON: $json'); // Debug print
    return CurrentBookedBanquet(
      bookingId: json['bookingID'] ?? 0,
      fkBanId: json['fK_BanID'] ?? 0,
      name: json['name']?.toString() ?? '',
      banquetTime: json['banquetTime']?.toString() ?? '',
      bookingStatus: json['bookingStatus']?.toString() ?? '',
      partType: json['partType']?.toString() ?? '',
      eventName: json['eventName']?.toString() ?? '',
      gurGuest: json['gurGuest'] ?? 0,
      expectedGuest: json['expectedGuest'] ?? 0,
      initialBookingBy: json['initialBookingBy']?.toString() ?? '',
    );
  }

  @override
  String toString() {
    return 'CurrentBookedBanquet(bookingId: $bookingId, name: $name, eventName: $eventName)';
  }
}

class BanquetDetails {
  final int banId;
  final String banType;
  final String banFloor;
  final int maximumOccupancy;
  final String banStatus;
  final DateTime lastCleanedDate;
  final String cleanedBy;
  final String repairsStatus;
  final String comment;
  final String? details1;
  final String? details2;

  BanquetDetails({
    required this.banId,
    required this.banType,
    required this.banFloor,
    required this.maximumOccupancy,
    required this.banStatus,
    required this.lastCleanedDate,
    required this.cleanedBy,
    required this.repairsStatus,
    required this.comment,
    this.details1,
    this.details2,
  });

  factory BanquetDetails.fromJson(Map<String, dynamic> json) {
    return BanquetDetails(
      banId: json['banID'] as int,
      banType: json['banType'] as String,
      banFloor: json['banFloor'] as String,
      maximumOccupancy: json['maximumOccupancy'] as int,
      banStatus: json['banStatus'] as String,
      lastCleanedDate: DateTime.parse(json['lastCleanedDate'] as String),
      cleanedBy: json['cleanedBy'] as String,
      repairsStatus: json['repairsStatus'] as String,
      comment: json['comment'] as String,
      details1: json['details1'] as String?,
      details2: json['details2'] as String?,
    );
  }
}

class CurrentBanquetBookings extends StatefulWidget {
  const CurrentBanquetBookings({super.key});

  @override
  State<CurrentBanquetBookings> createState() => _CurrentBanquetBookingsState();
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

  Future<List<CurrentBookedBanquet>> getCurrentBanquetBookings({
    required DateTime date,
    required DatabaseLocation location,
  }) async {
    try {
      final queryParameters = {
        'startDate': DateFormat('yyyy-MM-dd').format(date),
        'connectionString': location.dPath,
      };

      final uri = Uri.parse('$baseUrl/currentbookedbanquets')
          .replace(queryParameters: queryParameters);

      print('Requesting URL: $uri'); // Debug print

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('Response Status Code: ${response.statusCode}'); // Debug print
      print('Response Body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final List<dynamic> bookingsJson = json.decode(response.body);
        print('Parsed JSON: $bookingsJson'); // Debug print

        final bookings = bookingsJson
            .map((json) {
              try {
                return CurrentBookedBanquet.fromJson(json);
              } catch (e) {
                print('Error parsing booking: $e'); // Debug print
                return null;
              }
            })
            .where((booking) =>
                booking != null &&
                booking.bookingStatus.toLowerCase() != 'cancelled')
            .cast<CurrentBookedBanquet>()
            .toList();

        print('Final Bookings List: $bookings'); // Debug print
        return bookings;
      } else {
        print('Error response: ${response.body}'); // Debug print
        return [];
      }
    } catch (e) {
      print('Exception in getCurrentBanquetBookings: $e'); // Debug print
      throw Exception('Failed to load banquet bookings: $e');
    }
  }

  Future<List<BanquetDetails>> getAllBanquets({
    required DatabaseLocation location,
  }) async {
    try {
      final queryParameters = {
        'connectionString': location.dPath,
      };

      final uri = Uri.parse('$baseUrl/banquets')
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List<dynamic> banquetsJson = json.decode(response.body);
        return banquetsJson
            .map((json) => BanquetDetails.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load banquets: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load banquets: $e');
    }
  }
}

class _CurrentBanquetBookingsState extends State<CurrentBanquetBookings> {
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  List<CurrentBookedBanquet> banquetBookings = [];
  bool showNavigationButtons = false;
  bool showCards = false;
  late final ApiService _apiService;
  List<DatabaseLocation> _locations = [];
  DatabaseLocation? _selectedLocation;
  bool _isLoadingLocations = true;
  List<BanquetDetails> allBanquets = [];
  bool showLocationDropdown = true; // Add this new state variable

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

  Future<void> _fetchBanquetsAndBookings() async {
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
      // Fetch both banquets and bookings in parallel
      final Future<List<BanquetDetails>> banquetsFuture =
          _apiService.getAllBanquets(
        location: _selectedLocation!,
      );

      final Future<List<CurrentBookedBanquet>> bookingsFuture =
          _apiService.getCurrentBanquetBookings(
        date: selectedDate,
        location: _selectedLocation!,
      );

      final results = await Future.wait([banquetsFuture, bookingsFuture]);

      setState(() {
        allBanquets = results[0] as List<BanquetDetails>;
        banquetBookings = results[1] as List<CurrentBookedBanquet>;
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
    await _fetchBanquetsAndBookings();
    setState(() {
      showCards = true;
      showLocationDropdown =
          false; // Hide location dropdown after generating data
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
    _fetchBanquetsAndBookings();
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

  Widget _buildBanquetCard(BanquetDetails banquet) {
    // Find matching booking for this banquet
    final booking = banquetBookings
        .where((b) =>
            b.fkBanId == banquet.banId &&
            b.bookingStatus.toLowerCase() != 'cancelled')
        .firstOrNull;

    final bool needsRepair = banquet.repairsStatus.toLowerCase() == 'required';

    return Card(
      margin: const EdgeInsets.all(
          0), // Remove card margin since grid spacing handles it
      color: booking != null
          ? getStatusColor(booking.bookingStatus)
          : needsRepair
              ? Colors.red[50]
              : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Banquet ${banquet.banId} (${banquet.banType})',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Floor: ${banquet.banFloor}',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            Text(
              'Max Occupancy: ${banquet.maximumOccupancy}',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
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
                'Event: ${booking.eventName}',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              Text(
                'Time: ${booking.banquetTime}',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              Text(
                'Status: ${booking.bookingStatus}',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              if (booking.gurGuest > 0)
                Text(
                  'Guaranteed Guests: ${booking.gurGuest}',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              if (booking.expectedGuest > 0)
                Text(
                  'Expected Guests: ${booking.expectedGuest}',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
            ] else ...[
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status: ${banquet.banStatus}',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  if (needsRepair)
                    Text(
                      'Needs Repair',
                      style: GoogleFonts.poppins(
                        color: Colors.red[700],
                        fontSize: 13,
                      ),
                    )
                  else
                    Text(
                      'Available',
                      style: GoogleFonts.poppins(
                        color: Colors.green[700],
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ],
            if (banquet.comment != "NA") ...[
              const SizedBox(height: 4),
              Text(
                'Note: ${banquet.comment}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
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
                const SizedBox(height: 8),
                Text(
                  'Banquet Bookings',
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
                          _fetchBanquetsAndBookings();
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;

                        if (isLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (allBanquets.isEmpty) {
                          return Center(
                            child: Text(
                              'No banquet halls found',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }

                        // For mobile, use ListView
                        if (isMobile) {
                          return GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              childAspectRatio:
                                  1.3, // Adjust this value to control card height
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                            ),
                            padding: const EdgeInsets.all(16.0),
                            itemCount: allBanquets.length,
                            itemBuilder: (context, index) =>
                                _buildBanquetCard(allBanquets[index]),
                          );
                        }

                        // For tablets and larger screens, use GridView with 2 columns
                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio:
                                1.5, // Adjust this value to control card height
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                          ),
                          padding: const EdgeInsets.all(16.0),
                          itemCount: allBanquets.length,
                          itemBuilder: (context, index) =>
                              _buildBanquetCard(allBanquets[index]),
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
