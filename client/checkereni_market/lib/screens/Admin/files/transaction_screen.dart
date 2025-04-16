import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({Key? key}) : super(key: key);

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  // List to hold transaction data
  List<dynamic> transactions = [];
  
  // TextEditingControllers for input fields
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _transactionTypeController = TextEditingController();
  
  String? _selectedTransactionId; // To store the selected transaction ID for updates
  String? _selectedTransactionStatus; // To hold the selected transaction status for updates
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Key for form validation

  @override
  void initState() {
    super.initState();
    _fetchTransactions(); // Fetch transactions when the screen initializes
  }

  // Fetch all transactions from the API
  Future<void> _fetchTransactions() async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/transactions'));
    if (response.statusCode == 200) {
      setState(() {
        transactions = json.decode(response.body); // Decode and store the transaction data
      });
    } else {
      _showError('Failed to load transactions'); // Show error if fetching fails
    }
  }

  // Create a new transaction
  Future<void> _createTransaction() async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/api/transactions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': int.parse(_userIdController.text),
        'amount': double.parse(_amountController.text),
        'transaction_type': _transactionTypeController.text,
        'status': 'pending', // Default status for new transactions
      }),
    );

    if (response.statusCode == 201) {
      _fetchTransactions(); // Refresh the list of transactions
      _clearFields(); // Clear input fields after successful creation
      _showSuccess('Transaction created successfully!'); // Show success message
    } else {
      _showError('Failed to create transaction'); // Show error if creation fails
    }
  }

  // Update an existing transaction
  Future<void> _updateTransaction(String id) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/api/transactions/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': int.parse(_userIdController.text),
        'amount': double.parse(_amountController.text),
        'transaction_type': _transactionTypeController.text,
        'status': 'completed', // Modify as needed
      }),
    );

    if (response.statusCode == 200) {
      _fetchTransactions(); // Refresh the list of transactions
      _clearFields(); // Clear input fields after successful update
      _showSuccess('Transaction updated successfully!'); // Show success message
    } else {
      _showError('Failed to update transaction'); // Show error if update fails
    }
  }

  // Update the status of a transaction
  Future<void> _updateTransactionStatus(String id, String status) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/api/transactions/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'status': status, // Update the status based on user selection
      }),
    );

    if (response.statusCode == 200) {
      _fetchTransactions(); // Refresh the list of transactions
      _showSuccess('Transaction status updated successfully!'); // Show success message
    } else {
      _showError('Failed to update transaction status'); // Show error if status update fails
    }
  }

  // Delete an existing transaction
  Future<void> _deleteTransaction(String id) async {
    final response = await http.delete(Uri.parse('http://localhost:3000/api/transactions/$id'));
    if (response.statusCode == 200) {
      _fetchTransactions(); // Refresh the list of transactions
      _showSuccess('Transaction deleted successfully!'); // Show success message
    } else {
      _showError('Failed to delete transaction'); // Show error if deletion fails
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

  // Show the form for creating or updating a transaction
  void _showForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_selectedTransactionId == null ? 'Create Transaction' : 'Update Transaction'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _userIdController,
                  decoration: const InputDecoration(labelText: 'User ID'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _transactionTypeController,
                  decoration: const InputDecoration(labelText: 'Transaction Type (purchase, refund, commission)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_selectedTransactionId == null) {
                  _createTransaction(); // Create new transaction if no ID is selected
                } else {
                  _updateTransaction(_selectedTransactionId!); // Update existing transaction
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

  // Show dialog for updating transaction status
  void _showStatusUpdateDialog(String transactionId, String currentStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Transaction Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Status: $currentStatus'),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: currentStatus,
                items: ['pending', 'completed', 'failed'] // Status options
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateTransactionStatus(transactionId, value); // Update transaction status
                    Navigator.of(context).pop(); // Close the dialog
                  }
                },
              ),
            ],
          ),
          actions: [
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
        title: const Text('Transaction Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _clearFields(); // Clear fields for new transaction
              _showForm(context); // Show the transaction form
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('Transaction ID: ${transaction['transaction_id']}'),
              subtitle: Text(
                'Amount: \$${transaction['amount']} - Type: ${transaction['transaction_type']} - Status: ${transaction['status']}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Fill fields with existing transaction data for editing
                      _userIdController.text = transaction['user_id'].toString();
                      _amountController.text = transaction['amount'].toString();
                      _transactionTypeController.text = transaction['transaction_type'];
                      setState(() {
                        _selectedTransactionId = transaction['transaction_id'].toString(); // Set selected transaction ID
                      });
                      _showForm(context); // Show form for editing
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTransaction(transaction['transaction_id'].toString()), // Delete transaction
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      _showStatusUpdateDialog(transaction['transaction_id'].toString(), transaction['status']); // Update transaction status
                    },
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