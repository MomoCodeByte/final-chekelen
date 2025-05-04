import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Model class for Crop remains the same
class Crop {
  final int cropId;
  final String name;
  final String price;
  final bool isOrganic;
  final bool isFresh;
  final String? imagePath;
  final String emoji;

  Crop({
    required this.cropId,
    required this.name,
    required this.price,
    required this.isOrganic,
    required this.isFresh,
    this.imagePath,
    required this.emoji,
  });

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      cropId: json['crop_id'] ?? json['id'],
      name: json['name'],
      price: json['price'].toString(),
      isOrganic: json['is_organic'] ?? false,
      isFresh: json['is_fresh'] ?? false,
      imagePath: json['image_path'],
      emoji: _getEmojiForProduct(json['name']),
    );
  }

  static String _getEmojiForProduct(String name) {
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
      case 'rice':
        return '🌾';
      case 'mapara chichi':
        return '🥑';
      default:
        return '🌾';
    }
  }
}

// Updated CartItem model with additional fields from API
class CartItem {
  final int cropId;
  final String name;
  final String price;
  int quantity;
  final bool isOrganic;
  final bool isFresh;
  final String? imagePath;
  final String emoji;
  final int? cartItemId;
  final int? farmerId;
  final String? farmerName;
  final bool isAvailable;
  final double lineTotal;

  CartItem({
    required this.cropId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.isOrganic,
    required this.isFresh,
    this.imagePath,
    required this.emoji,
    this.cartItemId,
    this.farmerId,
    this.farmerName,
    this.isAvailable = true,
    this.lineTotal = 0.0,
  });

  double get totalPrice =>
      double.parse(price.replaceAll(RegExp(r'[^0-9.]'), '')) * quantity;

  Map<String, dynamic> toJson() {
    return {'crop_id': cropId, 'quantity': quantity};
  }

  String getEmoji() {
    return emoji;
  }

  factory CartItem.fromCrop(Crop crop) {
    return CartItem(
      cropId: crop.cropId,
      name: crop.name,
      price: crop.price,
      quantity: 1,
      isOrganic: crop.isOrganic,
      isFresh: crop.isFresh,
      imagePath: crop.imagePath,
      emoji: crop.emoji,
    );
  }

  // New factory constructor to parse API response
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['cart_item_id'],
      cropId: json['crop_id'],
      name: json['name'],
      price: json['price'].toString(),
      quantity: json['quantity'],
      isOrganic: json['is_organic'] ?? false,
      isFresh: json['is_fresh'] ?? false,
      imagePath: json['image_path'],
      emoji: Crop._getEmojiForProduct(json['name']),
      farmerId: json['farmer_id'],
      farmerName: json['farmer_name'],
      isAvailable: json['is_available'] ?? true,
      lineTotal: (json['line_total'] ?? 0).toDouble(),
    );
  }
}

