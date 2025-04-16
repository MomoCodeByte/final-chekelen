import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class FarmerDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farmer Dashboard'),
        backgroundColor: Color(0xFF43A047),

      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to the Farmer Dashboard!',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement logout logic here
                Navigator.pop(context); // Navigate back to login
              },
              child: Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}




// class SubAdminDashboard extends StatefulWidget {
//   const SubAdminDashboard({super.key});
//   @override
//   State<SubAdminDashboard> createState() => _SubAdminDashboardState();
// }

// class _SubAdminDashboardState extends State<SubAdminDashboard> {
  // String activeTab = 'dashboard';
  // bool isMobileMenuOpen = false;
  
  // // Reduced menu items for subadmin access level
  // final List<Map<String, dynamic>> menuItems = [
  //   {'id': 'dashboard', 'label': 'Dashboard', 'icon': Feather.bar_chart_2},
  //   {'id': 'users', 'label': 'Users', 'icon': Feather.users},
  //   {'id': 'crops', 'label': 'Crops', 'icon': Feather.sun},
  //   {'id': 'orders', 'label': 'Orders', 'icon': Feather.shopping_cart},
  //   {'id': 'reports', 'label': 'Reports', 'icon': Feather.file_text},
  // ];

  // // Simplified stats for subadmin view
  // final List<Map<String, String>> stats = [
  //   {'label': 'Active Users', 'value': '876'},
  //   {'label': 'Current Crops', 'value': '34'},
  // ];

  // // Recent activities for subadmin to monitor
  // final List<Map<String, dynamic>> recentActivities = [
  //   {
  //     'id': 1,
  //     'user': 'John Doe',
  //     'action': 'Placed an order',
  //     'time': '2 hours ago',
  //     'type': 'order'
  //   },
  //   {
  //     'id': 2,
  //     'user': 'Jane Smith',
  //     'action': 'Updated crop status',
  //     'time': '4 hours ago',
  //     'type': 'crop'
  //   },
  //   {
  //     'id': 3,
  //     'user': 'Mike Johnson',
  //     'action': 'Submitted support ticket',
  //     'time': 'Yesterday',
  //     'type': 'support'
  //   },
  // ];

  // @override
  // Widget build(BuildContext context) {
  //   final isDesktop = MediaQuery.of(context).size.width >= 1024;
    
  //   return Scaffold(
  //     backgroundColor: const Color(0xFFF0F7F2), // lighter green background
  //     body: Row(
  //       children: [
  //         // Sidebar with reduced width
  //         if (isDesktop || isMobileMenuOpen)
  //           Container(
  //             width: 220, // slightly narrower than admin dashboard
  //             color: const Color(0xFF166534), // dark green
  //             child: Column(
  //               children: [
  //                 Padding(
  //                   padding: const EdgeInsets.all(16),
  //                   child: Row(
  //                     children: [
  //                       Text(
  //                         'SubAdmin',
  //                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //                           color: Colors.white,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //                 Expanded(
  //                   child: ListView(
  //                     children: menuItems.map((item) => _buildMenuItem(item)).toList(),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
          
  //         // Main Content Area
  //         Expanded(
  //           child: Column(
  //             children: [
  //               // Top Bar - simplified
  //               Container(
  //                 padding: const EdgeInsets.all(12),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Colors.black.withOpacity(0.05),
  //                       blurRadius: 2,
  //                     ),
  //                   ],
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     if (!isDesktop)
  //                       IconButton(
  //                         icon: Icon(
  //                           isMobileMenuOpen ? Feather.x : Feather.menu,
  //                         ),
  //                         onPressed: () {
  //                           setState(() {
  //                             isMobileMenuOpen = !isMobileMenuOpen;
  //                           });
  //                         },
  //                       ),
  //                     const Expanded(
  //                       child: Text(
  //                         'SubAdmin Panel',
  //                         style: TextStyle(
  //                           fontSize: 18,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                       ),
  //                     ),
  //                     CircleAvatar(
  //                       backgroundColor: const Color(0xFF166534),
  //                       radius: 16,
  //                       child: const Text(
  //                         'SA',
  //                         style: TextStyle(color: Colors.white, fontSize: 12),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
                
  //               // Dashboard Content - streamlined
  //               Expanded(
  //                 child: SingleChildScrollView(
  //                   padding: const EdgeInsets.all(16),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       // Welcome message
  //                       Container(
  //                         padding: const EdgeInsets.all(16),
  //                         decoration: BoxDecoration(
  //                           color: Colors.white,
  //                           borderRadius: BorderRadius.circular(8),
  //                           boxShadow: [
  //                             BoxShadow(
  //                               color: Colors.black.withOpacity(0.05),
  //                               blurRadius: 2,
  //                             ),
  //                           ],
  //                         ),
  //                         child: const Row(
  //                           children: [
  //                             Icon(Feather.alert_circle, color: Color(0xFF166534)),
  //                             SizedBox(width: 12),
  //                             Expanded(
  //                               child: Text(
  //                                 'Welcome to the SubAdmin Dashboard. You have limited admin privileges.',
  //                                 style: TextStyle(fontSize: 14),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
                        
  //                       const SizedBox(height: 16),
                        
  //                       // Stats Row - simplified to a row instead of grid
  //                       Row(
  //                         children: stats.map((stat) => Expanded(
  //                           child: Padding(
  //                             padding: const EdgeInsets.symmetric(horizontal: 8),
  //                             child: _buildStatCard(stat),
  //                           ),
  //                         )).toList(),
  //                       ),
                        
  //                       const SizedBox(height: 16),
                        
  //                       // Recent Activities
  //                       Container(
  //                         padding: const EdgeInsets.all(16),
  //                         decoration: BoxDecoration(
  //                           color: Colors.white,
  //                           borderRadius: BorderRadius.circular(8),
  //                           boxShadow: [
  //                             BoxShadow(
  //                               color: Colors.black.withOpacity(0.05),
  //                               blurRadius: 2,
  //                             ),
  //                           ],
  //                         ),
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             const Text(
  //                               'Recent Activities',
  //                               style: TextStyle(
  //                                 fontSize: 16,
  //                                 fontWeight: FontWeight.w600,
  //                               ),
  //                             ),
  //                             const SizedBox(height: 12),
  //                             ...recentActivities.map((activity) => _buildActivityItem(activity)),
  //                           ],
  //                         ),
  //                       ),
                        
  //                       const SizedBox(height: 16),
                        
  //                       // Quick Actions
  //                       Container(
  //                         padding: const EdgeInsets.all(16),
  //                         decoration: BoxDecoration(
  //                           color: Colors.white,
  //                           borderRadius: BorderRadius.circular(8),
  //                           boxShadow: [
  //                             BoxShadow(
  //                               color: Colors.black.withOpacity(0.05),
  //                               blurRadius: 2,
  //                             ),
  //                           ],
  //                         ),
  //                         child: Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             const Text(
  //                               'Quick Actions',
  //                               style: TextStyle(
  //                                 fontSize: 16,
  //                                 fontWeight: FontWeight.w600,
  //                               ),
  //                             ),
  //                             const SizedBox(height: 12),
  //                             Row(
  //                               mainAxisAlignment: MainAxisAlignment.spaceAround,
  //                               children: [
  //                                 _buildQuickAction('View Users', Feather.users, () {}),
  //                                 _buildQuickAction('Crop Status', Feather.sun, () {}),
  //                                 _buildQuickAction('Generate Report', Feather.file_text, () {}),
  //                               ],
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildMenuItem(Map<String, dynamic> item) {
  //   final isActive = activeTab == item['id'];
  //   return Material(
  //     color: Colors.transparent,
  //     child: InkWell(
  //       onTap: () {
  //         setState(() {
  //           activeTab = item['id'];
  //           if (MediaQuery.of(context).size.width < 1024) {
  //             isMobileMenuOpen = false;
  //           }
  //         });
  //       },
  //       child: Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //         color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
  //         child: Row(
  //           children: [
  //             Icon(
  //               item['icon'],
  //               color: Colors.white,
  //               size: 18,
  //             ),
  //             const SizedBox(width: 8),
  //             Text(
  //               item['label'],
  //               style: const TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 14,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildStatCard(Map<String, String> stat) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(8),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.1),
  //           blurRadius: 2,
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           stat['label'] ?? '',
  //           style: TextStyle(
  //             color: Colors.grey[600],
  //             fontSize: 12,
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //         const SizedBox(height: 6),
  //         Text(
  //           stat['value'] ?? '',
  //           style: const TextStyle(
  //             fontSize: 20,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildActivityItem(Map<String, dynamic> activity) {
  //   IconData activityIcon;
  //   Color iconColor;
    
  //   switch (activity['type']) {
  //     case 'order':
  //       activityIcon = Feather.shopping_cart;
  //       iconColor = Colors.blue;
  //       break;
  //     case 'crop':
  //       activityIcon = Feather.sun;
  //       iconColor = Colors.green;
  //       break;
  //     case 'support':
  //       activityIcon = Feather.help_circle;
  //       iconColor = Colors.orange;
  //       break;
  //     default:
  //       activityIcon = Feather.activity;
  //       iconColor = Colors.grey;
  //   }
    
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8),
  //     child: Row(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(8),
  //           decoration: BoxDecoration(
  //             color: iconColor.withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Icon(activityIcon, color: iconColor, size: 16),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 activity['user'] ?? '',
  //                 style: const TextStyle(
  //                   fontWeight: FontWeight.w500,
  //                   fontSize: 14,
  //                 ),
  //               ),
  //               Text(
  //                 activity['action'] ?? '',
  //                 style: TextStyle(
  //                   color: Colors.grey[600],
  //                   fontSize: 12,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         Text(
  //           activity['time'] ?? '',
  //           style: TextStyle(
  //             color: Colors.grey[500],
  //             fontSize: 12,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap) {
  //   return InkWell(
  //     onTap: onTap,
  //     child: Column(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: const Color(0xFF166534).withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Icon(icon, color: const Color(0xFF166534), size: 20),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           label,
  //           style: const TextStyle(fontSize: 12),
  //         ),
  //       ],
  //     ),
  //   );
  // }
// }