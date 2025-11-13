// File: lib/screens/order_history_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:art_craft_materials/widgets/order_card.dart'; // Import the new widget

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: const Center(child: Text('Please log in to view your order history.')),
      );
    }

    // 1. Create a Query to fetch orders for the logged-in user
    final ordersQuery = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: currentUser.uid)
    // 2. Sort by 'createdAt' (most recent first) - FIX: Changed 'timestamp' to 'createdAt'
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersQuery,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading orders: ${snapshot.error}'));
          }

          // Check if data exists and is not empty
          final orders = snapshot.data?.docs ?? [];
          if (orders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'You have not placed any orders yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              ),
            );
          }

          // Build the list of orders
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final orderData = doc.data() as Map<String, dynamic>;
              // Pass the document ID into the map for display
              orderData['id'] = doc.id;

              return OrderCard(orderData: orderData);
            },
          );
        },
      ),
    );
  }
}