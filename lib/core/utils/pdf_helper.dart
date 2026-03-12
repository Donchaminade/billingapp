import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PdfHelper {
  static Future<File> generateReceipt({
    required String shopName,
    required String address1,
    required String address2,
    required String phone,
    required List<Map<String, dynamic>> items,
    required double total,
    required String currency,
    required String footer,
    DateTime? dateTime,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6, // Format compact pour les reçus
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(shopName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                pw.SizedBox(height: 5),
                if (address1.isNotEmpty) pw.Text(address1, style: const pw.TextStyle(fontSize: 10)),
                if (address2.isNotEmpty) pw.Text(address2, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(phone, style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Facture - ${DateFormat('dd/MM/yyyy HH:mm').format(dateTime ?? DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Divider(thickness: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Désignation', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
                pw.Divider(thickness: 0.5),
                ...items.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(item['name'], style: const pw.TextStyle(fontSize: 10)),
                              pw.Text('${item['qty']} x ${item['price']} $currency',
                                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                            ],
                          ),
                        ),
                        pw.Text('${item['total']} $currency',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  );
                }).toList(),
                pw.Divider(thickness: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL À PAYER', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('${total.toStringAsFixed(0)} $currency',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(footer, style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9)),
                pw.SizedBox(height: 10),
                pw.Text('Merci pour votre confiance !', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/facture_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> generateInventoryReport({
    required String shopName,
    required List<dynamic> products,
    required String currency,
  }) async {
    final pdf = pw.Document();
    final date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('RAPPORT D\'INVENTAIRE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                pw.Text(date, style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Text(shopName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.Divider(),
          ],
        ),
        build: (pw.Context context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            headers: ['ID', 'Produit', 'Prix Unit.', 'Stock', 'Valeur'],
            data: products.map((p) {
              return [
                p.id.substring(0, 5),
                p.name,
                '${p.price.toStringAsFixed(0)} $currency',
                '${p.stock}',
                '${(p.price * p.stock).toStringAsFixed(0)} $currency',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Valeur Totale du Stock : ${products.fold(0.0, (double sum, p) => sum + (p.price * p.stock)).toStringAsFixed(0)} $currency',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
        footer: (pw.Context context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text('Page ${context.pageNumber} / ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10)),
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/rapport_inventaire_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
