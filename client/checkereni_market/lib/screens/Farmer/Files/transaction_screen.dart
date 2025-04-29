import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart'; // For animations

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with TickerProviderStateMixin {
  // List to hold transaction data
  List<dynamic> transactions = [];
  List<dynamic> filteredTransactions = []; // For filtered transactions

  // TextEditingControllers for input fields
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _transactionTypeController =
      TextEditingController();
  final TextEditingController _searchController =
      TextEditingController(); // For search filtering

  String?
  _selectedTransactionId; // To store the selected transaction ID for updates
  String?
  _selectedTransactionStatus; // To hold the selected transaction status for updates
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); // Key for form validation

  // Filter variables
  String _selectedStatusFilter = "All";
  String _selectedTypeFilter = "All";
  DateTime? _startDate;
  DateTime? _endDate;

  // Animation controllers
  late AnimationController _fabAnimationController;
  late AnimationController _listAnimationController;
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchTransactions(); // Fetch transactions when the screen initializes

    // Initialize animation controllers
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Initialize search controller listener
    _searchController.addListener(_filterTransactions);
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _listAnimationController.dispose();
    _searchController.dispose();
    _userIdController.dispose();
    _amountController.dispose();
    _transactionTypeController.dispose();
    super.dispose();
  }

  // Fetch all transactions from the API
  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true; // Set loading state
    });

    try {
      // API call to fetch transactions
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/transactions'),
      );

      if (response.statusCode == 200) {
        setState(() {
          transactions = json.decode(
            response.body,
          ); // Decode and store the transaction data
          filteredTransactions = List.from(
            transactions,
          ); // Initialize filtered list
          _isLoading = false;

          // Start animations after data is loaded
          _listAnimationController.forward();
        });
      } else {
        _showError(
          'Failed to load transactions: ${response.statusCode}',
        ); // Show error if fetching fails
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError('Network error: $e'); // Handle network errors
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter transactions based on search, status, type, and date range
  void _filterTransactions() {
    setState(() {
      filteredTransactions =
          transactions.where((transaction) {
            // Search filter
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

            // Status filter
            bool matchesStatus =
                _selectedStatusFilter == "All" ||
                transaction['status'] == _selectedStatusFilter.toLowerCase();

            // Type filter
            bool matchesType =
                _selectedTypeFilter == "All" ||
                transaction['transaction_type'] ==
                    _selectedTypeFilter.toLowerCase();

            // Date filter functionality would require transaction date in the API response
            // This is placeholder for when that data is available
            // bool matchesDate = (_startDate == null || transactionDate.isAfter(_startDate!)) &&
            //                    (_endDate == null || transactionDate.isBefore(_endDate!));

            return matchesSearch && matchesStatus && matchesType;
          }).toList();
    });
  }

  // Create a new transaction
  Future<void> _createTransaction() async {
    // Validate form inputs
    if (_userIdController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _transactionTypeController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true; // Set loading state
    });

    try {
      // API call to create a transaction
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': int.parse(_userIdController.text),
          'amount': double.parse(_amountController.text),
          'transaction_type': _transactionTypeController.text.toLowerCase(),
          'status': 'pending', // Default status for new transactions
        }),
      );

      if (response.statusCode == 201) {
        _fetchTransactions(); // Refresh the list of transactions
        _clearFields(); // Clear input fields after successful creation
        _showSuccess(
          'Transaction created successfully!',
        ); // Show success message
      } else {
        _showError(
          'Failed to create transaction: ${response.statusCode}',
        ); // Show error if creation fails
      }
    } catch (e) {
      _showError('Error creating transaction: $e'); // Handle errors
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update an existing transaction
  Future<void> _updateTransaction(String id) async {
    // Validate form inputs
    if (_userIdController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _transactionTypeController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true; // Set loading state
    });

    try {
      // API call to update a transaction
      final response = await http.put(
        Uri.parse('http://localhost:3000/api/transactions/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': int.parse(_userIdController.text),
          'amount': double.parse(_amountController.text),
          'transaction_type': _transactionTypeController.text.toLowerCase(),
          'status': _selectedTransactionStatus ?? 'pending',
        }),
      );

      if (response.statusCode == 200) {
        _fetchTransactions(); // Refresh the list of transactions
        _clearFields(); // Clear input fields after successful update
        _showSuccess(
          'Transaction updated successfully!',
        ); // Show success message
      } else {
        _showError(
          'Failed to update transaction: ${response.statusCode}',
        ); // Show error if update fails
      }
    } catch (e) {
      _showError('Error updating transaction: $e'); // Handle errors
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update the status of a transaction
  Future<void> _updateTransactionStatus(String id, String status) async {
    setState(() {
      _isLoading = true; // Set loading state
    });

    try {
      // API call to update transaction status
      final response = await http.put(
        Uri.parse('http://localhost:3000/api/transactions/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': status, // Update the status based on user selection
        }),
      );

      if (response.statusCode == 200) {
        _fetchTransactions(); // Refresh the list of transactions
        _showSuccess(
          'Transaction status updated successfully!',
        ); // Show success message
      } else {
        _showError(
          'Failed to update transaction status: ${response.statusCode}',
        ); // Show error if status update fails
      }
    } catch (e) {
      _showError('Error updating status: $e'); // Handle errors
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Delete an existing transaction
  Future<void> _deleteTransaction(String id) async {
    setState(() {
      _isLoading = true; // Set loading state
    });

    try {
      // API call to delete a transaction
      final response = await http.delete(
        Uri.parse('http://localhost:3000/api/transactions/$id'),
      );

      if (response.statusCode == 200) {
        _fetchTransactions(); // Refresh the list of transactions
        _showSuccess(
          'Transaction deleted successfully!',
        ); // Show success message
      } else {
        _showError(
          'Failed to delete transaction: ${response.statusCode}',
        ); // Show error if deletion fails
      }
    } catch (e) {
      _showError('Error deleting transaction: $e'); // Handle errors
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Clear input fields
  void _clearFields() {
    _userIdController.clear();
    _amountController.clear();
    _transactionTypeController.clear();
    setState(() {
      _selectedTransactionId = null; // Reset selected transaction ID
      _selectedTransactionStatus = null; // Reset selected transaction status
    });
  }

  // Show error messages
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Show success messages
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Show the form for creating or updating a transaction
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
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // User ID Field
                TextFormField(
                  controller: _userIdController,
                  decoration: InputDecoration(
                    labelText: 'User ID',
                    prefixIcon: const Icon(Icons.person, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a user ID';
                    }
                    return null;
                  },
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: const Icon(
                      Icons.attach_money,
                      color: Colors.green,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    return null;
                  },
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),

                // Transaction Type Field
                TextFormField(
                  controller: _transactionTypeController,
                  decoration: InputDecoration(
                    labelText: 'Transaction Type',
                    hintText: 'purchase, refund, commission',
                    prefixIcon: const Icon(Icons.category, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a transaction type';
                    }
                    return null;
                  },
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),

                // Status dropdown for updates
                if (_selectedTransactionId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: DropdownButtonFormField<String>(
                          value: _selectedTransactionStatus ?? 'pending',
                          decoration: InputDecoration(
                            labelText: 'Status',
                            prefixIcon: const Icon(
                              Icons.info_outline,
                              color: Colors.green,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Colors.green,
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
                            setState(() {
                              _selectedTransactionStatus = value;
                            });
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
                Navigator.of(context).pop(); // Close the dialog
                _clearFields(); // Clear the form fields
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (_selectedTransactionId == null) {
                    _createTransaction(); // Create new transaction if no ID is selected
                  } else {
                    _updateTransaction(
                      _selectedTransactionId!,
                    ); // Update existing transaction
                  }
                  Navigator.of(context).pop(); // Close the dialog
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

  // Show dialog for updating transaction status
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
          title: const Text(
            'Update Transaction Status',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Status: $currentStatus',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      currentStatus == 'completed'
                          ? Colors.green
                          : currentStatus == 'failed'
                          ? Colors.red
                          : Colors.orange,
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
                  border: Border.all(color: Colors.green),
                ),
                child: DropdownButton<String>(
                  value: newStatus,
                  isExpanded: true,
                  underline: Container(), // Remove the default underline
                  items:
                      ['pending', 'completed', 'failed'] // Status options
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status,
                                style: TextStyle(
                                  color:
                                      status == 'completed'
                                          ? Colors.green
                                          : status == 'failed'
                                          ? Colors.red
                                          : Colors.orange,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      newStatus = value;
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  () =>
                      Navigator.of(
                        context,
                      ).pop(), // Close dialog without action
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                if (newStatus != currentStatus) {
                  _updateTransactionStatus(
                    transactionId,
                    newStatus,
                  ); // Update transaction status
                }
                Navigator.of(context).pop(); // Close the dialog
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

  // Show filter dialog
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
              title: const Text(
                'Filter Transactions',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status filter
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedStatusFilter,
                      isExpanded: true,
                      underline: Container(), // Remove the default underline
                      items:
                          [
                                'All',
                                'Pending',
                                'Completed',
                                'Failed',
                              ] // Status options
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedStatusFilter = value;
                          });
                        }
                      },
                    ),
                  ),

                  // Transaction Type filter
                  const Text(
                    'Transaction Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.green),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedTypeFilter,
                      isExpanded: true,
                      underline: Container(), // Remove the default underline
                      items:
                          [
                                'All',
                                'Purchase',
                                'Refund',
                                'Commission',
                              ] // Type options
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedTypeFilter = value;
                          });
                        }
                      },
                    ),
                  ),

                  // Date range selector would go here
                  // For future implementation when the API includes transaction dates
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Reset filters
                    setState(() {
                      _selectedStatusFilter = "All";
                      _selectedTypeFilter = "All";
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    // Apply filters
                    _filterTransactions();
                  },
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

  // Get color based on transaction status
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

  // Get icon based on transaction type
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.account_balance_wallet, color: Colors.green),
            SizedBox(width: 8), // space between icon and text
            Text(
              'Transaction Management',
              style: TextStyle(
                color:
                    Colors.black, // AppBar title should also match icon color
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
            tooltip: 'Filter transactions',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchTransactions,
            tooltip: 'Refresh transactions',
          ),
        ],
        elevation: 0,
      ),

      body: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white, // Outer container is white
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
                color: const Color(
                  0xFFE8F5E9,
                ), // light green inside (same as your image)
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.green),
                  hintText: 'Search users...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // Transaction count summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Transactions: ${filteredTransactions.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                // Could add summary statistics here in the future
              ],
            ),
          ),

          // Transactions list
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    )
                    : filteredTransactions.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 64,
                            color: Colors.green.shade200,
                          ),
                          const SizedBox(height: 16),
                          const Text(
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

                        // Staggered animation effect
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
                                          // Transaction ID
                                          Expanded(
                                            child: Text(
                                              'Transaction #${transaction['transaction_id']}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.green,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                          // Status chip
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

                                      // Transaction details
                                      Row(
                                        children: [
                                          // User ID
                                          Expanded(
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.person_outline,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'User ID: ${transaction['user_id']}',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Transaction type
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
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Amount
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '\$${transaction['amount']}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          // Action buttons
                                          Row(
                                            children: [
                                              // Edit button
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                ),
                                                tooltip: 'Edit transaction',
                                                onPressed: () {
                                                  // Fill fields with existing transaction data for editing
                                                  // _hereeee

                                                  // Fill fields with existing transaction data for editing
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
                                                            .toString(); // Set selected transaction ID
                                                    _selectedTransactionStatus =
                                                        transaction['status'];
                                                  });
                                                  _showForm(
                                                    context,
                                                  ); // Show form for editing
                                                },
                                              ),

                                              // Status update button
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.refresh,
                                                  color: Colors.orange,
                                                ),
                                                tooltip: 'Update status',
                                                onPressed: () {
                                                  _showStatusUpdateDialog(
                                                    transaction['transaction_id']
                                                        .toString(),
                                                    transaction['status'],
                                                  );
                                                },
                                              ),

                                              // Delete button
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                tooltip: 'Delete transaction',
                                                onPressed: () {
                                                  // Show confirmation dialog
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
                                                          title: const Text(
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
                                                              child: const Text(
                                                                'Cancel',
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
                                                              child: const Text(
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
                              )
                              .animate(
                                controller: _listAnimationController,
                                delay: Duration(milliseconds: 50 * index),
                              )
                              .fadeIn()
                              .slideX(begin: 0.2, end: 0),
                        );
                      },
                    ),
          ),
        ],
      ),
      // Floating action button with animation
      floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              _clearFields(); // Clear fields for new transaction
              _showForm(context); // Show the transaction form
              _fabAnimationController.reset();
              _fabAnimationController.forward();
            },
            backgroundColor: Colors.green,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
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
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// Additional helper widgets

