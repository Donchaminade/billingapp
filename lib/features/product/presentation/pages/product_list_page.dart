import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/product_bloc.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/utils/data_transfer_helper.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _scanQR(List<Product> products) async {
    final barcode = await context.push<String>('/scanner');
    if (barcode != null && barcode.isNotEmpty) {
      final matchedProduct =
          products.where((p) => p.barcode == barcode).firstOrNull;
      if (matchedProduct != null) {
        _searchController.text = matchedProduct.name;
      } else {
        _searchController.text =
            barcode; // If not found, just put barcode in search
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.grey[100]!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text('Gestion des Produits',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              return PopupMenuButton<String>(
                onSelected: (value) => _handleDataAction(value, state.products),
                icon: const Icon(Icons.more_vert_rounded),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'import',
                    child: ListTile(
                      leading: Icon(Icons.download_rounded, color: Colors.blue),
                      title: Text('Importer (Excel/CSV/SQL)'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'export_excel',
                    child: ListTile(
                      leading: Icon(Icons.table_view_rounded, color: Colors.green),
                      title: Text('Exporter Excel'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_csv',
                    child: ListTile(
                      leading: Icon(Icons.article_rounded, color: Colors.orange),
                      title: Text('Exporter CSV'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_sql',
                    child: ListTile(
                      leading: Icon(Icons.storage_rounded, color: Colors.purple),
                      title: Text('Exporter SQL'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<ShopBloc, ShopState>(
        builder: (context, shopState) {
          String currency = 'FCFA';
          if (shopState is ShopLoaded) {
            currency = shopState.shop.currency;
          }
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: BlocBuilder<ProductBloc, ProductState>(
                    builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _searchController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: 'Scan or enter barcode',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey[400],
                                ),
                              ),
                              validator:
                                  AppValidators.required('Please enter a barcode'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.qr_code_scanner,
                                  color: AppTheme.primaryColor),
                              onPressed: () => _scanQR(state.products),
                              padding: const EdgeInsets.all(15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text('Tap the icon to open camera scanner',
                          style: TextStyle(fontSize: 12, color: Color(0xFF4C669A))),
                    ],
                  );
                }),
              ),

              Expanded(
                child: BlocConsumer<ProductBloc, ProductState>(
                  listener: (context, state) {
                    if (state.status == ProductStatus.success &&
                        state.message != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(state.message!),
                            backgroundColor: Colors.green),
                      );
                    } else if (state.status == ProductStatus.error &&
                        state.message != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(state.message!),
                            backgroundColor: Colors.red),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state.status == ProductStatus.loading &&
                        state.products.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.products.isEmpty) {
                      if (state.status == ProductStatus.error) {
                        return Center(child: Text('Error: ${state.message}'));
                      }
                      return const Center(
                          child: Text('No products found. Add some!'));
                    }

                    final filteredProducts = state.products
                        .where((product) =>
                            product.name.toLowerCase().contains(_searchQuery) ||
                            product.barcode.toLowerCase().contains(_searchQuery))
                        .toList();

                    if (filteredProducts.isEmpty) {
                      return const Center(
                          child: Text('No products match your search.'));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 8, bottom: 100),
                      itemCount: filteredProducts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2))
                            ],
                          ),
                          child: InkWell(
                            onTap: () => _showProductDetails(context, product, currency),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$currency${product.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (product.stock < 5)
                                                ? Colors.red.withValues(alpha: 0.1)
                                                : Colors.green
                                                    .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Stock: ${product.stock}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: (product.stock < 5)
                                                  ? Colors.red
                                                  : Colors.green[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.edit_rounded,
                                              color: AppTheme.primaryColor,
                                              size: 20),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                          onPressed: () {
                                            context.push(
                                                '/products/edit/${product.id}',
                                                extra: product);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.red,
                                              size: 20),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                          onPressed: () =>
                                              _confirmDelete(context, product),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/products/add'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (innerContext) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete ${product.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(innerContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<ProductBloc>().add(DeleteProduct(product.id));
                Navigator.pop(innerContext);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _handleDataAction(String action, List<Product> currentProducts) async {
    switch (action) {
      case 'import':
        final products = await DataTransferHelper.importFromFiles();
        if (products != null && products.isNotEmpty) {
          if (mounted) {
            context.read<ProductBloc>().add(BulkAddProducts(products));
          }
        }
        break;
      case 'export_excel':
        await DataTransferHelper.exportToExcel(currentProducts);
        break;
      case 'export_csv':
        await DataTransferHelper.exportToCSV(currentProducts);
        break;
      case 'export_sql':
        await DataTransferHelper.exportToSQL(currentProducts);
        break;
    }
  }

  void _showProductDetails(BuildContext context, Product product, String currency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('Détails du Produit', 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _detailRow(Icons.label_outline_rounded, 'Nom', product.name),
                  const SizedBox(height: 16),
                  _detailRow(Icons.qr_code_2_rounded, 'Code Barre', product.barcode),
                  const SizedBox(height: 16),
                  _detailRow(Icons.payments_outlined, 'Prix', '$currency${product.price.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  _detailRow(
                    Icons.inventory_2_outlined, 
                    'Stock Actuel', 
                    '${product.stock} unités',
                    valueColor: (product.stock < 5) ? Colors.red : Colors.green[700],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/products/edit/${product.id}', extra: product);
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Modifier'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              Text(value, style: TextStyle(
                fontSize: 15, 
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87,
              )),
            ],
          ),
        ),
      ],
    );
  }
}
