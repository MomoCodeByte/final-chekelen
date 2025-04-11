// import 'package:flutter/material.dart';
// import 'menu_item.dart';

// class DrawerMenu extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(color: Colors.green),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircleAvatar(
//                   radius: 40,
//                   // backgroundImage: AssetImage('assets/logo.png'), // Add your logo image
//                 ),
//                 SizedBox(height: 10),
//                 Text('Farming App', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
//               ],
//             ),
//           ),
//           MenuItem(
//             title: 'User Management',
//             icon: Icons.person,
//             onTap: () {
//               Navigator.pushNamed(context, '/user_management');
//             },
//           ),
//           MenuItem(
//             title: 'Crop Management',
//             icon: Icons.local_florist,
//             onTap: () {
//               Navigator.pushNamed(context, '/crop_management');
//             },
//           ),
//           MenuItem(
//             title: 'Order Management',
//             icon: Icons.shopping_cart,
//             onTap: () {
//               Navigator.pushNamed(context, '/order_management');
//             },
//           ),
//           MenuItem(
//             title: 'Transaction Management',
//             icon: Icons.monetization_on,
//             onTap: () {
//               Navigator.pushNamed(context, '/transaction_management');
//             },
//           ),
//           MenuItem(
//             title: 'Logout',
//             icon: Icons.logout,
//             onTap: () {
//               // Implement logout functionality
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }