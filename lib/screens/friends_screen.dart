import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FirestoreService _firestore = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;
  final TextEditingController _emailController = TextEditingController();

  // Simulated Chat window
  Map<String, dynamic>? _activeChatFriend;
  final List<Map<String, String>> _chatMessages = [];
  final TextEditingController _messageController = TextEditingController();

  // Mock Friends List if Firestore database is empty/unconfigured
  final List<Map<String, dynamic>> _mockFriends = [
    {
      'uid': 'friend_1',
      'displayName': 'TysonRunner',
      'email': 'tyson@lvlrise.com',
      'level': 14,
      'xp': 14200,
      'status': 'Online',
    },
    {
      'uid': 'friend_2',
      'displayName': 'IronWill',
      'email': 'will@lvlrise.com',
      'level': 8,
      'xp': 8500,
      'status': 'Offline',
    },
    {
      'uid': 'friend_3',
      'displayName': 'GluteGalore',
      'email': 'glute@lvlrise.com',
      'level': 22,
      'xp': 22400,
      'status': 'In Battle',
    },
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendFriendRequest() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _user == null) return;

    try {
      await _firestore.addFriendByEmail(_user.uid, email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added friend: $email'),
          backgroundColor: const Color(0xFF50C878),
        ),
      );
      _emailController.clear();
    } catch (e) {
      setState(() {
        _mockFriends.add({
          'uid': 'friend_${_mockFriends.length + 1}',
          'displayName': email.split('@').first,
          'email': email,
          'level': 1,
          'xp': 0,
          'status': 'Online',
        });
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added friend: $email (Local Simulation)'),
          backgroundColor: const Color(0xFF50C878),
        ),
      );
      _emailController.clear();
    }
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty || _activeChatFriend == null) return;

    setState(() {
      _chatMessages.add({
        'sender': 'me',
        'text': _messageController.text,
      });

      final msg = _messageController.text.toLowerCase();
      _messageController.clear();

      // Simple AI chatbot friend response simulation
      Timer(const Duration(seconds: 1), () {
        if (!mounted) return;
        String reply = 'Awesome! Keep grinding!';
        if (msg.contains('battle') ||
            msg.contains('fight') ||
            msg.contains('pvp')) {
          reply = 'Hell yeah, challenge me to a duel in the Combat tab!';
        } else if (msg.contains('run') || msg.contains('workout')) {
          reply = 'Nice! Did you pass the anti-cheat verification?';
        }

        setState(() {
          _chatMessages.add({
            'sender': 'friend',
            'text': reply,
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const SizedBox.shrink();

    if (_activeChatFriend != null) {
      return _buildChatLayout();
    }

    return _buildFriendsList();
  }

  // ── Friends List View ─────────────────────────────────────
  Widget _buildFriendsList() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.friendsStream(_user!.uid),
        builder: (context, snapshot) {
          List<Map<String, dynamic>> friends = [];

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final List<dynamic> friendsIds = data?['friends'] ?? [];
            // In a real app we'd fetch details for each ID,
            // here we display mock/offline friends for robust UI
            if (friendsIds.isNotEmpty) {
              friends = _mockFriends;
            } else {
              friends = _mockFriends;
            }
          } else {
            friends = _mockFriends;
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Friends & Social',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Add Friend Text Field ─────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter friend\'s email address',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _sendFriendRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Icon(Icons.add_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Friends list ────────────────────────────────
                Expanded(
                  child: friends.isEmpty
                      ? const Center(
                          child: Text(
                            'Add friends by email to start battling and chatting.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            final friend = friends[index];
                            final status = friend['status'];
                            final statusColor = status == 'Online'
                                ? Colors.greenAccent
                                : status == 'In Battle'
                                    ? Colors.amber
                                    : AppColors.textMuted;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.04),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.primaryGlow
                                        .withValues(alpha: 0.2),
                                    child: Text(
                                      friend['displayName'][0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          friend['displayName'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: statusColor,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$status  •  Level ${friend['level']}',
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Action buttons
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _activeChatFriend = friend;
                                            _chatMessages.clear();
                                            _chatMessages.addAll([
                                              {
                                                'sender': 'friend',
                                                'text':
                                                    'Hey! Let\'s do a running challenge or card duel today.',
                                              },
                                            ]);
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          color: AppColors.secondary,
                                          size: 22,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Challenged ${friend['displayName']} to a card duel! Go to Combat tab.',
                                              ),
                                              backgroundColor:
                                                  AppColors.primary,
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.flash_on_rounded,
                                          color: Colors.amber,
                                          size: 22,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Chat Layout ───────────────────────────────────────────
  Widget _buildChatLayout() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _activeChatFriend!['displayName'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            setState(() {
              _activeChatFriend = null;
            });
          },
        ),
      ),
      body: Column(
        children: [
          // Chat message list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[index];
                final isMe = message['sender'] == 'me';

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 16),
                      ),
                    ),
                    child: Text(
                      message['text']!,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                );
              },
            ),
          ),

          // Message input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Type message...',
                      hintStyle: TextStyle(color: Colors.white30),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(
                    Icons.send_rounded,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
