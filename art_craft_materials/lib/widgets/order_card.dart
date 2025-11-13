// File: lib/widgets/order_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class OrderCard extends StatelessWidget {
  // We pass in the entire order data map
  final Map<String, dynamic> orderData;

  const OrderCard({super.key, required this.orderData});

  // Helper function to format the timestamp
  String _formatDate(Timestamp timestamp) {
    // Format: MM/dd/yyyy - hh:mm a (e.g., 11/06/2025 - 10:30 AM)
    final formatter = DateFormat('MM/dd/yyyy - hh:mm a');
    return formatter.format(timestamp.toDate());
  }

  // Helper function to build the list of items in the order
  Widget _buildItemsList() {
    final List<dynamic> items = orderData['items'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(left: 10.0, top: 4.0),
          child: Text(
            '${item['quantity']}x ${item['name']} (P${item['price'].toStringAsFixed(2)})',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Safely retrieve data - FIX: Changed 'timestamp' to 'createdAt'
    final timestamp = orderData['createdAt'] as Timestamp?;
    final totalPrice = orderData['totalPrice'] as num? ?? 0.0;
    final status = orderData['status'] as String? ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID (First few characters)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ID: ${orderData['id']?.substring(0, 8) ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: status == 'Pending' ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(height: 15),
            // Date
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Date: ${_formatDate(timestamp)}',
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
            // Items List
            const Text(
              'Items Purchased:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            _buildItemsList(),
            const Divider(height: 15),
            // Total Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL AMOUNT:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'P${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}