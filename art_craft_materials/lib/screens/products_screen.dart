// File: lib/screens/products_screen.dart

import 'package:flutter/material.dart';

// *****************************************************************
// PRODUCT CLASS DEFINITION (Ang modelo ng inyong produkto)
// *****************************************************************
class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.description,
  });
}

// NOTE: Ang mga widgets na nagdi-display ng products (tulad ng StreamBuilder at GridView)
// ay matatagpuan sa 'lib/screens/home_screen.dart'.