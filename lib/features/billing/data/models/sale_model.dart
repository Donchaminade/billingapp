import 'package:hive/hive.dart';
import '../../domain/entities/sale.dart';

part 'sale_model.g.dart';

@HiveType(typeId: 3)
class SaleModel extends Sale {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime dateTime;
  @HiveField(2)
  final List<SaleItemModel> items;
  @HiveField(3)
  final double totalAmount;

  const SaleModel({
    required this.id,
    required this.dateTime,
    required this.items,
    required this.totalAmount,
  }) : super(id: id, dateTime: dateTime, items: items, totalAmount: totalAmount);

  factory SaleModel.fromEntity(Sale sale) {
    return SaleModel(
      id: sale.id,
      dateTime: sale.dateTime,
      items: sale.items.map((item) => SaleItemModel.fromEntity(item)).toList(),
      totalAmount: sale.totalAmount,
    );
  }
}

@HiveType(typeId: 4)
class SaleItemModel extends SaleItem {
  @HiveField(0)
  final String productName;
  @HiveField(1)
  final int quantity;
  @HiveField(2)
  final double price;
  @HiveField(3)
  final double total;

  const SaleItemModel({
    required this.productName,
    required this.quantity,
    required this.price,
    required this.total,
  }) : super(productName: productName, quantity: quantity, price: price, total: total);

  factory SaleItemModel.fromEntity(SaleItem item) {
    return SaleItemModel(
      productName: item.productName,
      quantity: item.quantity,
      price: item.price,
      total: item.total,
    );
  }
}
