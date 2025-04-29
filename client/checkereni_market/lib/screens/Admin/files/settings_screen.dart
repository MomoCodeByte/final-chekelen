import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  // List to hold settings data
  List<dynamic> settings = [];
  bool isLoading = true;

  // TextEditingControllers for input fields
  final TextEditingController _settingNameController = TextEditingController();
  final TextEditingController _settingValueController = TextEditingController();

  String? _selectedSettingId; // To store the selected setting ID for updates

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> filteredSettings = [];

  // Animation controller
  late AnimationController _animationController;

  // Theme colors
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF81C784);
  final Color darkGreen = const Color(0xFF1B5E20);
  final Color backgroundWhite = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _fetchSettings(); // Fetch settings when the screen initializes

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _searchController.addListener(_filterSettings);
  }

  @override
  void dispose() {
    _settingNameController.dispose();
    _settingValueController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Filter settings based on search query
  void _filterSettings() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredSettings = List.from(settings);
      } else {
        filteredSettings =
            settings.where((setting) {
              return setting['setting_name'].toString().toLowerCase().contains(
                    query,
                  ) ||
                  setting['setting_value'].toString().toLowerCase().contains(
                    query,
                  );
            }).toList();
      }
    });
  }

  // Fetch all settings from the API
  Future<void> _fetchSettings() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/settings'),
      );
      if (response.statusCode == 200) {
        setState(() {
          settings = json.decode(
            response.body,
          ); // Decode and store the settings data
          filteredSettings = List.from(settings);
          isLoading = false;
        });
      } else {
        _showError('Failed to load settings'); // Show error if fetching fails
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _showError('Network error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Create a new setting
  Future<void> _createSetting() async {
    if (_settingNameController.text.isEmpty ||
        _settingValueController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/settings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'admin_id': '1', // Replace with actual admin ID
          'setting_name': _settingNameController.text,
          'setting_value': _settingValueController.text,
        }),
      );

      if (response.statusCode == 201) {
        _fetchSettings(); // Refresh the list of settings
        _clearFields(); // Clear input fields after successful creation
        _showSuccess('Setting created successfully!'); // Show success message
      } else {
        _showError(
          'Failed to create setting: ${response.body}',
        ); // Show error if creation fails
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  // Update an existing setting
  Future<void> _updateSetting(String id) async {
    if (_settingNameController.text.isEmpty ||
        _settingValueController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/api/settings/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'admin_id': '1', // Replace with actual admin ID
          'setting_name': _settingNameController.text,
          'setting_value': _settingValueController.text,
        }),
      );

      if (response.statusCode == 200) {
        _fetchSettings(); // Refresh the list of settings
        _clearFields(); // Clear input fields after successful update
        _showSuccess('Setting updated successfully!'); // Show success message
      } else {
        _showError(
          'Failed to update setting: ${response.body}',
        ); // Show error if update fails
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  // Delete an existing setting
  Future<void> _deleteSetting(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/api/settings/$id'),
      );
      if (response.statusCode == 200) {
        _fetchSettings(); // Refresh the list of settings
        _showSuccess('Setting deleted successfully!'); // Show success message
      } else {
        _showError(
          'Failed to delete setting: ${response.body}',
        ); // Show error if deletion fails
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  // Clear input fields
  void _clearFields() {
    _settingNameController.clear();
    _settingValueController.clear();
    setState(() {
      _selectedSettingId = null; // Reset selected setting ID
    });
  }

  // Show error messages
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show success messages
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show the form for creating or updating a setting
  void _showForm(BuildContext context) {
    final isUpdating = _selectedSettingId != null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FadeIn(
          duration: const Duration(milliseconds: 300),
          child: AlertDialog(
            title: Row(
              children: [
                Icon(
                  isUpdating ? Icons.edit : Icons.add_circle_outline,
                  color: primaryGreen,
                ),
                const SizedBox(width: 10),
                Text(
                  isUpdating ? 'Update Setting' : 'Create Setting',
                  style: TextStyle(color: darkGreen),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: backgroundWhite,
            content: SingleChildScrollView(
              child: Container(
                width:
                    MediaQuery.of(context).size.width > 600
                        ? 400
                        : MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _settingNameController,
                      decoration: InputDecoration(
                        labelText: 'Setting Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: lightGreen),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: primaryGreen, width: 2),
                        ),
                        prefixIcon: Icon(Icons.settings, color: primaryGreen),
                        labelStyle: TextStyle(color: darkGreen),
                      ),
                    ).animate().fade().slideY(
                      begin: 0.5,
                      end: 0,
                      duration: const Duration(milliseconds: 300),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                          controller: _settingValueController,
                          decoration: InputDecoration(
                            labelText: 'Setting Value',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: lightGreen),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: primaryGreen,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(Icons.tune, color: primaryGreen),
                            labelStyle: TextStyle(color: darkGreen),
                          ),
                        )
                        .animate()
                        .fade(delay: const Duration(milliseconds: 100))
                        .slideY(
                          begin: 0.5,
                          end: 0,
                          duration: const Duration(milliseconds: 300),
                        ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _clearFields();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_selectedSettingId == null) {
                    _createSetting(); // Create new setting if no ID is selected
                  } else {
                    _updateSetting(
                      _selectedSettingId!,
                    ); // Update existing setting
                  }
                  Navigator.of(context).pop(); // Close the dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: Text(isUpdating ? 'Update' : 'Create'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show confirmation dialog before deleting
  void _showDeleteConfirmation(String id, String settingName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ZoomIn(
          duration: const Duration(milliseconds: 300),
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text('Confirm Deletion'),
              ],
            ),
            content: Text(
              'Are you sure you want to delete the setting "$settingName"?',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _deleteSetting(id);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.settings, color: primaryGreen),
            const SizedBox(width: 8),
            const Text(
              'Settings Management',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSettings,
            tooltip: 'Refresh Settings',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _clearFields(); // Clear fields for new setting
              _showForm(context); // Show the settings form
            },
            tooltip: 'Add New Setting',
          ),
        ],
      ),
      body: Column(
        children: [
          // Gradient header section
          Container(
            decoration: BoxDecoration(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // part of serch bar
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white, // White background like the image
                    borderRadius: BorderRadius.circular(12), // Smooth corners
                  ),
                  child: Column(
                    children: [
                      // Hapa ndani unaweka ile Search Bar yetu tuliyotengeneza
                      FadeInDown(
                        delay: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFECFDF5,
                            ), // Light green background
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search users...',
                              hintStyle: TextStyle(color: Colors.grey.shade600),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.green.shade700,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats or summary section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.settings,
                        label: 'Total Settings',
                        value: settings.length.toString(),
                      ),
                      _buildStatItem(
                        icon: Icons.date_range,
                        label: 'Last Updated',
                        value: DateFormat(
                          'MMM dd, yyyy',
                        ).format(DateTime.now()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Settings list
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                      ),
                    )
                    : filteredSettings.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchController.text.isNotEmpty
                                ? Icons.search_off
                                : Icons.settings,
                            size: 70,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'No settings match your search'
                                : 'No settings found',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _fetchSettings,
                      color: primaryGreen,
                      child: ListView.builder(
                        itemCount: filteredSettings.length,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        itemBuilder: (context, index) {
                          final setting = filteredSettings[index];

                          return FadeInUp(
                            delay: Duration(milliseconds: 100 * index % 500),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Slidable(
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (_) {
                                        _settingNameController.text =
                                            setting['setting_name'];
                                        _settingValueController.text =
                                            setting['setting_value'];
                                        setState(() {
                                          _selectedSettingId =
                                              setting['setting_id'].toString();
                                        });
                                        _showForm(context);
                                      },
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      icon: Icons.edit,
                                      label: 'Edit',
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                    ),
                                    SlidableAction(
                                      onPressed: (_) {
                                        _showDeleteConfirmation(
                                          setting['setting_id'].toString(),
                                          setting['setting_name'],
                                        );
                                      },
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete,
                                      label: 'Delete',
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                  ],
                                ),
                                child: Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: lightGreen.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.settings,
                                        color: primaryGreen,
                                        size: 24,
                                      ),
                                    ),
                                    title: Text(
                                      setting['setting_name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Value: ${setting['setting_value']}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'ID: ${setting['setting_id']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing:
                                        isSmallScreen
                                            ? null
                                            : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.blue,
                                                  ),
                                                  onPressed: () {
                                                    _settingNameController
                                                            .text =
                                                        setting['setting_name'];
                                                    _settingValueController
                                                            .text =
                                                        setting['setting_value'];
                                                    setState(() {
                                                      _selectedSettingId =
                                                          setting['setting_id']
                                                              .toString();
                                                    });
                                                    _showForm(context);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () {
                                                    _showDeleteConfirmation(
                                                      setting['setting_id']
                                                          .toString(),
                                                      setting['setting_name'],
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                    onTap: () {
                                      // Optionally show details or quick actions
                                      if (isSmallScreen) {
                                        showModalBottomSheet(
                                          context: context,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                          ),
                                          builder: (context) {
                                            return Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    setting['setting_name'],
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  ListTile(
                                                    title: const Text(
                                                      'Setting Value',
                                                    ),
                                                    subtitle: Text(
                                                      setting['setting_value'],
                                                    ),
                                                  ),
                                                  ListTile(
                                                    title: const Text(
                                                      'Setting ID',
                                                    ),
                                                    subtitle: Text(
                                                      setting['setting_id']
                                                          .toString(),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    children: [
                                                      ElevatedButton.icon(
                                                        icon: const Icon(
                                                          Icons.edit,
                                                        ),
                                                        label: const Text(
                                                          'Edit',
                                                        ),
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors.blue,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                        onPressed: () {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          _settingNameController
                                                                  .text =
                                                              setting['setting_name'];
                                                          _settingValueController
                                                                  .text =
                                                              setting['setting_value'];
                                                          setState(() {
                                                            _selectedSettingId =
                                                                setting['setting_id']
                                                                    .toString();
                                                          });
                                                          _showForm(context);
                                                        },
                                                      ),
                                                      ElevatedButton.icon(
                                                        icon: const Icon(
                                                          Icons.delete,
                                                        ),
                                                        label: const Text(
                                                          'Delete',
                                                        ),
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors.red,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                        onPressed: () {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          _showDeleteConfirmation(
                                                            setting['setting_id']
                                                                .toString(),
                                                            setting['setting_name'],
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showForm(context),
            backgroundColor: lightGreen,
            icon: const Icon(Icons.settings, color: Colors.white),
            label: const Text(
              'Add Remeinder',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevation: 4,
          )
          .animate()
          .scale(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(
            duration: const Duration(seconds: 2),
            color: Colors.white.withOpacity(0.3),
          ),
    );
  }

  // Helper widget for stat items
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: primaryGreen, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: darkGreen,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}
