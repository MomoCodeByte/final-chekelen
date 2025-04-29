import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './files/dashboard_screen.dart';
import './files/user_management_screen.dart';
import './files/order_management_screen.dart';
import './files/transaction_screen.dart';
import './files/chat_screen.dart';
import './files/reports_screen.dart';
import './files/settings_screen.dart';
import './files/crop_management_screen.dart';
import 'files/businessReportsScreen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String activeTab = 'dashboard';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  DateTime? _lastBackPressTime;

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
    {
      'id': 'business_report',
      'label': 'Business Report',
      'icon': Feather.trending_up,
    },
    {'id': 'settings', 'label': 'System Settings', 'icon': Feather.settings},
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
      debugPrint('Deleting admin token...');
      await _storage.delete(key: 'jwt_token');
      debugPrint('Admin token deleted');

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/welcome', (Route<dynamic> route) => false);
      }
    } catch (e) {
      debugPrint('Admin logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  void _navigateToScreen(String screenId) async {
    // Close drawer on mobile after selection
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }

    if (screenId == 'logout') {
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Confirm Admin Logout'),
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
      setState(() => activeTab = screenId);
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
      case 'business_report':
        return const BusinessReportsScreen();
      case 'settings':
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  Widget _buildSidebar(BuildContext context, bool isMobile) {
    return Container(
      width: isMobile ? null : 260,
      color: Colors.green[800],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            color: Colors.green[900],
            child: Row(
              children: [
                Icon(Feather.shield, color: Colors.white, size: 28),
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
                          fontSize: isMobile ? 16 : 18,
                        ),
                      ),
                      Text(
                        'Chekeren Market Panel',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMobile)
                  IconButton(
                    icon: Icon(Feather.x, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
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

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      dense: isMobile,
                      horizontalTitleGap: 8,
                      leading: Icon(
                        item['icon'],
                        color: Colors.white,
                        size: isMobile ? 20 : 24,
                      ),
                      title: Text(
                        item['label'],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 14 : 16,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      tileColor:
                          isActive ? Colors.green[700] : Colors.transparent,
                      onTap: () => _navigateToScreen(item['id']),
                    ),
                    if (isMobile &&
                        [
                          'dashboard',
                          'reports',
                          'settings',
                        ].contains(item['id']))
                      Divider(height: 1, color: Colors.green[600]),
                  ],
                );
              },
            ),
          ),

          if (isMobile)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              color: Colors.green[900],
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 16,
                    child: Icon(
                      Feather.user,
                      color: Colors.green[900],
                      size: 18,
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
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'admin@chekeren.com',
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
        ],
      ),
    );
  }

  Widget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: Colors.green[800],
      elevation: 0,
      title: Text(
        menuItems.firstWhere((item) => item['id'] == activeTab)['label'],
        style: TextStyle(fontSize: 18),
      ),
      leading: IconButton(
        icon: Icon(Feather.menu),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Feather.bell),
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Notifications')));
          },
        ),
        PopupMenuButton(
          icon: Icon(Feather.more_vertical),
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        Feather.help_circle,
                        color: Colors.green[800],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text('Help'),
                    ],
                  ),
                  onTap: () {},
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Feather.user, color: Colors.green[800], size: 18),
                      const SizedBox(width: 8),
                      const Text('Profile'),
                    ],
                  ),
                  onTap: () {},
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Feather.log_out, color: Colors.green[800], size: 18),
                      const SizedBox(width: 8),
                      const Text('Logout'),
                    ],
                  ),
                  onTap: () => _navigateToScreen('logout'),
                ),
              ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.green[600], height: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

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
        appBar: isDesktop ? null : _buildMobileAppBar() as PreferredSizeWidget,
        drawer:
            isDesktop
                ? null
                : Drawer(
                  width: isTablet ? 300 : 280,
                  child: _buildSidebar(context, true),
                ),
        body: SafeArea(
          child: Row(
            children: [
              if (isDesktop) _buildSidebar(context, false),
              Expanded(
                child: Container(
                  color: Colors.green[50],
                  child: Column(
                    children: [
                      if (isDesktop)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          color: Colors.white,
                          child: Row(
                            children: [
                              Text(
                                menuItems.firstWhere(
                                  (item) => item['id'] == activeTab,
                                )['label'],
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Feather.bell),
                                color: Colors.green[800],
                                onPressed: () {},
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Feather.help_circle),
                                color: Colors.green[800],
                                onPressed: () {},
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: Colors.green[100],
                                child: Icon(
                                  Feather.user,
                                  color: Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(child: _getScreen()),
                      if (!isDesktop)
                        Container(
                          height: isTablet ? 0 : 56,
                          color: Colors.white,
                          child:
                              isTablet
                                  ? null
                                  : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildBottomNavItem(
                                        'dashboard',
                                        Feather.home,
                                      ),
                                      _buildBottomNavItem(
                                        'users',
                                        Feather.users,
                                      ),
                                      _buildBottomNavItem(
                                        'orders',
                                        Feather.shopping_cart,
                                      ),
                                      _buildBottomNavItem(
                                        'settings',
                                        Feather.settings,
                                      ),
                                    ],
                                  ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(String id, IconData icon) {
    final isActive = activeTab == id;
    return InkWell(
      onTap: () => _navigateToScreen(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.green[800] : Colors.grey[600],
              size: 22,
            ),
            const SizedBox(height: 4),
            Container(
              height: 3,
              width: 24,
              decoration: BoxDecoration(
                color: isActive ? Colors.green[800] : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
