import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import screens from the files directory
import './files/dashboard_screen.dart';
import './files/user_management_screen.dart'; 
import './files/crop_management_screen.dart';
import './files/order_management_screen.dart';
import './files/transaction_screen.dart';
import './files/chat_screen.dart';
import './files/reports_screen.dart';
import './files/settings_screen.dart';
// import './files/notifications_screen.dart';

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
      'description': 'View overall statistics and performance metrics'
    },
    {
      'id': 'users',
      'label': 'User Management',
      'icon': Feather.users,
      'description': 'Manage customers, farmers, and administrators'
    },
    {
      'id': 'crops',
      'label': 'Crop Management',
      'icon': Feather.sun,
      'description': 'Monitor and manage available crops and inventory'
    },
    {
      'id': 'orders',
      'label': 'Order Management',
      'icon': Feather.shopping_cart,
      'description': 'Track and process customer orders'
    },
    {
      'id': 'transactions',
      'label': 'Transactions',
      'icon': Feather.credit_card,
      'description': 'View and manage financial transactions'
    },
    {
      'id': 'communications',
      'label': 'Chat System',
      'icon': Feather.message_square,
      'description': 'Monitor user communications and support'
    },
    {
      'id': 'reports',
      'label': 'Reports & Analytics',
      'icon': Feather.file_text,
      'description': 'Generate and view system reports'
    },
    {
      'id': 'settings',
      'label': 'System Settings',
      'icon': Feather.settings,
      'description': 'Configure system parameters and preferences'
    },
    {
      'id': 'logout',
      'label': 'Logout',
      'icon': Feather.log_out,
      'description': 'Sign out from the admin panel'
    },
  ];

void _navigateToScreen(String screenId) async {
  setState(() {
    activeTab = screenId;
    if (!(MediaQuery.of(context).size.width >= 1024)) {
      isMobileMenuOpen = false; // Close drawer on mobile after selection
    }
  });

  if (screenId == 'logout') {
    // Handle logout logic here
    final _storage = FlutterSecureStorage();

    // Delete the token from secure storage
    await _storage.delete(key: 'jwt_token');
    print('Token deleted successfully.');

    // Navigate the user back to the login screen
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

  Widget _buildMenuItem(Map<String, dynamic> item) {
    final isActive = activeTab == item['id'];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToScreen(item['id']),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: isActive ? Colors.white : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                item['icon'],
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['label'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (item['description'] != null)
                      Text(
                        item['description'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (isActive)
                Icon(
                  Feather.chevron_right,
                  color: Colors.white,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop || isMobileMenuOpen)
            Container(
              width: 280,
              color: Colors.green[800],
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green[900],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Feather.shield,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Panel',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Farm Management System',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.7),
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: menuItems.length,
                      itemBuilder: (context, index) {
                        final item = menuItems[index];
                        return _buildMenuItem(item);
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[900],
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            Feather.user,
                            color: Colors.green[800],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin User',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'admin_panel',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Feather.log_out,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                          onPressed: () => _navigateToScreen('logout'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Container(
              color: Colors.green[50],
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (!isDesktop)
                          IconButton(
                            icon: Icon(
                              isMobileMenuOpen ? Feather.x : Feather.menu,
                              color: Colors.green[700],
                            ),
                            onPressed: () {
                              setState(() {
                                isMobileMenuOpen = !isMobileMenuOpen;
                              });
                            },
                          ),
                        Expanded(
                          child: Text(
                            menuItems.firstWhere((item) => item['id'] == activeTab)['label'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Feather.bell, color: Colors.green[700]),
                              onPressed: () {
                                // TODO: Show notifications
                              },
                            ),
                            IconButton(
                              icon: Icon(Feather.help_circle, color: Colors.green[700]),
                              onPressed: () {
                                // TODO: Show help/documentation
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _getScreen(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // TODO: Initialize API calls here
  }
}
