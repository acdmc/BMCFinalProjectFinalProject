// File: lib/screens/admin/admin_panel_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:art_craft_materials/screens/admin/admin_orders_screen.dart';
import 'package:art_craft_materials/screens/admin/admin_chat_list_screen.dart'; // NEW IMPORT

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  String _productName = '';
  String _productDescription = '';
  double _productPrice = 0.0;
  String _productImageUrl = '';
  String _productCategory = 'Art Supplies';
  bool _isLoading = false;

  final List<String> _categories = [
    'Art Supplies',
    'Craft Materials',
    'Tools',
    'Others'
  ];

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance.collection('products').add({
          'name': _productName,
          'description': _productDescription,
          'price': _productPrice,
          'imageUrl': _productImageUrl,
          'category': _productCategory,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear the form
        _formKey.currentState!.reset();
        setState(() {
          _productCategory = 'Art Supplies';
        });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Management (Example/Placeholder)

            const SizedBox(height: 10),

            // Manage All Orders Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    // ⭐️ FINAL FIX: Removed 'const' keyword
                    builder: (context) => AdminOrdersScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Manage All Orders'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),

            // Button to view the Admin Chat List
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('View User Chats'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminChatListScreen(),
                  ),
                );
              },
            ),

            const Divider(height: 30, thickness: 1),

            const Text(
              'Add New Product',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Product Add Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Product Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a product name.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _productName = value ?? '';
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _productDescription = value ?? '';
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Please enter a valid price.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _productPrice = double.tryParse(value ?? '0.0') ?? 0.0;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Image URL'),
                    validator: (value) {
                      if (value == null || !(Uri.tryParse(value)?.hasAbsolutePath ?? false)) {
                        return 'Please enter a valid URL.';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _productImageUrl = value ?? '';
                    },
                  ),
                  DropdownButtonFormField(
                    decoration: const InputDecoration(labelText: 'Category'),
                    value: _productCategory,
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _productCategory = value.toString();
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addProduct,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : const Text(
                      'Add Product',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}