

import 'package:flutter/foundation.dart';

@immutable
class Product {
  final String id;
  final String name;
  final double price; // Harga jual
  final double cost;  // Harga beli/modal
  
  final String? category;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.cost,
    
    this.category,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'cost': cost,
      
      'category': category,
      'image_url': imageUrl,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      price: map['price'] as double,
      cost: map['cost'] as double, // Pastikan ini ada di map
      
      category: map['category'] as String?,
      imageUrl: map['image_url'] as String?,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    double? cost,
    
    String? category,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

