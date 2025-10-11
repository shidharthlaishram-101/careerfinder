import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names
  static const String conversationsCollection = 'Conversations';
  static const String messagesCollection = 'Messages';

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Create a new conversation
  static Future<String> createNewConversation({
    required String userId,
    String? title,
  }) async {
    try {
      final conversationData = {
        'userId': userId,
        'title': title ?? 'New Conversation',
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'messageCount': 0,
        'isActive': true,
      };

      final docRef = await _firestore
          .collection(conversationsCollection)
          .add(conversationData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Save a message to a conversation
  static Future<void> saveMessage({
    required String conversationId,
    required String userId,
    required String role, // 'user' or 'bot'
    required String content,
  }) async {
    try {
      // Save the message
      await _firestore.collection(messagesCollection).add({
        'conversationId': conversationId,
        'userId': userId,
        'role': role,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update conversation metadata
      await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .update({
            'lastMessageAt': FieldValue.serverTimestamp(),
            'messageCount': FieldValue.increment(1),
          });

      // Auto-generate title from first user message if it's the first message
      final conversation = await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .get();

      if (conversation.exists && role == 'user') {
        final data = conversation.data()!;
        if (data['messageCount'] == 1) {
          // Generate title from first user message
          final title = _generateTitleFromMessage(content);
          await _firestore
              .collection(conversationsCollection)
              .doc(conversationId)
              .update({'title': title});
        }
      }
    } catch (e) {
      throw Exception('Failed to save message: $e');
    }
  }

  /// Get all conversations for a user
  static Future<List<Map<String, dynamic>>> getUserConversations(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(conversationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('lastMessageAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      throw Exception('Failed to get conversations: $e');
    }
  }

  /// Get messages for a specific conversation
  static Future<List<Map<String, dynamic>>> getConversationMessages(
    String conversationId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(messagesCollection)
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('timestamp', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  /// Delete a conversation and all its messages
  static Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete all messages in the conversation
      final messagesQuery = await _firestore
          .collection(messagesCollection)
          .where('conversationId', isEqualTo: conversationId)
          .get();

      for (final doc in messagesQuery.docs) {
        await doc.reference.delete();
      }

      // Delete the conversation
      await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  /// Update conversation title
  static Future<void> updateConversationTitle(
    String conversationId,
    String newTitle,
  ) async {
    try {
      await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .update({'title': newTitle});
    } catch (e) {
      throw Exception('Failed to update conversation title: $e');
    }
  }

  /// Get conversation details
  static Future<Map<String, dynamic>?> getConversation(
    String conversationId,
  ) async {
    try {
      final doc = await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .get();

      return doc.exists ? {'id': doc.id, ...doc.data()!} : null;
    } catch (e) {
      throw Exception('Failed to get conversation: $e');
    }
  }

  /// Get the latest conversation for a user
  static Future<String?> getLatestConversationId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(conversationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('lastMessageAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get latest conversation: $e');
    }
  }

  /// Archive/Deactivate a conversation
  static Future<void> archiveConversation(String conversationId) async {
    try {
      await _firestore
          .collection(conversationsCollection)
          .doc(conversationId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to archive conversation: $e');
    }
  }

  /// Generate a title from the first user message
  static String _generateTitleFromMessage(String message) {
    // Take first 30 characters and add ellipsis if longer
    if (message.length <= 30) {
      return message;
    }
    return '${message.substring(0, 30)}...';
  }

  /// Get conversation statistics for a user
  static Future<Map<String, int>> getUserChatStats(String userId) async {
    try {
      final conversationsQuery = await _firestore
          .collection(conversationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final messagesQuery = await _firestore
          .collection(messagesCollection)
          .where('userId', isEqualTo: userId)
          .get();

      return {
        'totalConversations': conversationsQuery.docs.length,
        'totalMessages': messagesQuery.docs.length,
        'activeConversations': conversationsQuery.docs
            .where((doc) => doc.data()['isActive'] == true)
            .length,
      };
    } catch (e) {
      throw Exception('Failed to get chat stats: $e');
    }
  }
}
