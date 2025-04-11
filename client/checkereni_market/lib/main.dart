import 'package:flutter/material.dart';
import './screens/Componets/Login_screen.dart';
import './screens/Componets/welcome_screen.dart';
import './screens/Componets/RegistrationScreen.dart';
import './screens/Clients/product_list.dart';
import './screens/Clients/product_details.dart';
// import './screens/Clients/dashboard.dart';
import './screens/Farmer/dashboard.dart';
import './screens/Admin/dashboard.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  get productName => null;
  get price => null;
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      title: 'Farming App',
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/home': (context) => ProductListScreen(),
        '/login': (context) => LoginScreen(),
        '/dateil':(context) => ProductDetailsScreen(productName: productName, price: price),
        '/registration': (context) => RegistrationScreen(),
        '/admin': (context) => AdminDashboard(),
        '/farmer': (context) => FarmerDashboard(),
        // '/admin': (context) => AdminDashboard(),
        // '/user_management': (context) => UserManagementScreen(),
        // '/crop_management': (context) => CropManagementScreen(),
        // '/order_management': (context) => OrderManagementScreen(),
        // '/transaction_management': (context) => TransactionManagementScreen(),
      },
    );
  }
}
