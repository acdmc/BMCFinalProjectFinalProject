// File: lib/screens/payment_screen.dart

import 'package:art_craft_materials/providers/cart_provider.dart';
import 'package:art_craft_materials/screens/order_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 1. An enum to represent our different payment methods [cite: 22, 34]
enum PaymentMethod { card, gcash, bank }

class PaymentScreen extends StatefulWidget {
  // 2. We need to know the total amount to be paid [cite: 24, 36]
  final double totalAmount;

  // 3. The constructor will require this amount [cite: 27]
  const PaymentScreen({super.key, required this.totalAmount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // 4. State variables to track selection and loading [cite: 31, 37, 38]
  PaymentMethod _selectedMethod = PaymentMethod.card; // Default to card
  bool _isLoading = false;

  // The main function that runs when the user taps "Pay Now."
  Future<void> _processPayment() async {
    // 1. Start loading spinner on the button [cite: 43, 83]
    setState(() {
      _isLoading = true;
    });

    try {
      // 2. --- THIS IS OUR MOCK API CALL --- [cite: 48]
      // We just wait for 3 seconds to simulate a real payment process. [cite: 49, 84, 85]
      await Future.delayed(const Duration(seconds: 3));

      // 3. If the "payment" is "successful," we get the CartProvider. [cite: 53, 56, 86]
      // (listen: false is critical for calls inside functions) [cite: 55]
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // 4. Call the functions we built in Module 10 [cite: 57]
      // This is the logic we are *moving* from the CartScreen [cite: 58, 87, 88]
      await cartProvider.placeOrder();
      await cartProvider.clearCart();

      // 5. If successful, navigate to success screen [cite: 61]
      // We use pushAndRemoveUntil to clear the cart/payment screens [cite: 62, 89]
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => const OrderSuccessScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      // 6. Handle any errors from placing the order [cite: 69, 70]
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    } finally {
      // 7. ALWAYS stop loading, even if an error occurred [cite: 76, 90]
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Format the total amount with the Philippine Peso sign (P) [cite: 98, 186]
    final String formattedTotal = 'P${widget.totalAmount.toStringAsFixed(2)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 2. Show the total amount [cite: 4, 110]
            Text(
              'Total Amount:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              formattedTotal,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple),
            ),
            const SizedBox(height: 24),
            const Divider(),

            // 3. Payment method selection [cite: 5, 122]
            Text(
              'Select Payment Method:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // 4. RadioListTile for Card [cite: 128, 187]
            RadioListTile<PaymentMethod>(
              title: const Text('Credit/Debit Card'),
              secondary: const Icon(Icons.credit_card),
              value: PaymentMethod.card, // unique enum value [cite: 189]
              groupValue: _selectedMethod, // tells which option is selected [cite: 190]
              onChanged: (PaymentMethod? value) {
                // update state on tap [cite: 191]
                setState(() {
                  _selectedMethod = value!;
                });
              },
            ),

            // 5. RadioListTile for GCash [cite: 140]
            RadioListTile<PaymentMethod>(
              title: const Text('GCash'),
              secondary: const Icon(Icons.phone_android),
              value: PaymentMethod.gcash,
              groupValue: _selectedMethod,
              onChanged: (PaymentMethod? value) {
                setState(() {
                  _selectedMethod = value!;
                });
              },
            ),

            // 6. RadioListTile for Bank Transfer [cite: 153]
            RadioListTile<PaymentMethod>(
              title: const Text('Bank Transfer'),
              secondary: const Icon(Icons.account_balance),
              value: PaymentMethod.bank,
              groupValue: _selectedMethod,
              onChanged: (PaymentMethod? value) {
                setState(() {
                  _selectedMethod = value!;
                });
              },
            ),
            const SizedBox(height: 32),

            // 7. The "Pay Now" button [cite: 166, 193]
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              // 8. Disable button when loading [cite: 171, 194]
              onPressed: _isLoading ? null : _processPayment,
              child: _isLoading
                  ? const CircularProgressIndicator(
                valueColor:
                AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : Text('Pay Now ($formattedTotal)'),
            ),
          ],
        ),
      ),
    );
  }
}