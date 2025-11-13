// File: lib/providers/cart_provider.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// *****************************************************************
// PART 1: The CartItem Model (with toMap/fromMap for Firestore)
// *****************************************************************
class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  // Function to convert CartItem to a map for Firestore saving
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  // Static function to create a CartItem from a Firestore map
  static CartItem fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
    );
  }
}

// *****************************************************************
// PART 2: The CartProvider
// *****************************************************************
class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  CollectionReference? _cartCollectionRef;
  DocumentReference? _cartDocRef;
  StreamSubscription<User?>? _authStateSubscription;

  // Getters
  List<CartItem> get items => [..._items];

  // 1. RENAME 'totalPrice' to 'subtotal'
  // This is the total price *before* tax.
  double get subtotal {
    double total = 0.0;
    for (var item in _items) {
      total += (item.price * item.quantity);
    }
    return total;
  }

  // 2. ADD this new getter for VAT (12%)
  double get vat {
    return subtotal * 0.12; // 12% of the subtotal
  }

  // 3. ADD this new getter for the FINAL total (VAT-inclusive)
  double get totalPriceWithVat {
    return subtotal + vat;
  }

  // We keep totalPrice as a computed property for any components that still use it.
  double get totalPrice => totalPriceWithVat;

  int get itemCount {
    // This 'fold' is a cleaner way to sum a list.
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Initialization function called from main.dart
  void initialize(String appId) {
    if (_authStateSubscription == null) {
      _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
        // 1. Clear state on any auth change
        _items.clear();

        if (user != null) {
          // 2. Set Firestore references for the new user (private data)
          final userId = user.uid;
          // Ensure your Firestore structure is correct here!
          _cartCollectionRef = FirebaseFirestore.instance
              .collection('artifacts')
              .doc(appId)
              .collection('users')
              .doc(userId)
              .collection('cart');
          _cartDocRef = _cartCollectionRef!.doc('currentCart');

          // 3. Load cart data for the new user
          _fetchCart();
        } else {
          // If logged out, reset refs
          _cartCollectionRef = null;
          _cartDocRef = null;
        }
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // Fetch cart data from Firestore on login
  Future<void> _fetchCart() async {
    if (_cartDocRef == null) return;

    try {
      final snapshot = await _cartDocRef!.get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final itemsList = data['items'] as List<dynamic>?;

        _items.clear();
        if (itemsList != null) {
          for (var itemMap in itemsList) {
            _items.add(CartItem.fromMap(itemMap as Map<String, dynamic>));
          }
        }
      }
      notifyListeners(); // Update UI after loading
    } catch (e) {
      print('Error fetching cart: $e');
    }
  }

  // Save the current cart to Firestore
  Future<void> _saveCart() async {
    if (_cartDocRef == null) return;

    try {
      final cartData = _items.map((item) => item.toMap()).toList();
      await _cartDocRef!.set({'items': cartData});
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // Logic: "Add Item to Cart" (Called from ProductDetailScreen)
  void addItem(String id, String name, double price, int quantity) {
    var index = _items.indexWhere((item) => item.id == id);

    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(id: id, name: name, price: price, quantity: quantity));
    }

    _saveCart(); // CRITICAL: Save to Firestore
    notifyListeners();
  }

  void increaseQuantity(String id) {
    var index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].quantity++;
      _saveCart();
      notifyListeners();
    }
  }

  void removeSingleItem(String id) {
    var index = _items.indexWhere((item) => item.id == id);

    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      _saveCart();
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _saveCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();
    // Ensure the cart document in Firestore is also cleared/reset
    if (_cartDocRef != null) {
      try {
        await _cartDocRef!.set({'items': []}); // Set items to an empty list
      } catch (e) {
        print('Error clearing Firestore cart: $e');
      }
    }
    notifyListeners();
  }

  // FIX: Updated placeOrder() to save the price breakdown
  Future<void> placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in. Cannot place order.');
    }
    if (_items.isEmpty) {
      throw Exception('Cart is empty.');
    }

    try {
      final List<Map<String, dynamic>> itemsData =
      _items.map((item) => item.toMap()).toList();

      // Get all our new calculated values
      final double sub = subtotal;
      final double v = vat;
      final double total = totalPriceWithVat;
      final int count = itemCount;

      // 2. Update the data we save to Firestore
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'items': itemsData,
        'subtotal': sub,
        'vat': v,
        'totalPrice': total, // This is now the VAT-inclusive price
        'itemCount': count,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Order placed successfully!');
    } catch (e) {
      print('Error placing order: $e');
      rethrow;
    }
  }

  void updateItemQuantity(String id, int newQuantity) {
    // ... (omitted quantity update logic)
  }
}