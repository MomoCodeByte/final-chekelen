import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // List to hold settings data
  List<dynamic> settings = [];
  
  // TextEditingControllers for input fields
  final TextEditingController _settingNameController = TextEditingController();
  final TextEditingController _settingValueController = TextEditingController();
  
  String? _selectedSettingId; // To store the selected setting ID for updates

  @override
  void initState() {
    super.initState();
    _fetchSettings(); // Fetch settings when the screen initializes
  }

  // Fetch all settings from the API
  Future<void> _fetchSettings() async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/settings'));
    if (response.statusCode == 200) {
      setState(() {
        settings = json.decode(response.body); // Decode and store the settings data
      });
    } else {
      _showError('Failed to load settings'); // Show error if fetching fails
    }
  }

  // Create a new setting
  Future<void> _createSetting() async {
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
      _showError('Failed to create setting'); // Show error if creation fails
    }
  }

  // Update an existing setting
  Future<void> _updateSetting(String id) async {
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
      _showError('Failed to update setting'); // Show error if update fails
    }
  }

  // Delete an existing setting
  Future<void> _deleteSetting(String id) async {
    final response = await http.delete(Uri.parse('http://localhost:3000/api/settings/$id'));
    if (response.statusCode == 200) {
      _fetchSettings(); // Refresh the list of settings
      _showSuccess('Setting deleted successfully!'); // Show success message
    } else {
      _showError('Failed to delete setting'); // Show error if deletion fails
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
      ),
    );
  }

  // Show success messages
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show the form for creating or updating a setting
  void _showForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_selectedSettingId == null ? 'Create Setting' : 'Update Setting'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _settingNameController,
                decoration: const InputDecoration(labelText: 'Setting Name'),
              ),
              TextField(
                controller: _settingValueController,
                decoration: const InputDecoration(labelText: 'Setting Value'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_selectedSettingId == null) {
                  _createSetting(); // Create new setting if no ID is selected
                } else {
                  _updateSetting(_selectedSettingId!); // Update existing setting
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Submit'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog without action
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _clearFields(); // Clear fields for new setting
              _showForm(context); // Show the settings form
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: settings.length,
        itemBuilder: (context, index) {
          final setting = settings[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(setting['setting_name']),
              subtitle: Text(setting['setting_value']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _settingNameController.text = setting['setting_name'];
                      _settingValueController.text = setting['setting_value'];
                      setState(() {
                        _selectedSettingId = setting['setting_id'].toString(); // Set selected setting ID
                      });
                      _showForm(context); // Show form for editing
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteSetting(setting['setting_id'].toString()), // Delete setting
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}