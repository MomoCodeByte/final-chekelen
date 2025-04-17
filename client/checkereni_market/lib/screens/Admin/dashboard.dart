import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import './files/dashboard_screen.dart';
import './files/user_management_screen.dart';
import './files/crop_management_screen.dart';
import './files/order_management_screen.dart';
import './files/transaction_screen.dart';
import './files/chat_screen.dart';
import './files/reports_screen.dart';
import './files/settings_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String activeTab = 'dashboard';
  bool isMobileMenuOpen = false;

  final List<Map<String, dynamic>> menuItems = [
    {
      'id': 'dashboard',
      'label': 'Dashboard Overview',
      'icon': Feather.bar_chart_2,
    },
    {'id': 'users', 'label': 'User Management', 'icon': Feather.users},
    {'id': 'crops', 'label': 'Crop Management', 'icon': Feather.sun},
    {
      'id': 'orders',
      'label': 'Order Management',
      'icon': Feather.shopping_cart,
    },
    {
      'id': 'transactions',
      'label': 'Transactions',
      'icon': Feather.credit_card,
    },
    {
      'id': 'communications',
      'label': 'Chat System',
      'icon': Feather.message_square,
    },
    {
      'id': 'reports',
      'label': 'Reports & Analytics',
      'icon': Feather.file_text,
    },
    {'id': 'settings', 'label': 'System Settings', 'icon': Feather.settings},
    {'id': 'logout', 'label': 'Logout', 'icon': Feather.log_out},
  ];

  void _navigateToScreen(String screenId) async {
    setState(() {
      activeTab = screenId;
      isMobileMenuOpen = false;
    });

    if (screenId == 'logout') {
      final _storage = FlutterSecureStorage();
      await _storage.delete(key: 'jwt_token');
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  Widget _getScreen() {
    switch (activeTab) {
      case 'dashboard':
        return const DashboardScreen();
      case 'users':
        return const UserManagementScreen();
      case 'crops':
        return const CropManagementScreen();
      case 'orders':
        return const OrderManagementScreen();
      case 'transactions':
        return const TransactionScreen();
      case 'communications':
        return const ChatScreen();
      case 'reports':
        return const ReportsScreen();
      case 'settings':
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.green[800],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.green[900],
            child: Row(
              children: [
                Icon(Feather.shield, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Farm System',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isActive = activeTab == item['id'];
                return ListTile(
                  leading: Icon(item['icon'], color: Colors.white),
                  title: Text(
                    item['label'],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  tileColor: isActive ? Colors.green[700] : Colors.transparent,
                  onTap: () => _navigateToScreen(item['id']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar:
          isDesktop
              ? null
              : AppBar(
                backgroundColor: Colors.green[800],
                title: Text(
                  menuItems.firstWhere(
                    (item) => item['id'] == activeTab,
                  )['label'],
                ),
                leading: IconButton(
                  icon: Icon(isMobileMenuOpen ? Feather.x : Feather.menu),
                  onPressed: () {
                    setState(() {
                      isMobileMenuOpen = !isMobileMenuOpen;
                    });
                  },
                ),
                actions: [
                  IconButton(icon: const Icon(Feather.bell), onPressed: () {}),
                  IconButton(
                    icon: const Icon(Feather.help_circle),
                    onPressed: () {},
                  ),
                ],
              ),
      drawer:
          isDesktop
              ? null
              : (isMobileMenuOpen
                  ? Drawer(child: _buildSidebar(context))
                  : null),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context),
          Expanded(
            child: Container(color: Colors.green[50], child: _getScreen()),
          ),
        ],
      ),
    );
  }
}
