import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class CropManagementScreen extends StatefulWidget {
  const CropManagementScreen({super.key});

  @override
  State<CropManagementScreen> createState() => _CropManagementScreenState();
}

class _CropManagementScreenState extends State<CropManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Name A-Z';
  
  // Sample crop data
  final List<Map<String, dynamic>> _crops = [
    {
      'id': 'CR001',
      'name': 'Organic Tomatoes',
      'category': 'Vegetables',
      'price': 3.99,
      'unit': 'kg',
      'stock': 150,
      'alertThreshold': 20,
      'farmer': 'John Smith',
      'harvestDate': '2025-04-05',
      'description': 'Fresh organic tomatoes grown without pesticides',
      'image': 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea',
      'status': 'Available'
    },
    {
      'id': 'CR002',
      'name': 'Fresh Carrots',
      'category': 'Vegetables',
      'price': 2.49,
      'unit': 'kg',
      'stock': 200,
      'alertThreshold': 30,
      'farmer': 'Maria Garcia',
      'harvestDate': '2025-04-02',
      'description': 'Locally grown fresh carrots',
      'image': 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37',
      'status': 'Available'
    },
    {
      'id': 'CR003',
      'name': 'Golden Apples',
      'category': 'Fruits',
      'price': 4.99,
      'unit': 'kg',
      'stock': 15,
      'alertThreshold': 25,
      'farmer': 'David Wilson',
      'harvestDate': '2025-04-01',
      'description': 'Sweet and juicy golden apples',
      'image': 'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2',
      'status': 'Low Stock'
    },
  ];

  final List<String> _categories = ['All', 'Vegetables', 'Fruits', 'Grains', 'Others'];
  final List<String> _sortOptions = ['Name A-Z', 'Name Z-A', 'Price Low-High', 'Price High-Low', 'Stock Low-High', 'Stock High-Low'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredCrops {
    return _crops.where((crop) {
      final matchesSearch = crop['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          crop['description'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || crop['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList()
      ..sort((a, b) {
        switch (_sortBy) {
          case 'Name A-Z':
            return a['name'].compareTo(b['name']);
          case 'Name Z-A':
            return b['name'].compareTo(a['name']);
          case 'Price Low-High':
            return a['price'].compareTo(b['price']);
          case 'Price High-Low':
            return b['price'].compareTo(a['price']);
          case 'Stock Low-High':
            return a['stock'].compareTo(b['stock']);
          case 'Stock High-Low':
            return b['stock'].compareTo(a['stock']);
          default:
            return 0;
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filter Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search crops...',
                    prefixIcon: const Icon(Feather.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Category Filter
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Sort Options
              DropdownButton<String>(
                value: _sortBy,
                items: _sortOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
                underline: Container(
                  height: 1,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(width: 16),
              // Add New Crop Button
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement add new crop functionality
                },
                icon: const Icon(Feather.plus),
                label: const Text('Add New Crop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Crops Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1,
              ),
              itemCount: filteredCrops.length,
              itemBuilder: (context, index) {
                final crop = filteredCrops[index];
                return _buildCropCard(crop);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropCard(Map<String, dynamic> crop) {
    final isLowStock = crop['stock'] <= crop['alertThreshold'];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  crop['image'],
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              if (isLowStock)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Feather.alert_triangle,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Low Stock',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crop['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  crop['description'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${crop['price'].toStringAsFixed(2)}/${crop['unit']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stock: ${crop['stock']} ${crop['unit']}',
                          style: TextStyle(
                            color: isLowStock ? Colors.red : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Feather.edit_2),
                          onPressed: () {
                            // TODO: Implement edit functionality
                          },
                          color: Colors.blue,
                        ),
                        IconButton(
                          icon: const Icon(Feather.trash_2),
                          onPressed: () {
                            // TODO: Implement delete functionality
                          },
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}