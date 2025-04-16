import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<dynamic> reports = []; // List to hold report data
  final TextEditingController _reportTypeController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Loading state for fetching reports

  @override
  void initState() {
    super.initState();
    _fetchReports(); // Fetch reports on initialization
  }

  // Fetch all reports from the API
  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    final response = await http.get(Uri.parse('http://localhost:3000/api/reports'));
    if (response.statusCode == 200) {
      setState(() {
        reports = json.decode(response.body); // Decode and store the report data
      });
    } else {
      _showError('Failed to load reports'); // Show error if fetching fails
    }
    setState(() => _isLoading = false);
  }

  // Create a new report
  Future<void> _createReport() async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/api/reports'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'admin_id': '1', // Replace with actual admin ID
        'report_type': _reportTypeController.text,
        'content': _contentController.text,
      }),
    );

    if (response.statusCode == 201) {
      _fetchReports(); // Refresh the list of reports
      _clearFields(); // Clear input fields after successful creation
    } else {
      _showError('Failed to create report'); // Show error if creation fails
    }
  }

  // Delete a report
  Future<void> _deleteReport(int id) async {
    final response = await http.delete(Uri.parse('http://localhost:3000/api/reports/$id'));
    if (response.statusCode == 200) {
      _fetchReports(); // Refresh the list of reports
    } else {
      _showError('Failed to delete report'); // Show error if deletion fails
    }
  }

  // Clear input fields
  void _clearFields() {
    _reportTypeController.clear();
    _contentController.clear();
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

  // Show the form for creating a report
  void _showForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Report'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _reportTypeController,
                    decoration: InputDecoration(
                      labelText: 'Report Type',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter Report Type' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) => value == null || value.isEmpty ? 'Enter Content' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _createReport(); // Create a new report
                  Navigator.of(context).pop(); // Close the dialog
                }
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
        title: const Text('Reports Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(context), // Show form to create a new report
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(report['report_type']),
                    subtitle: Text(report['content']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteReport(report['report_id']), // Delete report
                    ),
                  ),
                );
              },
            ),
    );
  }
}