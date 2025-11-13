// File: lib/screens/admin_chat_list_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:art_craft_materials/screens/chat_screen.dart';
import 'package:flutter/material.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Chats')),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Query all chats, sorted by last message time
        stream: FirebaseFirestore.instance
            .collection('chats')
            .orderBy('lastMessageAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No active chats.'));
          }

          final chatDocs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              // The document ID is the userId for the chat room.
              final String userId = chatDoc.id;
              final String userEmail = chatData['userEmail'] ?? 'User ID: $userId';
              final String lastMessage = chatData['lastMessage'] ?? 'No messages yet.';

              // Get the admin's unread count
              // Use ?.toInt() to safely handle data types from Firestore
              final int unreadCount = (chatData['unreadByAdminCount'] as num?)?.toInt() ?? 0;

              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(userEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Show a Badge if there are unread messages for the admin
                trailing: unreadCount > 0
                    ? Badge(
                  label: Text('$unreadCount'),
                  child: const Icon(Icons.arrow_forward_ios),
                )
                    : const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatRoomId: userId,
                        userName: userEmail,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}