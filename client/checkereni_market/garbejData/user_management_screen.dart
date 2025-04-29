import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Sample user data
  final List<Map<String, dynamic>> _farmers = [
    {'id': 'F001', 'name': 'John Smith', 'email': 'john@example.com', 'phone': '(555) 123-4567', 'status': 'Active', 'region': 'North', 'crops': 'Tomatoes, Corn', 'joinDate': '2024-01-15'},
    {'id': 'F002', 'name': 'Maria Garcia', 'email': 'maria@example.com', 'phone': '(555) 234-5678', 'status': 'Active', 'region': 'South', 'crops': 'Lettuce, Carrots', 'joinDate': '2024-02-20'},
    {'id': 'F003', 'name': 'Robert Chen', 'email': 'robert@example.com', 'phone': '(555) 345-6789', 'status': 'Inactive', 'region': 'East', 'crops': 'Rice, Beans', 'joinDate': '2024-01-05'},
    {'id': 'F004', 'name': 'Sarah Johnson', 'email': 'sarah@example.com', 'phone': '(555) 456-7890', 'status': 'Active', 'region': 'West', 'crops': 'Apples, Peaches', 'joinDate': '2024-03-10'},
    {'id': 'F005', 'name': 'Michael Brown', 'email': 'michael@example.com', 'phone': '(555) 567-8901', 'status': 'Active', 'region': 'North', 'crops': 'Potatoes, Onions', 'joinDate': '2024-02-28'},
  ];
  
  final List<Map<String, dynamic>> _customers = [
    {'id': 'C001', 'name': 'Emma Wilson', 'email': 'emma@example.com', 'phone': '(555) 987-6543', 'status': 'Active', 'location': 'Urban', 'orders': 12, 'joinDate': '2024-01-18'},
    {'id': 'C002', 'name': 'James Davis', 'email': 'james@example.com', 'phone': '(555) 876-5432', 'status': 'Active', 'location': 'Suburban', 'orders': 8, 'joinDate': '2024-02-14'},
    {'id': 'C003', 'name': 'Olivia Martinez', 'email': 'olivia@example.com', 'phone': '(555) 765-4321', 'status': 'Inactive', 'location': 'Rural', 'orders': 3, 'joinDate': '2024-01-30'},
    {'id': 'C004', 'name': 'Noah Thompson', 'email': 'noah@example.com', 'phone': '(555) 654-3210', 'status': 'Active', 'location': 'Urban', 'orders': 15, 'joinDate': '2024-03-05'},
    {'id': 'C005', 'name': 'Sophia Lee', 'email': 'sophia@example.com', 'phone': '(555) 543-2109', 'status': 'Active', 'location': 'Suburban', 'orders': 7, 'joinDate': '2024-02-25'},
  ];
  
  final List<Map<String, dynamic>> _admins = [
    {'id': 'A001', 'name': 'Daniel Taylor', 'email': 'daniel@example.com', 'phone': '(555) 432-1098', 'status': 'Active', 'role': 'Super Admin', 'lastLogin': '2025-04-10 09:45:22'},
    {'id': 'A002', 'name': 'Isabella White', 'email': 'isabella@example.com', 'phone': '(555) 321-0987', 'status': 'Active', 'role': 'Order Manager', 'lastLogin': '2025-04-10 10:30:15'},
    {'id': 'A003', 'name': 'William Anderson', 'email': 'william@example.com', 'phone': '(555) 210-9876', 'status': 'Inactive', 'role': 'Crop Manager', 'lastLogin': '2025-04-05 14:22:47'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredUsers(List<Map<String, dynamic>> users) {
    if (_searchQuery.isEmpty) return users;
    
    return users.where((user) {
      return user['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user['email'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user['id'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header and Actions Row
          Row(
            children: [
              Text(
                'User Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Feather.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Feather.user_plus),
                label: const Text('Add User'),
                onPressed: () {
                  _showAddUserDialog();
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.green[800],
              indicator: BoxDecoration(
                color: Colors.green[800],
                borderRadius: BorderRadius.circular(12),
              ),
              tabs: const [
                Tab(
                  icon: Icon(Feather.users),
                  text: 'Farmers',
                ),
                Tab(
                  icon: Icon(Feather.shopping_bag),
                  text: 'Customers',
                ),
                Tab(
                  icon: Icon(Feather.shield),
                  text: 'Administrators',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTable(_getFilteredUsers(_farmers), [
                  'ID', 'Name', 'Email', 'Phone', 'Status', 'Region', 'Crops', 'Actions'
                ], isFarmer: true),
                _buildUsersTable(_getFilteredUsers(_customers), [
                  'ID', 'Name', 'Email', 'Phone', 'Status', 'Location', 'Orders', 'Actions'
                ]),
                _buildUsersTable(_getFilteredUsers(_admins), [
                  'ID', 'Name', 'Email', 'Phone', 'Status', 'Role', 'Last Login', 'Actions'
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable(List<Map<String, dynamic>> users, List<String> columns, {bool isFarmer = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${users.length} Users Found',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (isFarmer)
                  OutlinedButton.icon(
                    icon: const Icon(Feather.filter),
                    label: const Text('Filter by Region'),
                    onPressed: () {
                      // TODO: Show region filter
                    },
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Feather.download),
                  label: const Text('Export'),
                  onPressed: () {
                    // TODO: Export user data
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Exporting user data...'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                    headingTextStyle: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                    columns: columns.map((column) => DataColumn(
                      label: Text(column),
                    )).toList(),
                    rows: users.map((user) {
                      return DataRow(
                        cells: [
                          DataCell(Text(user['id'], style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  child: Text(
                                    user['name'].toString().substring(0, 1),
                                    style: TextStyle(color: Colors.green[800]),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(user['name']),
                              ],
                            ),
                          ),
                          DataCell(Text(user['email'])),
                          DataCell(Text(user['phone'])),
                          DataCell(_buildStatusBadge(user['status'])),
                          if (isFarmer)
                            DataCell(Text(user['region'])),
                          if (isFarmer)
                            DataCell(Text(user['crops'])),
                          if (!isFarmer && columns.contains('Location'))
                            DataCell(Text(user['location'])),
                          if (!isFarmer && columns.contains('Orders'))
                            DataCell(Text(user['orders'].toString())),
                          if (!isFarmer && columns.contains('Role'))
                            DataCell(Text(user['role'])),
                          if (!isFarmer && columns.contains('Last Login'))
                            DataCell(Text(user['lastLogin'])),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Feather.eye, size: 18),
                                  tooltip: 'View Details',
                                  onPressed: () {
                                    _showUserDetails(user);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Feather.edit_2, size: 18),
                                  tooltip: 'Edit User',
                                  onPressed: () {
                                    _showEditUserDialog(user);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    user['status'] == 'Active' ? Feather.slash : Feather.check, 
                                    size: 18,
                                    color: user['status'] == 'Active' ? Colors.red : Colors.green,
                                  ),
                                  tooltip: user['status'] == 'Active' ? 'Deactivate' : 'Activate',
                                  onPressed: () {
                                    _toggleUserStatus(user);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            if (users.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      Icon(
                        Feather.users,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No users found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'Active' ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details: ${user['name']}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('ID', user['id']),
              _buildDetailRow('Name', user['name']),
              _buildDetailRow('Email', user['email']),
              _buildDetailRow('Phone', user['phone']),
              _buildDetailRow('Status', user['status']),
              if (user.containsKey('region')) _buildDetailRow('Region', user['region']),
              if (user.containsKey('crops')) _buildDetailRow('Crops', user['crops']),
              if (user.containsKey('location')) _buildDetailRow('Location', user['location']),
              if (user.containsKey('orders')) _buildDetailRow('Orders', user['orders'].toString()),
              if (user.containsKey('role')) _buildDetailRow('Role', user['role']),
              if (user.containsKey('joinDate')) _buildDetailRow('Join Date', user['joinDate']),
              if (user.containsKey('lastLogin')) _buildDetailRow('Last Login', user['lastLogin']),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String userType = 'Farmer';
    String status = 'Active';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: userType,
                  decoration: const InputDecoration(
                    labelText: 'User Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Farmer', 'Customer', 'Administrator'].map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    userType = value!;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Active', 'Inactive'].map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    status = value!;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add User'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                // TODO: Create user in database
                Navigator.pop(context);
                
                final newUser = {
                  'id': userType == 'Farmer' ? 'F00${_farmers.length + 1}' :
                         userType == 'Customer' ? 'C00${_customers.length + 1}' : 'A00${_admins.length + 1}',
                  'name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                  'status': status,
                };
                
                setState(() {
                  if (userType == 'Farmer') {
                    final farmerUser = Map<String, dynamic>.from(newUser);
                    farmerUser['region'] = 'North';
                    farmerUser['crops'] = 'Not specified';
                    farmerUser['joinDate'] = '2025-04-11';
                    _farmers.add(farmerUser);
                  } else if (userType == 'Customer') {
                    final customerUser = Map<String, dynamic>.from(newUser);
                    customerUser['location'] = 'Urban';
                    customerUser['orders'] = 0;
                    customerUser['joinDate'] = '2025-04-11';
                    _customers.add(customerUser);
                  } else {
                    final adminUser = Map<String, dynamic>.from(newUser);
                    adminUser['role'] = 'Support Staff';
                    adminUser['lastLogin'] = 'Never';
                    _admins.add(adminUser);
                  }
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$userType added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    final phoneController = TextEditingController(text: user['phone']);
    String status = user['status'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit User: ${user['name']}'),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Active', 'Inactive'].map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    status = value!;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Changes'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                
                setState(() {
                  // Update user in the appropriate list
                  if (user['id'].startsWith('F')) {
                    final index = _farmers.indexWhere((f) => f['id'] == user['id']);
                    if (index != -1) {
                      _farmers[index]['name'] = nameController.text;
                      _farmers[index]['email'] = emailController.text;
                      _farmers[index]['phone'] = phoneController.text;
                      _farmers[index]['status'] = status;
                    }
                  } else if (user['id'].startsWith('C')) {
                    final index = _customers.indexWhere((c) => c['id'] == user['id']);
                    if (index != -1) {
                      _customers[index]['name'] = nameController.text;
                      _customers[index]['email'] = emailController.text;
                      _customers[index]['phone'] = phoneController.text;
                      _customers[index]['status'] = status;
                    }
                  } else if (user['id'].startsWith('A')) {
                    final index = _admins.indexWhere((a) => a['id'] == user['id']);
                    if (index != -1) {
                      _admins[index]['name'] = nameController.text;
                      _admins[index]['email'] = emailController.text;
                      _admins[index]['phone'] = phoneController.text;
                      _admins[index]['status'] = status;
                    }
                  }
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(Map<String, dynamic> user) {
    setState(() {
      if (user['id'].startsWith('F')) {
        final index = _farmers.indexWhere((f) => f['id'] == user['id']);
        if (index != -1) {
          _farmers[index]['status'] = _farmers[index]['status'] == 'Active' ? 'Inactive' : 'Active';
        }
      } else if (user['id'].startsWith('C')) {
        final index = _customers.indexWhere((c) => c['id'] == user['id']);
        if (index != -1) {
          _customers[index]['status'] = _customers[index]['status'] == 'Active' ? 'Inactive' : 'Active';
        }
      } else if (user['id'].startsWith('A')) {
        final index = _admins.indexWhere((a) => a['id'] == user['id']);
        if (index != -1) {
          _admins[index]['status'] = _admins[index]['status'] == 'Active' ? 'Inactive' : 'Active';
        }
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User ${user['status'] == 'Active' ? 'deactivated' : 'activated'} successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}