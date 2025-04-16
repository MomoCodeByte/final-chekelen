// // admin_dashboard.dart
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';

// class AdminDashboard extends StatefulWidget {
//   @override
//   _AdminDashboardState createState() => _AdminDashboardState();
// }

// class _AdminDashboardState extends State<AdminDashboard> {
//   int _selectedIndex = 0;
//   String _selectedFilter = 'Weekly';
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Color(0xFF43A047),
//         elevation: 0,
//         title: Text(
//           'Admin Dashboard',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.notifications_outlined, color: Colors.white),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: Icon(Icons.settings_outlined, color: Colors.white),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       drawer: _buildAdminDrawer(),
//       body: Column(
//         children: [
//           // Top stats cards
//           Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Color(0xFF43A047),
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(24),
//                 bottomRight: Radius.circular(24),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Overview',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Row(
//                   children: [
//                     _buildFilterOption('Daily', _selectedFilter == 'Daily'),
//                     SizedBox(width: 12),
//                     _buildFilterOption('Weekly', _selectedFilter == 'Weekly'),
//                     SizedBox(width: 12),
//                     _buildFilterOption('Monthly', _selectedFilter == 'Monthly'),
//                   ],
//                 ),
//                 SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _buildStatsCard('Total Users', '2,458', Icons.person_outline, Colors.orangeAccent),
//                     ),
//                     SizedBox(width: 16),
//                     Expanded(
//                       child: _buildStatsCard('Total Orders', '1,782', Icons.shopping_cart_outlined, Colors.blueAccent),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _buildStatsCard('Products', '354', Icons.inventory_2_outlined, Colors.purpleAccent),
//                     ),
//                     SizedBox(width: 16),
//                     Expanded(
//                       child: _buildStatsCard('Revenue', '\$15,782', Icons.attach_money, Colors.greenAccent),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
          
//           // Content sections
//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.all(16),
//               children: [
//                 // Recent users
//                 _buildSectionHeader('Recent Users', 'View All'),
//                 SizedBox(height: 12),
//                 _buildUsersList(),
//                 SizedBox(height: 24),
                
//                 // Recent orders
//                 _buildSectionHeader('Recent Orders', 'View All'),
//                 SizedBox(height: 12),
//                 _buildOrdersList(),
//                 SizedBox(height: 24),
                
//                 // Product analytics
//                 _buildSectionHeader('Product Analytics', 'Full Report'),
//                 SizedBox(height: 12),
//                 _buildProductAnalytics(),
//               ],
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });
//         },
//         selectedItemColor: Color(0xFF43A047),
//         unselectedItemColor: Colors.grey,
//         selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
//         type: BottomNavigationBarType.fixed,
//         items: [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.dashboard_outlined),
//             activeIcon: Icon(Icons.dashboard),
//             label: 'Dashboard',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.people_outline),
//             activeIcon: Icon(Icons.people),
//             label: 'Users',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.inventory_2_outlined),
//             activeIcon: Icon(Icons.inventory_2),
//             label: 'Products',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.bar_chart_outlined),
//             activeIcon: Icon(Icons.bar_chart),
//             label: 'Reports',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings_outlined),
//             activeIcon: Icon(Icons.settings),
//             label: 'Settings',
//           ),
//         ],
//       ),
//     );
//   }
  
