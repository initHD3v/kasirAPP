import 'package:flutter/foundation.dart';

@immutable
class Product {
  final String id;
  final String name;
  final double price; // Harga jual
  final double cost; // Harga beli/modal
  final int stock;
  final String? category;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.cost,
    this.stock = 0,
    this.category,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'cost': cost,
      'stock': stock,
      'category': category,
      'image_url': imageUrl,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      category: map['category'] as String?,
      imageUrl: map['image_url'] as String?,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    double? cost,
    int? stock,
    String? category,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
