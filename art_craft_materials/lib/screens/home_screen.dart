// File: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:provider/provider.dart';
import 'package:art_craft_materials/providers/cart_provider.dart';
import 'package:art_craft_materials/screens/cart_screen.dart';
import 'package:art_craft_materials/screens/order_history_screen.dart';
import 'package:art_craft_materials/screens/admin/admin_panel_screen.dart';
import 'package:art_craft_materials/widgets/product_card.dart';
import 'package:art_craft_materials/screens/product_detail_screen.dart';
import 'package:art_craft_materials/screens/products_screen.dart';
import 'package:art_craft_materials/screens/profile_screen.dart';

// --- NEW IMPORT FOR CHAT ---
import 'package:art_craft_materials/screens/chat_screen.dart';
// --- END NEW IMPORT ---

// *****************************************************************
// HOMESCREEN WIDGET
// *****************************************************************
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userRole = 'user';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _checkUserRole();
    }
  }

  Future<void> _checkUserRole() async {
    if (_currentUser == null) return;

    // Check if user is an admin
    final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['role'] == 'admin') {
        setState(() {
          _userRole = 'admin';
        });
      }
    }
  }

  // Widget to build the Drawer
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(_currentUser?.email?.split('@')[0] ?? 'Guest'),
            accountEmail: Text(_currentUser?.email ?? 'Not Logged In'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.deepPurple, size: 50),
            ),
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Order History'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          // Admin Panel Link
          if (_userRole == 'admin')
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Panel'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),
          const Divider(),
          // Logout is handled on the Profile screen, but we can add one here for convenience
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context); // Close the drawer
              // Use the fixed logout logic from ProfileScreen's _signOut
              final navigator = Navigator.of(context);
              await FirebaseAuth.instance.signOut();
              navigator.popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Art & Craft Materials'),
        actions: [

          // Cart Icon
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      cartProvider.itemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context),

      // ⭐️ UPDATED: Floating Action Button with Unread Chat Badge
      floatingActionButton: _userRole == 'user' && _currentUser != null
          ? StreamBuilder<DocumentSnapshot>(
        // Listen to *this user's* chat document (chats/{USER_ID})
        stream: _firestore.collection('chats').doc(_currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          int unreadCount = 0;
          // Check if the doc exists and has our count field
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data();
            if (data != null) {
              // The 'num' cast handles both int and double from Firestore
              unreadCount = (data as Map<String, dynamic>)['unreadByUserCount'] as int? ?? 0;
            }
          }

          // Wrap the FAB in the Badge widget
          return Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount'),
            child: FloatingActionButton.extended(
              icon: const Icon(Icons.support_agent),
              label: const Text('Contact Admin'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatRoomId: _currentUser!.uid,
                    ),
                  ),
                );
              },
            ),
          );
        },
      )
          : null, // If admin or not logged in, don't show the FAB

      body: StreamBuilder<QuerySnapshot>(
        // Fetch products, limited for the home screen
        stream: _firestore
            .collection('products')
            .limit(8)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(child: Text('No products available.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3/4, // Standard aspect ratio for product cards
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productDoc = products[index];
              final productData = productDoc.data() as Map<String, dynamic>;

              final Product product = Product(
                id: productDoc.id,
                name: productData['name'] ?? 'No Name',
                price: (productData['price'] as num?)?.toDouble() ?? 0.0,
                imageUrl: productData['imageUrl'] ?? 'https://placehold.co/600x400/F5B0A8/ffffff?text=No+Image',
                description: productData['description'] ?? 'No description available.',
              );

              return ProductCard(
                productName: product.name,
                price: product.price,
                imageUrl: product.imageUrl,
                // On tap action
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(product: product),
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