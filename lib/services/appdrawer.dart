import 'package:flutter/material.dart';
import 'package:aipowered/services/user_service.dart';
import 'package:aipowered/services/chat_service.dart';
import 'package:aipowered/careerchatbot.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadConversations();
  }

  Future<void> _loadUserData() async {
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

  Future<void> _loadConversations() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final conversations = await ChatService.getUserConversations(
        currentUser.uid,
      );
      print(
        'Loaded ${conversations.length} conversations for user ${currentUser.uid}',
      );
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading conversations: $e');
    }
  }

  void _showConversationHistory() {
    Navigator.pop(context); // Close drawer first

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1C),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Conversation History",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _conversations.isEmpty
                    ? const Center(
                        child: Text(
                          "No conversations yet",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                conversation['title'] ??
                                    'Untitled Conversation',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${conversation['messageCount'] ?? 0} messages',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _navigateToConversation(conversation['id']);
                              },
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteConversation(conversation['id']);
                                  } else if (value == 'rename') {
                                    _renameConversation(
                                      conversation['id'],
                                      conversation['title'],
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Text('Rename'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _startNewConversation();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("New Conversation"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C74FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToConversation(String conversationId) {
    // Navigate to CareerChatbotPage with specific conversation
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const CareerChatbotPage(),
        settings: RouteSettings(
          arguments: {'action': 'load', 'conversationId': conversationId},
        ),
      ),
    );
  }

  void _startNewConversation() {
    // Clear current conversation and start fresh
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const CareerChatbotPage(),
        settings: const RouteSettings(arguments: {'action': 'new'}),
      ),
    );
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      await ChatService.deleteConversation(conversationId);
      await _loadConversations();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting conversation: $e')),
      );
    }
  }

  Future<void> _renameConversation(
    String conversationId,
    String currentTitle,
  ) async {
    final controller = TextEditingController(text: currentTitle);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1C),
        title: const Text(
          'Rename Conversation',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter conversation title',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != currentTitle) {
      try {
        await ChatService.updateConversationTitle(conversationId, newTitle);
        await _loadConversations();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation renamed successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error renaming conversation: $e')),
        );
      }
    }
  }

  void _showUserProfile() {
    Navigator.pop(context); // Close drawer first

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1C),
        title: const Text(
          'User Profile',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_userProfile != null) ...[
              _buildProfileRow('Name', _userProfile!['name'] ?? 'Not set'),
              _buildProfileRow('Email', _userProfile!['email'] ?? 'Not set'),
              _buildProfileRow(
                'Age',
                _userProfile!['age']?.toString() ?? 'Not set',
              ),
              _buildProfileRow('Stream', _userProfile!['stream'] ?? 'Not set'),
              _buildProfileRow(
                'Education Level',
                _userProfile!['educationLevel'] ?? 'Not set',
              ),
              if (_userProfile!['degree'] != null)
                _buildProfileRow('Degree', _userProfile!['degree']),
              if (_userProfile!['specialization'] != null)
                _buildProfileRow(
                  'Specialization',
                  _userProfile!['specialization'],
                ),
              _buildProfileRow(
                'Working Status',
                (_userProfile!['isWorking'] ?? false)
                    ? 'Currently Working'
                    : 'Not Working',
              ),
              if (_userProfile!['workDescription'] != null)
                _buildProfileRow(
                  'Work Description',
                  _userProfile!['workDescription'],
                ),
            ] else ...[
              const Text(
                'Loading profile...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1C), // Match the theme
      child: ListView(
        padding: EdgeInsets.zero, // Remove padding from ListView
        children: [
          // Drawer Header for Profile Info
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0E0E10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF3C74FF),
                  child: Icon(Icons.person, size: 30, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  _userProfile?['name'] ?? 'Loading...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: _showUserProfile,
                  child: const Text(
                    'view profile',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_conversations.isNotEmpty)
                  Text(
                    '${_conversations.length} conversations',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          // Menu Item: Chat History
          ListTile(
            leading: const Icon(Icons.history, color: Colors.white70),
            title: const Text(
              'Chat History',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: _conversations.isNotEmpty
                ? Text(
                    '${_conversations.length} conversations',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  )
                : null,
            onTap: _showConversationHistory,
          ),
          // Menu Item: New Conversation
          ListTile(
            leading: const Icon(
              Icons.add_comment_outlined,
              color: Colors.white70,
            ),
            title: const Text(
              'New Conversation',
              style: TextStyle(color: Colors.white),
            ),
            onTap: _startNewConversation,
          ),
          // Menu Item: Profile
          // ListTile(
          //   leading: const Icon(Icons.person_outline, color: Colors.white70),
          //   title: const Text('Profile', style: TextStyle(color: Colors.white)),
          //   onTap: _showUserProfile,
          // ),
          const Divider(color: Colors.grey),
          // Menu Item: Refresh
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.white70),
            title: const Text(
              'Refresh Data',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              _loadUserData();
              _loadConversations();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
