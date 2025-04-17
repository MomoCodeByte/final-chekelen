import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'RegistrationScreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false; // Track loading state

  // Function to handle API login
  Future<void> _login() async {
    // Validate form fields first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // Prepare request data matching server expectations
      final loginData = {
        'email': _emailController.text,
        'password': _passwordController.text,
      };

      // Make the API call to login endpoint
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(loginData),
      );

      // Handle the response
      if (response.statusCode == 200) {
        // Successful login - parse the response
        final responseData = json.decode(response.body);
        final token = responseData['token'];

        // Store the token securely
        final _storage = FlutterSecureStorage();
        try {
          await _storage.write(key: 'jwt_token', value: token);
          print('Token stored: $token');
        } catch (e) {
          print('Error storing token: $e');
        }

        // Check the stored token
        await _checkStoredToken();

        // Extract the payload from JWT token to get the role
        final parts = token.split('.');
        if (parts.length != 3) {
          throw Exception('Invalid token format');
        }

        // Decode the base64 payload
        String payload = parts[1];
        payload = base64.normalize(payload); // Add padding if needed
        final decodedPayload = utf8.decode(base64.decode(payload));
        final payloadMap = json.decode(decodedPayload);

        // Extract the role
        final userRole = payloadMap['role'] as String;
        print('User role from token: $userRole');

        // Navigate based on role from server
        switch (userRole.toLowerCase()) {
          case 'admin':
            Navigator.pushReplacementNamed(context, '/admin');
            break;
          case 'farmer':
            Navigator.pushReplacementNamed(context, '/farmer');
            break;
          case 'customer':
          default:
            Navigator.pushReplacementNamed(context, '/home');
            break;
        }
      } else {
        // Handle error responses
        String errorMessage = 'Login failed';
        try {
          errorMessage = response.body;
        } catch (e) {
          errorMessage = 'Login failed (${response.statusCode})';
        }

        // Show error message to user
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (error) {
      // Handle connection errors
      print('Error during login: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error. Please try again later.')),
      );
    } finally {
      // Always hide loading indicator when done
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to check stored token
  Future<void> _checkStoredToken() async {
    final _storage = FlutterSecureStorage();
    String? token = await _storage.read(key: 'jwt_token');

    if (token != null) {
      print('Stored token: $token');
    } else {
      print('No token found in storage.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF66BB6A), // Light green
              Color(0xFF2E7D32), // Dark green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Back Button
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: Color(0xFF43A047),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          // Logo and Title
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(
                              Icons.eco,
                              size: 50,
                              color: Color(0xFF43A047),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome to Checkereni Market',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Login to continue',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Email Field
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(color: Color(0xFF43A047)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFF43A047),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Password Field
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Color(0xFF43A047)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Color(0xFF43A047),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Color(0xFF43A047),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscureText,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                          ),
                          // Remember Me & Forgot Password
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: true,
                                        onChanged: (value) {},
                                        activeColor: Color(0xFF43A047),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Remember me'),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(color: Color(0xFF43A047)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Login Button
                          SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF43A047),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade400,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 3,
                              ),
                              child:
                                  _isLoading
                                      ? CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : Text(
                                        'LOGIN',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                            ),
                          ),
                          // Social Logins
                          SizedBox(height: 24),
                          Text(
                            'Or login with',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialButton(Icons.facebook, Colors.blue),
                              SizedBox(width: 16),
                              _buildSocialButton(
                                Icons.g_mobiledata,
                                Colors.red,
                              ),
                              SizedBox(width: 16),
                              _buildSocialButton(Icons.apple, Colors.black),
                            ],
                          ),
                          // Register Link
                          SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account?"),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => RegistrationScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Register',
                                  style: TextStyle(
                                    color: Color(0xFF43A047),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}
