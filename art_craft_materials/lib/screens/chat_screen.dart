// File: lib/screens/chat_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:art_craft_materials/widgets/chat_bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  // The chatRoomId is the user's UID.
  final String chatRoomId;
  // This is for the AppBar title (e.g., "Chat with user@example.com")
  final String? userName;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    this.userName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    // This ensures that if messages are already loaded, we scroll to the bottom immediately
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Determine if the current user is the chat user or the admin
    final isCurrentUserChatOwner = currentUser.uid == widget.chatRoomId;

    if (isCurrentUserChatOwner) {
      // If I am the USER, reset the user's unread count
      await _firestore.collection('chats').doc(widget.chatRoomId).set({
        'unreadByUserCount': 0,
      }, SetOptions(merge: true));

    } else {
      // If I am the ADMIN, reset the admin's unread count
      await _firestore.collection('chats').doc(widget.chatRoomId).set({
        'unreadByAdminCount': 0,
      }, SetOptions(merge: true));
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final String messageText = _messageController.text.trim();
    _messageController.clear();
    final timestamp = FieldValue.serverTimestamp();

    // Determine the role of the sender
    final isSenderUser = currentUser.uid == widget.chatRoomId;

    try {
      // --- TASK 1: Save the message to the subcollection ---
      await _firestore
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
        'text': messageText,
        'createdAt': timestamp,
        'senderId': currentUser.uid,
        'senderEmail': currentUser.email,
      });

      // --- TASK 2: Update the Parent Doc & Unread Counts ---
      Map<String, dynamic> parentDocData = {};
      parentDocData['lastMessage'] = messageText;
      parentDocData['lastMessageAt'] = timestamp;

      if (isSenderUser) {
        // If USER sends, increment ADMIN's count
        parentDocData['userEmail'] = currentUser.email;
        parentDocData['unreadByAdminCount'] = FieldValue.increment(1);

      } else {
        // If ADMIN sends, increment USER's count
        parentDocData['unreadByUserCount'] = FieldValue.increment(1);
      }

      await _firestore
          .collection('chats')
          .doc(widget.chatRoomId)
          .set(parentDocData, SetOptions(merge: true));

      // --- TASK 3: Scroll to bottom ---
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    } catch (e) {
      print("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName ?? 'Contact Admin'),
      ),
      body: Column(
        children: [
          // --- The Message List ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Say hello!'));
                }

                final messages = snapshot.data!.docs;

                // Add a small delay to scroll to the latest message
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;

                    return ChatBubble(
                      message: messageData['text'] ?? '',
                      isCurrentUser: messageData['senderId'] == currentUser.uid,
                    );
                  },
                );
              },
            ),
          ),

          // --- The Text Input Field ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}