// Cart Provider using ChangeNotifier for state management - Fixed
class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://localhost:3000';
  bool _isLoading = false;
  String _errorMessage = '';

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      total += item.totalPrice;
    }
    return total;
  }

  void addItem(CartItem cartItem) {
    final existingItemIndex = _items.indexWhere(
      (item) => item.cropId == cartItem.cropId,
    );

    if (existingItemIndex >= 0) {
      _items[existingItemIndex].quantity += cartItem.quantity;
    } else {
      _items.add(cartItem);
    }

    _syncWithServer();
    notifyListeners();
  }

  void removeItem(int cropId) {
    _items.removeWhere((item) => item.cropId == cropId);
    _syncWithServer();
    notifyListeners();
  }

  void decrementQuantity(int cropId) {
    final existingItemIndex = _items.indexWhere(
      (item) => item.cropId == cropId,
    );

    if (existingItemIndex >= 0) {
      if (_items[existingItemIndex].quantity > 1) {
        _items[existingItemIndex].quantity--;
      } else {
        _items.removeAt(existingItemIndex);
      }

      _syncWithServer();
      notifyListeners();
    }
  }

  void incrementQuantity(int cropId) {
    final existingItemIndex = _items.indexWhere(
      (item) => item.cropId == cropId,
    );

    if (existingItemIndex >= 0) {
      _items[existingItemIndex].quantity++;
      _syncWithServer();
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _syncWithServer();
    notifyListeners();
  }

  Future<void> _syncWithServer() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      await _saveCartLocally();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse('$baseUrl/api/cart/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'items': _items.map((item) => item.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _errorMessage = '';
      } else if (response.statusCode == 401) {
        _errorMessage = 'Session expired. Please log in again.';
        await _storage.delete(key: 'jwt_token');
      } else {
        _errorMessage = 'Failed to sync cart with server';
      }
    } catch (e) {
      _errorMessage = 'Error syncing cart: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCartLocally() async {
    try {
      final cartData = json.encode(
        _items.map((item) => item.toJson()).toList(),
      );
      await _storage.write(key: 'local_cart', value: cartData);
    } catch (e) {
      _errorMessage = 'Error saving cart locally: ${e.toString()}';
    }
  }

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'jwt_token');
      print('Loading cart with token: $token'); // Debug token

      if (token == null) {
        await _loadLocalCart();
      } else {
        await _loadServerCart(token);
      }
    } catch (e) {
      _errorMessage = 'Error loading cart: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLocalCart() async {
    final cartData = await _storage.read(key: 'local_cart');
    if (cartData != null) {
      try {
        final decoded = json.decode(cartData) as List<dynamic>;
        _items.clear();
        for (var item in decoded) {
          _items.add(
            CartItem(
              cropId: item['crop_id'],
              name: '', // Placeholder, fetch from server if needed
              price: '0', // Placeholder, fetch from server if needed
              quantity: item['quantity'],
              isOrganic: false,
              isFresh: false,
              emoji: '',
            ),
          );
        }
      } catch (e) {
        _errorMessage = 'Error parsing local cart data';
      }
    }
  }

  // Fixed method to properly parse the API response format
  Future<void> _loadServerCart(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print(
        'API Response: ${response.statusCode} - ${response.body}',
      ); // Debug response

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Handle the cart items directly from the response based on your API format
        if (decoded['cart'] is List) {
          final List<dynamic> cartItems = decoded['cart'];
          _items.clear();

          for (var item in cartItems) {
            _items.add(CartItem.fromJson(item));
          }
        } else if (decoded['items'] is List) {
          final List<dynamic> cartItems = decoded['items'];
          _items.clear();

          for (var item in cartItems) {
            _items.add(CartItem.fromJson(item));
          }
        } else {
          // Fallback to loading individual items if needed
          await _loadIndividualItems(token);
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Session expired. Please log in again.';
        await _storage.delete(key: 'jwt_token');
      } else {
        _errorMessage =
            'Failed to load cart from server: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error loading cart from server: ${e.toString()}';
    }
  }

  // Fallback method to load individual items
  Future<void> _loadIndividualItems(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/cart/items'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List<dynamic> cartItems = decoded['items'] ?? [];

      _items.clear();

      for (var item in cartItems) {
        final cropId = item['crop_id'];
        final quantity = item['quantity'];

        final cropResponse = await http.get(
          Uri.parse('$baseUrl/api/crops/$cropId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (cropResponse.statusCode == 200) {
          final cropData = json.decode(cropResponse.body);
          final crop = Crop.fromJson(cropData);
          final cartItem = CartItem.fromCrop(crop);
          cartItem.quantity = quantity;
          _items.add(cartItem);
        }
      }
    }
  }

  Future<bool> checkout() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _errorMessage = 'Please log in to checkout';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'items':
              _items
                  .map(
                    (item) => {
                      'crop_id': item.cropId,
                      'quantity': item.quantity,
                      'unit_price': double.parse(
                        item.price.replaceAll(RegExp(r'[^0-9.]'), ''),
                      ),
                    },
                  )
                  .toList(),
          'total_price': totalAmount,
          'order_status': 'pending',
        }),
      );

      if (response.statusCode == 201) {
        clear();
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        _errorMessage = 'Session expired. Please log in again.';
        await _storage.delete(key: 'jwt_token');
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        _errorMessage = 'Failed to create order. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error during checkout: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

// Cart Screen Widget - Fixed
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF81C784);
  final Color backgroundColor = const Color(0xFFF5F5F5);
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isAuthenticated = false;

  // Create a single instance of CartProvider
  final CartProvider cartProvider = CartProvider();

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _loadCart();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'jwt_token');
    setState(() {
      _isAuthenticated = token != null;
    });
  }

  Future<void> _loadCart() async {
    await cartProvider.loadCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Kikapu cha Ununuzi",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (cartProvider.items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => _showClearCartDialog(context, cartProvider),
              tooltip: 'Futa Kikapu',
            ),
        ],
      ),
      // Using AnimatedBuilder to rebuild UI when cart changes
      body: AnimatedBuilder(
        animation: cartProvider,
        builder: (context, _) {
          if (cartProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          } else if (cartProvider.items.isEmpty) {
            return _buildEmptyCart();
          } else {
            return _buildCartItems(cartProvider);
          }
        },
      ),

      // bottomNavigationBar: AnimatedBuilder(
      //   animation: cartProvider,
      //   builder: (context, _) {
      //     return Visibility(
      //       visible: cartProvider.items.isNotEmpty,
      //       child: _buildCheckoutBar(context, cartProvider),
      //     );
      //   },
      // ),
      bottomNavigationBar: AnimatedBuilder(
        animation: cartProvider,
        builder: (context, _) {
          return cartProvider.items.isEmpty
              ? const SizedBox.shrink()
              : _buildCheckoutBar(context, cartProvider);
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            "Kikapu chako ni tupu",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Ongeza bidhaa kwenye kikapu",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text("Nunua Sasa", style: TextStyle(fontSize: 16)),
          ),
          if (cartProvider.errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                cartProvider.errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartItems(CartProvider cart) {
    return ListView.builder(
      itemCount: cart.items.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      item.getEmoji(),
                      style: TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Tsh ${item.price}/ 1 kg",
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      SizedBox(height: 4),
                      if (item.farmerName != null)
                        Text(
                          "Mkulima: ${item.farmerName}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          if (item.isOrganic) _buildFeatureChip("Organic"),
                          if (item.isOrganic && item.isFresh)
                            SizedBox(width: 8),
                          if (item.isFresh) _buildFeatureChip("Fresh"),
                          if (!item.isAvailable) ...[
                            if (item.isOrganic || item.isFresh)
                              SizedBox(width: 8),
                            _buildFeatureChip("Haipo", isError: true),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "Tsh ${(item.totalPrice).toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _buildQuantityButton(
                          Icons.remove,
                          () => cart.decrementQuantity(item.cropId),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${item.quantity}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        _buildQuantityButton(
                          Icons.add,
                          () => cart.incrementQuantity(item.cropId),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureChip(String label, {bool isError = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isError
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isError ? Colors.red.shade700 : Colors.green.shade700,
        ),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildCheckoutBar(BuildContext context, CartProvider cart) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Jumla", style: TextStyle(color: Colors.grey.shade700)),
                Text(
                  "Tsh ${cart.totalAmount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _processCheckout(context, cart),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("Kamilisha Ununuzi", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text("Futa Kikapu"),
            content: Text(
              "Una uhakika unataka kufuta bidhaa zote kwenye kikapu?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text("Hapana"),
              ),
              ElevatedButton(
                onPressed: () {
                  cart.clear();
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                child: Text("Ndio"),
              ),
            ],
          ),
    );
  }

  Future<void> _processCheckout(BuildContext context, CartProvider cart) async {
    if (!_isAuthenticated) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text("Ingia kwenye Akaunti"),
              content: Text(
                "Tafadhali ingia kwenye akaunti yako ili kukamilisha ununuzi",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text("Ghairi"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                  ),
                  child: Text("Ingia"),
                ),
              ],
            ),
      );

      if (shouldLogin == true) {
        Navigator.pushNamed(context, '/login');
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(color: primaryGreen),
                SizedBox(width: 20),
                Text("Inakamilisha ununuzi..."),
              ],
            ),
          ),
    );

    final success = await cart.checkout();

    Navigator.of(context).pop();

    if (success) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text("Ununuzi Umekamilika"),
              content: Text(
                "Asante kwa kununua. Tutakuwasiliana hivi karibuni kwa maelezo zaidi ya ununuzi wako.",
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                  ),
                  child: Text("Sawa"),
                ),
              ],
            ),
      );
    } else {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text("Hitilafu"),
              content: Text(
                cart.errorMessage.isEmpty
                    ? "Kumekuwa na hitilafu wakati wa kukamilisha ununuzi. Tafadhali jaribu tena."
                    : cart.errorMessage,
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                  ),
                  child: Text("Sawa"),
                ),
              ],
            ),
      );
    }
  }
}
