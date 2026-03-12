import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:billing_app/features/product/presentation/bloc/product_bloc.dart';
import 'package:billing_app/features/shop/presentation/bloc/shop_bloc.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/utils/pdf_helper.dart';
import 'package:intl/intl.dart';
import 'package:billing_app/features/billing/presentation/bloc/history_bloc.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rapport & Analytics', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: MultiBlocBuilder(
        child: (productState, historyState) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Évolution des Ventes (7j)'),
              const SizedBox(height: 16),
              _buildSalesEvolutionChart(historyState),
              const SizedBox(height: 32),
              _buildSectionTitle('Répartition de l\'Inventaire'),
              const SizedBox(height: 16),
              _buildInventoryChart(productState),
              const SizedBox(height: 32),
              _buildSectionTitle('Performance par Produit'),
              const SizedBox(height: 16),
              _buildDetailedProductList(context, productState, historyState),
              const SizedBox(height: 32),
              _buildSectionTitle('Statistiques Globales'),
              const SizedBox(height: 16),
              _buildSummaryCards(productState),
              const SizedBox(height: 32),
              _buildSectionTitle('Actions'),
              const SizedBox(height: 16),
              _buildActionButtons(context, productState),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSalesEvolutionChart(HistoryState state) {
    if (state.allSales.isEmpty) return const Center(child: Text('Aucune vente enregistrée'));

    final salesByDay = <DateTime, double>{};
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        salesByDay[date] = 0.0;
    }

    for (final sale in state.allSales) {
        final date = DateTime(sale.dateTime.year, sale.dateTime.month, sale.dateTime.day);
        if (salesByDay.containsKey(date)) {
            salesByDay[date] = salesByDay[date]! + sale.totalAmount;
        }
    }

    final sortedDays = salesByDay.keys.toList()..sort();
    final spots = sortedDays.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), salesByDay[e.value]!);
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  if (val.toInt() >= sortedDays.length) return const SizedBox.shrink();
                  return Text(DateFormat('dd').format(sortedDays[val.toInt()]), style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryChart(ProductState state) {
    if (state.products.isEmpty) return const Center(child: Text('Aucune donnée'));

    final sortedProducts = List.from(state.products)..sort((a, b) => b.stock.compareTo(a.stock));
    final topProducts = sortedProducts.take(5).toList();
    final colors = [AppTheme.primaryColor, AppTheme.secondaryColor, AppTheme.accentColor, Colors.orange, Colors.purple];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: topProducts.asMap().entries.map((entry) {
                  return PieChartSectionData(
                    color: colors[entry.key % colors.length],
                    value: entry.value.stock.toDouble(),
                    title: '${entry.value.stock}',
                    radius: 50,
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...topProducts.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value.name, style: const TextStyle(fontSize: 12))),
                Text('${e.value.stock} pces', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailedProductList(BuildContext context, ProductState productState, HistoryState historyState) {
    if (productState.products.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: productState.products.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
        itemBuilder: (context, index) {
          final product = productState.products[index];
          final productSales = historyState.allSales.where((sale) => 
            sale.items.any((item) => item.productName == product.name)
          ).toList();

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(product.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Stock: ${product.stock} | Prix: ${product.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
            onTap: () => _showProductMovementDetail(context, product, productSales),
          );
        },
      ),
    );
  }

  void _showProductMovementDetail(BuildContext context, dynamic product, List<dynamic> sales) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Historique des Mouvements', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildStatBanner(product, sales),
            const SizedBox(height: 24),
            Text('Journal des Ventes', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: sales.isEmpty 
                ? Center(child: Text('Aucune vente enregistrée pour ce produit', style: TextStyle(color: Colors.grey[400])))
                : ListView.builder(
                    itemCount: sales.length,
                    itemBuilder: (context, index) {
                      final sale = sales[index];
                      final item = sale.items.firstWhere((i) => i.productName == product.name);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50]!,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                              child: Icon(Icons.call_made_rounded, color: Colors.red[400], size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Vente #${sale.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(DateFormat('dd/MM/yyyy HH:mm').format(sale.dateTime), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('-${item.quantity}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('${item.total.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBanner(dynamic product, List<dynamic> sales) {
    final totalSold = sales.fold(0, (sum, sale) {
      final item = sale.items.firstWhere((i) => i.productName == product.name);
      return sum + (item.quantity as int);
    });
    final totalRevenue = sales.fold(0.0, (sum, sale) {
      final item = sale.items.firstWhere((i) => i.productName == product.name);
      return sum + (item.total as double);
    });

    return Row(
      children: [
        _buildSmallStatCard('Total Vendu', '$totalSold', Colors.orange),
        const SizedBox(width: 12),
        _buildSmallStatCard('Revenue', '${totalRevenue.toStringAsFixed(0)}', Colors.green),
        const SizedBox(width: 12),
        _buildSmallStatCard('Stock Actuel', '${product.stock}', Colors.blue),
      ],
    );
  }

  Widget _buildSmallStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(ProductState productState) {
    final totalStock = productState.products.fold(0, (sum, p) => sum + p.stock);
    final totalValue = productState.products.fold(0.0, (sum, p) => sum + (p.price * p.stock));

    return Row(
      children: [
        Expanded(child: _buildStatTile('Stock Total', '$totalStock', Icons.inventory_2_rounded, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatTile('Valeur Stock', '${totalValue.toStringAsFixed(0)}', Icons.monetization_on_rounded, Colors.green)),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProductState state) {
    return Column(
      children: [
        _buildFullWidthButton(
          'Télécharger le Rapport d\'Inventaire (PDF)', 
          Icons.picture_as_pdf_rounded, 
          Colors.red, 
          () => _generatePdfReport(context, state),
        ),
      ],
    );
  }

  Widget _buildFullWidthButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  void _generatePdfReport(BuildContext context, ProductState state) async {
    final shopBloc = context.read<ShopBloc>();
    
    if (state.products.isEmpty) return;

    String shopName = 'Don Shop';
    String currency = 'FCFA';
    
    if (shopBloc.state is ShopLoaded) {
      final shop = (shopBloc.state as ShopLoaded).shop;
      shopName = shop.name;
      currency = shop.currency;
    }

    try {
      final file = await PdfHelper.generateInventoryReport(
        shopName: shopName,
        products: state.products,
        currency: currency,
      );

      await Share.shareXFiles([XFile(file.path)], text: 'Rapport d\'inventaire - $shopName');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

class MultiBlocBuilder extends StatelessWidget {
  final Widget Function(ProductState, HistoryState) child;
  const MultiBlocBuilder({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, productState) {
        return BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, historyState) {
            return child(productState, historyState);
          },
        );
      },
    );
  }
}


