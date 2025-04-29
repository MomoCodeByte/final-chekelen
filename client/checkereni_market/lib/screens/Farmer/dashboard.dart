import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './Files/chat_screen.dart';
import './Files/crop_management_screen.dart';
import './Files/order_management_screen.dart';
import './Files/reports_screen.dart';
import './Files/transaction_screen.dart';
import './Files/dashboard_screen.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  _FarmerDashboardState createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  String activeTab = 'dashboard';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  DateTime? _lastBackPressTime;

  final List<Map<String, dynamic>> menuItems = [
    {'id': 'dashboard', 'label': 'Dashboard', 'icon': Feather.home},
    {'id': 'crops', 'label': 'Manage Crops', 'icon': Feather.sun},
    {'id': 'orders', 'label': 'View Orders', 'icon': Feather.shopping_cart},
    {
      'id': 'transactions',
      'label': 'Transactions',
      'icon': Feather.credit_card,
    },
    {
      'id': 'communications',
      'label': 'Live Chat',
      'icon': Feather.message_circle,
    },
    {'id': 'reports', 'label': 'Reports', 'icon': Feather.file_text},
    {'id': 'logout', 'label': 'Logout', 'icon': Feather.log_out},
  ];

  Future<bool> _confirmExit() async {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Press back again to logout')),
      );
      return false;
    }
    return true;
  }

  Future<void> _performLogout() async {
    try {
      debugPrint('Deleting farmer token...');
      await _storage.delete(key: 'jwt_token');
      debugPrint('Farmer token deleted');

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/welcome', (Route<dynamic> route) => false);
      }
    } catch (e) {
      debugPrint('Farmer logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  void _navigateToScreen(String tabId) async {
    // Close drawer on mobile after selection
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }

    if (tabId == 'logout') {
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Confirm Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Logout'),
                ),
              ],
            ),
      );
      if (confirm == true) await _performLogout();
    } else {
      setState(() => activeTab = tabId);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 768;

    return WillPopScope(
      onWillPop: () async {
        // Handle drawer first
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.of(context).pop();
          return false;
        }

        // Then handle back button
        if (await _confirmExit()) {
          await _performLogout();
          return true;
        }
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: isSmallScreen ? _buildDrawer(context) : null,
        body:
            isSmallScreen
                ? _getScreen()
                : Row(
                  children: [
                    _buildSidebar(context),
                    Expanded(child: _getScreen()),
                  ],
                ),
        bottomNavigationBar: isSmallScreen ? _buildBottomNav() : null,
      ),
    );
  }

  Widget? _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: Colors.green[800],
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white.withOpacity(0.6),
      currentIndex: _getNavIndex(),
      onTap: (index) => _navigateToScreen(menuItems[index]['id']),
      items:
          menuItems
              .take(5)
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item['icon']),
                  label: item['label'],
                  backgroundColor: Colors.green[800],
                ),
              )
              .toList(),
    );
  }

  int _getNavIndex() {
    final index = menuItems.indexWhere((item) => item['id'] == activeTab);
    return (index >= 0 && index < 5) ? index : 0;
  }

  Widget _getScreen() {
    switch (activeTab) {
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
                        'Farmer Panel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Chekereni Market Panel',
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
          const SizedBox(height: 40),
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.green[800]!),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(Feather.user, color: Colors.green[800], size: 30),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Farmer Dashboard',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
          ...menuItems.map(
            (item) => ListTile(
              leading: Icon(item['icon']),
              title: Text(item['label']),
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen(item['id']);
              },
            ),
          ),
        ],
      ),
    );
  }
}
