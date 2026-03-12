import 'package:billing_app/core/widgets/input_label.dart';
import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/product_bloc.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _barcode;
  late double _price;
  late int _stock;

  @override
  void initState() {
    super.initState();
    _name = widget.product.name;
    _barcode = widget.product.barcode;
    _price = widget.product.price;
    _stock = widget.product.stock;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Uniqueness check for barcode (only if not empty and changed)
      if (_barcode.isNotEmpty && _barcode != widget.product.barcode) {
        final productState = context.read<ProductBloc>().state;
        final existingProduct = productState.products.where((p) => p.barcode == _barcode && p.id != widget.product.id).firstOrNull;

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

      final updatedProduct = Product(
        id: widget.product.id,
        name: _name,
        barcode: _barcode,
        price: _price,
        stock: _stock,
      );

      context.read<ProductBloc>().add(UpdateProduct(updatedProduct));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 32, color: Theme.of(context).primaryColor),
            onPressed: () => context.pop(),
          ),
          title: const Text('Modifier le Produit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const InputLabel(text: 'Code-barres (Optionnel)'),
                  TextFormField(
                    initialValue: _barcode,
                    decoration: const InputDecoration(
                      hintText: 'Scanner ou saisir le code-barres',
                    ),
                    onSaved: (value) => _barcode = value ?? '',
                  ),
                  const SizedBox(height: 24),

                  const InputLabel(text: 'Nom du Produit'),

                  TextFormField(
                    initialValue: _name,
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
                        initialValue: _price.toStringAsFixed(0),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          prefixText: '$currency ',
                          prefixStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                        validator: AppValidators.price,
                        onSaved: (value) => _price = double.parse(value!),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const InputLabel(text: 'Quantité en Stock'),
                  TextFormField(
                    initialValue: _stock.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0',
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer une quantité' : null,
                    onSaved: (value) => _stock = int.tryParse(value!) ?? 0,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    onPressed: _submit,
                    icon: Icons.save,
                    label: 'Enregistrer les modifications',
                  ),
                  const SizedBox(height: 80), // Extra space for the notch
                ],
              ),
            ),
          ),
        ),
      );
  }
}
