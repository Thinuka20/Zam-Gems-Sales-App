import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:genix_reports/controllers/login_controller.dart';
import 'package:genix_reports/widgets/user_activity_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

final loginController = Get.find<LoginController>();
final datasource = loginController.datasource;

class HousekeepingManager extends StatefulWidget {
  const HousekeepingManager({Key? key}) : super(key: key);

  @override
  State<HousekeepingManager> createState() => _HousekeepingManagerState();
}

class _HousekeepingManagerState extends State<HousekeepingManager> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String? errorMessage;
  DateTime? lastCleanedDate;

  @override
  void initState() {
    super.initState();
    final Map<String, dynamic> roomData = Get.arguments['roomData'];

    // Set initial values for controllers
    lastCleanedByController.text = roomData['cleanedBy'] ?? '';
    maintenanceCommentController.text = roomData['comment'] ?? '';
    additionalDetailsController.text = roomData['details1'] ?? '';

    // Set initial values for dropdowns
    selectedRoomStatus = roomData['roomStatus'];
    selectedMaintenanceStatus = roomData['repairsStatus'];
  }

  @override
  void dispose() {
    lastCleanedByController.dispose();
    maintenanceCommentController.dispose();
    additionalDetailsController.dispose();
    super.dispose();
  }

  // Controllers
  final lastCleanedByController = TextEditingController();
  final maintenanceCommentController = TextEditingController();
  final additionalDetailsController = TextEditingController();

  // Dropdown values
  String? selectedRoomStatus;
  String? selectedMaintenanceStatus;

  // Room status options
  final List<String> roomStatusOptions = [
    'Ready',
    'Occupied',
    'Reserved',
    'Not Available',
    'Closed for Maintenance',
    'Under Construction',
    'Other'
  ];

  // Maintenance status options
  final List<String> maintenanceStatusOptions = [
    'No Action Required',
    'Future Action Required',
    'Immediate Action Required',
    'Other'
  ];

  Future<String> _checkRoomStatus(String roomId) async {
    try {
      final queryParameters = {
        'connectionString': datasource,
      };

      final uri =
          Uri.parse('http://124.43.70.220:7072/Reports/checkstatus/$roomId')
              .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to check room status: ${response.statusCode}');
      }

      // Parse the response body and remove quotes
      final status = response.body.replaceAll('"', '');
      return status;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> _updateRoom(
      String roomId, Map<String, dynamic> updateData) async {
    try {
      final queryParameters = {
        'connectionString': datasource,
      };

      // Fix: Add forward slash between 'updateroom' and roomId
      final uri =
          Uri.parse('http://124.43.70.220:7072/Reports/updateroom/$roomId')
              .replace(queryParameters: queryParameters);

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode != 200) {
        // Add more detailed error information
        final errorBody = response.body;
        throw Exception(
            'Failed to update room: Status ${response.statusCode}, Details: $errorBody');
      }
    } catch (e) {
      throw Exception('Error updating room: ${e.toString()}');
    }
  }

  Future<void> _handleUpdateRoom(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final roomId = Get.arguments['roomData']['roomId'].toString();
    bool updateCompleted = false;

    try {
      // First check room status
      final status = await _checkRoomStatus(roomId);

      // If status is "CheckIn", show alert and return
      if (status == "CheckIN") {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Room Status Cannot Be Changed',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              content: Text(
                'Room $roomId is Currently Occupied, Please Check Out Room $roomId Before Change Room Status',
                style: GoogleFonts.poppins(),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'OK',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      } else if (!updateCompleted) {
        // Process the update only if not already completed
        updateCompleted = true;

        // Handle lastCleanedDate
        if (Get.arguments['roomData']['lastCleanedDate'] != null) {
          if (Get.arguments['roomData']['lastCleanedDate'] is String) {
            lastCleanedDate =
                DateTime.parse(Get.arguments['roomData']['lastCleanedDate']);
          } else if (Get.arguments['roomData']['lastCleanedDate'] is DateTime) {
            lastCleanedDate = Get.arguments['roomData']['lastCleanedDate'];
          }
        }

        final updateData = {
          'roomType': Get.arguments['roomData']['roomType'],
          'roomFloor': Get.arguments['roomData']['roomFloor'],
          'maximumOccupancy': Get.arguments['roomData']['maximumOccupancy'],
          'roomStatus': selectedRoomStatus,
          'lastCleanedDate': DateTime.now().toIso8601String(),
          'cleanedBy': lastCleanedByController.text,
          'repairsStatus': selectedMaintenanceStatus,
          'comment': maintenanceCommentController.text,
          'details1': additionalDetailsController.text,
          'details2': Get.arguments['roomData']['details2'],
        };

        await _updateRoom(roomId, updateData);

        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Room updated successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Get.back(result: 'refresh');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update room: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    final loginController = Get.find<LoginController>();
    await loginController.clearLoginData();
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
                  'Room Details',
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
        body: Stack(
          children: [
            Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Room Management',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          if (errorMessage != null &&
                              !errorMessage!.contains('occupied'))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                errorMessage!,
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          DropdownButtonFormField<String>(
                            value: selectedRoomStatus,
                            decoration:
                                _buildInputDecoration('Room Status', Icons.hotel),
                            items: roomStatusOptions.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => selectedRoomStatus = value);
                            },
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: lastCleanedByController,
                            decoration: _buildInputDecoration(
                                'Last Cleaned By', Icons.person_outline),
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedMaintenanceStatus,
                            decoration: _buildInputDecoration(
                                'Maintenance Status', Icons.build),
                            items: maintenanceStatusOptions.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => selectedMaintenanceStatus = value);
                            },
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: maintenanceCommentController,
                            decoration: _buildInputDecoration(
                                'Maintenance Comment', Icons.comment),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: additionalDetailsController,
                            decoration: _buildInputDecoration(
                                'Additional Details', Icons.notes),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => _handleUpdateRoom(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Update',
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
                  ],
                ),
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
