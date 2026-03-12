import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'stock_movement_model.g.dart';

@HiveType(typeId: 4)
class StockMovement extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String productId;
  @HiveField(2)
  final String productName;
  @HiveField(3)
  final int quantityAdded;
  @HiveField(4)
  final int previousStock;
  @HiveField(5)
  final DateTime dateTime;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantityAdded,
    required this.previousStock,
    required this.dateTime,
  });

  @override
  List<Object?> get props => [id, productId, productName, quantityAdded, previousStock, dateTime];
}
