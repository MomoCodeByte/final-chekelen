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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'checkereni_market',
      home: SplashScreen(),
      routes: {
        '/home': (context) => ProductListScreen(),
        '/welcome': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/registration': (context) => RegistrationScreen(),
        '/admin': (context) => AdminDashboard(),
        '/farmer': (context) => FarmerDashboard(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/details') {
          // Validate arguments
          if (settings.arguments is Map<String, dynamic>) {
            final args = settings.arguments as Map<String, dynamic>;
            // Ensure required parameters exist
            if (args.containsKey('productId') &&
                args.containsKey('farmerId') &&
                args.containsKey('productName') &&
                args.containsKey('price')) {
              return MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(
                  productId: args['productId'] as int,
                  farmerId: args['farmerId'] as int,
                  productName: args['productName'] as String,
                  price: args['price'] as String,
                  isOrganic: args['isOrganic'] as bool? ?? false,
                  isFresh: args['isFresh'] as bool? ?? false,
                  categories: args['categories'] as String?,
                ),
              );
            }
          }
          // Fallback for invalid arguments
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: Text('Error: Invalid product details'),
              ),
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

  SplashScreen({super.key});

  Future<void> _checkToken(BuildContext context) async {
    String? token = await _storage.read(key: 'jwt_token');

    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = utf8.decode(
            base64Url.decode(base64Url.normalize(parts[1])),
          );
          final payloadMap = json.decode(payload) as Map<String, dynamic>;
          final userRole = payloadMap['role'] as String?;

          if (userRole == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else if (userRole == 'farmer') {
            Navigator.pushReplacementNamed(context, '/farmer');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          await _storage.delete(key: 'jwt_token'); // Clear invalid token
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      } catch (e) {
        // Handle invalid token or decoding errors
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkToken(context);
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)), // Use primaryGreen
      ),
    );
  }
}