import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../Componets/Login_screen.dart';
import 'product_details.dart';

// Model class for Crop products
class Crop {
  final int cropId;
  final int? farmerId;
  final String name;
  final String categories;
  final String price;
  final bool isOrganic;
  final bool isFresh;
  final String? imagePath;
  final bool isAvailable;
  final String? productDisplay;
  final String? tags;

  Crop({
    required this.cropId,
    this.farmerId,
    required this.name,
    required this.categories,
    required this.price,
    required this.isOrganic,
    required this.isFresh,
    this.imagePath,
    required this.isAvailable,
    this.productDisplay,
    this.tags,
  });

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      cropId: json['crop_id'],
      farmerId: json['farmer_id'],
      name: json['name'],
      categories: json['categories'] ?? '',
      price: json['price'].toString(),
      isOrganic: json['organic'] == 1,
      isFresh: json['fresh'] == 1,
      imagePath: json['image_path'],
      isAvailable: json['is_available'] == 1,
      productDisplay: json['product_display'],
      tags: json['tags'],
    );
  }

  String getEmoji() {
    switch (name.toLowerCase()) {
      case 'mahindi':
        return '🌽';
      case 'maharage':
        return '🫘';
      case 'ndizi':
        return '🍌';
      case 'nyanya':
        return '🍅';
      case 'vitunguu':
        return '🧅';
      case 'pilipili':
        return '🌶️';
      case 'pilipili hoho':
        return '🍎';
      case 'maembe':
        return '🥭';
      case 'test crop':
        return '🌱';
      case 'mapara chichi':
        return '🥑';
      case 'karafuu':
        return '🌿';
      case 'mdalasini':
        return '🌱';
      case 'machungwa':
        return '🍊';
      case 'ma aple':
        return '🍏';
      case 'mapera':
        return '🍐';
      case 'mapapai':
        return '🍈';
      case 'matikiti maji':
        return '🍉';
      case 'viazi':
        return '🥔';
      case 'mihogo':
        return '🥔';
      case 'karanga':
        return '🥜';
      default:
        return '🌾';
    }
  }

  String getFormattedPrice() {
    return "Tsh ${price}/ 1 kg";
  }
}

class ProductCard extends StatelessWidget {
  final Crop crop;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.crop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(crop.getEmoji(), style: TextStyle(fontSize: 40)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on_outlined,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        SizedBox(width: 4),
                        Text(
                          crop.getFormattedPrice(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (crop.isOrganic) _buildFeatureChip("Organic"),
                        if (crop.isOrganic && crop.isFresh) SizedBox(width: 8),
                        if (crop.isFresh) _buildFeatureChip("Fresh"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                radius: 20,
                child: Icon(Icons.arrow_forward, color: Colors.green.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.green.shade700),
      ),
    );
  }
}

class CategorySelector extends StatelessWidget {
  final Function(String) onCategorySelected;
  final String selectedCategory;

