import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'knowledge_base_service.dart';

class RAGService {
  static const String _geminiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';
  
  /// Generate a response using RAG (Retrieval-Augmented Generation)
  static Future<String> generateRAGResponse({
    required String userQuery,
    Map<String, dynamic>? userProfile,
    int maxContextCareers = 3,
  }) async {
    try {
      // Ensure knowledge base is initialized
      await _ensureKnowledgeBaseInitialized();

      // Retrieve relevant careers from knowledge base
      final relevantCareers = KnowledgeBaseService.getRelevantCareers(
        userQuery,
        maxResults: maxContextCareers,
      );

      // If no relevant careers found, try broader search
      List<CareerInfo> contextCareers = relevantCareers;
      if (contextCareers.isEmpty) {
        contextCareers = KnowledgeBaseService.getAllCareers().take(3).toList();
      }

      // Build context from retrieved careers
      final context = _buildContext(contextCareers, userQuery, userProfile);

      // Generate response using Gemini with context
      return await _generateGeminiResponse(userQuery, context, userProfile);
    } catch (e) {
      print('Error in RAG response generation: $e');
      return 'I apologize, but I encountered an error while processing your career question. Please try again or rephrase your question.';
    }
  }

  /// Ensure knowledge base is initialized
  static Future<void> _ensureKnowledgeBaseInitialized() async {
    try {
      KnowledgeBaseService.getAllCareers();
    } catch (e) {
      await KnowledgeBaseService.initialize();
    }
  }

  /// Build context string from relevant careers
  static String _buildContext(List<CareerInfo> careers, String query, Map<String, dynamic>? userProfile) {
    final buffer = StringBuffer();
    
    buffer.writeln('RELEVANT CAREER INFORMATION:');
    buffer.writeln('Based on your query: "$query"');
    buffer.writeln();
    
    for (int i = 0; i < careers.length; i++) {
      final career = careers[i];
      buffer.writeln('${i + 1}. ${career.fullDescription}');
      buffer.writeln();
    }
    
    // Add user profile context if available
    if (userProfile != null) {
      buffer.writeln('USER PROFILE CONTEXT:');
      final age = userProfile['age'];
      final educationLevel = userProfile['educationLevel'];
      final stream = userProfile['stream'];
      final degree = userProfile['degree'];
      final specialization = userProfile['specialization'];
      final isWorking = userProfile['isWorking'] ?? false;
      final workDescription = userProfile['workDescription'];
      
      if (userProfile['name'] != null) {
        buffer.writeln('Name: ${userProfile['name']}');
      }
      if (age != null) buffer.writeln('Age: $age');
      if (stream != null) buffer.writeln('Stream: $stream');
      if (educationLevel != null) buffer.writeln('Education Level: $educationLevel');
      if (degree != null) buffer.writeln('Degree: $degree');
      if (specialization != null) buffer.writeln('Specialization: $specialization');
      if (isWorking && workDescription != null) {
        buffer.writeln('Current Work: $workDescription');
      } else if (!isWorking) {
        buffer.writeln('Status: Not currently working');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  /// Generate response using Gemini API with context
  static Future<String> _generateGeminiResponse(
    String userQuery,
    String context,
    Map<String, dynamic>? userProfile,
  ) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      return "Error: API Key is not configured. Please add your Gemini API key to the .env file.";
    }

    // Build the prompt with context
    final prompt = _buildPrompt(userQuery, context, userProfile);

    try {
      final response = await http.post(
        Uri.parse('$_geminiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": prompt,
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
        final errorBody = response.body;
        return "Error: Failed to get a response. Status: ${response.statusCode}. Response: $errorBody";
      }
    } catch (e) {
      return "Error: An exception occurred. Please check your connection. Details: $e";
    }
  }

  /// Build the complete prompt for Gemini
  static String _buildPrompt(String userQuery, String context, Map<String, dynamic>? userProfile) {
    return '''
You are a professional career advisor and mentor with access to comprehensive career information. Your role is STRICTLY limited to providing career guidance, job advice, professional development, and career-related information ONLY.

IMPORTANT: You must NOT answer questions about:
- General knowledge, history, science, or trivia
- Personal advice unrelated to careers
- Entertainment, movies, games, or hobbies
- Technical support or programming help
- Current events or news
- Health, relationships, or personal life advice

If a user asks about topics outside of career guidance, politely redirect them by saying: 'I'm a career advisor, so I can only help with career-related questions. Please ask me about career paths, job searching, professional development, workplace advice, or career planning.'

For career-related questions, use the provided context information to give accurate, detailed, and personalized responses. Keep responses concise, encouraging, and actionable.

$context

User Question: $userQuery

Instructions:
1. Use the relevant career information provided above to answer the user's question
2. If the information is not sufficient, acknowledge this and provide general guidance
3. Make your response personalized based on the user's profile if available
4. Provide specific, actionable advice
5. Keep the response conversational and encouraging
6. If suggesting multiple career paths, explain the differences between them
7. Always mention specific exams, degrees, or certifications when relevant

Please provide a helpful career guidance response to the user's question.
''';
  }

  /// Get career suggestions based on user profile
  static Future<List<CareerInfo>> getPersonalizedCareerSuggestions(
    Map<String, dynamic>? userProfile,
  ) async {
    try {
      await _ensureKnowledgeBaseInitialized();
      return KnowledgeBaseService.getCareerSuggestions(userProfile);
    } catch (e) {
      print('Error getting personalized career suggestions: $e');
      return [];
    }
  }

  /// Search for specific careers
  static Future<List<CareerInfo>> searchCareers(String query) async {
    try {
      await _ensureKnowledgeBaseInitialized();
      return KnowledgeBaseService.searchCareers(query);
    } catch (e) {
      print('Error searching careers: $e');
      return [];
    }
  }

  /// Get career details by name
  static Future<CareerInfo?> getCareerDetails(String careerName) async {
    try {
      await _ensureKnowledgeBaseInitialized();
      return KnowledgeBaseService.getCareerByName(careerName);
    } catch (e) {
      print('Error getting career details: $e');
      return null;
    }
  }

  /// Get careers by stream
  static Future<List<CareerInfo>> getCareersByStream(String stream) async {
    try {
      await _ensureKnowledgeBaseInitialized();
      return KnowledgeBaseService.getCareersByStream(stream);
    } catch (e) {
      print('Error getting careers by stream: $e');
      return [];
    }
  }

  /// Get career statistics
  static Future<Map<String, int>> getCareerStatistics() async {
    try {
      await _ensureKnowledgeBaseInitialized();
      return KnowledgeBaseService.getCareerStats();
    } catch (e) {
      print('Error getting career statistics: $e');
      return {};
    }
  }

  /// Initialize the RAG system
  static Future<void> initialize() async {
    try {
      await KnowledgeBaseService.initialize();
      print('RAG system initialized successfully');
    } catch (e) {
      print('Error initializing RAG system: $e');
    }
  }
}