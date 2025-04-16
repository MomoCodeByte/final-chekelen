import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert'; // Import for utf8 and json
import './screens/Componets/Login_screen.dart';
import './screens/Componets/welcome_screen.dart';
import './screens/Componets/RegistrationScreen.dart';
import './screens/Clients/product_list.dart';
import './screens/Clients/product_details.dart';
import './screens/Farmer/dashboard.dart';
import './screens/Admin/dashboard.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'checkereni_market',
      home: SplashScreen(), // Use a splash screen to determine the initial route
      routes: {
        '/home': (context) => ProductListScreen(),
        '/welcome':(context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/registration': (context) => RegistrationScreen(),
        '/admin': (context) => AdminDashboard(),
        '/farmer': (context) => FarmerDashboard(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes like '/details'
        if (settings.name == '/details') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              productName: args['productName'],
              price: args['price'],
            ),
          );
        }
        return null; // Return null for undefined routes
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  final _storage = FlutterSecureStorage();

  Future<void> _checkToken(BuildContext context) async {
    String? token = await _storage.read(key: 'jwt_token');

    if (token != null) {
      // Navigate to the appropriate dashboard based on the role
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        final payloadMap = json.decode(payload);
        final userRole = payloadMap['role'];

        if (userRole == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (userRole == 'farmer') {
          Navigator.pushReplacementNamed(context, '/farmer');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/welcome'); // Invalid token
      }
    } else {
      Navigator.pushReplacementNamed(context, '/welcome'); // No token found
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkToken(context); // Check the token when the splash screen is built
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Show a loading indicator
      ),
    );
  }
}