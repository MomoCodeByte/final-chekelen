import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../Componets/Login_screen.dart';
import '../Componets/chat_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int productId;
  final int farmerId;
  final String productName;
  final String price;
  final bool isOrganic;
  final bool isFresh;
  final String? categories;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.farmerId,
    required this.productName,
    required this.price,
    this.isOrganic = false,
    this.isFresh = false,
    this.categories,
  });

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  int _quantity = 1;

  Future<void> _addToCart() async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      _showError('Please log in to add to cart.');
      Navigator.pushNamed(context, '/login');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'crop_id': widget.productId, 'quantity': _quantity}),
      );

      if (response.statusCode == 201) {
        _showSuccess('Item added to cart');
      } else if (response.statusCode == 400) {
        _showError('Invalid crop or quantity');
      } else if (response.statusCode == 403) {
        _showError('Only customers can add to cart');
      } else {
        _showError(
          'Failed to add to cart: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _isLoading = true);
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      _showError('Please log in to place an order.');
      Navigator.pushNamed(context, '/login');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/orders/checkout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _showSuccess(
          'Order placed successfully! Order ID: ${data['order_id']}',
        );
        Navigator.pushNamed(context, '/orders'); // Navigate to OrdersScreen
      } else if (response.statusCode == 400) {
        _showError('Cart is empty or contains unavailable items');
      } else if (response.statusCode == 403) {
        _showError('Only customers can checkout');
      } else {
        _showError(
          'Failed to place order: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green.shade700),
    );
  }

  String _getProductEmoji(String name) {
    Map<String, String> emojiMap = {
      "mahindi": "🌽",
      "mpunga": "🌾",
      "maharage": "🫘",
      "ndizi": "🍌",
      "nyanya": "🍅",
      "vitunguu": "🧅",
      "pilipili": "🌶️",
      "maembe": "🥭",
      "mapara chichi": "🥑",
      "mapera": "🍐",
      "matikiti maji": "🍉",
      "pilipili hoho": "🍎",
      "karafuu": "🌿",
      "machungwa": "🍊",
      "ma aple": "🍏",
      "mdalasini": "🌱",
      "mapapai": "🍐",
    };
    return emojiMap[name.toLowerCase()] ?? "🥬";
  }

  String _getProductOrigin(String name) {
    Map<String, String> originMap = {
      "mahindi": "Mbeya",
      "mpunga": "Morogoro",
      "maharage": "Arusha",
      "viazi": "Iringa",
      "ndizi": "Kilimanjaro",
      "nyanya": "Iringa",
      "vitunguu": "Singida",
      "pilipili": "Tanga",
      "maembe": "Morogoro",
      "mapara chichi": "Mbeya",
    };
    return originMap[name.toLowerCase()] ?? "Tanzania";
  }

  String _getProductSeason(String name) {
    Map<String, String> seasonMap = {
      "mahindi": "Jan - Mar",
      "mpunga": "Mar - Jun",
      "maharage": "Apr - Jul",
      "viazi": "Msimu-Mwaka jana",
      "ndizi": "Msimu-Mwaka huu",
      "nyanya": "Sep - Dec",
      "vitunguu": "Feb - May",
      "pilipili": "Jan - Dec",
    };
    return seasonMap[name.toLowerCase()] ?? "Mwaka huu";
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green.shade700),
          SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 16, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon),
        label: Text(
          text,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade500],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getProductEmoji(widget.productName),
                  style: TextStyle(fontSize: 80),
                ),
                SizedBox(height: 16),
                Text(
                  widget.productName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (widget.categories != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      widget.categories!,
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Product ID",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              "#${widget.productId}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Farmer ID",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              "#${widget.farmerId}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 0, bottom: 24),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Bei ya Sasa",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              widget.price,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 18,
                                color: Colors.amber.shade700,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Bidhaa Bora",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "Maelezo ya Bidhaa",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  if (widget.isOrganic)
                    _buildFeatureRow(
                      Icons.check_circle_outline,
                      "Bidhaa za Asili",
                    ),
                  if (widget.isOrganic)
                    _buildFeatureRow(Icons.eco_outlined, "Kilimo Hai"),
                  if (widget.isFresh)
                    _buildFeatureRow(
                      Icons.local_florist_outlined,
                      "Fresh mazao",
                    ),
                  _buildFeatureRow(
                    Icons.location_on_outlined,
                    "Imetoka ${_getProductOrigin(widget.productName)}",
                  ),
                  _buildFeatureRow(
                    Icons.calendar_today_outlined,
                    "Msimu: ${_getProductSeason(widget.productName)}",
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        "Quantity: ",
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove, color: Colors.green.shade700),
                        onPressed: () {
                          if (_quantity > 1) {
                            setState(() => _quantity--);
                          }
                        },
                      ),
                      Text(
                        '$_quantity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.green.shade700),
                        onPressed: () {
                          setState(() => _quantity++);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Text(
                    "Tafadhali chagua hatua inayofuata:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          "Weka Kwa Kikapu",
                          Colors.green.shade700,
                          Icons.shopping_cart_outlined,
                          _addToCart,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          "Nunua Sasa",
                          Colors.green.shade700,
                          Icons.shopping_bag_outlined,
                          _placeOrder,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatUser: "Farmer #${widget.farmerId}",
                        farmerId: widget.farmerId,
                        productId: widget.productId,
                        productName: widget.productName,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.chat_outlined),
                label: Text(
                  "Anza Kubargain",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}