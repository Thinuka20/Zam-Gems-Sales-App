import 'package:flutter/material.dart';
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

      print('Room Response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to load rooms: ${response.statusCode}');
    } catch (e) {
      print('Error loading rooms: $e');
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
    final bookingResponse = await http.put(
      Uri.parse('$baseUrl/booking/$bookingId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'bookingStatus': 'CheckIN',
        'roomId': roomId,
        'connectionString': connectionString,
      }),
    );

    if (bookingResponse.statusCode != 200) {
      throw Exception('Failed to update booking status');
    }

    final roomResponse = await http.put(
      Uri.parse('$baseUrl/room/$roomId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'roomStatus': 'Occupied',
        'connectionString': connectionString,
      }),
    );

    if (roomResponse.statusCode != 200) {
      throw Exception('Failed to update room status');
    }

    final customerResponse = await http.put(
      Uri.parse('$baseUrl/customer/${customerData['customerId']}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        ...customerData,
        'connectionString': connectionString,
      }),
    );

    if (customerResponse.statusCode != 200) {
      throw Exception('Failed to update customer data');
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
        _loadAvailableRooms(),
        _loadNationalities(),
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
        // Handle null or empty name safely
        final fullName = (data['name'] ?? '').toString();
        final nameParts = fullName.isNotEmpty ? fullName.split(' ') : ['', ''];

        firstNameController.text = nameParts[0];
        lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        phoneController.text = (data['phone'] ?? '').toString();
        emailController.text = (data['email'] ?? '').toString();
        addressController.text = (data['address'] ?? '').toString();
        nicController.text = (data['nicPassport'] ?? '').toString();
        selectedNationality = data['details1']?.toString();
        customerId = (data['customerId'] ?? '').toString();
      });
    } catch (e) {
      _showError('Error loading customer data: $e');
    }
  }

  Future<void> _loadAvailableRooms() async {
    try {
      final response = await _apiService.getAvailableRooms(widget.bookingId);
      print('Parsed room data: $response');

      if (mounted) {
        setState(() {
          // Handle single room response
          final room = response;
          rooms = [{
            'roomId': room['roomID'], // Note: different case in API
            'roomNumber': room['roomID'], // Using roomID as number since it's missing
            'roomType': room['roomType'] ?? '',
            'roomFloor': room['roomFloor'] ?? '',
            'roomStatus': room['roomStatus'] ?? '',
          }];

          selectedRoom ??= rooms.isNotEmpty ? rooms[0]['roomId'].toString() : null;
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
    if (!_formKey.currentState!.validate() || customerId == null) return;

    setState(() => isLoading = true);
    try {
      await _apiService.checkIn(
        bookingId: widget.bookingId,
        customerData: {
          'customerId': customerId,
          'firstName': firstNameController.text,
          'lastName': lastNameController.text,
          'address': addressController.text,
          'phone': phoneController.text,
          'nicNumber': nicController.text,
          'email': emailController.text,
          'details1': selectedNationality,
        },
        roomId: selectedRoom!,
      );
      Get.back(result: true);
    } catch (e) {
      _showError('Error during check-in: $e');
    } finally {
      setState(() => isLoading = false);
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Customer Check In',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Theme.of(context).primaryColor.withOpacity(0.05), Colors.white],
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
                        decoration: _buildInputDecoration('First Name', Icons.person_outline),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: lastNameController,
                        decoration: _buildInputDecoration('Last Name', Icons.person_outline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: _buildInputDecoration('Phone', Icons.phone_outlined),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: _buildInputDecoration('Email', Icons.email_outlined),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: _buildInputDecoration('Address', Icons.location_on_outlined),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nicController,
                  decoration: _buildInputDecoration('NIC/Passport Number', Icons.badge_outlined),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedNationality,
                  decoration: _buildInputDecoration('Nationality', Icons.flag_outlined),
                  items: nationalities.map((nationality) {
                    return DropdownMenuItem<String>(
                      value: nationality['name'],
                      child: Text(nationality['name']),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedNationality = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                // if (rooms.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedRoom,
                    decoration: _buildInputDecoration('Room', Icons.meeting_room_outlined),
                    items: rooms.map((room) {
                      return DropdownMenuItem<String>(
                        value: room['roomId'].toString(),
                        child: Text('Room ${room['roomType']} ${room['roomNumber']} | ${room['roomType']} | ${room['roomFloor']}'),
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
    );
  }
}