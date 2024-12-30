import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/login_controller.dart';
import 'menu.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final connectivity = Connectivity();

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://124.43.70.220:7072/Reports',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      // Add these headers for web support
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    // Only use IOHttpClientAdapter for non-web platforms
    if (!kIsWeb) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
    }

    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ],
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (kDebugMode) {
          print('API Error: ${error.message}');
          print('Error type: ${error.type}');
          print('Error response: ${error.response?.data}');
          print('Error status code: ${error.response?.statusCode}');
        }

        // Handle web-specific CORS errors
        if (kIsWeb && error.type == DioExceptionType.badResponse) {
          if (error.response?.statusCode == 0) {
            return handler.reject(DioException(
              requestOptions: error.requestOptions,
              error: 'CORS error: Unable to access the API. Please check server configuration.',
              type: DioExceptionType.badResponse,
            ));
          }
        }

        if (error.response?.statusCode == 401) {
          Get.offAll(() => const LoginPage());
        }
        return handler.next(error);
      },
      onRequest: (request, handler) async {
        final hasConnection = await checkConnection();
        if (kDebugMode) {
          print('Connection check result: $hasConnection');
          print('API Request: ${request.uri}');
          print('Request headers: ${request.headers}');
        }

        if (!hasConnection) {
          return handler.reject(
            DioException(
              requestOptions: request,
              error: 'No internet connection',
              type: DioExceptionType.connectionError,
            ),
          );
        }
        return handler.next(request);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('API Response: ${response.statusCode}');
          print('Response data: ${response.data}');
        }
        return handler.next(response);
      },
    ));
  }

  Future<bool> checkConnection() async {
    try {
      if (kIsWeb) {
        // For web, we'll do a simple connectivity check
        final connectivityResult = await connectivity.checkConnectivity();
        return connectivityResult != ConnectivityResult.none;
      }

      final connectivityResult = await connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (kDebugMode) {
          print('No connectivity detected');
        }
        return false;
      }

      // Modified connection test for web compatibility
      final testDio = Dio()
        ..options.validateStatus = (status) {
          return status != null && status < 500;
        };

      if (kDebugMode) {
        print('Attempting to connect to server...');
      }

      final response = await testDio.head(
        'http://124.43.70.220:7072/Reports',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (kDebugMode) {
        print('Server response status: ${response.statusCode}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Connection check error: $e');
        if (e is DioException) {
          print('DioError type: ${e.type}');
          print('DioError message: ${e.message}');
          print('DioError response: ${e.response}');
        }
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String password, String username) async {
    try {
      if (kDebugMode) {
        print('Attempting login with username: $username');
      }

      final response = await _dio.post(
        '/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (kDebugMode) {
        print('Raw Response: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else if (response.data is String) {
        return json.decode(response.data);
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Login error: ${e.message}');
        print('Error type: ${e.type}');
        print('Error response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error during login: $e');
      }
      throw Exception('Network error: $e');
    }
  }

  String _handleDioError(DioException error) {
    if (kIsWeb && error.type == DioExceptionType.badResponse) {
      if (error.response?.statusCode == 0) {
        return 'Unable to access the server. Please check CORS configuration.';
      }
    }

    if (error.error is String) return error.error.toString();

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection and try again.';
      case DioExceptionType.badResponse:
        switch (error.response?.statusCode) {
          case 400:
            return 'Invalid credentials';
          case 401:
            return 'Unauthorized access';
          case 404:
            return 'Service not found';
          case 500:
            return 'Server error occurred. Please try again later.';
          default:
            return 'Server error occurred';
        }
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      default:
        return 'Network error occurred. Please try again.';
    }
  }
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final List<Duration> retryDelays;

  RetryInterceptor({
    required this.dio,
    this.retries = 3,
    this.retryDelays = const [
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 6),
    ],
  });

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    var extra = err.requestOptions.extra;
    var retriesRemaining = (extra['retries'] ?? retries) as int;

    if (retriesRemaining > 0 && _shouldRetry(err)) {
      await Future.delayed(retryDelays[retries - retriesRemaining]);
      retriesRemaining--;

      try {
        final options = Options(
          method: err.requestOptions.method,
          headers: err.requestOptions.headers,
        );
        options.extra = {
          ...err.requestOptions.extra,
          'retries': retriesRemaining
        };

        final response = await dio.request(
          err.requestOptions.path,
          data: err.requestOptions.data,
          queryParameters: err.requestOptions.queryParameters,
          options: options,
        );
        return handler.resolve(response);
      } catch (e) {
        return super.onError(err, handler);
      }
    }
    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.type == DioExceptionType.badResponse &&
            error.response?.statusCode == 500);
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passcodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePasscode = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (kDebugMode) {
        print('Checking connection...');
      }

      if (!await _apiService.checkConnection()) {
        if (kDebugMode) {
          print('Connection check failed');
        }
        throw Exception('No internet connection available');
      }

      final username = _usernameController.text.trim();
      final password = _passcodeController.text.trim();

      final response = await _apiService.login(password, username);
      final loginController = Get.put(LoginController());
      loginController.setLoginData(response);

      // Print stored data
      if (kDebugMode) {
        print('Stored Login Data: ${loginController.loginData}');
      }

      if (mounted) {
        Get.offAll(() => const DashboardPage());
      }
    } on DioException catch (e) {
      _handleLoginError(e.message ?? 'Login failed');
    } catch (e) {
      _handleLoginError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLoginError(String error) {
    if (!mounted) return;

    _passcodeController.clear();

    Get.snackbar(
      'Login Failed',
      error,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(10),
      icon: const Icon(
        Icons.error_outline,
        color: Colors.white,
      ),
    );
  }

  String? _validatePasscode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your passcode';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your Username';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  _buildLogo(context),
                  const SizedBox(height: 48),
                  _buildLoginCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Hero(
      tag: 'app_logo',
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/ceylon_logo.png',
          width: double.infinity,
          color: Colors.white,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Login to your account',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _usernameController,
              validator: _validateUsername,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.account_circle_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _passcodeController,
              obscureText: _obscurePasscode,
              validator: _validatePasscode,
              decoration: InputDecoration(
                labelText: 'Passcode',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePasscode ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePasscode = !_obscurePasscode),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Login',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildLionLogo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLionLogo(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const SizedBox(height: 55),
          Image.asset(
            'assets/images/lion_logo.png',
            height: 300,
            color: Colors.white,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 55),
        ],
      ),
    );
  }
}