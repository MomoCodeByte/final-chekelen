import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  _OrderManagementScreenState createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> orders = [];
  List<dynamic> filteredOrders = [];
  final TextEditingController _customerIdController = TextEditingController();
  final TextEditingController _cropIdController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String? _selectedOrderId;
  String? _selectedOrderStatus;
  String? _statusFilter;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animationController;
  final currencyFormatter = NumberFormat.currency(symbol: 'Tsh: ');

  // Secure storage for JWT token
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Change this to your server URL
  final String baseUrl =
      'http://localhost:3000'; // Use 10.0.2.2 for Android emulator

  // Custom Colors
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF81C784);
  final Color darkGreen = const Color(0xFF1B5E20);
  final Color backgroundColor = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchController.addListener(_filterOrders);
    _checkSessionAndFetchOrders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.removeListener(_filterOrders);
    _searchController.dispose();
    _customerIdController.dispose();
    _cropIdController.dispose();
    _quantityController.dispose();
    _totalPriceController.dispose();
    super.dispose();
  }

  // Check for token and fetch orders, redirect to login if no token
  Future<void> _checkSessionAndFetchOrders() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      _showError('No session found. Please log in.');
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    await fetchOrders();
  }

  void _filterOrders() {
    setState(() {
      filteredOrders =
          orders.where((order) {
            final searchMatch =
                _searchController.text.isEmpty ||
                order['order_id'].toString().contains(_searchController.text) ||
                order['customer_id'].toString().contains(
                  _searchController.text,
                ) ||
                order['crop_id'].toString().contains(_searchController.text);

            final statusMatch =
                _statusFilter == null || order['order_status'] == _statusFilter;

            return searchMatch && statusMatch;
          }).toList();
    });
  }

  // Fetch Orders
  Future<void> fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _showError('No session found. Please log in.');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          orders = json.decode(response.body);
          _filterOrders();
        });
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError(
          'Failed to load orders: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      _showError('Error loading orders: $e');
    }
    setState(() => _isLoading = false);
  }

  // Create Order
  Future<void> createOrder() async {
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
        Uri.parse('$baseUrl/api/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'customer_id': int.tryParse(_customerIdController.text) ?? 0,
          'crop_id': int.tryParse(_cropIdController.text) ?? 0,
          'quantity': int.tryParse(_quantityController.text) ?? 0,
          'total_price': double.tryParse(_totalPriceController.text) ?? 0.0,
        }),
      );

      if (response.statusCode == 201) {
        await fetchOrders();
        _clearFields();
        _showSuccess('Order created successfully!');
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError(
          'Failed to create order: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      _showError('Error creating order: $e');
    }
    setState(() => _isLoading = false);
  }

  // Update Order
  Future<void> updateOrder(String id) async {
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
        Uri.parse('$baseUrl/api/orders/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'customer_id': int.parse(_customerIdController.text),
          'crop_id': int.parse(_cropIdController.text),
          'quantity': int.parse(_quantityController.text),
          'total_price': double.parse(_totalPriceController.text),
        }),
      );

      if (response.statusCode == 200) {
        await fetchOrders();
        _clearFields();
        _showSuccess('Order updated successfully!');
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError(
          'Failed to update order: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      _showError('Error updating order: $e');
    }
    setState(() => _isLoading = false);
  }

  // Update Order Status
  Future<void> updateOrderStatus(String id, String status) async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _showError('No session found. Please log in.');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/orders/$id/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'order_status': status}),
      );

      if (response.statusCode == 200) {
        await fetchOrders();
        _showSuccess('Order status updated to $status successfully!');
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError(
          'Failed to update order status: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      _showError('Error updating order status: $e');
    }
    setState(() => _isLoading = false);
  }

  // Delete Order
  Future<void> deleteOrder(String id) async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _showError('No session found. Please log in.');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/orders/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchOrders();
        _showSuccess('Order deleted successfully!');
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError(
          'Failed to delete order: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      _showError('Error deleting order: $e');
    }
    setState(() => _isLoading = false);
  }

  // Logout function
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

  void _clearFields() {
    _customerIdController.clear();
    _cropIdController.clear();
    _quantityController.clear();
    _totalPriceController.clear();
    setState(() {
      _selectedOrderId = null;
      _selectedOrderStatus = null;
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
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: Text(
            _selectedOrderId == null ? 'Create Order' : 'Update Order',
            style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFormField(
                    _customerIdController,
                    'Customer ID',
                    Icons.person,
                    TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    _cropIdController,
                    'Crop ID',
                    Icons.grass,
                    TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    _quantityController,
                    'Quantity',
                    Icons.shopping_cart,
                    TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildFormField(
                    _totalPriceController,
                    'Total Price',
                    Icons.attach_money,
                    const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (_selectedOrderId == null) {
                    createOrder();
                  } else {
                    updateOrder(_selectedOrderId!);
                  }
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormField(
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType keyboardType,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightGreen),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        if (keyboardType == TextInputType.number &&
            double.tryParse(value) == null) {
          return 'Enter a valid number';
        }
        return null;
      },
    );
  }

  void _showStatusUpdateDialog(String orderId, String currentStatus) {
    setState(() {
      _selectedOrderStatus = currentStatus;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Update Order Status',
            style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Status:',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(currentStatus).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor(currentStatus)),
                ),
                child: Text(
                  currentStatus,
                  style: TextStyle(
                    color: _getStatusColor(currentStatus),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('New Status:', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.grey[50],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedOrderStatus,
                    hint: const Text('Select new status'),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_circle),
                    iconEnabledColor: primaryGreen,
                    items:
                        [
                              'pending',
                              'processed',
                              'shipped',
                              'delivered',
                              'canceled',
                            ]
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      status,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedOrderStatus = value;
                      });
                    },
                  ),
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
              onPressed: () {
                if (_selectedOrderStatus != null) {
                  updateOrderStatus(orderId, _selectedOrderStatus!);
                  Navigator.of(context).pop();
                } else {
                  _showError('Please select a status');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Update Status'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete Order #$orderId?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              onPressed: () {
                deleteOrder(orderId);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processed':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey; // Fallback for invalid or unknown statuses
    }
  }

  Widget _buildOrderStatusChip(String? status) {
    final safeStatus = status ?? 'pending'; // Default to 'pending' for null
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _getStatusColor(safeStatus).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(safeStatus)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(safeStatus),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            safeStatus,
            style: TextStyle(
              color: _getStatusColor(safeStatus),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.add_business_sharp, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Order Management',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchOrders,
            tooltip: 'Refresh Orders',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _clearFields();
          _showForm(context);
        },
        backgroundColor: primaryGreen,
        icon: const Icon(Icons.add_business_sharp, color: Colors.white),
        label: const Text(
          'Add Order',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ).animate().scale(
        curve: Curves.elasticOut,
        duration: const Duration(milliseconds: 500),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Search and Filter Bar
                  Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 1,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Search field
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search orders...',
                            prefixIcon: Icon(Icons.search, color: primaryGreen),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color.fromARGB(255, 255, 254, 254),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color.fromARGB(255, 255, 254, 254),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryGreen,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(255, 204, 238, 207),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Status filter chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All', null),
                              _buildFilterChip('Pending', 'pending'),
                              _buildFilterChip('Processed', 'processed'),
                              _buildFilterChip('Shipped', 'shipped'),
                              _buildFilterChip('Delivered', 'delivered'),
                              _buildFilterChip('Canceled', 'canceled'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Order Summary
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Text(
                          'Orders (${filteredOrders.length})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const Spacer(),
                        if (_statusFilter != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _statusFilter = null;
                              });
                              _filterOrders();
                            },
                            child: Text(
                              'Clear Filters',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 113, 101, 221),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Orders List
                  Expanded(
                    child:
                        _isLoading
                            ? Center(
                              child: CircularProgressIndicator(
                                color: primaryGreen,
                              ),
                            )
                            : filteredOrders.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No orders found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _statusFilter != null
                                        ? 'Try changing your filter'
                                        : 'Create a new order to get started',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = filteredOrders[index];
                                final orderId =
                                    order['order_id']?.toString() ?? 'N/A';
                                final customerId =
                                    order['customer_id']?.toString() ?? 'N/A';
                                final cropId =
                                    order['crop_id']?.toString() ?? 'N/A';
                                final quantity =
                                    order['quantity']?.toString() ?? '0';
                                final totalPrice =
                                    order['total_price']?.toString() ?? '0.00';
                                final orderStatus =
                                    order['order_status'] ?? 'pending';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: _getStatusColor(orderStatus),
                                            width: 8,
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Order Header
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: primaryGreen
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.shopping_bag,
                                                    color: primaryGreen,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Order #$orderId',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Customer ID: $customerId',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                _buildOrderStatusChip(
                                                  orderStatus,
                                                ),
                                              ],
                                            ),
                                            const Divider(height: 24),
                                            // Order Details
                                            Row(
                                              children: [
                                                _buildDetailItem(
                                                  'Crop ID',
                                                  cropId,
                                                  Icons.grass,
                                                ),
                                                _buildDetailItem(
                                                  'Quantity',
                                                  quantity,
                                                  Icons.shopping_cart,
                                                ),
                                                _buildDetailItem(
                                                  'Price',
                                                  currencyFormatter.format(
                                                    double.tryParse(
                                                          totalPrice,
                                                        ) ??
                                                        0.0,
                                                  ),
                                                  Icons.attach_money,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            // Action Buttons
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.edit_outlined,
                                                    color: primaryGreen,
                                                  ),
                                                  tooltip: 'Edit Order',
                                                  onPressed: () {
                                                    _customerIdController.text =
                                                        customerId;
                                                    _cropIdController.text =
                                                        cropId;
                                                    _quantityController.text =
                                                        quantity;
                                                    _totalPriceController.text =
                                                        totalPrice;
                                                    setState(() {
                                                      _selectedOrderId =
                                                          orderId;
                                                    });
                                                    _showForm(context);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.update,
                                                    color: Colors.blue,
                                                  ),
                                                  tooltip: 'Update Status',
                                                  onPressed: () {
                                                    _showStatusUpdateDialog(
                                                      orderId,
                                                      orderStatus,
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                  ),
                                                  tooltip: 'Delete Order',
                                                  onPressed: () {
                                                    _showDeleteConfirmationDialog(
                                                      orderId,
                                                    );
                                                  },
                                                ),
                                              ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _statusFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _statusFilter = isSelected ? null : value;
        });
        _filterOrders();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
