// File: lib/screens/notifications_screen.dart (ULTIMATE FIX - V3: Using FutureBuilder)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Storage for the initial list of unread documents to be marked on exit
  List<QueryDocumentSnapshot> _unreadDocsToMark = [];

  // Future to fetch all notifications once
  late Future<QuerySnapshot> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch all notifications once upon entering the screen
    if (_user != null) {
      _notificationsFuture = _fetchNotificationsOnce();
    }
  }

  // Function to fetch data using a Future (get()) instead of a Stream (snapshots())
  Future<QuerySnapshot> _fetchNotificationsOnce() {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _user!.uid)
        .orderBy('createdAt', descending: true)
        .get(); // <-- CRITICAL: Using get() instead of snapshots()
  }

  // Function to collect unread documents for the batch update
  void _collectUnreadDocs(List<QueryDocumentSnapshot> currentDocs) {
    // Only collect unread docs if the list hasn't been populated yet
    if (_unreadDocsToMark.isEmpty) {
      _unreadDocsToMark = currentDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return data != null && data['isRead'] == false;
      }).toList();
    }
  }

  // Function to mark notifications as read. Tumatakbo lang sa dispose.
  void _markNotificationsAsReadOnExit() {
    if (_unreadDocsToMark.isEmpty) return;

    final batch = _firestore.batch();

    for (var doc in _unreadDocsToMark) {
      // Update only the initial unread documents collected
      batch.update(doc.reference, {'isRead': true});
    }

    batch.commit().then((_) {
      print('SUCCESS: Notifications marked as read upon screen exit.');
    }).catchError((e) {
      print('ERROR: Failed to mark notifications as read on dispose: $e');
    });
  }

  // CRITICAL: The dispose() method triggers the update when leaving the screen.
  @override
  void dispose() {
    _markNotificationsAsReadOnExit();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      // ⭐️ FIX: Removed 'const' from Scaffold and added 'const' to AppBar and Center
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
        ),
        body: const Center(child: Text('Please log in.')),
      );
    }

    // Use FutureBuilder to load data once
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading notifications: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have no notifications.'));
          }

          final docs = snapshot.data!.docs;

          // Collect unread documents here, once the future is complete
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _collectUnreadDocs(docs);
            }
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final timestamp = (data['createdAt'] as Timestamp?);

              final formattedDate = timestamp != null
                  ? DateFormat('MM/dd/yy hh:mm a').format(timestamp.toDate())
                  : '';

              // Display logic
              final bool isUnread = data['isRead'] == false;

              return ListTile(
                leading: Icon(
                    isUnread ? Icons.circle : Icons.circle_outlined,
                    color: isUnread ? Colors.deepPurple : Colors.grey,
                    size: 12),
                title: Text(
                  data['title'] ?? 'No Title',
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  '${data['body'] ?? ""}\n$formattedDate',
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}