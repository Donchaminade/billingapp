import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/product_bloc.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';
import '../../../../core/utils/data_transfer_helper.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _barcode = '';
  double _price = 0.0;
  int _stock = 0;

  void _scanBarcode() async {
    final result = await context.push<String>('/scanner');
    if (result != null && result.isNotEmpty) {
      setState(() {
        _barcode = result;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final productState = context.read<ProductBloc>().state;
      if (_barcode.isNotEmpty) {
        final existingProduct =
            productState.products.where((p) => p.barcode == _barcode).firstOrNull;

        if (existingProduct != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Un produit avec le code-barres "$_barcode" existe déjà !'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final product = Product(
        id: const Uuid().v4(),
        name: _name,
        barcode: _barcode,
        price: _price,
        stock: _stock,
      );

      context.read<ProductBloc>().add(AddProduct(product));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: Theme.of(context).primaryColor),
            onPressed: () => context.pop(),
          ),
          title: const Text('Ajouter un Produit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const InputLabel(text: 'Code-barres (Optionnel)'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(_barcode),
                          initialValue: _barcode,
                          decoration: const InputDecoration(
                            hintText: 'Scanner ou saisir le code-barres',
                          ),
                          onSaved: (value) => _barcode = value ?? '',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code_scanner,
                              color: AppTheme.primaryColor),
                          onPressed: _scanBarcode,
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Appuyez sur l\'icône pour ouvrir le scanner',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4C669A))),
                  const SizedBox(height: 24),
                  const InputLabel(text: 'Nom du Produit'),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'ex: Riz Basmati',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: AppValidators.required('Veuillez entrer un nom'),
                    onSaved: (value) => _name = value!,
                  ),
                  const SizedBox(height: 24),
                  const InputLabel(text: 'Prix'),
                  BlocBuilder<ShopBloc, ShopState>(
                    builder: (context, shopState) {
                      String currency = 'FCFA';
                      if (shopState is ShopLoaded) {
                        currency = shopState.shop.currency;
                      }
                      return TextFormField(
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixText: '$currency ',
                          prefixStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                        validator: AppValidators.price,
                        onSaved: (value) => _price = double.parse(value!),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const InputLabel(text: 'Quantité en Stock'),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0',
                    ),
                    initialValue: '0',
                    validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer une quantité' : null,
                    onSaved: (value) => _stock = int.tryParse(value!) ?? 0,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    onPressed: _submit,
                    icon: Icons.add_circle,
                    label: 'Ajouter le Produit',
                  ),
                  const SizedBox(height: 48),
                  Center(
                    child: Column(
                      children: [
                        Text('OU IMPORTER UN FICHIER', 
                          style: GoogleFonts.outfit(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.grey[400],
                            letterSpacing: 1.2,
                          )),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _importButton(
                              icon: Icons.table_view_rounded, 
                              label: 'Excel', 
                              color: Colors.green,
                              onTap: () => _handleImport('excel'),
                            ),
                            const SizedBox(width: 12),
                            _importButton(
                              icon: Icons.article_rounded, 
                              label: 'CSV', 
                              color: Colors.orange,
                              onTap: () => _handleImport('csv'),
                            ),
                            const SizedBox(width: 12),
                            _importButton(
                              icon: Icons.storage_rounded, 
                              label: 'SQL', 
                              color: Colors.purple,
                              onTap: () => _handleImport('sql'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _importButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _handleImport(String type) async {
    final products = await DataTransferHelper.importFromFiles();
    if (products != null && products.isNotEmpty) {
      if (mounted) {
        context.read<ProductBloc>().add(BulkAddProducts(products));
        context.pop();
      }
    }
  }
}
