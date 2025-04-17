import '../Componets/Login_screen.dart';
import 'package:flutter/material.dart';
import 'product_details.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String image;
  final VoidCallback onTap;

  const ProductCard({
    Key? key,
    required this.name,
    required this.price,
    required this.image,
    required this.onTap,
  }) : super(key: key);

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
              child: Center(child: Text(image, style: TextStyle(fontSize: 40))),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
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
                          price,
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
                        _buildFeatureChip("Organic"),
                        SizedBox(width: 8),
                        _buildFeatureChip("Fresh"),
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
  @override
  Widget build(BuildContext context) {
    final categories = ["All", "Grains", "Vegetables", "Fruits", "Spices"];

    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return Container(
            margin: EdgeInsets.only(right: 12),
            child: Chip(
              backgroundColor:
                  isSelected ? Colors.green.shade700 : Colors.grey.shade100,
              label: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
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

class ProductListScreen extends StatelessWidget {
  // Sample data ya bidhaa na maelezo zaidi
  final List<Map<String, String>> products = [
    {
      "name": "Mahindi",
      "price": "Tsh 50,000",
      "image": "🌽",
      "origin": "Mbeya",
      "season": "Jan - Mar",
    },
    {
      "name": "Mpunga",
      "price": "Tsh 70,000",
      "image": "🌾",
      "origin": "Morogoro",
      "season": "Mar - Jun",
    },
    {
      "name": "Maharage",
      "price": "Tsh 30,000",
      "image": "🫘",
      "origin": "Arusha",
      "season": "Apr - Jul",
    },
    {
      "name": "Viazi",
      "price": "Tsh 25,000",
      "image": "🥔",
      "origin": "Iringa",
      "season": "Year-round",
    },
    {
      "name": "Ndizi",
      "price": "Tsh 15,000",
      "image": "🍌",
      "origin": "Kilimanjaro",
      "season": "Year-round",
    },
  ];

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
              child: SearchBar(),
            ),
          ),

          SizedBox(height: 16),

          // Categories
          CategorySelector(),

          SizedBox(height: 8),

          // Product count and sort
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${products.length} bidhaa zinapatikana",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "Panga: ",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    Text(
                      "Bei",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.green.shade700),
                  ],
                ),
              ],
            ),
          ),

          // Products list
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              padding: EdgeInsets.only(top: 8, bottom: 20),
              itemBuilder: (context, index) {
                return ProductCard(
                  name: products[index]["name"]!,
                  price: products[index]["price"]!,
                  image: products[index]["image"]!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProductDetailsScreen(
                              productName: products[index]["name"]!,
                              price: products[index]["price"]!,
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