//   Widget _buildAdminDrawer() {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           DrawerHeader(
//             decoration: BoxDecoration(
//               color: Color(0xFF43A047),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CircleAvatar(
//                   radius: 30,
//                   backgroundColor: Colors.white,
//                   child: Icon(
//                     Icons.person,
//                     size: 36,
//                     color: Color(0xFF43A047),
//                   ),
//                 ),
//                 SizedBox(height: 10),
//                 Text(
//                   'Admin User',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   'admin@example.com',
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           ListTile(
//             leading: Icon(Icons.dashboard, color: Color(0xFF43A047)),
//             title: Text('Dashboard'),
//             selected: true,
//             selectedTileColor: Colors.green.withOpacity(0.1),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.people, color: Colors.grey[700]),
//             title: Text('User Management'),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.inventory_2, color: Colors.grey[700]),
//             title: Text('Products'),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.shopping_cart, color: Colors.grey[700]),
//             title: Text('Orders'),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//           Divider(),
//           ListTile(
//             leading: Icon(Icons.analytics, color: Colors.grey[700]),
//             title: Text('Analytics'),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.report, color: Colors.grey[700]),
//             title: Text('Reports'),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//           Divider(),
//           ListTile(
//             leading: Icon(Icons.settings, color: Colors.grey[700]),
//             title: Text('Settings'),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//           ListTile(
//             leading: Icon(Icons.logout, color: Colors.red[400]),
//             title: Text('Logout', style: TextStyle(color: Colors.red[400])),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }
  
//   Widget _buildFilterOption(String title, bool isSelected) {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedFilter = title;
//         });
//       },
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Text(
//           title,
//           style: TextStyle(
//             color: isSelected ? Color(0xFF43A047) : Colors.white,
//             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.2),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               icon,
//               color: color,
//               size: 24,
//             ),
//           ),
//           SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title, String actionText) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.black87,
//           ),
//         ),
//         TextButton(
//           onPressed: () {},
//           child: Text(
//             actionText,
//             style: TextStyle(
//               color: Color(0xFF43A047),
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildUsersList() {
//     final List<Map<String, dynamic>> users = [
//       {
//         'name': 'John Doe',
//         'role': 'Customer',
//         'email': 'john.doe@example.com',
//         'image': 'assets/images/user1.jpg',
//         'status': 'Active',
//       },
//       {
//         'name': 'Sarah Johnson',
//         'role': 'Vendor',
//         'email': 'sarah.j@example.com',
//         'image': 'assets/images/user2.jpg',
//         'status': 'Active',
//       },
//       {
//         'name': 'Michael Smith',
//         'role': 'Customer',
//         'email': 'michael.s@example.com',
//         'image': 'assets/images/user3.jpg',
//         'status': 'Inactive',
//       },
//     ];

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: users.map((user) => _buildUserListItem(
//           user['name'],
//           user['role'],
//           user['email'],
//           user['image'],
//           user['status'],
//         )).toList(),
//       ),
//     );
//   }

//   Widget _buildUserListItem(String name, String role, String email, String imagePath, String status) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         border: Border(
//           bottom: BorderSide(
//             color: Colors.grey[200]!,
//             width: 1,
//           ),
//         ),
//       ),
//       child: Row(
//         children: [
//           // User Avatar
//           Container(
//             width: 50,
//             height: 50,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.grey[200],
//             ),
//             child: Center(
//               child: Icon(
//                 Icons.person,
//                 color: Colors.grey[500],
//               ),
//             ),
//           ),
//           SizedBox(width: 16),
//           // User Info
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   name,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   email,
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // User Role Tag
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: role == 'Customer' ? Colors.blue[50] : Colors.amber[50],
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               role,
//               style: TextStyle(
//                 color: role == 'Customer' ? Colors.blue[700] : Colors.amber[700],
//                 fontWeight: FontWeight.w500,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//           SizedBox(width: 12),
//           // Status Indicator
//           Container(
//             width: 12,
//             height: 12,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: status == 'Active' ? Colors.green : Colors.red[300],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrdersList() {
//     final List<Map<String, dynamic>> orders = [
//       {
//         'id': '#ORD-5782',
//         'customer': 'John Doe',
//         'date': '09 Apr 2025',
//         'amount': '\$145.80',
//         'status': 'Delivered',
//       },
//       {
//         'id': '#ORD-5781',
//         'customer': 'Sarah Johnson',
//         'date': '08 Apr 2025',
//         'amount': '\$289.50',
//         'status': 'Processing',
//       },
//       {
//         'id': '#ORD-5780',
//         'customer': 'Michael Smith',
//         'date': '07 Apr 2025',
//         'amount': '\$95.20',
//         'status': 'Shipped',
//       },
//     ];

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: orders.map((order) => _buildOrderListItem(
//           order['id'],
//           order['customer'],
//           order['date'],
//           order['amount'],
//           order['status'],
//         )).toList(),
//       ),
//     );
//   }

//   Widget _buildOrderListItem(String id, String customer, String date, String amount, String status) {
//     Color statusColor;
//     Color statusBgColor;
    
//     switch (status) {
//       case 'Delivered':
//         statusColor = Colors.green[700]!;
//         statusBgColor = Colors.green[50]!;
//         break;
//       case 'Processing':
//         statusColor = Colors.orange[700]!;
//         statusBgColor = Colors.orange[50]!;
//         break;
//       case 'Shipped':
//         statusColor = Colors.blue[700]!;
//         statusBgColor = Colors.blue[50]!;
//         break;
//       default:
//         statusColor = Colors.grey[700]!;
//         statusBgColor = Colors.grey[50]!;
//     }

//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         border: Border(
//           bottom: BorderSide(
//             color: Colors.grey[200]!,
//             width: 1,
//           ),
//         ),
//       ),
//       child: Row(
//         children: [
//           // Order Icon
//           Container(
//             width: 45,
//             height: 45,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.grey[100],
//             ),
//             child: Center(
//               child: Icon(
//                 Icons.shopping_bag_outlined,
//                 color: Color(0xFF43A047),
//               ),
//             ),
//           ),
//           SizedBox(width: 16),
//           // Order Info
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   id,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   customer,
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 14,
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   date,
//                   style: TextStyle(
//                     color: Colors.grey[500],
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Order Amount
//           Text(
//             amount,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//           SizedBox(width: 16),
//           // Status Tag
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: statusBgColor,
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               status,
//               style: TextStyle(
//                 color: statusColor,
//                 fontWeight: FontWeight.w500,
//                 fontSize: 12,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProductAnalytics() {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // Chart title
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Product Performance',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   _selectedFilter,
//                   style: TextStyle(
//                     color: Colors.grey[700],
//                     fontWeight: FontWeight.w500,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 16),
          
//           // Product performance chart
//           Container(
//             height: 200,
//             child: _buildBarChart(),
//           ),
          
//           SizedBox(height: 16),
          
//           // Performance indicators
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _buildPerformanceIndicator('Electronics', Colors.blue),
//               _buildPerformanceIndicator('Clothing', Colors.green),
//               _buildPerformanceIndicator('Home Goods', Colors.orange),
//               _buildPerformanceIndicator('Others', Colors.purple),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
  
//   Widget _buildBarChart() {
//     return BarChart(
//       BarChartData(
//         alignment: BarChartAlignment.spaceAround,
//         maxY: 20,
//         barTouchData: BarTouchData(
//           enabled: false,
//         ),
//         titlesData: FlTitlesData(
//           show: true,
//           bottomTitles: SideTitles(
//             showTitles: true,
//             getTextStyles: (context, value) => const TextStyle(
//               color: Color(0xff7589a2),
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//             margin: 10,
//             getTitles: (double value) {
//               switch(value.toInt()) {
//                 case 0: return 'Mon';
//                 case 1: return 'Tue';
//                 case 2: return 'Wed';
//                 case 3: return 'Thu';
//                 case 4: return 'Fri';
//                 case 5: return 'Sat';
//                 case 6: return 'Sun';
//                 default: return '';
//               }
//             },
//           ),
//           leftTitles: SideTitles(
//             showTitles: true,
//             getTextStyles: (context, value) => const TextStyle(
//               color: Color(0xff7589a2),
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//             margin: 10,
//             reservedSize: 30,
//             getTitles: (value) {
//               if (value == 0) return '0';
//               if (value == 5) return '5K';
//               if (value == 10) return '10K';
//               if (value == 15) return '15K';
//               if (value == 20) return '20K';
//               return '';
//             },
//           ),
//           rightTitles: SideTitles(showTitles: false),
//           topTitles: SideTitles(showTitles: false),
//         ),
//         borderData: FlBorderData(
//           show: false,
//         ),
//         barGroups: [
//           _makeGroupData(0, 12, 5, 8, 3),
//           _makeGroupData(1, 8, 12, 7, 5),
//           _makeGroupData(2, 15, 10, 9, 4),
//           _makeGroupData(3, 10, 14, 6, 7),
//           _makeGroupData(4, 14, 8, 12, 9),
//           _makeGroupData(5, 17, 15, 10, 11),
//           _makeGroupData(6, 13, 10, 9, 8),
//         ],
//         gridData: FlGridData(
//           show: true,
//           checkToShowHorizontalLine: (value) => value % 5 == 0,
//           getDrawingHorizontalLine: (value) {
//             return FlLine(
//               color: Colors.grey[300],
//               strokeWidth: 1,
//             );
//           },
//         ),
//       ),
//     );
//   }

//   BarChartGroupData _makeGroupData(int x, double electronics, double clothing, double homeGoods, double others) {
//     return BarChartGroupData(
//       x: x,
//       barRods: [
//         BarChartRodData(
//           y: electronics,
//           colors: [Colors.blue],
//           width: 5,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(6),
//             topRight: Radius.circular(6),
//           ),
//         ),
//         BarChartRodData(
//           y: clothing,
//           colors: [Colors.green],
//           width: 5,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(6),
//             topRight: Radius.circular(6),
//           ),
//         ),
//         BarChartRodData(
//           y: homeGoods,
//           colors: [Colors.orange],
//           width: 5,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(6),
//             topRight: Radius.circular(6),
//           ),
//         ),
//         BarChartRodData(
//           y: others,
//           colors: [Colors.purple],
//           width: 5,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(6),
//             topRight: Radius.circular(6),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPerformanceIndicator(String category, Color color) {
//     return Row(
//       children: [
//         Container(
//           width: 12,
//           height: 12,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: color,
//           ),
//         ),
//         SizedBox(width: 4),
//         Text(
//           category,
//           style: TextStyle(
//             color: Colors.grey[700],
//             fontSize: 12,
//           ),
//         ),
//       ],
//     );
//   }
// }