import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainNavigationWrapper extends StatefulWidget {
  final Widget child;

  const MainNavigationWrapper({super.key, required this.child});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/history')) return 2;
    if (location.startsWith('/shop')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/products');
        break;
      case 2:
        context.go('/history');
        break;
      case 3:
        context.go('/shop');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: widget.child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/scanner?mode=sale'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        color: Colors.white,
        elevation: 20,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Left Side
              Row(
                children: [
                   _buildNavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Home',
                    isSelected: selectedIndex == 0,
                    onTap: () => _onItemTapped(0, context),
                  ),
                  _buildNavItem(
                    icon: Icons.inventory_2_rounded,
                    label: 'Produits',
                    isSelected: selectedIndex == 1,
                    onTap: () => _onItemTapped(1, context),
                  ),
                ],
              ),
              // Right Side
              Row(
                children: [
                  _buildNavItem(
                    icon: Icons.history_rounded,
                    label: 'Historique',
                    isSelected: selectedIndex == 2,
                    onTap: () => _onItemTapped(2, context),
                  ),
                  _buildNavItem(
                    icon: Icons.storefront_rounded,
                    label: 'Paramètre',
                    isSelected: selectedIndex == 3,
                    onTap: () => _onItemTapped(3, context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
