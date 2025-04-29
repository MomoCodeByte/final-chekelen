import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> chats = [];
  Map<String, String> userNames = {};
  String? currentUserId;
  bool isLoading = true;
  final TextEditingController _senderIdController = TextEditingController();
  final TextEditingController _receiverIdController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Custom theme colors
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreen = const Color(0xFF81C784);
  final Color darkGreen = const Color(0xFF1B5E20);
  final Color backgroundWhite = const Color(0xFFF5F9F6);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      isLoading = true;
    });
    await _fetchUsers();
    await _fetchChats();
    setState(() {
      isLoading = false;
    });
    // Auto scroll to bottom after loading messages
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/users'),
      );
      if (response.statusCode == 200) {
        final users = json.decode(response.body);
        setState(() {
          for (var user in users) {
            userNames[user['user_id'].toString()] = user['username'];
          }
          // Set the first user as current by default
          if (users.isNotEmpty && currentUserId == null) {
            currentUserId = users[0]['user_id'].toString();
            _senderIdController.text = currentUserId!;
          }
        });
      } else {
        _showError('Failed to load users');
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  Future<void> _fetchChats() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/chat'),
      );
      if (response.statusCode == 200) {
        setState(() {
          chats = json.decode(response.body);
        });
      } else {
        _showError('Failed to load chats');
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  Future<void> _createChat() async {
    if (_messageController.text.trim().isEmpty) {
      _showError('Message cannot be empty');
      return;
    }

    if (_senderIdController.text.isEmpty ||
        _receiverIdController.text.isEmpty) {
      _showError('Please select sender and receiver');
      return;
    }

    try {
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
        _messageController.clear();
        await _fetchChats();
        _scrollToBottom();
        _showSuccess('Message sent!');
      } else {
        _showError('Failed to send message');
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  Future<void> _deleteChat(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/api/chat/$id'),
      );
      if (response.statusCode == 200) {
        await _fetchChats();
        _showSuccess('Message deleted');
      } else {
        _showError('Failed to delete message');
      }
    } catch (e) {
      _showError('Network error: $e');
    }
  }

  void _showUserSelector(BuildContext context, bool isSender) {
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Text(
                  isSender ? 'Select Sender' : 'Select Receiver',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: userNames.length,
                  itemBuilder: (context, index) {
                    final userId = userNames.keys.elementAt(index);
                    final username = userNames[userId];
                    return FadeInLeft(
                      delay: Duration(milliseconds: index * 50),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: lightGreen,
                          child: Text(
                            username?.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(username ?? 'Unknown'),
                        subtitle: Text('ID: $userId'),
                        onTap: () {
                          if (isSender) {
                            _senderIdController.text = userId;
                            currentUserId = userId;
                          } else {
                            _receiverIdController.text = userId;
                          }
                          Navigator.pop(context);
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatTimeAgo(String? timestamp) {
    if (timestamp == null) return '';

    try {
      final messageTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(messageTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d').format(messageTime);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.white),
            const SizedBox(width: 10),
            const Text(
              'Chat Management',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _initialize,
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat selection header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: lightGreen.withOpacity(0.2),
              border: Border(bottom: BorderSide(color: lightGreen, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showUserSelector(context, true),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: lightGreen),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: primaryGreen,
                            child: Text(
                              userNames[currentUserId]
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'From:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  userNames[currentUserId] ?? 'Select Sender',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: primaryGreen),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _showUserSelector(context, false),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: lightGreen),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: darkGreen,
                            child: Text(
                              _receiverIdController.text.isEmpty
                                  ? '?'
                                  : userNames[_receiverIdController.text]
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'To:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _receiverIdController.text.isEmpty
                                      ? 'Select Receiver'
                                      : userNames[_receiverIdController.text] ??
                                          'Unknown',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: primaryGreen),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                      ),
                    )
                    : chats.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: lightGreen.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(
                        duration: const Duration(milliseconds: 500),
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          final isCurrentUser =
                              chat['sender_id'].toString() == currentUserId;
                          final chatId = chat['chat_id']?.toString() ?? '';
                          final messageText = chat['message'] ?? '';
                          final timestamp = chat['created_at'];
                          final senderName =
                              userNames[chat['sender_id'].toString()] ??
                              'Unknown';
                          final receiverName =
                              userNames[chat['receiver_id'].toString()] ??
                              'Unknown';

                          return FadeIn(
                            delay: Duration(milliseconds: 50 * index),
                            child: Slidable(
                              key: ValueKey(chatId),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (context) => _deleteChat(chatId),
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete,
                                    label: 'Delete',
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      isCurrentUser
                                          ? MainAxisAlignment.end
                                          : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isCurrentUser)
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: darkGreen,
                                        child: Text(
                                          senderName
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            isCurrentUser
                                                ? CrossAxisAlignment.end
                                                : CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isCurrentUser
                                                      ? primaryGreen
                                                      : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  spreadRadius: 1,
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                              border:
                                                  isCurrentUser
                                                      ? null
                                                      : Border.all(
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade200,
                                                      ),
                                            ),
                                            child: Text(
                                              messageText,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color:
                                                    isCurrentUser
                                                        ? Colors.white
                                                        : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                              left: 4,
                                              right: 4,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  isCurrentUser
                                                      ? 'You → ${userNames[chat['receiver_id'].toString()] ?? 'Unknown'}'
                                                      : '${userNames[chat['sender_id'].toString()] ?? 'Unknown'} → You',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _formatTimeAgo(timestamp),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isCurrentUser)
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: primaryGreen,
                                        child: Text(
                                          senderName
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
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
          ),

          // Message input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: lightGreen.withOpacity(0.5)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          if (_senderIdController.text.isNotEmpty &&
                              _receiverIdController.text.isNotEmpty) {
                            _createChat();
                          } else {
                            _showError('Please select sender and receiver');
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      if (_senderIdController.text.isNotEmpty &&
                          _receiverIdController.text.isNotEmpty) {
                        _createChat();
                      } else {
                        _showError('Please select sender and receiver');
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 22,
                      ),
                    ).animate().scale(
                      duration: const Duration(milliseconds: 200),
                      begin: const Offset(1, 1),
                      end: const Offset(0.9, 0.9),
                      curve: Curves.easeInOut,
                    ),
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
