import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  final List<Map<String, String>> chats = [
    {"name": "Juma Wakulima", "message": "Habari! Je, bado una mahindi?", "time": "10:30 AM"},
    {"name": "Amina", "message": "Ningependa kujua bei ya mpunga.", "time": "9:45 AM"},
    {"name": "Musa", "message": "Je, unafanya delivery Dodoma?", "time": "8:20 AM"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mazungumzo")),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade200,
              child: Text(chats[index]["name"]![0]), // Herufi ya kwanza ya jina
            ),
            title: Text(chats[index]["name"]!, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(chats[index]["message"]!),
            trailing: Text(chats[index]["time"]!, style: TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(chatUser: chats[index]["name"]!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
