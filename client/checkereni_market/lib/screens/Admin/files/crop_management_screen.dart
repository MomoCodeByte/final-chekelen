import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final TextEditingController _availabilityController = TextEditingController();
  String? _selectedCropId;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCrops();
  }

  Future<void> _fetchCrops() async {
    setState(() => _isLoading = true);
    final response = await http.get(Uri.parse('http://localhost:3000/api/crops'));
    if (response.statusCode == 200) {
      setState(() {
        crops = json.decode(response.body);
      });
    } else {
      _showError('Failed to load crops');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _createCrop() async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/api/crops'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'farmer_id': _farmerIdController.text,
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'availability': int.parse(_availabilityController.text),
      }),
    );

    if (response.statusCode == 201) {
      _fetchCrops();
      _clearFields();
    } else {
      _showError('Failed to create crop');
    }
  }

  Future<void> _updateCrop(String id) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/api/crops/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'farmer_id': _farmerIdController.text,
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'availability': int.parse(_availabilityController.text),
      }),
    );

    if (response.statusCode == 200) {
      _fetchCrops();
      _clearFields();
    } else {
      _showError('Failed to update crop');
    }
  }

  Future<void> _deleteCrop(String id) async {
    final response = await http.delete(Uri.parse('http://localhost:3000/api/crops/$id'));
    if (response.statusCode == 200) {
      _fetchCrops();
    } else {
      _showError('Failed to delete crop');
    }
  }

  void _clearFields() {
    _farmerIdController.clear();
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _availabilityController.clear();
    setState(() {
      _selectedCropId = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_selectedCropId == null ? 'Create Crop' : 'Update Crop'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _farmerIdController,
                    decoration: InputDecoration(
                      labelText: 'Farmer ID',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter Farmer ID' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Crop Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter Crop Name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Enter Description' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Enter Price' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _availabilityController,
                    decoration: InputDecoration(
                      labelText: 'Availability',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Enter Availability' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (_selectedCropId == null) {
                    _createCrop();
                  } else {
                    _updateCrop(_selectedCropId!);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Submit'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
        title: const Text('Crop Management')
     
      ),

        floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              _clearFields();
              _showForm(context);
            },
          ),
          
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            )
          : ListView.builder(
              itemCount: crops.length,
              itemBuilder: (context, index) {
                final crop = crops[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(crop['name']),
                    subtitle: Text('Price: \Tsh${crop['price']} - Descriptin: ${crop['description']} - Availability: ${crop['availability']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                          onPressed: () {
                            _farmerIdController.text = crop['farmer_id'].toString();
                            _nameController.text = crop['name'];
                            _descriptionController.text = crop['description'];
                            _priceController.text = crop['price'].toString();
                            _availabilityController.text = crop['availability'].toString();
                            setState(() {
                              _selectedCropId = crop['crop_id'].toString();
                            });
                            _showForm(context);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCrop(crop['crop_id'].toString()),
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