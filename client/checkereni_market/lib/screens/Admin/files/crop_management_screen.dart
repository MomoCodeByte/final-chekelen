import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

class CropManagementScreen extends StatefulWidget {
  const CropManagementScreen({Key? key}) : super(key: key);

  @override
  _CropManagementScreenState createState() => _CropManagementScreenState();
}

class _CropManagementScreenState extends State<CropManagementScreen> {
  List<dynamic> crops = [];
  final TextEditingController _farmerIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isAvailable = true;
  bool _isOrganic = false;
  bool _isFresh = false;
  File? _imageFile;
  String? _imagePath;
  String? _selectedCropId;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Change this to your server URL
  final String baseUrl = 'http://10.0.2.2'; // Use 10.0.2.2 for Android emulator

  @override
  void initState() {
    super.initState();
    _fetchCrops();
  }

  Future<void> _fetchCrops() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/crops'));
      if (response.statusCode == 200) {
        setState(() {
          crops = json.decode(response.body);
        });
      } else {
        _showError('Failed to load crops: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error loading crops: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imagePath = null; // Clear existing path when new image is selected
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _createOrUpdateCrop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create the multipart request
      final url =
          _selectedCropId == null
              ? Uri.parse('$baseUrl/api/crops')
              : Uri.parse('$baseUrl/api/crops/$_selectedCropId');

      final request = http.MultipartRequest(
        _selectedCropId == null ? 'POST' : 'PUT',
        url,
      );

      // Add text fields
      request.fields['farmer_id'] = _farmerIdController.text;
      request.fields['name'] = _nameController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['price'] = _priceController.text;
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
            path.extension(_imageFile!.path).substring(1),
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
        _fetchCrops();
        _clearFields();
        if (mounted) Navigator.of(context).pop();
      } else {
        _showError(
          'Failed to ${_selectedCropId == null ? 'create' : 'update'} crop: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteCrop(String id) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/crops/$id'));
      if (response.statusCode == 200) {
        _fetchCrops();
      } else {
        _showError('Failed to delete crop: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error deleting crop: $e');
    }
    setState(() => _isLoading = false);
  }

  void _clearFields() {
    _farmerIdController.clear();
    _nameController.clear();
    _descriptionController.clear();
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _loadCropData(String id) {
    final crop = crops.firstWhere((c) => c['crop_id'].toString() == id);
    _farmerIdController.text = crop['farmer_id'].toString();
    _nameController.text = crop['name'];
    _descriptionController.text = crop['description'] ?? '';
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

  Widget _buildCropItem(dynamic crop) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display the crop image at the top if available
          if (crop['image_path'] != null)
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('$baseUrl/${crop['image_path']}'),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 150,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.agriculture, size: 50, color: Colors.grey),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
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
                          const SizedBox(height: 4),
                          Text(
                            'Tsh ${crop['price'].toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _loadCropData(crop['crop_id'].toString());
                            _showForm(context);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed:
                              () => _deleteCrop(crop['crop_id'].toString()),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Tags
                if (crop['organic'] == 1 || crop['fresh'] == 1)
                  Wrap(
                    spacing: 8,
                    children: [
                      if (crop['organic'] == 1)
                        Chip(
                          label: const Text('Organic'),
                          backgroundColor: Colors.green[100],
                          labelStyle: TextStyle(color: Colors.green[800]),
                        ),
                      if (crop['fresh'] == 1)
                        Chip(
                          label: const Text('Fresh'),
                          backgroundColor: Colors.green[100],
                          labelStyle: TextStyle(color: Colors.green[800]),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  crop['description'] ?? 'No description',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${crop['is_available'] == 1 ? 'Available' : 'Unavailable'}',
                  style: TextStyle(
                    color:
                        crop['is_available'] == 1 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  _selectedCropId == null ? 'Add New Crop' : 'Edit Crop',
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _farmerIdController,
                          decoration: const InputDecoration(
                            labelText: 'Farmer ID',
                          ),
                          keyboardType: TextInputType.number,
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Crop Name',
                          ),
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price (Tsh)',
                          ),
                          keyboardType: TextInputType.number,
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Available'),
                          value: _isAvailable,
                          onChanged:
                              (value) => setState(() => _isAvailable = value),
                        ),
                        SwitchListTile(
                          title: const Text('Organic'),
                          value: _isOrganic,
                          onChanged:
                              (value) => setState(() => _isOrganic = value),
                        ),
                        SwitchListTile(
                          title: const Text('Fresh'),
                          value: _isFresh,
                          onChanged:
                              (value) => setState(() => _isFresh = value),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _pickImage,
                          child: const Text('Upload Image'),
                        ),
                        const SizedBox(height: 8),
                        if (_imageFile != null)
                          Image.file(_imageFile!, height: 100)
                        else if (_imagePath != null && _selectedCropId != null)
                          Image.network('$baseUrl/$_imagePath', height: 100),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () async {
                              if (_formKey.currentState!.validate()) {
                                await _createOrUpdateCrop();
                              }
                            },
                    child:
                        _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Save'),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchCrops),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _clearFields();
          _showForm(context);
        },
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : crops.isEmpty
              ? const Center(child: Text('No crops available'))
              : RefreshIndicator(
                onRefresh: _fetchCrops,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: crops.length,
                  itemBuilder: (context, index) => _buildCropItem(crops[index]),
                ),
              ),
    );
  }
}
