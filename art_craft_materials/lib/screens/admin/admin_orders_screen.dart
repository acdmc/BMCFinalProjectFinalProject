// File: lib/screens/admin/admin_orders_screen.dart (FIXED V2: Simplified Update)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminOrdersScreen extends StatelessWidget {
  AdminOrdersScreen({super.key});

  static const List<String> _statuses = [
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange[400]!;
      case 'Processing':
        return Colors.blue[400]!;
      case 'Shipped':
        return Colors.deepPurple[400]!;
      case 'Delivered':
        return Colors.green[400]!;
      case 'Cancelled':
        return Colors.red[400]!;
      default:
        return Colors.grey;
    }
  }

  // CRITICAL FIX: Removed transaction and used two sequential writes.
  Future<void> _updateOrderStatus(
      BuildContext context, String orderId, String newStatus, String userId) async {
    try {
      // 1. UPDATE THE ORDER STATUS (First write operation)
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
      });

      // 2. CREATE THE NOTIFICATION (Second write operation)
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Order Status Updated',
        'body': 'Your order (${orderId.substring(0, 8)}...) has been updated to "$newStatus".',
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Show success confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${orderId.substring(0, 8)}... updated to $newStatus!'),
          backgroundColor: _getStatusColor(newStatus),
        ),
      );
    } catch (e) {
      // Error handling now explicitly mentions the rules
      print('Firestore Update Failed (Check Rules/Index): $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update order status. Please check Security Rules in Firestore.'),
            backgroundColor: Colors.red
        ),
      );
    }
  }

  // Function to show the status update dialog (Unchanged from previous fix)
  void _showStatusDialog(BuildContext context, String orderId, String currentStatus, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Update Order Status'),
        children: _statuses.map((status) {
          return SimpleDialogOption(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close the dialog
              await _updateOrderStatus(context, orderId, status, userId);
            },
            child: Row(
              children: [
                Icon(
                  status == currentStatus ? Icons.check_circle : Icons.circle_outlined,
                  color: _getStatusColor(status),
                ),
                const SizedBox(width: 10),
                Text(status),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allOrdersStream = _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage All Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: allOrdersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading orders: ${snapshot.error}'));
          }

          final orders = snapshot.data?.docs ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text('No orders have been placed yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final orderData = doc.data() as Map<String, dynamic>;
              final orderId = doc.id;
              final status = orderData['status'] as String? ?? 'Pending';
              final String userId = orderData['userId'] as String? ?? 'N/A';
              final totalPrice = orderData['totalPrice'] as num? ?? 0.0;
              final email = orderData['email'] as String? ?? 'Email N/A';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                child: ListTile(
                  onTap: () => _showStatusDialog(context, orderId, status, userId),
                  title: Text(
                    'Order ID: ${orderId.substring(0, 8)}...',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('User: $email\nUser ID: ${userId.substring(0, 8)}...'),
                  leading: CircleAvatar(
                    child: Text(
                      (orderData['items'] as List<dynamic>?)?.length.toString() ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 15.0),
                        child: Text(
                          'P${totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Theme.of(context).primaryColorDark),
                        ),
                      ),
                      Chip(
                        label: Text(
                          status,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: _getStatusColor(status),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}