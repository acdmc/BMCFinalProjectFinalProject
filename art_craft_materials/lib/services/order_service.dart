// File: lib/services/order_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to update the status of a specific order
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      // Access the specific document in the 'orders' collection
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus, // Update the status field
      });
      print('Order $orderId status updated to $newStatus successfully.');
    } catch (e) {
      print('Error updating order status: $e');
      rethrow; // Throw the error up for UI handling
    }
  }
}