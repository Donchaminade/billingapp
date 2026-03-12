import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_logo.dart';
import '../bloc/billing_bloc.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/history_bloc.dart';
import 'package:billing_app/features/billing/domain/entities/sale.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(context),
                  const SizedBox(height: 32),
                  _buildQuickActions(context),
                  const SizedBox(height: 32),
                  _buildRecentSalesHeader(context),
                  const SizedBox(height: 16),
                  _buildRecentSalesList(context),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Row(
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 12),
            Text(
              'Don Shop',
              style: GoogleFonts.outfit(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.black),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, shopState) {
        String currency = 'FCFA ';
        if (shopState is ShopLoaded) {
          currency = shopState.shop.currency;
        }
        return BlocBuilder<BillingBloc, BillingState>(
          builder: (context, state) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ventes du jour',
                        style: GoogleFonts.ibmPlexSans(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$currency  ${state.totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildMiniStat('Nombre d\'articles', '${state.cartItems.length}'),
                      const SizedBox(width: 40),
                      _buildMiniStat('Transactions', '0'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ibmPlexSans(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(context, Icons.add_rounded, 'Nouveau Produit', AppTheme.primaryColor, '/products/add'),
            _buildActionItem(context, Icons.qr_code_scanner_rounded, 'Vente Rapide', AppTheme.secondaryColor, '/scanner?mode=sale'),
            _buildActionItem(context, Icons.receipt_long_rounded, 'Facture', AppTheme.accentColor, '/checkout'),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String label, Color color, String route) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSalesHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Ventes récentes',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () => context.push('/history'),
          child: Text(
            'Voir tout',
            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSalesList(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state.allSales.isEmpty) {
            return _buildEmptySalesState();
          }

          final recentSales = state.allSales.take(5).toList();

          return Column(
            children: recentSales.map((sale) => _buildRecentSaleItem(context, sale)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildRecentSaleItem(BuildContext context, Sale sale) {
    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, shopState) {
        String currency = 'FCFA';
        if (shopState is ShopLoaded) {
          currency = shopState.shop.currency;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_rounded, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vente #${sale.id.substring(0, 5)}',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      DateFormat('dd MMM, HH:mm').format(sale.dateTime),
                      style: GoogleFonts.ibmPlexSans(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '$currency ${sale.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptySalesState() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(Icons.receipt_rounded, size: 48, color: Colors.grey[200]),
        const SizedBox(height: 12),
        Text(
          'Aucune vente encore',
          style: GoogleFonts.ibmPlexSans(color: Colors.grey[400], fontSize: 13),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
