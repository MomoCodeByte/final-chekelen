import 'package:flutter/material.dart';
import 'add_product.dart';
import 'my_products.dart';
import 'orders_screen.dart';
import 'seller_chat.dart';
import 'seller_profile.dart';

class SellerDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Seller Panel")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                
                children: [
                  Icon(Icons.store, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "Muuzaji wa Mazao",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Profile"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SellerProfileScreen()),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.add),
              title: Text("Ongeza Bidhaa"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddProductScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text("Orodha ya Bidhaa"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyProductsScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart),
              title: Text("Oda Zilizopokelewa"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrdersScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text("Mazungumzo"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SellerChatScreen()),
                );
              },
            ),
           
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text("Karibu kwenye Seller Panel", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
