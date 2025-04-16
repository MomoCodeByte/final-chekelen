import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> chats = [];
  Map<String, String> userNames = {};
  final TextEditingController _senderIdController = TextEditingController();
  final TextEditingController _receiverIdController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchChats();
  }

  Future<void> _fetchUsers() async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/users'));
    if (response.statusCode == 200) {
      final users = json.decode(response.body);
      setState(() {
        for (var user in users) {
          userNames[user['user_id'].toString()] = user['username']; // Map user ID to username
        }
      });
    } else {
      _showError('Failed to load users');
    }
  }

  Future<void> _fetchChats() async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/chat'));
    if (response.statusCode == 200) {
      setState(() {
        chats = json.decode(response.body);
      });
    } else {
      _showError('Failed to load chats');
    }
  }

  Future<void> _createChat() async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'sender_id': _senderIdController.text,
        'receiver_id': _receiverIdController.text,
        'message': _messageController.text,
      }),
    );

    if (response.statusCode == 201) {
      _fetchChats();
      _clearFields();
      _showSuccess('Chat message sent successfully!');
    } else {
      _showError('Failed to create chat');
    }
  }

  Future<void> _deleteChat(String id) async {
    final response = await http.delete(Uri.parse('http://localhost:3000/api/chat/$id'));
    if (response.statusCode == 200) {
      _fetchChats();
      _showSuccess('Chat message deleted successfully!');
    } else {
      _showError('Failed to delete chat');
    }
  }

  void _clearFields() {
    _senderIdController.clear();
    _receiverIdController.clear();
    _messageController.clear();
  }

  void _showForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Chat Message'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _senderIdController,
                  decoration: const InputDecoration(labelText: 'Sender ID'),
                ),
                TextField(
                  controller: _receiverIdController,
                  decoration: const InputDecoration(labelText: 'Receiver ID'),
                ),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(labelText: 'Message'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _createChat();
                Navigator.of(context).pop();
              },
              child: const Text('Send'),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _clearFields();
              _showForm(context);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          final senderName = userNames[chat['sender_id'].toString()] ?? 'Unknown';
          final receiverName = userNames[chat['receiver_id'].toString()] ?? 'Unknown';

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: chat['sender_id'].toString() == _senderIdController.text
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: chat['sender_id'].toString() == _senderIdController.text
                        ? Colors.blue[200]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '${chat['message']}',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
                Text(
                  chat['sender_id'].toString() == _senderIdController.text ? senderName : receiverName,
                  style: TextStyle(fontSize: 12.0, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}












// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class Contact {
//   final String id;
//   final String name;

//   Contact({required this.id, required this.name});
// }

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({Key? key}) : super(key: key);

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   List<Contact> contacts = [];
//   List<dynamic> chats = [];
//   Map<String, String> userNames = {};
//   String? selectedContactId;
//   final TextEditingController _messageController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _fetchUsers();
//     _fetchChats();
//   }

//   Future<void> _fetchUsers() async {
//     final response = await http.get(Uri.parse('http://localhost:3000/api/users'));
//     if (response.statusCode == 200) {
//       final users = json.decode(response.body);
//       setState(() {
//         contacts = users.map<Contact>((user) => Contact(id: user['user_id'].toString(), name: user['username'])).toList();
//       });
//     } else {
//       _showError('Failed to load users');
//     }
//   }

//   Future<void> _fetchChats() async {
//     final response = await http.get(Uri.parse('http://localhost:3000/api/chat'));
//     if (response.statusCode == 200) {
//       setState(() {
//         chats = json.decode(response.body);
//       });
//     } else {
//       _showError('Failed to load chats');
//     }
//   }

//   Future<void> _createChat() async {
//     final response = await http.post(
//       Uri.parse('http://localhost:3000/api/chat'),
//       headers: {'Content-Type': 'application/json'},
//       body: json.encode({
//         'sender_id': '1',  // Replace with actual sender ID
//         'receiver_id': selectedContactId,
//         'message': _messageController.text,
//       }),
//     );

//     if (response.statusCode == 201) {
//       _fetchChats();
//       _messageController.clear();
//       _showSuccess('Chat message sent successfully!');
//     } else {
//       _showError('Failed to create chat');
//     }
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red.shade400,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   void _showSuccess(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green.shade400,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   void _selectContact(String id) {
//     setState(() {
//       selectedContactId = id;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chat Contacts'),
//       ),
//       body: Column(
//         children: [
//           // Contact List
//           Expanded(
//             child: ListView.builder(
//               itemCount: contacts.length,
//               itemBuilder: (context, index) {
//                 final contact = contacts[index];
//                 return ListTile(
//                   title: Text(contact.name),
//                   onTap: () => _selectContact(contact.id),
//                 );
//               },
//             ),
//           ),
//           // Chat Area
//           if (selectedContactId != null) ...[
//             Expanded(
//               child: ListView.builder(
//                 itemCount: chats.length,
//                 itemBuilder: (context, index) {
//                   final chat = chats[index];
//                   final isSender = chat['sender_id'].toString() == '1'; // Replace with actual sender ID
//                   return Container(
//                     alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
//                     padding: const EdgeInsets.all(8.0),
//                     child: Container(
//                       padding: const EdgeInsets.all(10.0),
//                       decoration: BoxDecoration(
//                         color: isSender ? Colors.blue[200] : Colors.grey[300],
//                         borderRadius: BorderRadius.circular(8.0),
//                       ),
//                       child: Text(
//                         chat['message'],
//                         style: TextStyle(fontSize: 16.0),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _messageController,
//                       decoration: const InputDecoration(labelText: 'Type a message'),
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.send),
//                     onPressed: _createChat,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }