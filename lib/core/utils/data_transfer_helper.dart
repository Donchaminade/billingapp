import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../features/product/domain/entities/product.dart';
import 'package:uuid/uuid.dart';

class DataTransferHelper {
  static const List<String> columns = ['ID', 'Nom', 'Code Barre', 'Prix', 'Stock'];

  // --- EXPORT ---

  static Future<void> exportToExcel(List<Product> products) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Produits'];
    excel.delete('Sheet1');

    // Header
    sheetObject.appendRow(columns.map((e) => TextCellValue(e)).toList());

    // Data
    for (var p in products) {
      sheetObject.appendRow([
        TextCellValue(p.id),
        TextCellValue(p.name),
        TextCellValue(p.barcode),
        DoubleCellValue(p.price),
        IntCellValue(p.stock),
      ]);
    }

    final fileBytes = excel.save();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/export_produits.xlsx');
    await file.writeAsBytes(fileBytes!);

    await Share.shareXFiles([XFile(file.path)], text: 'Exportation des produits (Excel)');
  }

  static Future<void> exportToCSV(List<Product> products) async {
    List<List<dynamic>> rows = [];
    rows.add(columns);

    for (var p in products) {
      rows.add([p.id, p.name, p.barcode, p.price, p.stock]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/export_produits.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: 'Exportation des produits (CSV)');
  }

  static Future<void> exportToSQL(List<Product> products) async {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('-- Exportation des produits');
    buffer.writeln('CREATE TABLE IF NOT EXISTS products (id TEXT PRIMARY KEY, name TEXT, barcode TEXT, price REAL, stock INTEGER);');
    
    for (var p in products) {
      String name = p.name.replaceAll("'", "''");
      buffer.writeln("INSERT INTO products (id, name, barcode, price, stock) VALUES ('${p.id}', '$name', '${p.barcode}', ${p.price}, ${p.stock});");
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/export_produits.sql');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(file.path)], text: 'Exportation des produits (SQL)');
  }

  // --- IMPORT ---

  static Future<List<Product>?> importFromFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv', 'sql'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String ext = result.files.single.extension!.toLowerCase();

      if (ext == 'xlsx') return _importFromExcel(file);
      if (ext == 'csv') return _importFromCSV(file);
      if (ext == 'sql') return _importFromSQL(file);
    }
    return null;
  }

  static Future<List<Product>> _importFromExcel(File file) async {
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    List<Product> products = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table]!;
      // Skip header
      for (int i = 1; i < sheet.maxRows; i++) {
        var row = sheet.rows[i];
        if (row.length < 5) continue;

        products.add(Product(
          id: row[0]?.value?.toString() ?? const Uuid().v4(),
          name: row[1]?.value?.toString() ?? 'Produit sans nom',
          barcode: row[2]?.value?.toString() ?? '',
          price: double.tryParse(row[3]?.value?.toString() ?? '0') ?? 0,
          stock: int.tryParse(row[4]?.value?.toString() ?? '0') ?? 0,
        ));
      }
    }
    return products;
  }

  static Future<List<Product>> _importFromCSV(File file) async {
    final input = file.openRead();
    final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList();
    List<Product> products = [];

    // Skip header
    for (int i = 1; i < fields.length; i++) {
      var row = fields[i];
      if (row.length < 5) continue;

      products.add(Product(
        id: row[0].toString(),
        name: row[1].toString(),
        barcode: row[2].toString(),
        price: double.tryParse(row[3].toString()) ?? 0,
        stock: int.tryParse(row[4].toString()) ?? 0,
      ));
    }
    return products;
  }

  static Future<List<Product>> _importFromSQL(File file) async {
    String sql = await file.readAsString();
    List<Product> products = [];
    
    // Regex simple pour capturer les VALUES des INSERTS
    // Format attendu: INSERT INTO products (id, name, barcode, price, stock) VALUES ('...', '...', '...', ..., ...);
    final regExp = RegExp(r"VALUES\s*\(\s*'([^']*)'\s*,\s*'([^']*)'\s*,\s*'([^']*)'\s*,\s*([\d\.]+)\s*,\s*(\d+)\s*\)", caseSensitive: false);
    
    final matches = regExp.allMatches(sql);
    for (var m in matches) {
      products.add(Product(
        id: m.group(1)!,
        name: m.group(2)!.replaceAll("''", "'"),
        barcode: m.group(3)!,
        price: double.parse(m.group(4)!),
        stock: int.parse(m.group(5)!),
      ));
    }
    
    return products;
  }
}
