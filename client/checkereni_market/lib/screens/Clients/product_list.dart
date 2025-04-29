import '../Componets/Login_screen.dart';
import 'package:flutter/material.dart';
import 'product_details.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  // Get emoji based on crop name
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

  // Format price for display
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

  @override
  void initState() {
    super.initState();
    _fetchCrops();
  }

  Future<void> _fetchCrops() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/crops'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> cropData = json.decode(response.body);
        final List<Crop> crops =
            cropData.map((data) => Crop.fromJson(data)).toList();

        setState(() {
          _allCrops = crops;
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load crops. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Crop> filtered = List.from(_allCrops);

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filtered =
          filtered
              .where(
                (crop) => crop.name.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
              )
              .toList();
    }

    // Apply category filter
    if (_selectedCategory != "All") {
      // This is a simple mapping - adjust based on your actual categorization
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
      filtered =
          filtered
              .where((crop) => categoryItems.contains(crop.name.toLowerCase()))
              .toList();
    }

    // Apply sorting
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

  void _onSearchChanged(String query) {
    setState(() {
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
            icon: Icon(Icons.login_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
          SizedBox(width: 20),
        ],
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header gradient section
          Container(
            height: 135,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade700],
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
                onChanged: _onSearchChanged,
              ),
            ),
          ),

          SizedBox(height: 16),

          // Categories
          CategorySelector(
            onCategorySelected: _onCategorySelected,
            selectedCategory: _selectedCategory,
          ),

          SizedBox(height: 8),

          // Product count and sort
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
                    // Toggle between price and name sorting
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
                          color: Colors.green.shade700,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.green.shade700),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Products list or loading indicator
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.green.shade700,
                      ),
                    )
                    : _errorMessage.isNotEmpty
                    ? Center(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
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
                                builder:
                                    (context) => ProductDetailsScreen(
                                      productName: crop.name,
                                      price: crop.getFormattedPrice(),
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
        backgroundColor: Colors.green.shade700,
        child: Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
