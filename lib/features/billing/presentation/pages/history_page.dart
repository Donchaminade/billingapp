import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/history_bloc.dart';
import 'package:billing_app/features/billing/domain/entities/sale.dart';
import '../../../../core/utils/printer_helper.dart';
import '../../../../core/utils/pdf_helper.dart';
import '../../../../core/utils/whatsapp_helper.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(LoadHistoryEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _buildSearchBar(),
          ),
          BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state.status == HistoryStatus.loading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state.filteredSales.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sale = state.filteredSales[index];
                      return _buildSaleCard(sale);
                    },
                    childCount: state.filteredSales.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(
          'Historique',
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            context.read<HistoryBloc>().add(SearchHistoryEvent(value));
          },
          decoration: InputDecoration(
            hintText: 'Rechercher un produit ou ID...',
            hintStyle: GoogleFonts.ibmPlexSans(color: Colors.grey[400], fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, shopState) {
        String currency = 'FCFA';
        if (shopState is ShopLoaded) {
          currency = shopState.shop.currency;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _showSaleDetails(sale, currency),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.receipt_rounded, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vente #${sale.id.substring(0, 8)}',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          DateFormat('dd MMM, kk:mm').format(sale.dateTime),
                          style: GoogleFonts.ibmPlexSans(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currency ${sale.totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        '${sale.items.length} articles',
                        style: GoogleFonts.ibmPlexSans(color: Colors.grey, fontSize: 11),
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
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            'Aucun historique trouvé',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  void _showSaleDetails(Sale sale, String currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailsSheet(sale, currency),
    );
  }

  Widget _buildDetailsSheet(Sale sale, String currency) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Détails de la vente', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text('#${sale.id}', style: GoogleFonts.ibmPlexSans(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showWhatsappDialog(sale, currency),
                      icon: const Icon(Icons.share_rounded, color: Colors.green),
                      tooltip: 'Partager via WhatsApp',
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(DateFormat('dd MMMM yyyy, HH:mm').format(sale.dateTime), style: GoogleFonts.ibmPlexSans(color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Articles', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...sale.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600)),
                            Text('${item.quantity} x $currency ${item.price.toStringAsFixed(0)}',
                                style: GoogleFonts.ibmPlexSans(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text('$currency ${item.total.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
                const Divider(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('$currency ${sale.totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteSale(sale),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Supprimer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reprintReceipt(sale, currency),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Réimprimer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteSale(Sale sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la vente'),
        content: const Text('Voulez-vous vraiment supprimer cette transaction de l\'historique ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              context.read<HistoryBloc>().add(DeleteSaleEvent(sale.id));
              Navigator.pop(ctx);
              Navigator.pop(context); // Close details sheet
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _reprintReceipt(Sale sale, String currency) async {
    final shopState = context.read<ShopBloc>().state;
    if (shopState is! ShopLoaded) return;

    final printerHelper = PrinterHelper();
    
    if (!printerHelper.isConnected) {
       // Logic to auto-reconnect if needed, similar to BillingBloc
       // For brevity using simple check
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imprimante non connectée')));
       return;
    }

    try {
      final items = sale.items.map((item) => {
        'name': item.productName,
        'qty': item.quantity,
        'price': item.price,
        'total': item.total,
      }).toList();

      await printerHelper.printReceipt(
        shopName: shopState.shop.name,
        address1: shopState.shop.addressLine1,
        address2: shopState.shop.addressLine2,
        phone: shopState.shop.phoneNumber,
        items: items,
        total: sale.totalAmount,
        footer: shopState.shop.footerText,
        dateTime: sale.dateTime,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reçu réimprimé !'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        _showNoPrinterDialog(sale, currency);
      }
    }
  }

  void _showNoPrinterDialog(Sale sale, String currency) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.print_disabled_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(child: Text('Imprimante déconnectée')),
          ],
        ),
        content: const Text(
          'Voulez-vous générer une facture PDF et l\'envoyer par WhatsApp ?',
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
              _showWhatsappDialog(sale, currency);
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

  void _showWhatsappDialog(Sale sale, String currency) {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    final shopState = context.read<ShopBloc>().state;
    
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
              
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Génération du reçu PDF...'), duration: Duration(seconds: 1)),
              );

              try {
                final items = sale.items.map((item) => {
                  'name': item.productName,
                  'qty': item.quantity,
                  'price': item.price,
                  'total': item.total,
                }).toList();

                final file = await PdfHelper.generateReceipt(
                  shopName: shopState.shop.name,
                  address1: shopState.shop.addressLine1,
                  address2: shopState.shop.addressLine2,
                  phone: shopState.shop.phoneNumber,
                  items: items,
                  total: sale.totalAmount,
                  currency: currency,
                  footer: shopState.shop.footerText,
                  dateTime: sale.dateTime,
                );

                await WhatsappHelper.sendReceipt(
                  pdfFile: file,
                  phoneNumber: phone,
                  shopName: shopState.shop.name,
                  clientName: name,
                );
              } catch (e) {
                if (mounted) {
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
}
