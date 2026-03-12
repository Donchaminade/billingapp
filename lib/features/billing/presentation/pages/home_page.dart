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
import 'package:billing_app/features/product/presentation/bloc/product_bloc.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  final PageController _pageController = PageController();
  int _currentStatsPage = 0;

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

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
        String currency = 'FCFA';
        if (shopState is ShopLoaded) {
          currency = shopState.shop.currency;
        }

        return BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, historyState) {
            return BlocBuilder<ProductBloc, ProductState>(
              builder: (context, productState) {
                // CALCULS RÉELS
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final sevenDaysAgo = today.subtract(const Duration(days: 7));

                // 1. Ventes du jour
                final salesToday = historyState.allSales.where((s) => s.dateTime.isAfter(today)).toList();
                final totalToday = salesToday.fold(0.0, (sum, s) => sum + s.totalAmount);
                final countToday = salesToday.length;

                // 2. Performance Hebdomadaire
                final salesWeek = historyState.allSales.where((s) => s.dateTime.isAfter(sevenDaysAgo)).toList();
                final totalWeek = salesWeek.fold(0.0, (sum, s) => sum + s.totalAmount);

                // 3. Valeur de l'Inventaire
                final totalStockValue = productState.products.fold(0.0, (sum, p) => sum + (p.price * p.stock));
                final totalProducts = productState.products.length;

                // 4. Stock Bas
                final lowStockCount = productState.products.where((p) => p.stock < 5).length;

                return Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() => _currentStatsPage = index),
                        children: [
                          _buildStatSlide(
                            'Ventes du jour',
                            '$currency ${totalToday.toStringAsFixed(0)}',
                            'Nombre de ventes: $countToday',
                            Icons.today_rounded,
                            AppTheme.primaryGradient,
                          ),
                          _buildStatSlide(
                            'Performance Hebdo',
                            '$currency ${totalWeek.toStringAsFixed(0)}',
                            'Derniers 7 jours',
                            Icons.bar_chart_rounded,
                            const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
                          ),
                          _buildStatSlide(
                            'Valeur de l\'Inventaire',
                            '$currency ${totalStockValue.toStringAsFixed(0)}',
                            '$totalProducts produits en stock',
                            Icons.inventory_2_rounded,
                            const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF3B82F6)]),
                          ),
                          _buildStatSlide(
                            'Alertes Stock Bas',
                            '$lowStockCount Articles',
                            'Nécessitent une recharge',
                            Icons.warning_amber_rounded,
                            const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) => _buildIndicator(index == _currentStatsPage)),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatSlide(String title, String value, String subValue, IconData icon, Gradient gradient) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                title,
                style: GoogleFonts.ibmPlexSans(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: Colors.white, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            subValue,
            style: GoogleFonts.ibmPlexSans(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryColor : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
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
        // Bouton VENDRE Mis en évidence
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: _pulseController.value * 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: ElevatedButton.icon(
            onPressed: () => context.push('/manual-sale'),
            icon: const Icon(Icons.shopping_basket_rounded, size: 28),
            label: Text(
              'VENDRE MAINTENANT',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Autres boutons en grille
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(context, Icons.inventory_rounded, 'STOCK', AppTheme.secondaryColor, '/stock-movement'),
            _buildActionItem(context, Icons.analytics_rounded, 'RAPPORT', AppTheme.accentColor, '/reports'),
            _buildActionItem(context, Icons.add_rounded, 'PRODUIT', AppTheme.primaryColor, '/products/add'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(context, Icons.qr_code_scanner_rounded, 'SCANNER', Colors.orange, '/scanner?mode=sale'),
            _buildActionItem(context, Icons.receipt_long_rounded, 'FACTURE', Colors.teal, '/checkout'),
            _buildActionItem(context, Icons.settings_rounded, 'RÉGLAGES', Colors.blueGrey, '/settings'),
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
