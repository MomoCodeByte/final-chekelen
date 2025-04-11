import 'package:flutter/material.dart';
import '../Componets/Login_screen.dart';
import '../Componets/chat_screen.dart';


class ProductDetailsScreen extends StatelessWidget {
  final String productName;
  final String price;

  ProductDetailsScreen({required this.productName, required this.price});

  @override
  Widget build(BuildContext context) {
    // Get emoji for product
    String productEmoji = _getProductEmoji(productName);

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
          // Product Hero Image Section
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
                Text(productEmoji, style: TextStyle(fontSize: 80)),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    productName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Details Section
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Card
                  Container(
                    margin: EdgeInsets.only(top: 10, bottom: 24),
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
                              price,
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

                  // Product Features
                  Text(
                    "Maelezo ya Bidhaa",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),

                  _buildFeatureRow(
                    Icons.check_circle_outline,
                    "Bidhaa za Asili",
                  ),
                  _buildFeatureRow(Icons.eco_outlined, "Kilimo Hai"),
                  _buildFeatureRow(
                    Icons.location_on_outlined,
                    "Imetoka ${_getProductOrigin(productName)}",
                  ),
                  _buildFeatureRow(
                    Icons.calendar_today_outlined,
                    "Msimu: ${_getProductSeason(productName)}",
                  ),

                  SizedBox(height: 30),

                  // Call to Action Section
                  Text(
                    "Tafadhali chagua hatua inayofuata:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Purchase Actions - TWO BUTTONS SIDE BY SIDE
                  Row(
                    children: [
                      // Buy Now Button
                      Expanded(
                        child: _buildActionButton(
                          context,
                          "Nunua Sasa",
                          Colors.green.shade700,
                          Icons.shopping_bag_outlined,
                          () {
                            // Navigate to checkout page
                           
                           Navigator.push(
                           context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                           );
                   
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Kuendelea na malipo..."),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      // Add to Cart Button
                      Expanded(
                        child: _buildActionButton(
                          context,
                          "Weka Kwa Kikapu",
                          Colors.green.shade700,
                          Icons.shopping_cart_outlined,
                          () {
                            // Add to cart functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Bidhaa imeongezwa kwenye kikapu"),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          },
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
            // Call Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Phone call functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Kupiga simu kwa muuzaji..."),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                },
                icon: Icon(Icons.call_outlined),
                label: Text(
                  "Piga Simu",
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
            SizedBox(width: 16),
            // Chat Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatScreen(chatUser: "Juma Wakulima")),
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
    BuildContext context,
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
        onPressed: onPressed,
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

  // Helper methods to get product-specific information
  String _getProductEmoji(String name) {
    Map<String, String> emojiMap = {
      "Mahindi": "🌽",
      "Mpunga": "🌾",
      "Maharage": "🫘",
      "Viazi": "🥔",
      "Ndizi": "🍌",
    };

    return emojiMap[name] ?? "🥬";
  }

  String _getProductOrigin(String name) {
    Map<String, String> originMap = {
      "Mahindi": "Mbeya",
      "Mpunga": "Morogoro",
      "Maharage": "Arusha",
      "Viazi": "Iringa",
      "Ndizi": "Kilimanjaro",
    };

    return originMap[name] ?? "Tanzania";
  }

  String _getProductSeason(String name) {
    Map<String, String> seasonMap = {
      "Mahindi": "Jan - Mar",
      "Mpunga": "Mar - Jun",
      "Maharage": "Apr - Jul",
      "Viazi": "Year-round",
      "Ndizi": "Year-round",
    };

    return seasonMap[name] ?? "Year-round";
  }
}