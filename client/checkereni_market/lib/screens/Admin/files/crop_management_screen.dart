import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class CropManagementScreen extends StatefulWidget {
  const CropManagementScreen({super.key});

  @override
  _CropManagementScreenState createState() => _CropManagementScreenState();
}

class _CropManagementScreenState extends State<CropManagementScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> crops = [];
  List<dynamic> filteredCrops = [];
  final TextEditingController _farmerIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoriesController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isAvailable = true;
  bool _isOrganic = false;
  bool _isFresh = false;
  File? _imageFile;
  String? _imagePath;
  String? _selectedCropId;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;

  // Secure storage for JWT token
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Filter options
  bool _filterAvailable = false;
  bool _filterOrganic = false;
  bool _filterFresh = false;
  String _sortBy = 'name'; // Default sort by name

  // Custom colors
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF81C784);
  final Color darkGreen = const Color(0xFF1B5E20);
  final Color backgroundColor = const Color(0xFFF5F5F5);

  // Currency formatter
  final currencyFormat = NumberFormat.currency(
    symbol: 'Tsh ',
    decimalDigits: 0,
  );

  // Change this to your server URL
  final String baseUrl =
      'http://localhost:3000'; // Use 10.0.2.2 for Android emulator

  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num)
      return value.toDouble(); // If it's already a number, return as double
    String priceStr = value.toString().trim();
    if (priceStr.isEmpty) return 0.0;

    try {
      return double.parse(priceStr); // Parse the string to double
    } catch (e) {
      return 0.0; // Return 0.0 if parsing fails
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchController.addListener(_filterCrops);
    _checkSessionAndFetchCrops();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.removeListener(_filterCrops);
    _searchController.dispose();
    _farmerIdController.dispose();
    _nameController.dispose();
    _categoriesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Check for token and fetch crops, redirect to login if no token
  Future<void> _checkSessionAndFetchCrops() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      _showMessage('No session found. Please log in.', isError: true);
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    await _fetchCrops();
  }

  void _filterCrops() {
    setState(() {
      filteredCrops =
          crops.where((crop) {
            // Apply text search
            final searchMatch =
                _searchController.text.isEmpty ||
                crop['name'].toString().toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                (crop['categories'] != null &&
                    crop['categories'].toString().toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    ));

            // Apply availability filter
            final availabilityMatch =
                !_filterAvailable || crop['is_available'] == 1;

            // Apply organic filter
            final organicMatch = !_filterOrganic || crop['organic'] == 1;

            // Apply fresh filter
            final freshMatch = !_filterFresh || crop['fresh'] == 1;

            return searchMatch &&
                availabilityMatch &&
                organicMatch &&
                freshMatch;
          }).toList();

      // Apply sorting
      filteredCrops.sort((a, b) {
        switch (_sortBy) {
          case 'name':
            return a['name'].toString().compareTo(b['name'].toString());
          case 'price_low':
            return _parsePrice(a['price']).compareTo(_parsePrice(b['price']));
          case 'price_high':
            return _parsePrice(b['price']).compareTo(_parsePrice(a['price']));
          default:
            return 0;
        }
      });
    });
  }

  Future<void> _fetchCrops() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _showMessage('No session found. Please log in.', isError: true);
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/crops'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          crops = json.decode(response.body);
          _filterCrops(); // Apply initial filtering
        });
      } else if (response.statusCode == 401) {
        _showMessage('Session expired. Please log in again.', isError: true);
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showMessage(
          'Failed to load crops: ${response.statusCode}\n${response.body}',
          isError: true,
        );
      }
    } catch (e) {
      _showMessage('Error loading crops: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imagePath = null; // Clear existing path when new image is selected
        });
      }
    } catch (e) {
      _showMessage('Error picking image: $e', isError: true);
    }
  }

  Future<void> _takePicture() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imagePath = null; // Clear existing path when new image is selected
        });
      }
    } catch (e) {
      _showMessage('Error taking picture: $e', isError: true);
    }
  }

  Future<void> _createOrUpdateCrop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _showMessage('No session found. Please log in.', isError: true);
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final url =
          _selectedCropId == null
              ? Uri.parse('$baseUrl/api/crops')
              : Uri.parse('$baseUrl/api/crops/$_selectedCropId');

      final request = http.MultipartRequest(
        _selectedCropId == null ? 'POST' : 'PUT',
        url,
      );

      // Add Authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields['farmer_id'] = _farmerIdController.text;
      request.fields['name'] = _nameController.text;
      request.fields['categories'] =
          _categoriesController.text.isNotEmpty
              ? _categoriesController.text
              : '';

      // Ensure price is a valid number
      final price = _parsePrice(_priceController.text);
      request.fields['price'] = price.toString();
      request.fields['is_available'] = _isAvailable ? '1' : '0';
      request.fields['organic'] = _isOrganic ? '1' : '0';
      request.fields['fresh'] = _isFresh ? '1' : '0';

      // Add image file if selected
      if (_imageFile != null) {
        final fileStream = http.ByteStream(_imageFile!.openRead());
        final fileLength = await _imageFile!.length();

        final multipartFile = http.MultipartFile(
          'image',
          fileStream,
          fileLength,
          filename: path.basename(_imageFile!.path),
          contentType: MediaType(
            'image',
            path.extension(_imageFile!.path).toLowerCase().substring(1),
          ),
        );

        request.files.add(multipartFile);
      } else if (_imagePath != null && _selectedCropId != null) {
        // If updating without changing image, send the existing path
        request.fields['image_path'] = _imagePath!;
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        await _fetchCrops();
        _clearFields();
        if (mounted) Navigator.of(context).pop();
        _showMessage(
          _selectedCropId == null
              ? 'Crop created successfully!'
              : 'Crop updated successfully!',
          isError: false,
        );
      } else if (response.statusCode == 401) {
        _showMessage('Session expired. Please log in again.', isError: true);
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showMessage(
          'Failed to ${_selectedCropId == null ? 'create' : 'update'} crop: ${response.statusCode}\n${response.body}',
          isError: true,
        );
      }
    } catch (e) {
      _showMessage('Error: ${e.toString()}', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteCrop(String id) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Confirm Deletion'),
            content: const Text(
              'Are you sure you want to delete this crop? This cannot be undone.',
            ),
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
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (shouldDelete != true) return;

    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _showMessage('No session found. Please log in.', isError: true);
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/crops/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await _fetchCrops();
        _showMessage('Crop deleted successfully!', isError: false);
      } else if (response.statusCode == 401) {
        _showMessage('Session expired. Please log in again.', isError: true);
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showMessage(
          'Failed to delete crop: ${response.statusCode}\n${response.body}',
          isError: true,
        );
      }
    } catch (e) {
      _showMessage('Error deleting crop: $e', isError: true);
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
      _showMessage('Logged out successfully', isError: false);
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _clearFields() {
    _farmerIdController.clear();
    _nameController.clear();
    _categoriesController.clear();
    _priceController.clear();
    setState(() {
      _isAvailable = true;
      _isOrganic = false;
      _isFresh = false;
      _imageFile = null;
      _imagePath = null;
      _selectedCropId = null;
    });
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : lightGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _loadCropData(String id) {
    final crop = crops.firstWhere((c) => c['crop_id'].toString() == id);
    _farmerIdController.text = crop['farmer_id'].toString();
    _nameController.text = crop['name'];
    _categoriesController.text = crop['categories'] ?? '';
    _priceController.text = crop['price'].toString();
    setState(() {
      _isAvailable = crop['is_available'] == 1;
      _isOrganic = crop['organic'] == 1;
      _isFresh = crop['fresh'] == 1;
      _imagePath = crop['image_path'];
      _selectedCropId = id;
      _imageFile =
          null; // Clear any selected new image when loading existing crop
    });
  }

  Widget _buildCropItem(dynamic crop, int index) {
    final bool isAvailable = crop['is_available'] == 1;
    final bool isOrganic = crop['organic'] == 1;
    final bool isFresh = crop['fresh'] == 1;

    return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with overlay for unavailable items
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child:
                          crop['image_path'] != null
                              ? CachedNetworkImage(
                                imageUrl: '$baseUrl/${crop['image_path']}',
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      height: 180,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      height: 180,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(
                                          Icons.error_outline,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                              )
                              : Container(
                                height: 180,
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                    ),
                    // Availability overlay
                    if (!isAvailable)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Currently Unavailable',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Crop details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              crop['name'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'ID: ${crop['crop_id']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Farmer ID: ${crop['farmer_id']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Categories
                      if (crop['categories'] != null &&
                          crop['categories'].toString().isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            crop['categories'] ?? 'No categories',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: Icon(
                              Icons.edit,
                              size: 16,
                              color: primaryGreen,
                            ),
                            label: Text(
                              'Edit',
                              style: TextStyle(color: primaryGreen),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primaryGreen),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              _loadCropData(crop['crop_id'].toString());
                              _showForm(context);
                            },
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed:
                                () => _deleteCrop(crop['crop_id'].toString()),
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
        .fadeIn(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: index * 50),
        )
        .slideY(
          begin: 0.1,
          end: 0,
          curve: Curves.easeOutQuad,
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 50),
        );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '$label is required';
        }
        if (keyboardType == TextInputType.number &&
            value != null &&
            value.isNotEmpty) {
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
        }
        return null;
      },
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    required Color activeColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: value ? activeColor : Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: value ? darkGreen : Colors.grey[700],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
          activeTrackColor: activeColor.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildFilterOption({
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: value ? primaryGreen : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: value ? primaryGreen : Colors.grey[800],
                fontWeight: value ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            Checkbox(
              value: value,
              onChanged: (val) => onChanged(val!),
              activeColor: primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required String title,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    final bool isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryGreen : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? primaryGreen : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grass_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No crops found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first crop by clicking the + button',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Add New Crop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search crops by name or categories...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: primaryGreen),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _filterCrops();
                  },
                ),
              IconButton(
                icon: Icon(Icons.filter_list, color: primaryGreen),
                onPressed: _showFilterBottomSheet,
              ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter & Sort',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    // Filter options
                    Text(
                      'Filter by',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFilterOption(
                      title: 'Available Only',
                      value: _filterAvailable,
                      onChanged:
                          (value) => setState(() => _filterAvailable = value),
                      icon: Icons.check_circle,
                    ),
                    const SizedBox(height: 8),
                    _buildFilterOption(
                      title: 'Organic Only',
                      value: _filterOrganic,
                      onChanged:
                          (value) => setState(() => _filterOrganic = value),
                      icon: Icons.eco,
                    ),
                    const SizedBox(height: 8),
                    _buildFilterOption(
                      title: 'Fresh Only',
                      value: _filterFresh,
                      onChanged:
                          (value) => setState(() => _filterFresh = value),
                      icon: Icons.water_drop,
                    ),
                    const SizedBox(height: 24),
                    // Sort options
                    Text(
                      'Sort by',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSortOption(
                      title: 'Name (A-Z)',
                      value: 'name',
                      groupValue: _sortBy,
                      onChanged: (value) => setState(() => _sortBy = value!),
                      icon: Icons.sort_by_alpha,
                    ),
                    const SizedBox(height: 8),
                    _buildSortOption(
                      title: 'Price (Low to High)',
                      value: 'price_low',
                      groupValue: _sortBy,
                      onChanged: (value) => setState(() => _sortBy = value!),
                      icon: Icons.trending_up,
                    ),
                    const SizedBox(height: 8),
                    _buildSortOption(
                      title: 'Price (High to Low)',
                      value: 'price_high',
                      groupValue: _sortBy,
                      onChanged: (value) => setState(() => _sortBy = value!),
                      icon: Icons.trending_down,
                    ),
                    const SizedBox(height: 32),
                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _filterCrops();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _filterAvailable = false;
                            _filterOrganic = false;
                            _filterFresh = false;
                            _sortBy = 'name';
                          });
                        },
                        child: Text(
                          'Reset All',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ),
                    // Add extra padding at the bottom for better UX with the keyboard
                    SizedBox(
                      height:
                          MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 0,
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Crop Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCrops,
            tooltip: 'Refresh crops',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _clearFields();
          _showForm(context);
        },
        backgroundColor: primaryGreen,
        child: const Icon(Icons.add),
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        color: primaryGreen,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading crops...',
                      style: TextStyle(
                        color: darkGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _fetchCrops,
                color: primaryGreen,
                child: Column(
                  children: [
                    // Search bar
                    _buildSearchBar(),
                    // Showing applied filters
                    if (_filterAvailable ||
                        _filterOrganic ||
                        _filterFresh ||
                        _sortBy != 'name' ||
                        _searchController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Filtered Results:',
                              style: TextStyle(
                                color: darkGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${filteredCrops.length} crops found',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _filterAvailable = false;
                                  _filterOrganic = false;
                                  _filterFresh = false;
                                  _sortBy = 'name';
                                });
                                _filterCrops();
                              },
                              child: const Text('Clear Filters'),
                            ),
                          ],
                        ),
                      ),
                    // Crop list or empty state
                    Expanded(
                      child:
                          filteredCrops.isEmpty
                              ? _buildEmptyState()
                              : isTablet
                              ? _buildTabletLayout()
                              : _buildMobileLayout(),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildMobileLayout() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
      itemCount: filteredCrops.length,
      itemBuilder:
          (context, index) => _buildCropItem(filteredCrops[index], index),
    );
  }

  Widget _buildTabletLayout() {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredCrops.length,
      itemBuilder:
          (context, index) => _buildCropItem(filteredCrops[index], index),
    );
  }

  void _showForm(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width:
                      MediaQuery.of(context).size.width > 600
                          ? 600
                          : MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Icon(
                                _selectedCropId == null
                                    ? Icons.add
                                    : Icons.edit,
                                color: primaryGreen,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedCropId == null
                                    ? 'Add New Crop'
                                    : 'Edit Crop',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          // Image upload section
                          Center(
                            child: Column(
                              children: [
                                if (_imageFile != null && !kIsWeb)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _imageFile!,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else if (_imagePath != null &&
                                    _selectedCropId != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: '$baseUrl/$_imagePath',
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                            height: 120,
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Container(
                                            height: 120,
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Icon(
                                                Icons.error,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                    ),
                                  )
                                else
                                  Container(
                                    height: 120,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.add_photo_alternate,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.photo_library),
                                      label: const Text('Gallery'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: lightGreen,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: _pickImage,
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Camera'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryGreen,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          !kIsWeb
                                              ? _takePicture
                                              : null, // Disable camera on web
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Form fields
                          _buildFormField(
                            controller: _nameController,
                            label: 'Crop Name',
                            icon: Icons.grass,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            controller: _farmerIdController,
                            label: 'Farmer ID',
                            icon: Icons.person,
                            isRequired: true,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            controller: _priceController,
                            label: 'Price (Tsh)',
                            icon: Icons.attach_money,
                            isRequired: true,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            controller: _categoriesController,
                            label: 'Categories',
                            icon: Icons.category,
                            isRequired: false,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          // Toggle switches
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              children: [
                                _buildSwitchTile(
                                  title: 'Available',
                                  subtitle:
                                      'Is this crop available for purchase?',
                                  value: _isAvailable,
                                  onChanged:
                                      (value) =>
                                          setState(() => _isAvailable = value),
                                  icon: Icons.check_circle,
                                  activeColor: lightGreen,
                                ),
                                const Divider(height: 16),
                                _buildSwitchTile(
                                  title: 'Organic',
                                  subtitle: 'Is this crop organically grown?',
                                  value: _isOrganic,
                                  onChanged:
                                      (value) =>
                                          setState(() => _isOrganic = value),
                                  icon: Icons.eco,
                                  activeColor: darkGreen,
                                ),
                                const Divider(height: 16),
                                _buildSwitchTile(
                                  title: 'Fresh',
                                  subtitle: 'Is this crop freshly harvested?',
                                  value: _isFresh,
                                  onChanged:
                                      (value) =>
                                          setState(() => _isFresh = value),
                                  icon: Icons.water_drop,
                                  activeColor: lightGreen,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _createOrUpdateCrop,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(120, 48),
                                ),
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Text(
                                          _selectedCropId == null
                                              ? 'Create Crop'
                                              : 'Update Crop',
                                          style: const TextStyle(fontSize: 16),
                                        ),
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
    );
  }
}
