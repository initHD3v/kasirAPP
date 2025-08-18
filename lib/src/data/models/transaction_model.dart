
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:kasir_app/src/data/models/cart_item_model.dart';

@immutable
class TransactionModel {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final String paymentMethod;
  final double amountPaid;
  final double change;
  final String cashierId;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.amountPaid,
    required this.change,
    required this.cashierId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': jsonEncode(items.map((item) => item.toMap()).toList()),
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'amount_paid': amountPaid,
      'change': change,
      'cashier_id': cashierId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      items: (jsonDecode(map['items']) as List)
          .map((itemData) => CartItem.fromMap(itemData as Map<String, dynamic>))
          .toList(),
      totalAmount: map['total_amount'] as double,
      paymentMethod: map['payment_method'] as String,
      amountPaid: map['amount_paid'] as double,
      change: map['change'] as double,
      cashierId: map['cashier_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
