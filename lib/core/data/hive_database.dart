import 'package:hive_flutter/hive_flutter.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/shop/data/models/shop_model.dart';
import '../../features/billing/data/models/sale_model.dart';

class HiveDatabase {
  static const String productBoxName = 'products';
  static const String shopBoxName = 'shop';
  static const String settingsBoxName = 'settings';
  static const String saleBoxName = 'sales';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(ShopModelAdapter());
    Hive.registerAdapter(SaleModelAdapter());
    Hive.registerAdapter(SaleItemModelAdapter());

    // Open Boxes
    await Hive.openBox<ProductModel>(productBoxName);
    await Hive.openBox<ShopModel>(shopBoxName);
    await Hive.openBox<SaleModel>(saleBoxName);
    await Hive.openBox(settingsBoxName); // Generic box for simple key-value
  }

  static Box<ProductModel> get productBox =>
      Hive.box<ProductModel>(productBoxName);
  static Box<ShopModel> get shopBox => Hive.box<ShopModel>(shopBoxName);
  static Box<SaleModel> get saleBox => Hive.box<SaleModel>(saleBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
}
