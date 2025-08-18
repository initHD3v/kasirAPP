
import 'package:flutter/foundation.dart';
import 'package:kasir_app/src/data/models/product_model.dart';

@immutable
class CartItem {
  final Product product;
  final int quantity;
  final double costAtSale; // Harga beli produk saat transaksi terjadi

  const CartItem({required this.product, required this.quantity, required this.costAtSale});

  // Menghitung subtotal untuk item ini (berdasarkan harga jual)
  double get subtotal => product.price * quantity;

  // Menghitung total biaya untuk item ini (berdasarkan harga beli saat penjualan)
  double get totalCost => costAtSale * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? costAtSale,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      costAtSale: costAtSale ?? this.costAtSale,
    );
  }

  // Konversi object ke Map (untuk JSON)
  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
      'costAtSale': costAtSale,
    };
  }

  // Buat object dari Map (dari JSON)
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: Product.fromMap(map['product'] as Map<String, dynamic>),
      quantity: map['quantity'] as int,
      costAtSale: map['costAtSale'] as double,
    );
  }
}
