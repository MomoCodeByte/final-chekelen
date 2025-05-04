import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _storage = FlutterSecureStorage();
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late String _token;
  late int _myId;
  late String _myName;
  List<Map<String, dynamic>> _chats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    // 1) Read stored JWT
    _token = (await _storage.read(key: 'jwt')) ?? '';
    if (_token.isEmpty) {
      /* redirect to login */
      return;
    }

    // 2) Get my profile (ID & name)
    final meRes = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/users/me'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    final me = json.decode(meRes.body);
    _myId = me['user_id'];
    _myName = me['username'];

    // 3) Fetch chats
    await _fetchChats();
    _loading = false;
    setState(() {});
    _scrollToBottom();
  }

  Future<void> _fetchChats() async {
    final res = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/chat'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    final list = (json.decode(res.body) as List).cast<Map<String, dynamic>>();
    setState(() => _chats = list);
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    await http.post(
      Uri.parse('http://10.0.2.2:3000/api/chat'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'receiver_id': widget.key, // pass selected recipient ID
        'message': text,
      }),
    );
    _messageCtrl.clear();
    await _fetchChats();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _deleteChat(int chatId) async {
    await http.delete(
      Uri.parse('http://10.0.2.2:3000/api/chat/$chatId'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    await _fetchChats();
  }

  String _formatTime(String iso) {
    final dt = DateTime.parse(iso);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with Farmer'), centerTitle: true),
      body:
          _loading
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      itemCount: _chats.length,
                      itemBuilder: (c, i) {
                        final m = _chats[i];
                        final isMe = m['sender_id'] == _myId;
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                            children: [
                              if (!isMe) _Avatar(name: m['sender_name']),
                              SizedBox(width: 6),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment:
                                      isMe
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            isMe
                                                ? Colors.green
                                                : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        m['message'] ?? '',
                                        style: TextStyle(
                                          color:
                                              isMe
                                                  ? Colors.white
                                                  : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _formatTime(m['created_at']),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 6),
                              if (isMe) _Avatar(name: _myName),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Input bar
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageCtrl,
                              decoration: InputDecoration(
                                hintText: 'Type your message…',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          SizedBox(width: 8),
                          FloatingActionButton(
                            mini: true,
                            child: Icon(Icons.send),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});
  @override
  Widget build(BuildContext _) {
    return CircleAvatar(child: Text(name.substring(0, 1).toUpperCase()));
  }
}
