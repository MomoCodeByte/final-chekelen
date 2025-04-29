import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> reports = [];
  final TextEditingController _reportTypeController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late TabController _tabController;
  String _filterType = 'All';
  bool _isExpanded = false;

  // Color scheme
  final Color primaryGreen = const Color.fromARGB(255, 93, 202, 99);
  final Color lightGreen = const Color(0xFFE8F5E9);
  final Color white = Colors.white;
  final Color darkText = const Color(0xFF3C4046);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reportTypeController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Fetch all reports from the API
  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/reports'),
      );
      if (response.statusCode == 200) {
        setState(() {
          reports = json.decode(response.body);
        });
      } else {
        _showError('Failed to load reports');
      }
    } catch (e) {
      _showError('Network error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Create a new report
  Future<void> _createReport() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/reports'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'admin_id': '1',
          'report_type': _reportTypeController.text,
          'content': _contentController.text,
          'created_at': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        _fetchReports();
        _clearFields();
        _showSuccess('Report created successfully');
      } else {
        _showError('Failed to create report');
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  // Delete a report
  Future<void> _deleteReport(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/api/reports/$id'),
      );
      if (response.statusCode == 200) {
        _fetchReports();
        _showSuccess('Report deleted successfully');
      } else {
        _showError('Failed to delete report');
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  // Filter reports by type
  List<dynamic> get filteredReports {
    if (_filterType == 'All') return reports;
    return reports
        .where((report) => report['report_type'] == _filterType)
        .toList();
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

  // Show success messages
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show the form for creating a report
  void _showForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
         
          child: FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  // BoxShadow(
                  //   color: Colors.black.withOpacity(0.1),
                  //   blurRadius: 10,
                  //   offset: const Offset(0, 5),
                  // ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_chart, color: white, size: 30),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create New Report',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _reportTypeController,
                            decoration: InputDecoration(
                              labelText: 'Report Type',
                              hintText: 'Select report type',
                              prefixIcon: Icon(
                                Icons.category,
                                color: primaryGreen,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: primaryGreen,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Report type is required'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _contentController,
                            decoration: InputDecoration(
                              labelText: 'Report Content',
                              hintText: 'Enter detailed report content',
                              prefixIcon: Icon(
                                Icons.description,
                                color: primaryGreen,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: primaryGreen,
                                  width: 2,
                                ),
                              ),
                            ),
                            maxLines: 5,
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Content is required'
                                        : null,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: const Text('Save Report'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    _createReport();
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Format date for display
  String _formatDate(String dateString) {
    final DateTime date = DateTime.parse(dateString);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 600;

    return Scaffold(
      backgroundColor: lightGreen.withOpacity(0.3),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.report, color: Colors.green),
            const SizedBox(width: 8),
            const Text(
              'Techinical Reports & Remainder',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: _fetchReports,
            tooltip: 'Refresh Reports',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.deepPurpleAccent),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            tooltip: 'Filter Reports',
          ),
        ],
        bottom:
            _isExpanded
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(48.0),
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      onTap: (index) {
                        setState(() {
                          switch (index) {
                            case 0:
                              _filterType = 'All';
                              break;
                            case 1:
                              _filterType = 'Monthly';
                              break;
                            case 2:
                              _filterType = 'Weekly';
                              break;
                          }
                        });
                      },
                      labelColor: primaryGreen,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: primaryGreen,
                      tabs: const [
                        Tab(text: 'All Reports'),
                        Tab(text: 'Monthly'),
                        Tab(text: 'Weekly'),
                      ],
                    ),
                  ),
                )
                : null,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                ),
              )
              : reports.isEmpty
              ? Center(
                child: FadeIn(
                  duration: const Duration(milliseconds: 800),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_late_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reports available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => _showForm(context),
                      ),
                    ],
                  ),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${filteredReports.length} Reports Found',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredReports.length,
                        itemBuilder: (context, index) {
                          final report = filteredReports[index];
                          return FadeInUp(
                            duration: Duration(
                              milliseconds: 300 + (index * 100),
                            ),
                            child: Slidable(
                              key: ValueKey(report['report_id']),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed:
                                        (_) =>
                                            _deleteReport(report['report_id']),
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete,
                                    label: 'Delete',
                                    borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 8 : 12,
                                    ),
                                  ),
                                ],
                              ),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    isSmallScreen ? 8 : 12,
                                  ),
                                  side: BorderSide(color: lightGreen, width: 1),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 8 : 12,
                                    ),
                                    gradient: LinearGradient(
                                      colors: [
                                        white,
                                        lightGreen.withOpacity(0.3),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryGreen,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(
                                              isSmallScreen ? 8 : 12,
                                            ),
                                            topRight: Radius.circular(
                                              isSmallScreen ? 8 : 12,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                report['report_type'],
                                                style: TextStyle(
                                                  color: white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      isSmallScreen ? 14 : 16,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (report['created_at'] != null)
                                              Text(
                                                _formatDate(
                                                  report['created_at'],
                                                ),
                                                style: TextStyle(
                                                  color: white.withOpacity(0.8),
                                                  fontSize:
                                                      isSmallScreen ? 12 : 14,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              report['content'],
                                              style: TextStyle(
                                                fontSize:
                                                    isSmallScreen ? 14 : 16,
                                                color: darkText,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                _ActionButton(
                                                  icon: Icons.edit,
                                                  label: 'Edit',
                                                  color: Colors.blue,
                                                  onPressed: () {
                                                    // Edit functionality could be added here
                                                    _showError(
                                                      'Edit functionality not implemented yet',
                                                    );
                                                  },
                                                  isSmallScreen: isSmallScreen,
                                                ),
                                                const SizedBox(width: 8),
                                                _ActionButton(
                                                  icon: Icons.delete,
                                                  label: 'Delete',
                                                  color: Colors.red,
                                                  onPressed:
                                                      () => _deleteReport(
                                                        report['report_id'],
                                                      ),
                                                  isSmallScreen: isSmallScreen,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showForm(context),
            backgroundColor: Colors.green,
            icon: const Icon(Icons.report, color: Colors.white),
            label: const Text(
              'Create Report',
              style: TextStyle(color: Colors.white),
            ),
            elevation: 4,
          )
          .animate()
          .scale(duration: 300.ms, curve: Curves.easeOut)
          .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.3))
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 1800.ms,
            delay: 800.ms,
            color: Colors.white.withOpacity(0.2),
          ),
    );
  }
}

// Custom action button for card actions
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isSmallScreen;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: isSmallScreen ? 16 : 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 12,
          vertical: isSmallScreen ? 4 : 8,
        ),
        textStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      onPressed: onPressed,
    );
  }
}
