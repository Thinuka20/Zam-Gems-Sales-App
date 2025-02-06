import 'package:flutter/material.dart';
import 'package:genix_reports/widgets/user_activity_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../controllers/login_controller.dart';

final loginController = Get.find<LoginController>();
final datasource = loginController.datasource;

class ApiService {
  static const String baseUrl = 'http://124.43.70.220:7072/Reports';
  final String connectionString;

  ApiService({required this.connectionString});

  Future<Map<String, dynamic>> getCustomerData(int bookingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/booking/$bookingId/customer')
          .replace(queryParameters: {'connectionString': connectionString}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load customer data: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getAvailableRooms(int bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/booking/$bookingId/room')
            .replace(queryParameters: {'connectionString': connectionString}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to load rooms: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error loading rooms: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNationalities() async {
    final response = await http.get(
      Uri.parse('$baseUrl/nationalities')
          .replace(queryParameters: {'connectionString': connectionString}),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load nationalities: ${response.statusCode}');
  }

  Future<void> checkIn({
    required int bookingId,
    required Map<String, dynamic> customerData,
    required String roomId,
  }) async {
    try {
      final checkInBody = {
        'bookingId': bookingId,
        'firstName': customerData['firstName'],
        'lastName': customerData['lastName'],
        'phone': customerData['phone'] ?? '',
        'address': customerData['address'] ?? '',
        'nicPassport': customerData['nicPassport'] ?? '',
        'nationality': customerData['nationality'] ?? '',
        'roomId': int.parse(roomId),
        'email': customerData['email'] ?? '',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/selfcheckin')
            .replace(queryParameters: {'connectionString': connectionString}),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(checkInBody),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to complete check-in: ${response.body}');
      }
    } catch (e) {
      throw e;
    }
  }
}

class CustomerCheckIn extends StatefulWidget {
  final int bookingId;
  final String dPath;

  const CustomerCheckIn({
    Key? key,
    required this.bookingId,
    required this.dPath,
  }) : super(key: key);

  @override
  State<CustomerCheckIn> createState() => _CustomerCheckInState();
}

class _CustomerCheckInState extends State<CustomerCheckIn> {
  late final ApiService _apiService;
  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final nicController = TextEditingController();

  String? selectedNationality;
  String? selectedRoom;
  List<Map<String, dynamic>> rooms = [];
  List<Map<String, dynamic>> nationalities = [];
  bool isLoading = false;
  String? customerId;

  void _handleLogout() async {
    final loginController = Get.find<LoginController>();
    await loginController.clearLoginData();
  }

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(connectionString: widget.dPath);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([
        _loadCustomerData(),
        _loadNationalities(),
        _loadAvailableRooms(),
      ]);
    } catch (e) {
      _showError('Error loading initial data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadCustomerData() async {
    try {
      final data = await _apiService.getCustomerData(widget.bookingId);
      setState(() {
        firstNameController.text = (data['firstName'] ?? '').toString();
        lastNameController.text = (data['lastName'] ?? '').toString();
        phoneController.text = (data['phone'] ?? '').toString();
        emailController.text = (data['email'] ?? '').toString();
        addressController.text = (data['address'] ?? '').toString();
        nicController.text = (data['nicNumber'] ?? '').toString();
        final nationality = (data['details1'] ?? '').toString();
        selectedNationality = nationality.isNotEmpty ? nationality : null;
        customerId = (data['customerId'] ?? '').toString();
      });
    } catch (e) {
      _showError('Error loading customer data: $e');
    }
  }

  Future<void> _loadAvailableRooms() async {
    try {
      final response = await _apiService.getAvailableRooms(widget.bookingId);

      if (mounted) {
        setState(() {
          // Handle single room response
          final room = response;
          rooms = [
            {
              'roomId': room['roomID'], // Note: different case in API
              'roomNumber':
                  room['roomID'], // Using roomID as number since it's missing
              'roomType': room['roomType'] ?? '',
              'roomFloor': room['roomFloor'] ?? '',
              'roomStatus': room['roomStatus'] ?? '',
            }
          ];

          selectedRoom ??=
              rooms.isNotEmpty ? rooms[0]['roomId'].toString() : null;
        });
      }
    } catch (e) {
      _showError('Error loading rooms: $e');
    }
  }

  Future<void> _loadNationalities() async {
    try {
      final fetchedNationalities = await _apiService.getNationalities();
      setState(() {
        nationalities = fetchedNationalities;
      });
    } catch (e) {
      _showError('Error loading nationalities: $e');
    }
  }

  Future<void> _handleCheckIn() async {
    if (!_formKey.currentState!.validate() || customerId == null) {
      _showError('Please fill all required fields');
      return;
    }

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Check In Warning'),
        content: Text('Please Press Yes to Check the Selected Booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    setState(() => isLoading = true);
    try {
      await _apiService.checkIn(
        bookingId: widget.bookingId,
        customerData: {
          'customerId': customerId,
          'firstName': firstNameController.text,
          'lastName': lastNameController.text,
          'phone': phoneController.text,
          'address': addressController.text,
          'nicPassport': nicController.text,
          'email': emailController.text,
          'nationality': selectedNationality,
        },
        roomId: selectedRoom!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in completed successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
      prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  'Customer CheckIn',
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.05),
                Colors.white
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guest Information',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: firstNameController,
                          decoration: _buildInputDecoration(
                              'First Name', Icons.person_outline),
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: lastNameController,
                          decoration: _buildInputDecoration(
                              'Last Name', Icons.person_outline),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration:
                        _buildInputDecoration('Phone', Icons.phone_outlined),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration:
                        _buildInputDecoration('Email', Icons.email_outlined),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressController,
                    decoration: _buildInputDecoration(
                        'Address', Icons.location_on_outlined),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nicController,
                    decoration: _buildInputDecoration(
                        'NIC/Passport Number', Icons.badge_outlined),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedNationality?.isNotEmpty == true
                        ? selectedNationality
                        : null,
                    decoration:
                        _buildInputDecoration('Nationality', Icons.flag_outlined),
                    items: [
                      if (nationalities.isEmpty)
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Loading nationalities...'),
                        ),
                      ...nationalities.map((nationality) {
                        final name = nationality['name']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedNationality = value);
                      }
                    },
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // if (rooms.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedRoom,
                    decoration: _buildInputDecoration(
                        'Room', Icons.meeting_room_outlined),
                    items: rooms.map((room) {
                      return DropdownMenuItem<String>(
                        value: room['roomId'].toString(),
                        child: Text(
                            'Room ${room['roomType']} ${room['roomNumber']} | ${room['roomType']} | ${room['roomFloor']}'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => selectedRoom = v),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleCheckIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Complete Check-In',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
