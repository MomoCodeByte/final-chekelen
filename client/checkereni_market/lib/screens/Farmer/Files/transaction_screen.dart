import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with TickerProviderStateMixin {
  List<dynamic> transactions = [];
  List<dynamic> filteredTransactions = [];
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _transactionTypeController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedTransactionId;
  String? _selectedTransactionStatus;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _selectedStatusFilter = "All";
  String _selectedTypeFilter = "All";
  DateTime? _startDate;
  DateTime? _endDate;
  late AnimationController _fabAnimationController;
  late AnimationController _listAnimationController;
  bool _isLoading = true;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://localhost:3000';

  // Custom Colors (aligned with OrderManagementScreen)
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF81C784);
  final Color darkGreen = const Color(0xFF1B5E20);
  final Color backgroundColor = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _searchController.addListener(_filterTransactions);
    _checkSessionAndFetchTransactions();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _listAnimationController.dispose();
    _searchController.removeListener(_filterTransactions);
    _searchController.dispose();
    _userIdController.dispose();
    _amountController.dispose();
    _transactionTypeController.dispose();
    super.dispose();
  }

  Future<void> _checkSessionAndFetchTransactions() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      _showError('No session found. Please log in.');
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    await _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _showError('No session found. Please log in.');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          transactions = json.decode(response.body);
          filteredTransactions = List.from(transactions);
          _isLoading = false;
          _listAnimationController.forward();
        });
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError(
          'Failed to load transactions: ${response.statusCode}\n${response.body}',
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Error loading transactions: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _showError('No session found. Please log in.');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/transactions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': int.parse(_userIdController.text),
          'amount': double.parse(_amountController.text),
          'transaction_type': _transactionTypeController.text.toLowerCase(),
          'status': 'pending',
        }),
      );

      if (response.statusCode == 201) {
        await _fetchTransactions();
        _clearFields();
        _showSuccess('Transaction created successfully!');
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError(
          'Failed to create transaction: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      _showError('Error creating transaction: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTransaction(String id) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _showError('No session found. Please log in.');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/transactions/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': int.parse(_userIdController.text),
          'amount': double.parse(_amountController.text),
          'transaction_type': _transactionTypeController.text.toLowerCase(),
          'status': _selectedTransactionStatus ?? 'pending',
        }),
      );

      if (response.statusCode == 200) {
        await _fetchTransactions();
        _clearFields();
        _showSuccess('Transaction updated successfully!');
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError(
          'Failed to update transaction: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      _showError('Error updating transaction: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTransactionStatus(String id, String status) async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _showError('No session found. Please log in.');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/transactions/$id/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        await _fetchTransactions();
        _showSuccess('Transaction status updated successfully!');
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError(
          'Failed to update transaction status: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      _showError('Error updating status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTransaction(String id) async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _showError('No session found. Please log in.');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/transactions/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await _fetchTransactions();
        _showSuccess('Transaction deleted successfully!');
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError(
          'Failed to delete transaction: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      _showError('Error deleting transaction: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _storage.delete(key: 'jwt_token');
      _showSuccess('Logged out successfully');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _filterTransactions() {
    setState(() {
      filteredTransactions =
          transactions.where((transaction) {
            bool matchesSearch =
                _searchController.text.isEmpty ||
                transaction['transaction_id'].toString().contains(
                  _searchController.text,
                ) ||
                transaction['user_id'].toString().contains(
                  _searchController.text,
                ) ||
                transaction['amount'].toString().contains(
                  _searchController.text,
                ) ||
                transaction['transaction_type']
                    .toString()
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase());

            bool matchesStatus =
                _selectedStatusFilter == "All" ||
                transaction['status'] == _selectedStatusFilter.toLowerCase();

            bool matchesType =
                _selectedTypeFilter == "All" ||
                transaction['transaction_type'] ==
                    _selectedTypeFilter.toLowerCase();

            return matchesSearch && matchesStatus && matchesType;
          }).toList();
    });
  }

  void _clearFields() {
    _userIdController.clear();
    _amountController.clear();
    _transactionTypeController.clear();
    setState(() {
      _selectedTransactionId = null;
      _selectedTransactionStatus = null;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: lightGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Text(
            _selectedTransactionId == null
                ? 'Create Transaction'
                : 'Update Transaction',
            style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _userIdController,
                  decoration: InputDecoration(
                    labelText: 'User ID',
                    prefixIcon: Icon(Icons.person, color: primaryGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: primaryGreen, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter a user ID';
                    if (int.tryParse(value) == null)
                      return 'User ID must be a number';
                    return null;
                  },
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.attach_money, color: primaryGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: primaryGreen, width: 2),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter an amount';
                    if (double.tryParse(value) == null)
                      return 'Amount must be a number';
                    return null;
                  },
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _transactionTypeController,
                  decoration: InputDecoration(
                    labelText: 'Transaction Type',
                    hintText: 'purchase, refund, commission',
                    prefixIcon: Icon(Icons.category, color: primaryGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: primaryGreen, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter a transaction type';
                    return null;
                  },
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                if (_selectedTransactionId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: DropdownButtonFormField<String>(
                          value: _selectedTransactionStatus ?? 'pending',
                          decoration: InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(
                              Icons.info_outline,
                              color: primaryGreen,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: primaryGreen,
                                width: 2,
                              ),
                            ),
                          ),
                          items:
                              ['pending', 'completed', 'failed']
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() => _selectedTransactionStatus = value);
                          },
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearFields();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (_selectedTransactionId == null) {
                    _createTransaction();
                  } else {
                    _updateTransaction(_selectedTransactionId!);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                _selectedTransactionId == null ? 'Create' : 'Update',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showStatusUpdateDialog(String transactionId, String currentStatus) {
    String newStatus = currentStatus;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Update Transaction Status',
            style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Status: $currentStatus',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(currentStatus),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: primaryGreen),
                ),
                child: DropdownButton<String>(
                  value: newStatus,
                  isExpanded: true,
                  underline: Container(),
                  items:
                      ['pending', 'completed', 'failed']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      newStatus = value;
                      setState(() {}); // Trigger rebuild for dialog
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                if (newStatus != currentStatus) {
                  _updateTransactionStatus(transactionId, newStatus);
                }
                Navigator.of(context).pop();
              },
              child: const Text(
                'Update',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              title: Text(
                'Filter Transactions',
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: primaryGreen),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedStatusFilter,
                      isExpanded: true,
                      underline: Container(),
                      items:
                          ['All', 'Pending', 'Completed', 'Failed']
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedStatusFilter = value);
                          _filterTransactions();
                        }
                      },
                    ),
                  ),
                  Text(
                    'Transaction Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: primaryGreen),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedTypeFilter,
                      isExpanded: true,
                      underline: Container(),
                      items:
                          ['All', 'Purchase', 'Refund', 'Commission']
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedTypeFilter = value);
                          _filterTransactions();
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatusFilter = "All";
                      _selectedTypeFilter = "All";
                      _startDate = null;
                      _endDate = null;
                    });
                    _filterTransactions();
                    Navigator.of(context).pop();
                  },
                  child: Text('Reset', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Apply',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'purchase':
        return Icons.shopping_cart;
      case 'refund':
        return Icons.refresh;
      case 'commission':
        return Icons.attach_money;
      default:
        return Icons.swap_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: primaryGreen),
            const SizedBox(width: 8),
            Text(
              'Transaction Management',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: primaryGreen),
            onPressed: _showFilterDialog,
            tooltip: 'Filter transactions',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: primaryGreen),
            onPressed: _fetchTransactions,
            tooltip: 'Refresh transactions',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: primaryGreen),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: lightGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: primaryGreen),
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: lightGreen.withOpacity(0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Transactions: ${filteredTransactions.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    )
                    : filteredTransactions.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 64,
                            color: lightGreen,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];
                        return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(
                                    color: _getStatusColor(
                                      transaction['status'],
                                    ).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Transaction #${transaction['transaction_id']}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: primaryGreen,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                transaction['status'],
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _getStatusColor(
                                                  transaction['status'],
                                                ),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              transaction['status']
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: _getStatusColor(
                                                  transaction['status'],
                                                ),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.person_outline,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'User ID: ${transaction['user_id']}',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _getTransactionTypeIcon(
                                                    transaction['transaction_type'],
                                                  ),
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  transaction['transaction_type']
                                                      .toString()
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '\$${transaction['amount']}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                ),
                                                tooltip: 'Edit transaction',
                                                onPressed: () {
                                                  _userIdController.text =
                                                      transaction['user_id']
                                                          .toString();
                                                  _amountController.text =
                                                      transaction['amount']
                                                          .toString();
                                                  _transactionTypeController
                                                          .text =
                                                      transaction['transaction_type'];
                                                  setState(() {
                                                    _selectedTransactionId =
                                                        transaction['transaction_id']
                                                            .toString();
                                                    _selectedTransactionStatus =
                                                        transaction['status'];
                                                  });
                                                  _showForm(context);
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.refresh,
                                                  color: Colors.orange,
                                                ),
                                                tooltip: 'Update status',
                                                onPressed:
                                                    () => _showStatusUpdateDialog(
                                                      transaction['transaction_id']
                                                          .toString(),
                                                      transaction['status'],
                                                    ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                tooltip: 'Delete transaction',
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (
                                                          context,
                                                        ) => AlertDialog(
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                          ),
                                                          title: Text(
                                                            'Confirm Delete',
                                                          ),
                                                          content: Text(
                                                            'Are you sure you want to delete transaction #${transaction['transaction_id']}?',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop(),
                                                              child: Text(
                                                                'Cancel',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .grey[700],
                                                                ),
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                  context,
                                                                ).pop();
                                                                _deleteTransaction(
                                                                  transaction['transaction_id']
                                                                      .toString(),
                                                                );
                                                              },
                                                              child: Text(
                                                                'Delete',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .animate(
                              controller: _listAnimationController,
                              delay: Duration(milliseconds: 50 * index),
                            )
                            .fadeIn()
                            .slideX(begin: 0.2, end: 0);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              _clearFields();
              _showForm(context);
              _fabAnimationController.reset();
              _fabAnimationController.forward();
            },
            backgroundColor: primaryGreen,
            icon: Icon(Icons.add, color: Colors.white),
            label: Text(
              'New Transaction',
              style: TextStyle(color: Colors.white),
            ),
            elevation: 4,
          )
          .animate(
            controller: _fabAnimationController,
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .scaleXY(begin: 1, end: 1.05, duration: 600.ms)
          .then(delay: 200.ms),
    );
  }
}
