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
      'status': 'Available',
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
      'status': 'Available',
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
      'status': 'Low Stock',
    },
  ];

  final List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Grains',
    'Others',
  ];
  final List<String> _sortOptions = [
    'Name A-Z',
    'Name Z-A',
    'Price Low-High',
    'Price High-Low',
    'Stock Low-High',
    'Stock High-Low',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredCrops {
    return _crops.where((crop) {
        final matchesSearch =
            crop['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
            crop['description'].toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
        final matchesCategory =
            _selectedCategory == 'All' || crop['category'] == _selectedCategory;
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
                items:
                    _categories.map((category) {
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
                items:
                    _sortOptions.map((option) {
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
                underline: Container(height: 1, color: Colors.grey[300]),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
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







// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'package:http_parser/http_parser.dart';
// import 'package:path/path.dart' as path;
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';

// class CropManagementScreen extends StatefulWidget {
//   const CropManagementScreen({Key? key}) : super(key: key);

//   @override
//   _CropManagementScreenState createState() => _CropManagementScreenState();
// }

// class _CropManagementScreenState extends State<CropManagementScreen>
//     with SingleTickerProviderStateMixin {
//   List<dynamic> crops = [];
//   List<dynamic> filteredCrops = [];
//   final TextEditingController _farmerIdController = TextEditingController();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _priceController = TextEditingController();
//   final TextEditingController _searchController = TextEditingController();

//   bool _isAvailable = true;
//   bool _isOrganic = false;
//   bool _isFresh = false;
//   File? _imageFile;
//   String? _imagePath;
//   String? _selectedCropId;
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;
//   final ImagePicker _picker = ImagePicker();
//   late AnimationController _animationController;

//   // Filter options
//   bool _filterAvailable = false;
//   bool _filterOrganic = false;
//   bool _filterFresh = false;
//   String _sortBy = 'name'; // Default sort by name

//   // Custom colors
//   final Color primaryGreen = const Color(0xFF2E7D32);
//   final Color lightGreen = const Color(0xFF81C784);
//   final Color darkGreen = const Color(0xFF1B5E20);
//   final Color backgroundColor = const Color(0xFFF5F5F5);

//   // Currency formatter
//   final currencyFormat = NumberFormat.currency(
//     symbol: 'Tsh ',
//     decimalDigits: 0,
//   );

//   // Change this to your server URL
//   final String baseUrl =
//       'http://localhost:3000'; // Use 10.0.2.2 for Android emulator

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _searchController.addListener(_filterCrops);
//     _fetchCrops();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _searchController.removeListener(_filterCrops);
//     _searchController.dispose();
//     _farmerIdController.dispose();
//     _nameController.dispose();
//     _descriptionController.dispose();
//     _priceController.dispose();
//     super.dispose();
//   }

//   // Filter crops based on search text and filter options
//   void _filterCrops() {
//     setState(() {
//       filteredCrops = crops.where((crop) {
//         // Apply text search
//         final searchMatch = _searchController.text.isEmpty ||
//             crop['name'].toString().toLowerCase().contains(
//                   _searchController.text.toLowerCase(),
//                 ) ||
//             (crop['description'] != null &&
//                 crop['description'].toString().toLowerCase().contains(
//                       _searchController.text.toLowerCase(),
//                     ));

//         // Apply availability filter
//         final availabilityMatch = !_filterAvailable || crop['is_available'] == 1;

//         // Apply organic filter
//         final organicMatch = !_filterOrganic || crop['organic'] == 1;

//         // Apply fresh filter
//         final freshMatch = !_filterFresh || crop['fresh'] == 1;

//         return searchMatch && availabilityMatch && organicMatch && freshMatch;
//       }).toList();

//       // Apply sorting
//       filteredCrops.sort((a, b) {
//         switch (_sortBy) {
//           case 'name':
//             return a['name'].toString().compareTo(b['name'].toString());
//           case 'price_low':
//             return (a['price'] as num).compareTo(b['price'] as num);
//           case 'price_high':
//             return (b['price'] as num).compareTo(a['price'] as num);
//           default:
//             return 0;
//         }
//       });
//     });
//   }

//   // Fetch all crops from the API
//   Future<void> _fetchCrops() async {
//     setState(() => _isLoading = true);
//     try {
//       final response = await http.get(Uri.parse('$baseUrl/api/crops'));
//       if (response.statusCode == 200) {
//         setState(() {
//           crops = json.decode(response.body);
//           _filterCrops(); // Apply initial filtering
//         });
//       } else {
//         _showMessage(
//           'Failed to load crops: ${response.statusCode}',
//           isError: true,
//         );
//       }
//     } catch (e) {
//       _showMessage('Error loading crops: $e', isError: true);
//     }
//     setState(() => _isLoading = false);
//   }

//   // Pick image from gallery
//   Future<void> _pickImage() async {
//     try {
//       final pickedFile = await _picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//       );
//       if (pickedFile != null) {
//         setState(() {
//           _imageFile = File(pickedFile.path);
//           _imagePath = null; // Clear existing path when new image is selected
//         });
//       }
//     } catch (e) {
//       _showMessage('Error picking image: $e', isError: true);
//     }
//   }

//   // Take picture using camera
//   Future<void> _takePicture() async {
//     try {
//       final pickedFile = await _picker.pickImage(
//         source: ImageSource.camera,
//         imageQuality: 80,
//       );
//       if (pickedFile != null) {
//         setState(() {
//           _imageFile = File(pickedFile.path);
//           _imagePath = null; // Clear existing path when new image is selected
//         });
//       }
//     } catch (e) {
//       _showMessage('Error taking picture: $e', isError: true);
//     }
//   }

//   // Create or update crop with image handling
//   Future<void> _createOrUpdateCrop() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     try {
//       // Create the multipart request
//       final url = _selectedCropId == null
//           ? Uri.parse('$baseUrl/api/crops')
//           : Uri.parse('$baseUrl/api/crops/$_selectedCropId');

//       final request = http.MultipartRequest(
//         _selectedCropId == null ? 'POST' : 'PUT',
//         url,
//       );

//       // Add text fields
//       request.fields['farmer_id'] = _farmerIdController.text;
//       request.fields['name'] = _nameController.text;
//       request.fields['description'] = _descriptionController.text.isNotEmpty
//           ? _descriptionController.text
//           : ''; // Handle empty description
//       request.fields['price'] = _priceController.text;
//       request.fields['is_available'] = _isAvailable ? '1' : '0';
//       request.fields['organic'] = _isOrganic ? '1' : '0';
//       request.fields['fresh'] = _isFresh ? '1' : '0';

//       // Add image file if selected
//       if (_imageFile != null) {
//         final fileStream = http.ByteStream(_imageFile!.openRead());
//         final fileLength = await _imageFile!.length();

//         final multipartFile = http.MultipartFile(
//           'image',
//           fileStream,
//           fileLength,
//           filename: path.basename(_imageFile!.path),
//           contentType: MediaType(
//             'image',
//             path.extension(_imageFile!.path).toLowerCase().substring(1),
//           ),
//         );

//         request.files.add(multipartFile);
//       } else if (_imagePath != null && _selectedCropId != null) {
//         // If updating without changing image, send the existing path
//         request.fields['image_path'] = _imagePath!;
//       }

//       // Send the request
//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);

//       if (response.statusCode == 201 || response.statusCode == 200) {
//         await _fetchCrops();
//         _clearFields();
//         if (mounted) Navigator.of(context).pop();
//         _showMessage(
//           _selectedCropId == null
//               ? 'Crop created successfully!'
//               : 'Crop updated successfully!',
//           isError: false,
//         );
//       } else {
//         _showMessage(
//           'Failed to ${_selectedCropId == null ? 'create' : 'update'} crop: ${response.statusCode}\n${response.body}',
//           isError: true,
//         );
//       }
//     } catch (e) {
//       _showMessage('Error: ${e.toString()}', isError: true);
//     }
//     setState(() => _isLoading = false);
//   }

//   // Delete crop with confirmation dialog
// Future<void> _deleteCrop(String id) async {
//   // Show confirmation dialog
//   final shouldDelete = await showDialog<bool>(
//     context: context,
//     builder: (context) => AlertDialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       title: const Text('Confirm Deletion'),
//       content: const Text(
//         'Are you sure you want to delete this crop? This cannot be undone.',
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(false),
//           child: Text(
//             'Cancel',
//             style: TextStyle(color: Colors.grey[700]),
//           ),
//         ),
//         ElevatedButton(
//           onPressed: () => Navigator.of(context).pop(true),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.red,
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: const Text('Delete'),
//         ),
//       ],
//     ),
//   );

//   if (shouldDelete != true) return;

//   setState(() => _isLoading = true);
//   try {
//     final response = await http.delete(Uri.parse('$baseUrl/api/crops/$id'));
//     if (response.statusCode == 200) {
//       await _fetchCrops();
//       _showMessage('Crop deleted successfully!', isError: false);
//     } else {
//       _showMessage(
//         'Failed to delete crop: ${response.statusCode}',
//         isError: true,
//       );
//     }
//   } catch (e) {
//     _showMessage('Error deleting crop: $e', isError: true);
//   }
//   setState(() => _isLoading = false);
// }

//   // Clear all form fields
//   void _clearFields() {
//     _farmerIdController.clear();
//     _nameController.clear();
//     _descriptionController.clear();
//     _priceController.clear();
//     setState(() {
//       _isAvailable = true;
//       _isOrganic = false;
//       _isFresh = false;
//       _imageFile = null;
//       _imagePath = null;
//       _selectedCropId = null;
//     });
//   }

//   // Show snackbar message
//   void _showMessage(String message, {required bool isError}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(
//               isError ? Icons.error_outline : Icons.check_circle_outline,
//               color: Colors.white,
//             ),
//             const SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: isError ? Colors.red : lightGreen,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(12),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   // Load crop data into form for editing
//   void _loadCropData(String id) {
//     final crop = crops.firstWhere((c) => c['crop_id'].toString() == id);
//     _farmerIdController.text = crop['farmer_id'].toString();
//     _nameController.text = crop['name'];
//     _descriptionController.text = crop['description'] ?? '';
//     _priceController.text = crop['price'].toString();
//     setState(() {
//       _isAvailable = crop['is_available'] == 1;
//       _isOrganic = crop['organic'] == 1;
//       _isFresh = crop['fresh'] == 1;
//       _imagePath = crop['image_path'];
//       _selectedCropId = id;
//       _imageFile = null; // Clear any selected new image when loading existing crop
//     });
//   }

//   // Build a compact crop card item
//   Widget _buildCropItem(dynamic crop, int index) {
//     final bool isAvailable = crop['is_available'] == 1;
//     final bool isOrganic = crop['organic'] == 1;
//     final bool isFresh = crop['fresh'] == 1;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () {
//             _loadCropData(crop['crop_id'].toString());
//             _showForm(context);
//           },
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Image with overlay for unavailable items
//               Stack(
//                 children: [
//                   ClipRRect(
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(12),
//                     ),
//                     child: crop['image_path'] != null
//                         ? CachedNetworkImage(
//                             imageUrl: '$baseUrl/${crop['image_path']}',
//                             height: 120,
//                             width: double.infinity,
//                             fit: BoxFit.cover,
//                             placeholder: (context, url) => Container(
//                               height: 120,
//                               color: Colors.grey[200],
//                               child: const Center(
//                                 child: CircularProgressIndicator(),
//                               ),
//                             ),
//                             errorWidget: (context, url, error) => Container(
//                               height: 120,
//                               color: Colors.grey[200],
//                               child: const Center(
//                                 child: Icon(
//                                   Icons.error_outline,
//                                   size: 40,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                             ),
//                           )
//                         : Container(
//                             height: 120,
//                             width: double.infinity,
//                             color: Colors.grey[200],
//                             child: const Center(
//                               child: Icon(
//                                 Icons.image,
//                                 size: 40,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ),
//                   ),

//                   // Availability overlay
//                   if (!isAvailable)
//                     Positioned.fill(
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(0.5),
//                           borderRadius: const BorderRadius.vertical(
//                             top: Radius.circular(12),
//                           ),
//                         ),
//                         child: Center(
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 6,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.red.withOpacity(0.8),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: const Text(
//                               'Unavailable',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),

//                   // Price badge
//                   Positioned(
//                     top: 8,
//                     right: 8,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: primaryGreen,
//                         borderRadius: BorderRadius.circular(8),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             spreadRadius: 1,
//                             blurRadius: 3,
//                           ),
//                         ],
//                       ),
//                       child: Text(
//                         currencyFormat.format(crop['price']),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               // Crop details
//               Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Expanded(
//                           child: Text(
//                             crop['name'],
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         if (isOrganic || isFresh)
//                           Row(
//                             children: [
//                               if (isOrganic)
//                                 const Icon(Icons.eco, size: 16, color: Colors.green),
//                               if (isOrganic && isFresh) const SizedBox(width: 4),
//                               if (isFresh)
//                                 const Icon(Icons.water_drop, size: 16, color: Colors.blue),
//                             ],
//                           ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Farmer ID: ${crop['farmer_id']}',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     const SizedBox(height: 8),

//                     // Action buttons
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         IconButton(
//                           icon: Icon(Icons.edit, size: 20, color: primaryGreen),
//                           onPressed: () {
//                             _loadCropData(crop['crop_id'].toString());
//                             _showForm(context);
//                           },
//                           padding: EdgeInsets.zero,
//                           constraints: const BoxConstraints(),
//                         ),
//                         const SizedBox(width: 8),
//                         IconButton(
//                           icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
//                           onPressed: () => _deleteCrop(crop['crop_id'].toString()),
//                           padding: EdgeInsets.zero,
//                           constraints: const BoxConstraints(),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ).animate()
//       .fadeIn(
//         duration: const Duration(milliseconds: 400),
//         delay: Duration(milliseconds: index * 50),
//       )
//       .slideY(
//         begin: 0.1,
//         end: 0,
//         curve: Curves.easeOutQuad,
//         duration: const Duration(milliseconds: 300),
//         delay: Duration(milliseconds: index * 50),
//       );
//   }

//   // Build a form field with consistent styling
//   Widget _buildFormField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     bool isRequired = false,
//     TextInputType keyboardType = TextInputType.text,
//     int maxLines = 1,
//   }) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon, color: primaryGreen),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: primaryGreen, width: 2),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Colors.red, width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 16,
//         ),
//       ),
//       keyboardType: keyboardType,
//       maxLines: maxLines,
//       validator: (value) {
//         if (isRequired && (value == null || value.isEmpty)) {
//           return '$label is required';
//         }
//         if (keyboardType == TextInputType.number && value != null && value.isNotEmpty) {
//           if (double.tryParse(value) == null) {
//             return 'Please enter a valid number';
//           }
//         }
//         return null;
//       },
//     );
//   }

//   // Build a switch tile for form options
//   Widget _buildSwitchTile({
//     required String title,
//     required String subtitle,
//     required bool value,
//     required Function(bool) onChanged,
//     required IconData icon,
//     required Color activeColor,
//   }) {
//     return Row(
//       children: [
//         Icon(icon, color: value ? activeColor : Colors.grey),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: value ? darkGreen : Colors.grey[700],
//                 ),
//               ),
//               Text(
//                 subtitle,
//                 style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//               ),
//             ],
//           ),
//         ),
//         Switch(
//           value: value,
//           onChanged: onChanged,
//           activeColor: activeColor,
//           activeTrackColor: activeColor.withOpacity(0.3),
//         ),
//       ],
//     );
//   }

//   // Build filter option widget
//   Widget _buildFilterOption({
//     required String title,
//     required bool value,
//     required Function(bool) onChanged,
//     required IconData icon,
//   }) {
//     return InkWell(
//       onTap: () => onChanged(!value),
//       borderRadius: BorderRadius.circular(8),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//         child: Row(
//           children: [
//             Icon(icon, color: value ? primaryGreen : Colors.grey, size: 20),
//             const SizedBox(width: 12),
//             Text(
//               title,
//               style: TextStyle(
//                 color: value ? primaryGreen : Colors.grey[800],
//                 fontWeight: value ? FontWeight.bold : FontWeight.normal,
//               ),
//             ),
//             const Spacer(),
//             Checkbox(
//               value: value,
//               onChanged: (val) => onChanged(val!),
//               activeColor: primaryGreen,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(4),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Build sort option widget
//   Widget _buildSortOption({
//     required String title,
//     required String value,
//     required String groupValue,
//     required Function(String?) onChanged,
//     required IconData icon,
//   }) {
//     final bool isSelected = value == groupValue;

//     return InkWell(
//       onTap: () => onChanged(value),
//       borderRadius: BorderRadius.circular(8),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               color: isSelected ? primaryGreen : Colors.grey,
//               size: 20,
//             ),
//             const SizedBox(width: 12),
//             Text(
//               title,
//               style: TextStyle(
//                 color: isSelected ? primaryGreen : Colors.grey[800],
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//               ),
//             ),
//             const Spacer(),
//             Radio<String>(
//               value: value,
//               groupValue: groupValue,
//               onChanged: onChanged,
//               activeColor: primaryGreen,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Build empty state widget
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.grass_outlined, size: 80, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text(
//             'No crops found',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[700],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Add your first crop by clicking the + button',
//             style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             onPressed: () => _showForm(context),
//             icon: const Icon(Icons.add),
//             label: const Text('Add New Crop'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: primaryGreen,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Build search bar widget
//   Widget _buildSearchBar() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             offset: const Offset(0, 3),
//             blurRadius: 6,
//           ),
//         ],
//       ),
//       child: TextField(
//         controller: _searchController,
//         decoration: InputDecoration(
//           hintText: 'Search crops by name or description...',
//           border: InputBorder.none,
//           prefixIcon: Icon(Icons.search, color: primaryGreen),
//           suffixIcon: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (_searchController.text.isNotEmpty)
//                 IconButton(
//                   icon: const Icon(Icons.clear, color: Colors.grey),
//                   onPressed: () {
//                     _searchController.clear();
//                     _filterCrops();
//                   },
//                 ),
//               IconButton(
//                 icon: Icon(Icons.filter_list, color: primaryGreen),
//                 onPressed: _showFilterBottomSheet,
//               ),
//             ],
//           ),
//           contentPadding: const EdgeInsets.symmetric(vertical: 16),
//         ),
//       ),
//     );
//   }

//   // Show filter bottom sheet
//   void _showFilterBottomSheet() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) {
//           return Container(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 20,
//               vertical: 24,
//             ),
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Filter & Sort',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: darkGreen,
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                   ],
//                 ),
//                 const Divider(height: 32),

//                 // Filter options
//                 Text(
//                   'Filter by',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: darkGreen,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 _buildFilterOption(
//                   title: 'Available Only',
//                   value: _filterAvailable,
//                   onChanged: (value) => setState(() => _filterAvailable = value),
//                   icon: Icons.check_circle,
//                 ),
//                 const SizedBox(height: 8),
//                 _buildFilterOption(
//                   title: 'Organic Only',
//                   value: _filterOrganic,
//                   onChanged: (value) => setState(() => _filterOrganic = value),
//                   icon: Icons.eco,
//                 ),
//                 const SizedBox(height: 8),
//                 _buildFilterOption(
//                   title: 'Fresh Only',
//                   value: _filterFresh,
//                   onChanged: (value) => setState(() => _filterFresh = value),
//                   icon: Icons.water_drop,
//                 ),

//                 const SizedBox(height: 24),

//                 // Sort options
//                 Text(
//                   'Sort by',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: darkGreen,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 _buildSortOption(
//                   title: 'Name (A-Z)',
//                   value: 'name',
//                   groupValue: _sortBy,
//                   onChanged: (value) => setState(() => _sortBy = value!),
//                   icon: Icons.sort_by_alpha,
//                 ),
//                 const SizedBox(height: 8),
//                 _buildSortOption(
//                   title: 'Price (Low to High)',
//                   value: 'price_low',
//                   groupValue: _sortBy,
//                   onChanged: (value) => setState(() => _sortBy = value!),
//                   icon: Icons.trending_up,
//                 ),
//                 const SizedBox(height: 8),
//                 _buildSortOption(
//                   title: 'Price (High to Low)',
//                   value: 'price_high',
//                   groupValue: _sortBy,
//                   onChanged: (value) => setState(() => _sortBy = value!),
//                   icon: Icons.trending_down,
//                 ),

//                 const SizedBox(height: 32),

//                 // Apply button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       _filterCrops();
//                       Navigator.pop(context);
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: primaryGreen,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'Apply Filters',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 SizedBox(
//                   width: double.infinity,
//                   child: TextButton(
//                     onPressed: () {
//                       setState(() {
//                         _filterAvailable = false;
//                         _filterOrganic = false;
//                         _filterFresh = false;
//                         _sortBy = 'name';
//                       });
//                     },
//                     child: Text(
//                       'Reset All',
//                       style: TextStyle(color: Colors.grey[700]),
//                     ),
//                   ),
//                 ),
//                 // Add extra padding at the bottom for better UX with the keyboard
//                 SizedBox(
//                   height: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 0,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   // Show crop form dialog
//   void _showForm(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) {
//           return Dialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Container(
//               width: MediaQuery.of(context).size.width > 600
//                   ? 600
//                   : MediaQuery.of(context).size.width * 0.9,
//               padding: const EdgeInsets.all(20),
//               child: SingleChildScrollView(
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Header
//                       Row(
//                         children: [
//                           Icon(
//                             _selectedCropId == null ? Icons.add : Icons.edit,
//                             color: primaryGreen,
//                             size: 28,
//                           ),
//                           const SizedBox(width: 12),
//                           Text(
//                             _selectedCropId == null ? 'Add New Crop' : 'Edit Crop',
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: darkGreen,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const Divider(height: 32),

//                       // Image upload section
//                       Center(
//                         child: Column(
//                           children: [
//                             if (_imageFile != null)
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(12),
//                                 child: Image.file(
//                                   _imageFile!,
//                                   height: 120,
//                                   width: double.infinity,
//                                   fit: BoxFit.cover,
//                                 ),
//                               )
//                             else if (_imagePath != null && _selectedCropId != null)
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(12),
//                                 child: CachedNetworkImage(
//                                   imageUrl: '$baseUrl/$_imagePath',
//                                   height: 120,
//                                   width: double.infinity,
//                                   fit: BoxFit.cover,
//                                   placeholder: (context, url) => Container(
//                                     height: 120,
//                                     color: Colors.grey[200],
//                                     child: const Center(
//                                       child: CircularProgressIndicator(),
//                                     ),
//                                   ),
//                                   errorWidget: (context, url, error) => Container(
//                                     height: 120,
//                                     color: Colors.grey[200],
//                                     child: const Center(
//                                       child: Icon(
//                                         Icons.error,
//                                         size: 40,
//                                         color: Colors.grey,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               )
//                             else
//                               Container(
//                                 height: 120,
//                                 width: double.infinity,
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey[200],
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(
//                                     color: Colors.grey[300]!,
//                                   ),
//                                 ),
//                                 child: const Center(
//                                   child: Icon(
//                                     Icons.add_photo_alternate,
//                                     size: 50,
//                                     color: Colors.grey,
//                                   ),
//                                 ),
//                               ),
//                             const SizedBox(height: 16),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 ElevatedButton.icon(
//                                   icon: const Icon(Icons.photo_library),
//                                   label: const Text('Gallery'),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: lightGreen,
//                                     foregroundColor: Colors.white,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                   ),
//                                   onPressed: _pickImage,
//                                 ),
//                                 const SizedBox(width: 16),
//                                 ElevatedButton.icon(
//                                   icon: const Icon(Icons.camera_alt),
//                                   label: const Text('Camera'),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: primaryGreen,
//                                     foregroundColor: Colors.white,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                   ),
//                                   onPressed: _takePicture,
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 24),

//                       // Form fields
//                       _buildFormField(
//                         controller: _nameController,
//                         label: 'Crop Name',
//                         icon: Icons.grass,
//                         isRequired: true,
//                       ),
//                       const SizedBox(height: 16),
//                       _buildFormField(
//                         controller: _farmerIdController,
//                         label: 'Farmer ID',
//                         icon: Icons.person,
//                         isRequired: true,
//                         keyboardType: TextInputType.number,
//                       ),
//                       const SizedBox(height: 16),
//                       _buildFormField(
//                         controller: _priceController,
//                         label: 'Price (Tsh)',
//                         icon: Icons.attach_money,
//                         isRequired: true,
//                         keyboardType: TextInputType.number,
//                       ),
//                       const SizedBox(height: 16),
//                       _buildFormField(
//                         controller: _descriptionController,
//                         label: 'Description',
//                         icon: Icons.description,
//                         isRequired: false,
//                         maxLines: 3,
//                       ),
//                       const SizedBox(height: 24),

//                       // Toggle switches
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[100],
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: Colors.grey[300]!),
//                         ),
//                         child: Column(
//                           children: [
//                             _buildSwitchTile(
//                               title: 'Available',
//                               subtitle: 'Is this crop available for purchase?',
//                               value: _isAvailable,
//                               onChanged: (value) => setState(() => _isAvailable = value),
//                               icon: Icons.check_circle,
//                               activeColor: lightGreen,
//                             ),
//                             const Divider(height: 16),
//                             _buildSwitchTile(
//                               title: 'Organic',
//                               subtitle: 'Is this crop organically grown?',
//                               value: _isOrganic,
//                               onChanged: (value) => setState(() => _isOrganic = value),
//                               icon: Icons.eco,
//                               activeColor: darkGreen,
//                             ),
//                             const Divider(height: 16),
//                             _buildSwitchTile(
//                               title: 'Fresh',
//                               subtitle: 'Is this crop freshly harvested?',
//                               value: _isFresh,
//                               onChanged: (value) => setState(() => _isFresh = value),
//                               icon: Icons.water_drop,
//                               activeColor: lightGreen,
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 32),

//                       // Action buttons
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           TextButton(
//                             onPressed: () => Navigator.pop(context),
//                             child: Text(
//                               'Cancel',
//                               style: TextStyle(color: Colors.grey[700]),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           ElevatedButton(
//                             onPressed: _isLoading ? null : _createOrUpdateCrop,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: primaryGreen,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 24,
//                                 vertical: 12,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               minimumSize: const Size(120, 48),
//                             ),
//                             child: _isLoading
//                                 ? const SizedBox(
//                                     width: 24,
//                                     height: 24,
//                                     child: CircularProgressIndicator(
//                                       color: Colors.white,
//                                       strokeWidth: 2,
//                                     ),
//                                   )
//                                 : Text(
//                                     _selectedCropId == null ? 'Create Crop' : 'Update Crop',
//                                     style: const TextStyle(fontSize: 16),
//                                   ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   // Build mobile layout
//   Widget _buildMobileLayout() {
//     return ListView.builder(
//       padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
//       itemCount: filteredCrops.length,
//       itemBuilder: (context, index) => _buildCropItem(filteredCrops[index], index),
//     );
//   }

//   // Build tablet layout
//   Widget _buildTabletLayout() {
//     return GridView.builder(
//       padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         childAspectRatio: 0.85,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//       ),
//       itemCount: filteredCrops.length,
//       itemBuilder: (context, index) => _buildCropItem(filteredCrops[index], index),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Get screen size for responsive layout
//     final Size screenSize = MediaQuery.of(context).size;
//     final bool isTablet = screenSize.width > 600;

//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         title: Text(
//           'Crop Management',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: primaryGreen,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _fetchCrops,
//             tooltip: 'Refresh crops',
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           _clearFields();
//           _showForm(context);
//         },
//         backgroundColor: primaryGreen,
//         child: const Icon(Icons.add),
//       ),
//       body: _isLoading
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   SizedBox(
//                     width: 50,
//                     height: 50,
//                     child: CircularProgressIndicator(
//                       color: primaryGreen,
//                       strokeWidth: 3,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Loading crops...',
//                     style: TextStyle(
//                       color: darkGreen,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           : RefreshIndicator(
//               onRefresh: _fetchCrops,
//               color: primaryGreen,
//               child: Column(
//                 children: [
//                   // Search bar
//                   _buildSearchBar(),

//                   // Showing applied filters
//                   if (_filterAvailable ||
//                       _filterOrganic ||
//                       _filterFresh ||
//                       _sortBy != 'name' ||
//                       _searchController.text.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 8,
//                       ),
//                       child: Row(
//                         children: [
//                           Text(
//                             'Filtered Results:',
//                             style: TextStyle(
//                               color: darkGreen,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Text(
//                             '${filteredCrops.length} crops found',
//                             style: TextStyle(color: Colors.grey[700]),
//                           ),
//                           const Spacer(),
//                           TextButton(
//                             onPressed: () {
//                               setState(() {
//                                 _searchController.clear();
//                                 _filterAvailable = false;
//                                 _filterOrganic = false;
//                                 _filterFresh = false;
//                                 _sortBy = 'name';
//                               });
//                               _filterCrops();
//                             },
//                             child: const Text('Clear Filters'),
//                           ),
//                         ],
//                       ),
//                     ),

//                   // Crop list or empty state
//                   Expanded(
//                     child: filteredCrops.isEmpty
//                         ? _buildEmptyState()
//                         : isTablet
//                             ? _buildTabletLayout()
//                             : _buildMobileLayout(),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }