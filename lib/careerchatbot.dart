import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      final latestConversationId = await ChatService.getLatestConversationId(
        currentUser.uid,
      );
      if (latestConversationId != null) {
        await _loadConversation(latestConversationId);
      } else {
        await _createNewConversation();
      }
    } catch (e) {
      print('Error initializing conversation: $e');
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
        _messages
          ..clear()
          ..addAll(
            messages.map(
              (msg) => {'role': msg['role'], 'text': msg['content']},
            ),
          );
      });
      _scrollToBottom();
    } catch (e) {
      print('Error loading conversation: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final profile = await UserService.getCompleteUserProfile(
          currentUser.uid,
        );
        setState(() => _userProfile = profile);
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

  Future<String> _getGeminiResponse(String userMessage) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return "Error: API Key is not configured. Please add your Gemini API key.";
    }

    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

    String userContext = "";
    if (_userProfile != null) {
      final name = _userProfile?['name'] ?? 'there';
      final education = _userProfile?['educationLevel'];
      final degree = _userProfile?['degree'];
      userContext =
          "\nUser Profile:\nName: $name\nDegree: $degree\nEducation: $education\n";
    }

    // === Guardrail to restrict non-career queries ===
    const instruction = """
You are an AI Career Advisor. 
You must respond ONLY to queries related to:
- Career guidance
- Job searching
- Skills development
- Resume/Interview preparation
- Career growth, mentorship, or education paths
- Professional development or workplace advice

If the user asks about topics unrelated to career or professional life 
(e.g., entertainment, politics, personal life, religion, relationships, etc.), 
respond strictly with:
"I'm sorry, but I can only help with career-related questions. Please ask me something about your career or goals."

Always maintain an empathetic, professional, and conversational tone.
""";

    try {
      final response = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "$instruction$userContext\nUser asked: $userMessage"},
              ],
            },
          ],
          "generationConfig": {"temperature": 0.7, "maxOutputTokens": 1024},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            "No response from Gemini.";
      } else {
        return "Error: Gemini API failed (${response.statusCode})";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  void _sendMessage({String? message}) async {
    final userMessage = message ?? _controller.text.trim();
    if (userMessage.isEmpty || _currentConversationId == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _messages.add({"role": "user", "text": userMessage});
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    await ChatService.saveMessage(
      conversationId: _currentConversationId!,
      userId: currentUser.uid,
      role: 'user',
      content: userMessage,
    );

    final botResponse = await _getGeminiResponse(userMessage);

    setState(() {
      _messages.add({"role": "bot", "text": botResponse});
      _isTyping = false;
    });

    await ChatService.saveMessage(
      conversationId: _currentConversationId!,
      userId: currentUser.uid,
      role: 'bot',
      content: botResponse,
    );

    _scrollToBottom();
  }

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
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Exit app instead of navigating back to another page
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF0E0E10),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          backgroundColor: const Color(0xFF0E0E10),
          elevation: 0,
          title: const Text(
            "Career Advisor",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
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
                  itemBuilder: (context, index) =>
                      _buildMessageBubble(_messages[index]),
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
      ),
    );
  }
}
