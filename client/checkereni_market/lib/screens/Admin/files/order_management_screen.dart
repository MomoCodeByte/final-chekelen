import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({Key? key}) : super(key: key);

  @override
  _OrderManagementScreenState createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  List<dynamic> orders = []; // List to hold order data
  final TextEditingController _customerIdController = TextEditingController();
  final TextEditingController _cropIdController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  
  String? _selectedOrderId; // To hold the selected order ID for updates
  String? _selectedOrderStatus; // To hold the selected order status for updates
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Loading state for fetching orders

  @override
  void initState() {
    super.initState();
    fetchOrders(); // Fetch orders when the screen initializes
  }

  // Fetch all orders from the API
  Future<void> fetchOrders() async {
    setState(() => _isLoading = true);
    final response = await http.get(Uri.parse('http://localhost:3000/api/orders'));
    
    if (response.statusCode == 200) {
      setState(() {
        orders = json.decode(response.body); // Decode and store the order data
      });
    } else {
      _showError('Failed to load orders'); // Show error message if fetching fails
    }
    setState(() => _isLoading = false);
  }

  // Create a new order
  Future<void> createOrder() async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/api/orders'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customer_id': int.parse(_customerIdController.text),
        'crop_id': int.parse(_cropIdController.text),
        'quantity': int.parse(_quantityController.text),
        'total_price': double.parse(_totalPriceController.text),
      }),
    );

    if (response.statusCode == 201) {
      fetchOrders(); // Refresh the list of orders
      _clearFields(); // Clear input fields after successful creation
      _showSuccess('Order created successfully!'); // Show success message
    } else {
      _showError('Failed to create order'); // Show error if creation fails
    }
  }

  // Update an existing order
  Future<void> updateOrder(String id) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/api/orders/$id'), // Updated endpoint
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customer_id': int.parse(_customerIdController.text),
        'crop_id': int.parse(_cropIdController.text),
        'quantity': int.parse(_quantityController.text),
        'total_price': double.parse(_totalPriceController.text),
      }),
    );

    if (response.statusCode == 200) {
      fetchOrders(); // Refresh the list of orders
      _clearFields(); // Clear input fields after successful update
      _showSuccess('Order updated successfully!'); // Show success message
    } else {
      _showError('Failed to update order'); // Show error if update fails
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String id, String status) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/api/orders/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'order_status': status,
      }),
    );

    if (response.statusCode == 200) {
      fetchOrders(); // Refresh the list of orders
      _showSuccess('Order status updated to $status successfully!'); // Show success message
    } else {
      _showError('Failed to update order status'); // Show error if update fails
    }
  }

  // Delete an order
  Future<void> deleteOrder(String id) async {
    final response = await http.delete(Uri.parse('http://localhost:3000/api/orders/$id')); // Updated endpoint
    if (response.statusCode == 200) {
      fetchOrders(); // Refresh the list of orders
      _showSuccess('Order deleted successfully!'); // Show success message
    } else {
      _showError('Failed to delete order'); // Show error if deletion fails
    }
  }

  // Clear input fields
  void _clearFields() {
    _customerIdController.clear();
    _cropIdController.clear();
    _quantityController.clear();
    _totalPriceController.clear();
    setState(() {
      _selectedOrderId = null; // Reset selected order ID
      _selectedOrderStatus = null; // Reset selected order status
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

  // Show the order creation/update form
  void _showForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_selectedOrderId == null ? 'Create Order' : 'Update Order'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _customerIdController,
                    decoration: InputDecoration(
                      labelText: 'Customer ID',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Enter Customer ID' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cropIdController,
                    decoration: InputDecoration(
                      labelText: 'Crop ID',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Enter Crop ID' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Enter Quantity' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _totalPriceController,
                    decoration: InputDecoration(
                      labelText: 'Total Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Enter Total Price' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) { // Validate form inputs
                  if (_selectedOrderId == null) {
                    createOrder(); // Create new order if no ID is selected
                  } else {
                    updateOrder(_selectedOrderId!); // Update existing order
                  }
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

  // Show the order status update dialog
  void _showStatusUpdateDialog(String orderId, String currentStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Order Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Status: $currentStatus'),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: _selectedOrderStatus,
                hint: const Text('Select new status'),
                items: ['pending', 'processed', 'shipped', 'delivered', 'canceled']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedOrderStatus = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_selectedOrderStatus != null) {
                  updateOrderStatus(orderId, _selectedOrderStatus!); // Update order status
                  Navigator.of(context).pop(); // Close the dialog
                } else {
                  _showError('Please select a status'); // Show error if no status is selected
                }
              },
              child: const Text('Update Status'),
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
        title: const Text('Order Management'),
        centerTitle: true, // Center the title
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _clearFields(); // Clear fields for new order
          _showForm(context); // Show the order form
        },
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(), // Show loading indicator
            )
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('Order ID: ${order['order_id']}'),
                    subtitle: Text(
                      'Customer ID: ${order['customer_id']}\n'
                      'Crop ID: ${order['crop_id']}\n'
                      'Quantity: ${order['quantity']}\n'
                      'Total Price: \$${order['total_price']}\n'
                      'Order Status: ${order['order_status']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                          onPressed: () {
                            // Fill fields with existing order data for editing
                            _customerIdController.text = order['customer_id'].toString();
                            _cropIdController.text = order['crop_id'].toString();
                            _quantityController.text = order['quantity'].toString();
                            _totalPriceController.text = order['total_price'].toString();
                            setState(() {
                              _selectedOrderId = order['order_id'].toString(); // Set selected order ID
                            });
                            _showForm(context); // Show form for editing
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteOrder(order['order_id'].toString()), // Delete order
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.blue),
                          onPressed: () {
                            _showStatusUpdateDialog(order['order_id'].toString(), order['order_status']);
                          }, // Update order status
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