import 'package:flutter/material.dart';
import 'package:aipowered/services/appdrawer.dart';
import 'package:aipowered/services/careerexplorer.dart';
import 'package:aipowered/services/user_service.dart';
import 'package:aipowered/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CareerChatbotPage extends StatefulWidget {
  const CareerChatbotPage({super.key});

  @override
  State<CareerChatbotPage> createState() => _CareerChatbotPageState();
}

class _CareerChatbotPageState extends State<CareerChatbotPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];

  bool _isTyping = false;
  Map<String, dynamic>? _userProfile;
  String? _currentConversationId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _initializeConversation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle navigation arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args['action'] == 'new') {
        _createNewConversation();
      } else if (args['action'] == 'load' && args['conversationId'] != null) {
        _loadConversation(args['conversationId']);
      }
    }
  }

  Future<void> _initializeConversation() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Check if there's an existing active conversation
      final latestConversationId = await ChatService.getLatestConversationId(
        currentUser.uid,
      );

      if (latestConversationId != null) {
        // Load existing conversation
        await _loadConversation(latestConversationId);
      } else {
        // Create new conversation
        await _createNewConversation();
      }
    } catch (e) {
      print('Error initializing conversation: $e');
      // Fallback: create new conversation
      await _createNewConversation();
    }
  }

  Future<void> _createNewConversation() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final conversationId = await ChatService.createNewConversation(
        userId: currentUser.uid,
      );

      setState(() {
        _currentConversationId = conversationId;
        _messages.clear();
        _messages.add({
          "role": "bot",
          "text":
              "Hello! I'm your dedicated career advisor and mentor. I specialize in helping with career paths, job searching, professional development, workplace advice, and career planning. How can I assist you with your career goals today?",
        });
      });

      // Save the initial bot message
      await ChatService.saveMessage(
        conversationId: conversationId,
        userId: currentUser.uid,
        role: 'bot',
        content: _messages.first['text']!,
      );
    } catch (e) {
      print('Error creating new conversation: $e');
    }
  }

  Future<void> _loadConversation(String conversationId) async {
    try {
      final messages = await ChatService.getConversationMessages(
        conversationId,
      );
      setState(() {
        _currentConversationId = conversationId;
        _messages.clear();
        _messages.addAll(
          messages.map((msg) => {'role': msg['role'], 'text': msg['content']}),
        );
      });
      _scrollToBottom();
    } catch (e) {
      print('Error loading conversation: $e');
    }
  }

  Future<void> startNewConversation() async {
    await _createNewConversation();
  }

  Future<void> loadSpecificConversation(String conversationId) async {
    await _loadConversation(conversationId);
  }

  Future<void> _loadUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final profile = await UserService.getCompleteUserProfile(
          currentUser.uid,
        );
        setState(() {
          _userProfile = profile;
        });
      } catch (e) {
        print('Error loading user profile: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Makes an API call to the Google Gemini model.
  Future<String> _getGeminiResponse(String userMessage) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      return "Error: API Key is not configured. Please add your Gemini API key to the .env file.";
    }

    // Updated to use the current Gemini API endpoint
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

    // Build personalized context based on user profile
    String userContext = "";
    if (_userProfile != null) {
      final name = _userProfile?['name'] ?? 'there';
      final age = _userProfile?['age'];
      final educationLevel = _userProfile?['educationLevel'];
      final stream = _userProfile?['stream'];
      final degree = _userProfile?['degree'];
      final specialization = _userProfile?['specialization'];
      final isWorking = _userProfile?['isWorking'] ?? false;
      final workDescription = _userProfile?['workDescription'];

      userContext = "\n\nUser Profile Context:\n";
      userContext += "Name: $name\n";
      if (age != null) userContext += "Age: $age\n";
      if (stream != null) userContext += "Stream: $stream\n";
      if (educationLevel != null)
        userContext += "Education Level: $educationLevel\n";
      if (degree != null) userContext += "Degree: $degree\n";
      if (specialization != null)
        userContext += "Specialization: $specialization\n";
      if (isWorking && workDescription != null) {
        userContext += "Current Work: $workDescription\n";
      } else if (!isWorking) {
        userContext += "Status: Not currently working\n";
      }
    }

    try {
      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "You are a professional career advisor and mentor. Your role is STRICTLY limited to providing career guidance, job advice, professional development, and career-related information ONLY. You must NOT answer questions about:\n- General knowledge, history, science, or trivia\n- Personal advice unrelated to careers\n- Entertainment, movies, games, or hobbies\n- Technical support or programming help\n- Current events or news\n- Health, relationships, or personal life advice\n\nIf a user asks about topics outside of career guidance, politely redirect them by saying: 'I'm a career advisor, so I can only help with career-related questions. Please ask me about career paths, job searching, professional development, workplace advice, or career planning.'\n\nFor career-related questions, keep responses concise, encouraging, and actionable. Use the user's profile information to provide personalized career advice.$userContext\n\nAnswer this career question: $userMessage",
                },
              ],
            },
          ],
          "generationConfig": {
            "temperature": 0.7,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Navigate through the JSON to get the response text
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          return text;
        } else {
          return "Error: Invalid response format from API.";
        }
      } else {
        // More detailed error handling
        final errorBody = response.body;
        return "Error: Failed to get a response. Status: ${response.statusCode}. Response: $errorBody";
      }
    } catch (e) {
      return "Error: An exception occurred. Please check your connection. Details: $e";
    }
  }

  /// Handles sending a message (both from user input and pre-defined actions).
  void _sendMessage({String? message}) async {
    final userMessage = message ?? _controller.text.trim();
    if (userMessage.isEmpty || _currentConversationId == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _messages.add({"role": "user", "text": userMessage});
      _isTyping = true;
    });

    _scrollToBottom();
    _controller.clear();

    // Save user message to database
    try {
      await ChatService.saveMessage(
        conversationId: _currentConversationId!,
        userId: currentUser.uid,
        role: 'user',
        content: userMessage,
      );
      print('User message saved to conversation: $_currentConversationId');
    } catch (e) {
      print('Error saving user message: $e');
    }

    String botResponse = await _getGeminiResponse(userMessage);

    setState(() {
      _messages.add({"role": "bot", "text": botResponse});
      _isTyping = false;
    });

    // Save bot response to database
    try {
      await ChatService.saveMessage(
        conversationId: _currentConversationId!,
        userId: currentUser.uid,
        role: 'bot',
        content: botResponse,
      );
      print('Bot message saved to conversation: $_currentConversationId');
    } catch (e) {
      print('Error saving bot message: $e');
    }

    _scrollToBottom();
  }

  /// Smoothly scrolls the chat list to the latest message.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Shows the career explorer bottom sheet.
  void _showCareerExplorerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return CareerExplorerSheet(
          onCareerSelected: (careerName) {
            Navigator.pop(context);
            _sendMessage(message: "Tell me about being a $careerName");
          },
        );
      },
    );
  }

  /// Builds the UI for a single chat message bubble.
  Widget _buildMessageBubble(Map<String, String> message) {
    bool isUser = message["role"] == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF3C74FF) : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message["text"]!,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF0E0E10),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        backgroundColor: const Color(0xFF0E0E10),
        elevation: 0,
        title: const Text(
          "Career Advisor",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(10),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            if (_isTyping)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Career Advisor is typing...",
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            // Keyboard-aware input container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                left: 10,
                right: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0
                    ? MediaQuery.of(context).viewInsets.bottom + 10
                    : MediaQuery.of(context).padding.bottom + 10,
                top: 6,
              ),
              color: const Color(0xFF1A1A1C),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: Colors.grey,
                    ),
                    onPressed: _showCareerExplorerSheet,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        // hintText:
                        //     "Ask about career guidance, jobs, or professional development...",
                        // hintStyle: TextStyle(color: Colors.grey.shade500),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: GestureDetector(
                      onTap: () => _sendMessage(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF3C74FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
