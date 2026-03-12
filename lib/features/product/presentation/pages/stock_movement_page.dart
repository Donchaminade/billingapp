import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:billing_app/features/product/presentation/bloc/product_bloc.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/core/theme/app_theme.dart';

class StockMovementPage extends StatefulWidget {
  final bool showLowStockOnly;
  const StockMovementPage({super.key, this.showLowStockOnly = false});

  @override
  State<StockMovementPage> createState() => _StockMovementPageState();
}

class _StockMovementPageState extends State<StockMovementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late bool _showOnlyLowStock;

  @override
  void initState() {
    super.initState();
    _showOnlyLowStock = widget.showLowStockOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mouvement de Stock', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un produit...',
                      prefixIcon: Icon(Icons.inventory_2_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Stock Bas'),
                  selected: _showOnlyLowStock,
                  onSelected: (v) => setState(() => _showOnlyLowStock = v),
                  selectedColor: Colors.red[100],
                  checkmarkColor: Colors.red,
                  labelStyle: TextStyle(
                    color: _showOnlyLowStock ? Colors.red : Colors.black87,
                    fontWeight: _showOnlyLowStock ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                final filtered = state.products.where((p) {
                  final matchesSearch = p.name.toLowerCase().contains(_searchQuery) || p.barcode.contains(_searchQuery);
                  final matchesStock = !_showOnlyLowStock || p.stock < 5;
                  return matchesSearch && matchesStock;
                }).toList();

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return _buildProductStockCard(context, product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductStockCard(BuildContext context, Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Stock actuel: ${product.stock}', style: TextStyle(color: product.stock < 5 ? Colors.red : Colors.grey)),
        trailing: ElevatedButton(
          onPressed: () => _showAddStockDialog(context, product),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            foregroundColor: AppTheme.primaryColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('AJOUTER'),
        ),
      ),
    );
  }

  void _showAddStockDialog(BuildContext context, Product product) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Ajouter du stock - ${product.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock actuel : ${product.stock}'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Quantité à ajouter',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ANNULER')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                final updated = Product(
                  id: product.id,
                  name: product.name,
                  barcode: product.barcode,
                  price: product.price,
                  stock: product.stock + val,
                );
                context.read<ProductBloc>().add(UpdateProduct(updated));
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Stock mis à jour : ${product.stock + val}')),
                );
              }
            },
            child: const Text('CONFIRMER'),
          ),
        ],
      ),
    );
  }
}
