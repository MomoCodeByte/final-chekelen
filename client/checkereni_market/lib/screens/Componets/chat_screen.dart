// screens/Componets/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

class ChatScreen extends StatefulWidget {
  final String chatUser;
  final int? farmerId;
  final int? productId;
  final String? productName;

  const ChatScreen({
    super.key,
    required this.chatUser,
    this.farmerId,
    this.productId,
    this.productName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _storage = const FlutterSecureStorage();
  final TextEditingController _directMessageController =
      TextEditingController();
  final TextEditingController _aiMessageController = TextEditingController();
  List<ChatMessage> _directMessages = [];
  List<ChatMessage> _aiMessages = [];
  bool _isLoading = false;
  String? _currentUsername;
  String? _currentRole;
  String? _errorMessage;
  final String baseUrl = 'http://localhost:3000';
  bool _showCards = true; // Control whether to show the selection cards
  bool _isAIChatSelected = false; // Track which chat is selected

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
    _directMessageController.dispose();
    _aiMessageController.dispose();
    super.dispose();
  }

  /// Initializes the chat by setting the current user and fetching conversations.
  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      // Step 1: Retrieve JWT token from secure storage
      final token = await _storage.read(key: 'jwt_token');
      print('JWT Token: $token');

      // Step 2: Set username and role based on authentication status
      if (token == null) {
        // Guest user: Generate a unique guest username
        _currentUsername = 'guest_${Random().nextInt(1000000)}';
        _currentRole = 'guest';
        print('Guest user initialized: $_currentUsername');
      } else {
        // Authenticated user: Decode the JWT token to get username and role
        final parts = token.split('.');
        if (parts.length != 3) {
          throw Exception('Invalid JWT token format');
        }
        final payload = utf8.decode(
          base64Url.decode(base64Url.normalize(parts[1])),
        );
        final payloadMap = json.decode(payload);
        _currentUsername = payloadMap['username'] as String?;
        _currentRole = payloadMap['role'] as String?;
        print('Authenticated user: $_currentUsername, Role: $_currentRole');
      }

      // Step 3: Validate username and role
      if (_currentUsername == null || _currentRole == null) {
        throw Exception('Failed to identify user: Username or role is null');
      }

      // Step 4: Determine receiver username
      final receiverUsername =
          _currentRole == 'admin'
              ? widget.chatUser.toLowerCase().replaceAll(
                RegExp(r'farmer #', caseSensitive: false),
                'farmer',
              )
              : 'farmer${widget.farmerId}';
      print('Receiver Username: $receiverUsername');

      // Step 5: Fetch conversations
      await _fetchDirectConversation(receiverUsername);
      if (_currentRole != 'guest') {
        await _fetchAIConversation();
      }

      // Step 6: Add initial greeting messages
      if (widget.productId != null && widget.productName != null) {
        _directMessages.insert(
          0,
          ChatMessage(
            text:
                "Karibu! Ninaweza kukusaidia kuhusu ${widget.productName}. Unahitaji msaada gani?",
            isMe: false,
            time: DateTime.now(),
            isAI: false,
          ),
        );
        if (_currentRole != 'guest') {
          _aiMessages.insert(
            0,
            ChatMessage(
              text:
                  "Karibu! Napenda kuzungumza kuhusu ${widget.productName}. Bei ya bidhaa hii ni inaweza kubadilika? Ninaweza kukusaidia?",
              isMe: false,
              time: DateTime.now(),
              isAI: true,
            ),
          );
        }
      } else {
        _directMessages.insert(
          0,
          ChatMessage(
            text: "Karibu! Unahitaji msaada gani leo?",
            isMe: false,
            time: DateTime.now(),
            isAI: false,
          ),
        );
        if (_currentRole != 'guest') {
          _aiMessages.insert(
            0,
            ChatMessage(
              text: "Karibu! Ninaweza kukusaidia vipi leo?",
              isMe: false,
              time: DateTime.now(),
              isAI: true,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error initializing chat: $e');
      _showError('Error initializing chat: $e');
      print('Error in _initializeChat: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Fetches the direct conversation history between the current user and the receiver.
  /// [receiverUsername] is the username of the person the user is chatting with (e.g., 'farmer123').
  /// This method supports both authenticated users (with JWT token) and guest users (no token).
  Future<void> _fetchDirectConversation(String receiverUsername) async {
    // Ensure the current username is set
    if (_currentUsername == null) {
      _showError('Current username is not set. Cannot fetch conversation.');
      print('Error: _currentUsername is null in _fetchDirectConversation');
      return;
    }

    try {
      // Step 1: Retrieve the JWT token from secure storage (if the user is authenticated)
      final token = await _storage.read(key: 'jwt_token');
      print('JWT Token in _fetchDirectConversation: $token');

      // Step 2: Set headers based on authentication status
      // - If token exists, include Authorization header
      // - If no token (guest user), send empty headers
      final Map<String, String> headers =
          token != null
              ? {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              }
              : {'Content-Type': 'application/json'};

      // Debug: Log the request details
      print('Fetching conversation:');
      print(
        'URL: $baseUrl/api/chat/conversation/$_currentUsername/$receiverUsername',
      );
      print('Headers: $headers');
      print('User Role: $_currentRole');

      // Step 3: Make the HTTP GET request to fetch the conversation
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/chat/conversation/$_currentUsername/$receiverUsername',
        ),
        headers: headers,
      );

      // Debug: Log the response details
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Step 4: Handle the response based on status code
      if (response.statusCode == 200) {
        // Parse the response body
        final List<dynamic> data;
        try {
          data = json.decode(response.body);
        } catch (e) {
          _showError('Failed to parse conversation data: $e');
          print('JSON Decode Error: $e');
          return;
        }

        // Debug: Log the parsed data
        print('Parsed Data: $data');

        setState(() {
          _directMessages =
              data.map((msg) {
                return ChatMessage(
                  text: msg['message']?.toString() ?? 'No message content',
                  isMe: msg['sender_username']?.toString() == _currentUsername,
                  time:
                      DateTime.tryParse(msg['created_at']?.toString() ?? '') ??
                      DateTime.now(),
                  isAI: false,
                  chatId: int.tryParse(msg['chat_id']?.toString() ?? ''),
                  isArchived: (msg['is_archived']?.toString() == '1'),
                  archivedBy: msg['archived_by_username']?.toString(),
                );
              }).toList();
        });
        print('Successfully fetched ${_directMessages.length} messages');
      } else if (response.statusCode == 401 && _currentRole != 'guest') {
        // Unauthorized: Token is invalid or expired (for authenticated users only)
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else if (response.statusCode == 404) {
        // Conversation not found (e.g., no messages yet)
        _showError(
          'No conversation found between $_currentUsername and $receiverUsername',
        );
        print('No conversation found (404)');
        setState(() {
          _directMessages = []; // Clear messages if none exist
        });
      } else {
        // Other errors (e.g., 500 server error)
        _showError(
          'Failed to load direct conversation: ${response.statusCode}',
        );
        print('Error Response Body: ${response.body}');
      }
    } catch (e) {
      // Catch network errors, timeouts, or other exceptions
      _showError('Error fetching direct conversation: $e');
      print('Exception in _fetchDirectConversation: $e');
    }
  }

  /// Fetches the AI conversation history for the current user.
  Future<void> _fetchAIConversation() async {
    if (_currentUsername == null) return;

    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/ai/$_currentUsername'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('AI Conversation Response Status: ${response.statusCode}');
      print('AI Conversation Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _aiMessages =
              data
                  .map(
                    (msg) => ChatMessage(
                      text: msg['message'],
                      isMe: msg['sender_username'] == _currentUsername,
                      time: DateTime.parse(msg['created_at']),
                      isAI: true,
                      chatId: msg['chat_id'],
                      isArchived: msg['is_archived'] == 1,
                      archivedBy: msg['archived_by_username'],
                    ),
                  )
                  .toList();
        });
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showError('Failed to load AI conversation: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error fetching AI conversation: $e');
      print('Exception in _fetchAIConversation: $e');
    }
  }

  /// Sends a direct message to the receiver.
  Future<void> _sendDirectMessage() async {
    if (_directMessageController.text.trim().isEmpty ||
        _currentUsername == null)
      return;

    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      final headers =
          token != null
              ? {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              }
              : {'Content-Type': 'application/json'};
      final receiverUsername =
          _currentRole == 'admin'
              ? widget.chatUser.toLowerCase().replaceAll(
                RegExp(r'farmer #', caseSensitive: false),
                'farmer',
              )
              : 'farmer${widget.farmerId}';

      print('Sending direct message:');
      print('Sender: $_currentUsername');
      print('Receiver: $receiverUsername');
      print('Message: ${_directMessageController.text}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: headers,
        body: json.encode({
          'sender_username': _currentUsername,
          'receiver_username': receiverUsername,
          'message': _directMessageController.text,
          'crop_id': widget.productId,
        }),
      );

      print('Send Direct Message Response Status: ${response.statusCode}');
      print('Send Direct Message Response Body: ${response.body}');

      if (response.statusCode == 201) {
        _directMessageController.clear();
        await _fetchDirectConversation(receiverUsername);
      } else if (response.statusCode == 401 && _currentRole != 'guest') {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final error = json.decode(response.body);
        _showError(
          'Failed to send message: ${error['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      _showError('Error sending message: $e');
      print('Exception in _sendDirectMessage: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Sends a message to the AI.
  Future<void> _sendAIMessage() async {
    if (_aiMessageController.text.trim().isEmpty || _currentUsername == null)
      return;

    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _showError('AI chat requires authentication. Please log in.');
        return;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/ai'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'sender_username': _currentUsername,
          'message': _aiMessageController.text,
          'crop_id': widget.productId,
        }),
      );

      print('Send AI Message Response Status: ${response.statusCode}');
      print('Send AI Message Response Body: ${response.body}');

      if (response.statusCode == 201) {
        _aiMessageController.clear();
        await _fetchAIConversation();
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final error = json.decode(response.body);
        _showError(
          'Failed to send AI message: ${error['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      _showError('Error sending AI message: $e');
      print('Exception in _sendAIMessage: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Archives a message.
  Future<void> _archiveMessage(int chatId, bool isAIChat) async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        _showError('Archiving requires authentication. Please log in.');
        return;
      }
      final response = await http.put(
        Uri.parse('$baseUrl/api/chat/$chatId/archive'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _showSuccess('Message archived successfully');
        if (isAIChat) {
          await _fetchAIConversation();
        } else {
          final receiverUsername =
              _currentRole == 'admin'
                  ? widget.chatUser.toLowerCase().replaceAll(
                    RegExp(r'farmer #', caseSensitive: false),
                    'farmer',
                  )
                  : 'farmer${widget.farmerId}';
          await _fetchDirectConversation(receiverUsername);
        }
      } else if (response.statusCode == 401) {
        _showError('Session expired. Please log in again.');
        await _storage.delete(key: 'jwt_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final error = json.decode(response.body);
        _showError(
          'Failed to archive message: ${error['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      _showError('Error archiving message: $e');
      print('Exception in _archiveMessage: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Shows an error snackbar.
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

  /// Shows a success snackbar.
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

  /// Builds a card for selecting a chat type (AI or Direct).
  Widget _buildSelectionCard(String title, bool isAI, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 150, // Smaller width for the card
          height: 100, // Smaller height for the card
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isAI ? Icons.smart_toy : Icons.person,
                color: isAI ? Colors.blue : primaryGreen,
                size: 30,
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isAI ? Colors.blue : primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the chat interface after a card is selected.
  Widget _buildChatInterface(
    String title,
    List<ChatMessage> messages,
    TextEditingController controller,
    VoidCallback onSend,
    bool isAIChat,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAIChat ? Colors.blue.shade50 : primaryGreen,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isAIChat ? Colors.blue : Colors.white,
                ),
                onPressed: () {
                  setState(
                    () => _showCards = true,
                  ); // Go back to card selection
                },
              ),
              Icon(
                isAIChat ? Icons.smart_toy : Icons.person,
                color: isAIChat ? Colors.blue : Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isAIChat ? Colors.blue : Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              messages.isEmpty
                  ? Center(child: Text('No messages yet'))
                  : ListView.builder(
                    padding: EdgeInsets.all(16),
                    reverse: false,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return ChatMessage(
                        text: messages[index].text,
                        isMe: messages[index].isMe,
                        time: messages[index].time,
                        isAI: isAIChat,
                        chatId: messages[index].chatId,
                        isArchived: messages[index].isArchived,
                        archivedBy: messages[index].archivedBy,
                        onArchive:
                            messages[index].chatId != null &&
                                    !messages[index].isArchived
                                ? () => _archiveMessage(
                                  messages[index].chatId!,
                                  isAIChat,
                                )
                                : null,
                      );
                    },
                  ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.emoji_emotions_outlined,
                  color: Colors.grey.shade700,
                ),
                onPressed: () {},
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Andika ujumbe wako hapa...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: primaryGreen),
                onPressed: _isLoading ? null : onSend,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Text(
                widget.chatUser.substring(0, 1),
                style: TextStyle(color: primaryGreen),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatUser,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (widget.productId != null)
                  Text(
                    "Product #${widget.productId} - ${widget.productName}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.call), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryGreen))
              : _errorMessage != null
              ? Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              )
              : Column(
                children: [
                  if (widget.productId != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      color: Colors.green.shade50,
                      child: Row(
                        children: [
                          Icon(
                            Icons.agriculture,
                            color: primaryGreen,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Bargaining for: ${widget.productName}",
                            style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Spacer(),
                          Text(
                            "Farmer ID: #${widget.farmerId}",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child:
                        _showCards
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSelectionCard(
                                  'Chat with ${widget.chatUser}',
                                  false,
                                  () {
                                    setState(() {
                                      _showCards = false;
                                      _isAIChatSelected = false;
                                    });
                                  },
                                ),
                                if (_currentRole != 'guest')
                                  _buildSelectionCard('Chat with AI', true, () {
                                    setState(() {
                                      _showCards = false;
                                      _isAIChatSelected = true;
                                    });
                                  }),
                              ],
                            )
                            : _isAIChatSelected
                            ? _buildChatInterface(
                              'Chat with AI',
                              _aiMessages,
                              _aiMessageController,
                              _sendAIMessage,
                              true,
                            )
                            : _buildChatInterface(
                              'Chat with ${widget.chatUser}',
                              _directMessages,
                              _directMessageController,
                              _sendDirectMessage,
                              false,
                            ),
                  ),
                ],
              ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime time;
  final bool isAI;
  final int? chatId;
  final bool isArchived;
  final String? archivedBy;
  final VoidCallback? onArchive;

  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    required this.isAI,
    this.chatId,
    this.isArchived = false,
    this.archivedBy,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress:
          isArchived || chatId == null || onArchive == null ? null : onArchive,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe)
              CircleAvatar(
                backgroundColor:
                    isAI ? Colors.blue.shade100 : Colors.green.shade100,
                radius: 16,
                child: Icon(
                  isAI ? Icons.smart_toy : Icons.person,
                  size: 18,
                  color: isAI ? Colors.blue.shade700 : Colors.green.shade700,
                ),
              ),
            SizedBox(width: isMe ? 0 : 8),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isMe
                        ? Colors.green.shade700
                        : isAI
                        ? Colors.blue.shade100
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isMe ? Radius.circular(0) : Radius.circular(20),
                  bottomLeft: isMe ? Radius.circular(20) : Radius.circular(0),
                ),
                border:
                    isArchived
                        ? Border.all(color: Colors.grey, width: 1)
                        : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isArchived && archivedBy != null)
                    Text(
                      'Archived by $archivedBy',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "${time.hour}:${time.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      color:
                          isMe
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isMe ? 8 : 0),
            if (isMe)
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                radius: 16,
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
