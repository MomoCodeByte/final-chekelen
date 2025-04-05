import 'package:flutter/material.dart';
import './signup_screen.dart';
import '../product/product_details.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _login() {
    String email = emailController.text;
    String password = passwordController.text;

    // Email validation using regular expression
    String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regExp = RegExp(emailPattern);

    // Check if the email is valid and password length is at least 6 characters
    if (email.isNotEmpty && password.isNotEmpty) {
      if (!regExp.hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Tafadhali ingiza email sahihi"),
            backgroundColor: Colors.red,
          ),
        );
      } else if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Neno la siri lazima liwe na angalau herufi 6"),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print("Login successful: $email");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              productName: "Mahindi",
              price: "Tsh 5000",
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Tafadhali jaza Email na Password"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("INGIA HAPA", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryGreen,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 50),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(Icons.lock_open_rounded, size: 80, color: primaryGreen),
              ),
              SizedBox(height: 10),
              Center(
                child: Text(
                  "Ingia kwenye akaunti yako",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen),
                ),
              ),
              SizedBox(height: 20),
              buildTextField(controller: emailController, label: "Email", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              SizedBox(height: 16),
              buildTextField(controller: passwordController, label: "Password", icon: Icons.lock_outline, isPassword: true),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text("Ukumbuki password yako?", style: TextStyle(color: primaryGreen)),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("INGIA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Huna akaunti? ", style: TextStyle(color: Colors.black54)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen()));
                      },
                      child: Text("Jisajili hapa", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black87),
        prefixIcon: Icon(icon, color: Color(0xFF2E7D32)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
    );
  }
}
