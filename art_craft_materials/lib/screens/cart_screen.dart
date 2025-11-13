// File: lib/screens/cart_screen.dart

import 'package:art_craft_materials/providers/cart_provider.dart';
import 'package:art_craft_materials/screens/payment_screen.dart'; // 1. Import PaymentScreen [cite: 200]
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 2. It's a StatelessWidget again! [cite: 203, 307]
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. We listen: true, so the list and total update [cite: 208]
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: Column(
        children: [
          // 4. The ListView is the same as before [cite: 215]
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text('Your cart is empty.'))
                : ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final cartItem = cart.items[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(cartItem.name[0]),
                  ),
                  title: Text(cartItem.name),
                  subtitle: Text('Qty: ${cartItem.quantity}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          'P${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}'),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          cart.removeItem(cartItem.id);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // 5. --- THIS IS OUR NEW PRICE BREAKDOWN CARD (from Module 15) --- [cite: 245]
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                      Text('P${cart.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('VAT (12%):', style: TextStyle(fontSize: 16)),
                      Text('P${cart.vat.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        'P${cart.totalPriceWithVat.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 6. --- THIS IS THE MODIFIED BUTTON --- [cite: 282]
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              // 7. Disable if cart is empty, otherwise navigate [cite: 289, 308]
              onPressed: cart.items.isEmpty
                  ? null
                  : () {
                // 8. Navigate to our new PaymentScreen [cite: 290]
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      // 9. Pass the final VAT-inclusive total [cite: 291, 309]
                      totalAmount: cart.totalPriceWithVat,
                    ),
                  ),
                );
              },
              // 10. No more spinner! [cite: 300, 310]
              child: const Text('Proceed to Payment'),
            ),
          ),
        ],
      ),
    );
  }
}