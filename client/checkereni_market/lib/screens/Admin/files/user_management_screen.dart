import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For animations
import 'package:flutter_slidable/flutter_slidable.dart'; // For swipe actions

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  // Main data lists
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers =
      []; // For search/filter functionality
  List<String> roles = [];

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // State variables
  String _selectedRole = 'customer';
  String? _selectedUserId;
  bool _isLoading = false;
  bool _isGridView = false; // Toggle between list and grid view
  String _sortBy = 'username'; // Default sort field
  bool _sortAscending = true; // Default sort direction

  // Filter options
  String? _filterRole;

  // Animation controller
  late AnimationController _animationController;

  // Storage for JWT token
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Theme colors
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF4CAF50);
  final Color paleGreen = const Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Fetch data on initialization
    _fetchUsers();
    _fetchRoles();

    // Initialize search listener
    _searchController.addListener(_filterUsers);
  }

  // Filter users based on search text and role filter
  void _filterUsers() {
    if (mounted) {
      setState(() {
        final query = _searchController.text.toLowerCase();
        filteredUsers =
            users.where((user) {
              final matchesSearch =
                  user['username'].toString().toLowerCase().contains(query) ||
                  user['email'].toString().toLowerCase().contains(query) ||
                  user['phone'].toString().toLowerCase().contains(query);

              final matchesRoleFilter =
                  _filterRole == null || user['role'] == _filterRole;

              return matchesSearch && matchesRoleFilter;
            }).toList();

        // Sort the filtered list
        _sortUsers();
      });
    }
  }

  // Sort users based on current sort field and direction
  void _sortUsers() {
    filteredUsers.sort((a, b) {
      final aValue = a[_sortBy].toString().toLowerCase();
      final bValue = b[_sortBy].toString().toLowerCase();
      return _sortAscending
          ? aValue.compareTo(bValue)
          : bValue.compareTo(aValue);
    });
  }

  // Change sort field and direction
  void _changeSortField(String field) {
    setState(() {
      if (_sortBy == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = field;
        _sortAscending = true;
      }
      _sortUsers();
    });
  }

  // API: Fetch roles from backend
  Future<void> _fetchRoles() async {
    try {
      // Make API request to get all available roles
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/roles'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          // Map response to list of roles
          roles = responseData.map((role) => role.toString()).toList();
          _selectedRole = roles.isNotEmpty ? roles[0] : 'customer';
        });
      } else {
        _showError('Failed to load roles: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Network error when fetching roles: ${e.toString()}');
    }
  }

  // API: Fetch users from backend
  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      // Get JWT token from secure storage
      final token = await _storage.read(key: 'jwt_token');

      // Make API request with authentication
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/users'),
        headers: {
          'Authorization': 'Bearer $token', // Authentication header
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          // Map API response to user objects
          users =
              responseData
                  .map(
                    (user) => {
                      'user_id': user['user_id']?.toString() ?? '',
                      'username': user['username']?.toString() ?? '',
                      'email': user['email']?.toString() ?? '',
                      'phone': user['phone']?.toString() ?? '',
                      'role': user['role']?.toString() ?? 'customer',
                      // Add a color for the avatar based on the username
                      'color': Color(
                        user['username'].toString().hashCode,
                      ).withOpacity(1.0),
                    },
                  )
                  .toList();

          // Initialize filtered users with all users
          filteredUsers = List.from(users);
          _sortUsers(); // Apply initial sorting
        });
      } else {
        _showError('Failed to load users: ${response.body}');
      }
    } catch (e) {
      _showError('Network error when fetching users: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // API: Create a new user
  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Start loading indicator
      setState(() => _isLoading = true);

      // Get JWT token for authentication
      final token = await _storage.read(key: 'jwt_token');

      // Make API request to create user
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
          'role': _selectedRole,
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context);
        await _fetchUsers(); // Refresh user list
        _clearFields();
        _showSuccess('User created successfully');
      } else {
        _showError('Failed to create user: ${response.body}');
      }
    } catch (e) {
      _showError('Network error during user creation: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // API: Update an existing user
  Future<void> _updateUser(String userId) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Start loading indicator
      setState(() => _isLoading = true);

      // Get JWT token for authentication
      final token = await _storage.read(key: 'jwt_token');

      // Prepare update data (include password only if provided)
      final Map<String, dynamic> updateData = {
        'username': _usernameController.text.trim(),
        'role': _selectedRole,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      // Only include password if it was changed
      if (_passwordController.text.isNotEmpty) {
        updateData['password'] = _passwordController.text;
      }

      // Make API request to update user
      final response = await http.put(
        Uri.parse('http://localhost:3000/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        await _fetchUsers(); // Refresh user list
        _clearFields();
        _showSuccess('User updated successfully');
      } else {
        _showError('Failed to update user: ${response.body}');
      }
    } catch (e) {
      _showError('Network error during user update: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // API: Delete a user
  Future<void> _deleteUser(String userId) async {
    try {
      // Start loading indicator
      setState(() => _isLoading = true);

      // Get JWT token for authentication
      final token = await _storage.read(key: 'jwt_token');

      // Make API request to delete user
      final response = await http.delete(
        Uri.parse('http://localhost:3000/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await _fetchUsers(); // Refresh user list
        _showSuccess('User deleted successfully');
      } else {
        _showError('Failed to delete user: ${response.body}');
      }
    } catch (e) {
      _showError('Network error during user deletion: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Reset form fields
  void _clearFields() {
    _usernameController.clear();
    _passwordController.clear();
    _emailController.clear();
    _phoneController.clear();
    _selectedRole = roles.isNotEmpty ? roles[0] : 'customer';
    _selectedUserId = null;
  }

  // Show success message
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: lightGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        animation: CurvedAnimation(
          parent: _animationController,
          curve: Curves.elasticOut,
        ),
      ),
    );
    _animationController.forward(from: 0.0);
  }

  // Show error message
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 5),
        animation: CurvedAnimation(
          parent: _animationController,
          curve: Curves.elasticOut,
        ),
      ),
    );
    _animationController.forward(from: 0.0);
  }

  // Show user form dialog for create/edit
  void _showForm(BuildContext context, [Map<String, dynamic>? user]) {
    // If editing, populate fields with user data
    if (user != null) {
      _selectedUserId = user['user_id'].toString();
      _usernameController.text = user['username'].toString();
      _emailController.text = user['email'].toString();
      _phoneController.text = user['phone'].toString();
      _selectedRole = user['role'].toString();
      _passwordController.clear(); // Don't show existing password
    } else {
      _clearFields(); // Clear fields for new user
    }

    // Show dialog with animated appearance
    showGeneralDialog(
      context: context,
      pageBuilder: (_, __, ___) => Container(), // Required but not used
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutBack,
        );

        return ScaleTransition(
          scale: curvedAnimation,
          child: FadeTransition(
            opacity: curvedAnimation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    user == null ? Icons.person_add : Icons.edit,
                    color: primaryGreen,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    user == null ? 'Create User' : 'Edit User',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Username field
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: TextStyle(color: primaryGreen),
                            prefixIcon: Icon(Icons.person, color: primaryGreen),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: lightGreen,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true
                                      ? 'Username is required'
                                      : null,
                        ),
                      ),

                      // Password field
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText:
                                user == null
                                    ? 'Password'
                                    : 'New Password (leave blank to keep unchanged)',
                            labelStyle: TextStyle(color: primaryGreen),
                            prefixIcon: Icon(Icons.lock, color: primaryGreen),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: lightGreen,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          obscureText: true,
                          validator:
                              (value) =>
                                  user == null && (value?.isEmpty ?? true)
                                      ? 'Password is required for new users'
                                      : null,
                        ),
                      ),

                      // Email field
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: primaryGreen),
                            prefixIcon: Icon(Icons.email, color: primaryGreen),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: lightGreen,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Email is required';
                            }
                            // Basic email validation
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value!)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ),

                      // Phone field
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone',
                            labelStyle: TextStyle(color: primaryGreen),
                            prefixIcon: Icon(Icons.phone, color: primaryGreen),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: lightGreen,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.phone,
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true
                                      ? 'Phone is required'
                                      : null,
                        ),
                      ),

                      // Role dropdown
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Role',
                            labelStyle: TextStyle(color: primaryGreen),
                            prefixIcon: Icon(
                              Icons.admin_panel_settings,
                              color: primaryGreen,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: lightGreen,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items:
                              roles.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedRole = value;
                              });
                            }
                          },
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: primaryGreen,
                          ),
                          dropdownColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                      onPressed: () {
                        if (_selectedUserId == null) {
                          _createUser();
                        } else {
                          _updateUser(_selectedUserId!);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lightGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        shadowColor: lightGreen.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        user == null ? 'Create' : 'Update',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .scale(delay: 100.ms, duration: 300.ms),
              ],
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  // Delete confirmation dialog
  Future<void> _showDeleteConfirmation(Map<String, dynamic> user) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 10),
                const Text('Delete User', style: TextStyle(color: Colors.red)),
              ],
            ),
            content: Text(
              'Are you sure you want to delete ${user['username']}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteUser(user['user_id'].toString());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  // Build user card for grid view
  Widget _buildUserCard(Map<String, dynamic> user) {
    final username = user['username'].toString();
    final email = user['email'].toString();
    final role = user['role'].toString();
    final color = user['color'] ?? Colors.green;

    return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: const EdgeInsets.all(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => _showForm(context, user),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: paleGreen,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: color,
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: lightGreen),
                            onPressed: () => _showForm(context, user),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(user),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
  }

  // Build user list item with swipe actions
  Widget _buildUserListItem(Map<String, dynamic> user) {
    final username = user['username'].toString();
    final email = user['email'].toString();
    final phone = user['phone'].toString();
    final role = user['role'].toString();
    final color = user['color'] ?? Colors.green;

    return Slidable(
          key: ValueKey(user['user_id']),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (_) => _showForm(context, user),
                backgroundColor: lightGreen,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Edit',
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              SlidableAction(
                onPressed: (_) => _showDeleteConfirmation(user),
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
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: color,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              title: Text(
                username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          phone,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: () => _showForm(context, user),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }

  // Filter bar widget
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: Icon(Icons.search, color: primaryGreen),
              filled: true,
              fillColor: paleGreen,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const SizedBox(height: 12),

          // Filter and sort options
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // View toggle
                FilterChip(
                  label: Row(
                    children: [
                      Icon(
                        _isGridView ? Icons.grid_view : Icons.list,
                        size: 16,
                        color: primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(_isGridView ? 'Grid View' : 'List View'),
                    ],
                  ),
                  selected: true,
                  selectedColor: paleGreen,
                  checkmarkColor: primaryGreen,
                  onSelected: (_) {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),

                const SizedBox(width: 8),

                // Role filter
                ChoiceChip(
                  label: Text(_filterRole ?? 'All Roles'),
                  selected: _filterRole != null,
                  selectedColor: paleGreen,
                  onSelected: (_) {
                    // Show role selection dialog
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text(
                              'Filter by Role',
                              style: TextStyle(color: primaryGreen),
                            ),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  ListTile(
                                    title: const Text('All Roles'),
                                    leading:
                                        _filterRole == null
                                            ? Icon(
                                              Icons.check_circle,
                                              color: primaryGreen,
                                            )
                                            : const Icon(Icons.circle_outlined),
                                    onTap: () {
                                      setState(() {
                                        _filterRole = null;
                                      });
                                      Navigator.pop(context);
                                      _filterUsers();
                                    },
                                  ),
                                  ...roles.map(
                                    (role) => ListTile(
                                      title: Text(role),
                                      leading:
                                          _filterRole == role
                                              ? Icon(
                                                Icons.check_circle,
                                                color: primaryGreen,
                                              )
                                              : const Icon(
                                                Icons.circle_outlined,
                                              ),
                                      onTap: () {
                                        setState(() {
                                          _filterRole = role;
                                        });
                                        Navigator.pop(context);
                                        _filterUsers();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                    );
                  },
                ),

                const SizedBox(width: 8),

                // Sort options
                ChoiceChip(
                  label: Row(
                    children: [
                      const Text('Sort'),
                      const SizedBox(width: 4),
                      Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                        color: primaryGreen,
                      ),
                    ],
                  ),
                  selected: true,
                  selectedColor: paleGreen,
                  onSelected: (_) {
                    // Show sort options dialog
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text(
                              'Sort Users',
                              style: TextStyle(color: primaryGreen),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('By Username'),
                                  leading: Radio<String>(
                                    value: 'username',
                                    groupValue: _sortBy,
                                    onChanged: (value) {
                                      setState(() {
                                        _sortBy = value!;
                                      });
                                      _sortUsers();
                                      Navigator.pop(context);
                                    },
                                    activeColor: primaryGreen,
                                  ),
                                ),
                                ListTile(
                                  title: const Text('By Email'),
                                  leading: Radio<String>(
                                    value: 'email',
                                    groupValue: _sortBy,
                                    onChanged: (value) {
                                      setState(() {
                                        _sortBy = value!;
                                      });
                                      _sortUsers();
                                      Navigator.pop(context);
                                    },
                                    activeColor: primaryGreen,
                                  ),
                                ),
                                ListTile(
                                  title: const Text('By Role'),
                                  leading: Radio<String>(
                                    value: 'role',
                                    groupValue: _sortBy,
                                    onChanged: (value) {
                                      setState(() {
                                        _sortBy = value!;
                                      });
                                      _sortUsers();
                                      Navigator.pop(context);
                                    },
                                    activeColor: primaryGreen,
                                  ),
                                ),
                                const Divider(),
                                ListTile(
                                  title: Text(
                                    _sortAscending
                                        ? 'Ascending Order'
                                        : 'Descending Order',
                                  ),
                                  trailing: Switch(
                                    value: _sortAscending,
                                    onChanged: (value) {
                                      setState(() {
                                        _sortAscending = value;
                                      });
                                      _sortUsers();
                                    },
                                    activeColor: primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                    );
                  },
                ),

                const SizedBox(width: 8),

                // Reset filters
                ActionChip(
                  label: const Text('Reset Filters'),
                  avatar: const Icon(Icons.refresh, size: 16),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _filterRole = null;
                      _sortBy = 'username';
                      _sortAscending = true;
                      filteredUsers = List.from(users);
                    });
                    _sortUsers();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // User stats summary widget
  Widget _buildUserStats() {
    // Calculate stats
    final totalUsers = users.length;
    final Map<String, int> roleCounts = {};

    for (final user in users) {
      final role = user['role'].toString();
      roleCounts[role] = (roleCounts[role] ?? 0) + 1;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Statistics',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Users: $totalUsers',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...roleCounts.entries.map((entry) {
              final percent =
                  totalUsers > 0
                      ? (entry.value / totalUsers * 100).toStringAsFixed(1)
                      : '0';

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ${entry.value} ($percent%)',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: totalUsers > 0 ? entry.value / totalUsers : 0,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  @override
  Widget build(BuildContext context) {
    // Main scaffold
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.supervisor_account, color: primaryGreen),
            const SizedBox(width: 8),
            const Text(
              'User Management',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh, color: primaryGreen),
            onPressed: _fetchUsers,
            tooltip: 'Refresh',
          ),
          // Logout button
          IconButton(
            icon: Icon(Icons.logout, color: primaryGreen),
            onPressed: () async {
              // Show logout confirmation
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );

              // Process logout if confirmed
              if (confirm == true) {
                await _storage.delete(key: 'jwt_token');
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      // FAB with animated effect
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        backgroundColor: lightGreen,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Add User',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ).animate().scale(curve: Curves.elasticOut, duration: 500.ms),
      // Main body content
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(lightGreen),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading users...',
                      style: TextStyle(color: primaryGreen),
                    ),
                  ],
                ),
              )
              : Container(
                color: paleGreen.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter bar
                      _buildFilterBar(),

                      const SizedBox(height: 16),

                      // Stats and results count
                      Row(
                        children: [
                          // User stats in expandable section
                          Expanded(flex: 1, child: _buildUserStats()),

                          const SizedBox(width: 16),

                          // Results count
                          Expanded(
                            flex: 2,
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Found ${filteredUsers.length} users',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (filteredUsers.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          _searchController.text.isNotEmpty ||
                                                  _filterRole != null
                                              ? 'No users match your search criteria'
                                              : 'No users available',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    if (_searchController.text.isNotEmpty ||
                                        _filterRole != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'Filtered by: ' +
                                              (_searchController.text.isNotEmpty
                                                  ? 'Search '
                                                  : '') +
                                              (_filterRole != null
                                                  ? 'Role (${'$_filterRole'})'
                                                  : ''),
                                          style: TextStyle(
                                            color: primaryGreen,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // User list/grid
                      Expanded(
                        child:
                            filteredUsers.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_search,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No users found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (_searchController.text.isNotEmpty ||
                                          _filterRole != null)
                                        TextButton.icon(
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Clear filters'),
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                              _filterRole = null;
                                              filteredUsers = List.from(users);
                                            });
                                            _sortUsers();
                                          },
                                        ),
                                    ],
                                  ),
                                )
                                : _isGridView
                                // Grid view for users
                                ? GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount:
                                            3, // Adjust based on screen size
                                        childAspectRatio: 0.8,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                      ),
                                  itemCount: filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    return _buildUserCard(filteredUsers[index]);
                                  },
                                )
                                // List view for users
                                : ListView.builder(
                                  itemCount: filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    return _buildUserListItem(
                                      filteredUsers[index],
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    // Clean up resources
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    _searchController.removeListener(_filterUsers);
    _animationController.dispose();
    super.dispose();
  }
}
