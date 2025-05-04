import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final String chatUser;
  final int farmerId;
  final int productId;
  final String productName;

  const ChatScreen({
    super.key,
    required this.chatUser,
    required this.farmerId,
    required this.productId,
    required this.productName,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _storage = const FlutterSecureStorage();
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _currentUsername;
  String? _errorMessage;
  final String baseUrl = 'http://localhost:3000';

  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF81C784);
  final Color backgroundColor = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _showError('Please log in to chat');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = utf8.decode(
          base64Url.decode(base64Url.normalize(parts[1])),
        );
        final payloadMap = json.decode(payload);
        setState(() => _currentUsername = payloadMap['username']);
      }

      final receiverId = widget.farmerId;
      await _fetchConversation(receiverId);
    } catch (e) {
      setState(() => _errorMessage = 'Error initializing chat: $e');
      _showError('Failed to load chat');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchConversation(int receiverId) async {
    if (_currentUsername == null) return;

    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _messages = data
              .where((chat) => (chat['sender_name'] == _currentUsername && chat['receiver_name'] == 'farmer$receiverId') ||
                               (chat['sender_name'] == 'farmer$receiverId' && chat['receiver_name'] == _currentUsername))
              .map((chat) => {
                    'chat_id': chat['chat_id'],
                    'message': chat['message'],
                    'created_at': chat['created_at'],
                    'sender_username': chat['sender_name'],
                    'receiver_username': chat['receiver_name'],
                  })
              .toList();
        });
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError('Failed to load conversation: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error fetching conversation: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUsername == null) return;

    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      final receiverId = widget.farmerId;

      // Extract sender_id from token payload if available, otherwise assume currentUsername maps to id
      final parts = token?.split('.');
      int senderId = -1;
      if (parts?.length == 3) {
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts![1])));
        final payloadMap = json.decode(payload);
        senderId = payloadMap['id'] ?? -1; // Adjust based on your JWT payload structure
      }

      if (senderId == -1) {
        _showError('Unable to determine sender ID from token');
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'message': _messageController.text,
        }),
      );

      if (response.statusCode == 201) {
        _messageController.clear();
        await _fetchConversation(receiverId);
        _showSuccess('Message sent successfully');
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError('Failed to send message: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showError('Error sending message: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMessage(int chatId) async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.delete(
        Uri.parse('$baseUrl/api/chat/$chatId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _showSuccess('Message deleted successfully');
        final receiverId = widget.farmerId;
        await _fetchConversation(receiverId);
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError('Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error deleting message: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(12),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: lightGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(12),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Chat with ${widget.chatUser}',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryGreen))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
                    : _messages.isEmpty
                        ? Center(child: Text('No messages yet'))
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isCurrentUser = message['sender_username'] == _currentUsername;

                              return GestureDetector(
                                onLongPress: () {
                                  if (isCurrentUser) {
                                    _deleteMessage(message['chat_id']);
                                  }
                                },
                                child: Align(
                                  alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 4),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isCurrentUser ? primaryGreen : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message['message'],
                                          style: TextStyle(
                                            color: isCurrentUser ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          message['created_at']?.substring(0, 16) ?? '',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isCurrentUser ? Colors.white70 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: primaryGreen),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}