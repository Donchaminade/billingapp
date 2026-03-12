import 'package:go_router/go_router.dart';
import '../../features/billing/presentation/pages/home_page.dart';
import '../../features/product/presentation/pages/product_list_page.dart';
import '../../features/product/presentation/pages/add_product_page.dart';
import '../../features/product/presentation/pages/edit_product_page.dart';
import '../../features/shop/presentation/pages/shop_details_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/billing/presentation/pages/scanner_page.dart';
import '../../features/billing/presentation/pages/checkout_page.dart';
import '../../features/product/domain/entities/product.dart';

import '../../features/billing/presentation/pages/history_page.dart';
import '../../features/billing/presentation/pages/manual_sale_page.dart';
import '../../features/product/presentation/pages/stock_movement_page.dart';
import '../../features/product/presentation/pages/reports_page.dart';
import '../../core/widgets/main_navigation_wrapper.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/splash_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainNavigationWrapper(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductListPage(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddProductPage(),
            ),
            GoRoute(
              path: 'edit/:id',
              builder: (context, state) {
                final product = state.extra as Product?;
                if (product == null) {
                  return const ProductListPage();
                }
                return EditProductPage(product: product);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryPage(),
        ),
        GoRoute(
          path: '/shop',
          builder: (context, state) => const ShopDetailsPage(),
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/scanner',
      builder: (context, state) {
        final isSaleMode = state.uri.queryParameters['mode'] == 'sale';
        return ScannerPage(isSaleMode: isSaleMode);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/checkout',
      builder: (context, state) => const CheckoutPage(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/manual-sale',
      builder: (context, state) => const ManualSalePage(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/stock-movement',
      builder: (context, state) => const StockMovementPage(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/reports',
      builder: (context, state) => const ReportsPage(),
    ),
  ],
);
