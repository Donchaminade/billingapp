import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:billing_app/features/product/presentation/bloc/product_bloc.dart';
import 'package:billing_app/features/shop/presentation/bloc/shop_bloc.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/utils/pdf_helper.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rapport & Analytics', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Performance de l\'Inventaire'),
            const SizedBox(height: 16),
            _buildInventoryChart(context),
            const SizedBox(height: 32),
            _buildSectionTitle('Statistiques Clés'),
            const SizedBox(height: 16),
            _buildSummaryCards(context),
            const SizedBox(height: 32),
            _buildSectionTitle('Actions'),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
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

  Widget _buildInventoryChart(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state.products.isEmpty) return const Center(child: Text('Aucune donnée'));

        final sortedProducts = List.from(state.products)..sort((a, b) => b.stock.compareTo(a.stock));
        final topProducts = sortedProducts.take(5).toList();

        return Container(
          height: 250,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: PieChart(
            PieChartData(
              sections: topProducts.asMap().entries.map((entry) {
                final colors = [AppTheme.primaryColor, AppTheme.secondaryColor, AppTheme.accentColor, Colors.orange, Colors.purple];
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
        );
      },
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, productState) {
        final totalStock = productState.products.fold(0, (sum, p) => sum + p.stock);
        final totalValue = productState.products.fold(0.0, (sum, p) => sum + (p.price * p.stock));

        return Row(
          children: [
            Expanded(child: _buildStatTile('Stock Total', '$totalStock', Icons.inventory_2_rounded, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatTile('Valeur Stock', '${totalValue.toStringAsFixed(0)}', Icons.monetization_on_rounded, Colors.green)),
          ],
        );
      },
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

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        _buildFullWidthButton(
          'Télécharger le Rapport d\'Inventaire (PDF)', 
          Icons.picture_as_pdf_rounded, 
          Colors.red, 
          () => _generatePdfReport(context),
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

  void _generatePdfReport(BuildContext context) async {
    final productBloc = context.read<ProductBloc>();
    final shopBloc = context.read<ShopBloc>();
    
    if (productBloc.state.products.isEmpty) return;

    String shopName = 'Don Shop';
    String currency = 'FCFA';
    
    if (shopBloc.state is ShopLoaded) {
      final shop = (shopBloc.state as ShopLoaded).shop;
      shopName = shop.name;
      currency = shop.currency;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Génération du rapport en cours...')));

    try {
      final file = await PdfHelper.generateInventoryReport(
        shopName: shopName,
        products: productBloc.state.products,
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
