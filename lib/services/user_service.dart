import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection names
  static const String usersCollection = 'Users';
  static const String userInfoCollection = 'UserInfo';

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Save basic user information during registration
  static Future<void> saveBasicUserInfo({
    required String userId,
    required String email,
    required String name,
    required String signInMethod,
  }) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).set({
        'userId': userId,
        'email': email,
        'name': name,
        'signInMethod': signInMethod, // 'email' or 'google'
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'hasCompletedProfile': false,
        'totalConversations': 0,
        'totalMessages': 0,
      });
    } catch (e) {
      throw Exception('Failed to save user info: $e');
    }
  }

  /// Save detailed user information from UserInfoPage
  static Future<void> saveDetailedUserInfo({
    required String userId,
    required int age,
    required String stream,
    required String educationLevel,
    String? degree,
    String? specialization,
    required bool isWorking,
    String? workDescription,
  }) async {
    try {
      await _firestore.collection(userInfoCollection).doc(userId).set({
        'userId': userId,
        'age': age,
        'stream': stream,
        'educationLevel': educationLevel,
        'degree': degree,
        'specialization': specialization,
        'isWorking': isWorking,
        'workDescription': workDescription,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update the main user document to mark profile as completed
      await _firestore.collection(usersCollection).doc(userId).update({
        'hasCompletedProfile': true,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save detailed user info: $e');
    }
  }

  /// Get user's basic information
  static Future<Map<String, dynamic>?> getUserBasicInfo(String userId) async {
    try {
      final doc = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Failed to get user basic info: $e');
    }
  }

  /// Get user's detailed information
  static Future<Map<String, dynamic>?> getUserDetailedInfo(
    String userId,
  ) async {
    try {
      final doc = await _firestore
          .collection(userInfoCollection)
          .doc(userId)
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Failed to get user detailed info: $e');
    }
  }

  /// Get complete user profile (basic + detailed info)
  static Future<Map<String, dynamic>?> getCompleteUserProfile(
    String userId,
  ) async {
    try {
      final basicInfo = await getUserBasicInfo(userId);
      final detailedInfo = await getUserDetailedInfo(userId);

      if (basicInfo == null) return null;

      return {...basicInfo, ...?detailedInfo};
    } catch (e) {
      throw Exception('Failed to get complete user profile: $e');
    }
  }

  /// Update user's last login time
  static Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update last login: $e');
    }
  }

  /// Check if user has completed their profile
  static Future<bool> hasCompletedProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .get();
      return doc.exists ? (doc.data()?['hasCompletedProfile'] ?? false) : false;
    } catch (e) {
      return false;
    }
  }

  /// Delete user data (for account deletion)
  static Future<void> deleteUserData(String userId) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).delete();
      await _firestore.collection(userInfoCollection).doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }

  /// Update specific user info fields
  static Future<void> updateUserInfo({
    required String userId,
    Map<String, dynamic>? basicInfoUpdates,
    Map<String, dynamic>? detailedInfoUpdates,
  }) async {
    try {
      if (basicInfoUpdates != null) {
        await _firestore.collection(usersCollection).doc(userId).update({
          ...basicInfoUpdates,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (detailedInfoUpdates != null) {
        await _firestore.collection(userInfoCollection).doc(userId).update({
          ...detailedInfoUpdates,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to update user info: $e');
    }
  }

  /// Update chat statistics for a user
  static Future<void> updateChatStats(String userId) async {
    try {
      // Get current chat stats from ChatService
      final stats = await _firestore
          .collection('Conversations')
          .where('userId', isEqualTo: userId)
          .get();

      final messages = await _firestore
          .collection('Messages')
          .where('userId', isEqualTo: userId)
          .get();

      // Update user document with latest stats
      await _firestore.collection(usersCollection).doc(userId).update({
        'totalConversations': stats.docs.length,
        'totalMessages': messages.docs.length,
        'lastChatUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update chat stats: $e');
    }
  }
}
