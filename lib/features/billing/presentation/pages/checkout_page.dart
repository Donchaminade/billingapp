import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:billing_app/features/shop/presentation/bloc/shop_bloc.dart';
import 'package:billing_app/features/billing/presentation/bloc/billing_bloc.dart';
import 'package:billing_app/features/billing/presentation/bloc/history_bloc.dart';
import 'package:billing_app/features/billing/domain/entities/sale.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/presentation/bloc/product_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/printer_helper.dart';
import '../../../../core/utils/pdf_helper.dart';
import '../../../../core/utils/whatsapp_helper.dart';
import 'package:uuid/uuid.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isSaleSaved = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text('Revue de commande', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => _handleBack(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () => _showWhatsappDialog(context),
              tooltip: 'Partager via WhatsApp',
            ),
          ],
        ),
        body: BlocConsumer<BillingBloc, BillingState>(
          listener: (context, state) {
            if (state.printSuccess) {
              if (!_isSaleSaved) {
                 _saveToHistory(context, state);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reçu imprimé avec succès !'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              // Redirection vers l'historique
              Future.delayed(const Duration(seconds: 1), () {
                if (context.mounted) {
                  context.read<BillingBloc>().add(ClearCartEvent());
                  context.go('/history');
                }
              });
            }
          },
          builder: (context, billingState) {
            return BlocBuilder<ShopBloc, ShopState>(
              builder: (context, shopState) {
                String upiId = '';
                String shopName = 'Ma Boutique';
                String currency = ' FCFA';

                if (shopState is ShopLoaded) {
                  upiId = shopState.shop.upiId;
                  shopName = shopState.shop.name;
                  currency = shopState.shop.currency;
                }

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOrderCard(billingState, currency),
                            const SizedBox(height: 24),
                            if (upiId.isNotEmpty) _buildPaymentQR(upiId, shopName, billingState.totalAmount),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomBar(context, billingState, shopState),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
     // Retour à l'accueil et vidage du panier
     context.read<BillingBloc>().add(ClearCartEvent());
     context.go('/');
  }

  Widget _buildOrderCard(BillingState state, String currency) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Articles',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: AppTheme.backgroundColor.withValues(alpha: 0.5)),
                children: [
                  _headerCell('Produit'),
                  _headerCell('Qté'),
                  _headerCell('Total'),
                ],
              ),
              ...state.cartItems.map((item) => TableRow(
                children: [
                  _dataCell(item.product.name),
                  _dataCell('x${item.quantity}', align: TextAlign.center),
                  _dataCell('$currency${item.total.toStringAsFixed(0)}', align: TextAlign.right, isBold: true),
                ],
              )),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sous-total', style: GoogleFonts.ibmPlexSans(color: Colors.grey)),
                Text('$currency${state.totalAmount.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentQR(String upiId, String shopName, double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            'Scanner pour payer',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Paiement UPI (No Cash)',
            style: GoogleFonts.ibmPlexSans(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SizedBox(
              width: 180,
              height: 180,
              child: PrettyQrView.data(
                data: 'upi://pay?pa=$upiId&pn=$shopName&am=${amount.toStringAsFixed(2)}&cu=INR',
                decoration: PrettyQrDecoration(
                  image: PrettyQrDecorationImage(
                    image: AssetImage('assets/icons/logo.png'),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(upiId, style: GoogleFonts.ibmPlexSans(fontSize: 10, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, BillingState billingState, ShopState shopState) {
    String currency = 'FCFA';
    if (shopState is ShopLoaded) {
      currency = shopState.shop.currency;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              onPressed: () {
                if (shopState is ShopLoaded) {
                  final printer = PrinterHelper();
                  if (!printer.isConnected) {
                    _showNoPrinterDialog(context, shopState.shop, billingState, currency);
                  } else {
                    context.read<BillingBloc>().add(
                      PrintReceiptEvent(
                        shopName: shopState.shop.name,
                        address1: shopState.shop.addressLine1,
                        address2: shopState.shop.addressLine2,
                        phone: shopState.shop.phoneNumber,
                        footer: shopState.shop.footerText,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Détails de la boutique non chargés'), backgroundColor: Colors.red),
                  );
                }
              },
              label: 'Imprimer le Reçu',
              icon: Icons.print_rounded,
              isLoading: billingState.isPrinting,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _saveToHistory(context, billingState);
                context.read<BillingBloc>().add(ClearCartEvent());
                context.go('/');
              },
              child: Text(
                'Nouvelle Vente',
                style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveToHistory(BuildContext context, BillingState state) {
    if (state.cartItems.isEmpty || _isSaleSaved) return;

    final sale = Sale(
      id: Uuid().v4(),
      dateTime: DateTime.now(),
      items: state.cartItems.map((item) => SaleItem(
        productName: item.product.name,
        quantity: item.quantity,
        price: item.product.price,
        total: item.total,
      )).toList(),
      totalAmount: state.totalAmount,
    );

    context.read<HistoryBloc>().add(AddSaleToHistoryEvent(sale));

    // Décrémenter les stocks
    for (var item in state.cartItems) {
      final product = item.product;
      final updatedProduct = Product(
        id: product.id,
        name: product.name,
        barcode: product.barcode,
        price: product.price,
        stock: product.stock - item.quantity,
      );
      context.read<ProductBloc>().add(UpdateProduct(updatedProduct));
    }

    setState(() {
      _isSaleSaved = true;
    });
  }

  void _showNoPrinterDialog(BuildContext context, dynamic shop, BillingState state, String currency) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.print_disabled_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(child: Text('Imprimante non détectée')),
          ],
        ),
        content: const Text(
          'Voulez-vous générer une facture PDF et l\'envoyer par WhatsApp à votre client ?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showWhatsappDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Envoyer WhatsApp'),
          ),
        ],
      ),
    );
  }

  void _showWhatsappDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    final shopState = context.read<ShopBloc>().state;
    final billingState = context.read<BillingBloc>().state;
    
    if (shopState is! ShopLoaded) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Envoi WhatsApp', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Informations du client pour le reçu.', 
                style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Nom du client (Optionnel)',
                  prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Numéro WhatsApp (Ex: 228...)',
                  prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Colors.green),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              final name = nameController.text.trim();
              if (phone.isEmpty) return;
              
              Navigator.pop(ctx);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Génération du reçu PDF...'), duration: Duration(seconds: 1)),
              );

              try {
                String currency = shopState.shop.currency;

                final items = billingState.cartItems.map((item) => {
                  'name': item.product.name,
                  'qty': item.quantity,
                  'price': item.product.price,
                  'total': item.total,
                }).toList();

                final file = await PdfHelper.generateReceipt(
                  shopName: shopState.shop.name,
                  address1: shopState.shop.addressLine1,
                  address2: shopState.shop.addressLine2,
                  phone: shopState.shop.phoneNumber,
                  items: items,
                  total: billingState.totalAmount,
                  currency: currency,
                  footer: shopState.shop.footerText,
                );

                await WhatsappHelper.sendReceipt(
                  pdfFile: file,
                  phoneNumber: phone,
                  shopName: shopState.shop.name,
                  clientName: name,
                );

                if (!_isSaleSaved) {
                  _saveToHistory(context, billingState);
                }

                // Redirection vers l'historique après envoi
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reçu envoyé via WhatsApp !'), backgroundColor: Colors.green),
                  );
                  context.read<BillingBloc>().add(ClearCartEvent());
                  context.go('/history');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Envoyer le PDF'),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600])),
    );
  }

  Widget _dataCell(String text, {TextAlign align = TextAlign.left, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.ibmPlexSans(
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}