  const CategorySelector({
    super.key,
    required this.onCategorySelected,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ["All", "Grains", "Vegetables", "Fruits", "Spices"];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final isSelected = categories[index] == selectedCategory;
          return GestureDetector(
            onTap: () => onCategorySelected(categories[index]),
            child: Container(
              margin: EdgeInsets.only(right: 12),
              child: Chip(
                backgroundColor:
                    isSelected ? Colors.green.shade700 : Colors.grey.shade100,
                label: Text(
                  categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const SearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: "Tafuta bidhaa...",
          prefixIcon: Icon(Icons.search, color: Colors.green.shade700),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Crop> _allCrops = [];
  List<Crop> _filteredCrops = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedCategory = "All";
  String _sortBy = "Bei";
  final TextEditingController _searchController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://localhost:3000';
  bool _isAuthenticated = false;

  // Custom Colors (aligned with TransactionScreen)
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF81C784);
  final Color backgroundColor = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _checkSessionAndFetchCrops();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkSessionAndFetchCrops() async {
    final token = await _storage.read(key: 'jwt_token');
    setState(() => _isAuthenticated = token != null);
    if (token == null) {
      // Allow public access to crops without redirecting
      await _fetchCrops();
    } else {
      await _fetchCrops(token: token);
    }
  }

  Future<void> _fetchCrops({String? token}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/api/crops/public'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List<dynamic>) {
          final List<Crop> crops = decoded.map((data) => Crop.fromJson(data)).toList();
          setState(() {
            _allCrops = crops;
            _applyFilters();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Invalid response format: Expected a list';
            _isLoading = false;
          });
          _showError('Invalid response format from server');
        }
      } else if (response.statusCode == 401 && token != null) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        setState(() => _isAuthenticated = false);
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          _errorMessage = 'Failed to load crops: ${response.statusCode}\n${response.body}';
          _isLoading = false;
        });
        _showError('Failed to load crops: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching crops: ${e.toString()}';
        _isLoading = false;
      });
      _showError('Error fetching crops: $e');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.delete(key: 'jwt_token');
      _showSuccess('Logged out successfully');
      setState(() => _isAuthenticated = false);
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _applyFilters() {
    List<Crop> filtered = List.from(_allCrops);

    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((crop) =>
              crop.name.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    }

    if (_selectedCategory != "All") {
      Map<String, List<String>> categoryMapping = {
        "Grains": ["mahindi", "mchele", "ngano", "uwele", "mtama"],
        "Vegetables": ["nyanya", "vitunguu", "pilipili"],
        "Fruits": [
          "ndizi",
          "machungwa",
          "maembe",
          "ma aple",
          "mapera",
          "mapapai",
          "matikitiki",
          "mapara chichi",
        ],
        "Spices": [
          "iliki",
          "binzari",
          "pilipili hoho",
          "karafuu",
          "mdalasini",
          "vanilla",
          "nyanya chungu",
          "viazi",
          "miogo",
          "karanga",
        ],
      };

      List<String> categoryItems = categoryMapping[_selectedCategory] ?? [];
      filtered = filtered
          .where((crop) => categoryItems.contains(crop.name.toLowerCase()))
          .toList();
    }

    if (_sortBy == "Bei") {
      filtered.sort((a, b) {
        double priceA = double.tryParse(a.price) ?? 0;
        double priceB = double.tryParse(b.price) ?? 0;
        return priceA.compareTo(priceB);
      });
    } else if (_sortBy == "Jina") {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    setState(() {
      _filteredCrops = filtered;
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      _applyFilters();
    });
  }

  void _onSearchChanged() {
    setState(() {
      _applyFilters();
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(12),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: lightGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(12),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Bidhaa za Msimu",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notification_add, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              _isAuthenticated ? Icons.logout : Icons.login,
              color: Colors.white,
            ),
            onPressed: () {
              if (_isAuthenticated) {
                _logout();
              } else {
                Navigator.pushNamed(context, '/login');
              }
            },
            tooltip: _isAuthenticated ? 'Logout' : 'Login',
          ),
          SizedBox(width: 20),
        ],
        backgroundColor: primaryGreen,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            height: 135,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGreen, primaryGreen],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 80, 16, 0),
              child: SearchBar(
                controller: _searchController,
                onChanged: (_) => _onSearchChanged(),
              ),
            ),
          ),
          SizedBox(height: 16),
          CategorySelector(
            onCategorySelected: _onCategorySelected,
            selectedCategory: _selectedCategory,
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_filteredCrops.length} bidhaa zinapatikana",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _onSortChanged(_sortBy == "Bei" ? "Jina" : "Bei");
                  },
                  child: Row(
                    children: [
                      Text(
                        "Panga: ",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      Text(
                        _sortBy,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: primaryGreen),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryGreen))
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 48),
                            SizedBox(height: 16),
                            Text(_errorMessage, style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      )
                    : _filteredCrops.isEmpty
                        ? Center(child: Text("Hakuna bidhaa zinazopatikana"))
                        : ListView.builder(
                            itemCount: _filteredCrops.length,
                            padding: EdgeInsets.only(top: 8, bottom: 20),
                            itemBuilder: (context, index) {
                              final crop = _filteredCrops[index];
                              return ProductCard(
                                crop: crop,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailsScreen(
                                        productId: crop.cropId,
                                        farmerId: crop.farmerId ?? 0,
                                        productName: crop.name,
                                        price: crop.getFormattedPrice(),
                                        isOrganic: crop.isOrganic,
                                        isFresh: crop.isFresh,
                                        categories: crop.categories,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryGreen,
        child: Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
    );
  }
}