// Custom transaction card widget - can be extracted for better code organization
class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final Function(String) onEdit;
  final Function(String) onDelete;
  final Function(String, String) onStatusUpdate;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusUpdate,
  });

  // Get color based on transaction status
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

  // Get icon based on transaction type
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: _getStatusColor(transaction['status']).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Transaction ID
                Expanded(
                  child: Text(
                    'Transaction #${transaction['transaction_id']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color.fromARGB(255, 41, 40, 40),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      transaction['status'],
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(transaction['status']),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    transaction['status'].toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(transaction['status']),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Transaction details
            Row(
              children: [
                // User ID
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'User ID: ${transaction['user_id']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                // Transaction type
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
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${transaction['amount']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Action buttons
                Row(
                  children: [
                    // Edit button
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit transaction',
                      onPressed:
                          () =>
                              onEdit(transaction['transaction_id'].toString()),
                    ),

                    // Status update button
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      tooltip: 'Update status',
                      onPressed:
                          () => onStatusUpdate(
                            transaction['transaction_id'].toString(),
                            transaction['status'],
                          ),
                    ),

                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete transaction',
                      onPressed:
                          () => onDelete(
                            transaction['transaction_id'].toString(),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Transaction statistics widget - for future implementation
class TransactionStatistics extends StatelessWidget {
  final List<dynamic> transactions;

  const TransactionStatistics({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Calculate statistics
    int totalTransactions = transactions.length;
    int completedTransactions =
        transactions.where((t) => t['status'] == 'completed').length;
    int pendingTransactions =
        transactions.where((t) => t['status'] == 'pending').length;
    int failedTransactions =
        transactions.where((t) => t['status'] == 'failed').length;

    double totalAmount = transactions.fold(
      0.0,
      (sum, t) => sum + (t['amount'] as double),
    );

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'Total',
                  totalTransactions,
                  Icons.account_balance_wallet,
                ),
                _buildStatItem(
                  'Completed',
                  completedTransactions,
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Pending',
                  pendingTransactions,
                  Icons.hourglass_empty,
                  Colors.orange,
                ),
                _buildStatItem(
                  'Failed',
                  failedTransactions,
                  Icons.cancel,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Total Amount: \$${totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    int count,
    IconData icon, [
    Color color = Colors.blue,
  ]) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

// User management screen connection - for future implementation
/*
 * The transaction screen can be linked with user management screen for 
 * better integration. This can be achieved by passing user data from the
 * user management screen to this transaction screen.
 *
 * Sample implementation:
 *
 * class UserManagementScreen extends StatefulWidget {
 *   const UserManagementScreen({Key? key}) : super(key: key);
 *
 *   @override
 *   _UserManagementScreenState createState() => _UserManagementScreenState();
 * }
 *
 * class _UserManagementScreenState extends State<UserManagementScreen> {
 *   void _navigateToUserTransactions(int userId) {
 *     Navigator.of(context).push(
 *       MaterialPageRoute(
 *         builder: (context) => TransactionScreen(initialUserId: userId),
 *       ),
 *     );
 *   }
 *
 *   // Rest of the user management implementation
 * }
 *
 * // And in the TransactionScreen constructor:
 * const TransactionScreen({Key? key, this.initialUserId}) : super(key: key);
 * final int? initialUserId;
 *
 * // Then in initState, if initialUserId is provided, filter by that user
 */
