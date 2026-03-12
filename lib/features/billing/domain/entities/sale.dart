import 'package:equatable/equatable.dart';

class Sale extends Equatable {
  final String id;
  final DateTime dateTime;
  final List<SaleItem> items;
  final double totalAmount;

  const Sale({
    required this.id,
    required this.dateTime,
    required this.items,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [id, dateTime, items, totalAmount];
}

class SaleItem extends Equatable {
  final String productName;
  final int quantity;
  final double price;
  final double total;

  const SaleItem({
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  @override
  List<Object?> get props => [productName, quantity, price, total];
}
