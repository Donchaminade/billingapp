import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../bloc/billing_bloc.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/cart_item.dart';
import 'package:google_fonts/google_fonts.dart';

class ScannerPage extends StatefulWidget {
  final bool isSaleMode;

  const ScannerPage({
    super.key, 
    this.isSaleMode = false,
  });

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    returnImage: false,
    autoStart: false,
  );

  final Map<String, DateTime> _lastScanTimes = {};
  String? _lastScannedName;
  double? _lastScannedPrice;
  bool _showPopup = false;
  bool _isScanned = false;
  String? _lastScannedBarcode;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    if (widget.isSaleMode) {
      context.read<BillingBloc>().add(ClearCartEvent());
    }
    _initScanner();
  }

  Future<void> _initScanner() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _hasPermission = status.isGranted;
        _isCheckingPermission = false;
      });
      if (_hasPermission) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) controller.start();
        });
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!widget.isSaleMode && _isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    final now = DateTime.now();

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final rawValue = barcode.rawValue!;

        if (widget.isSaleMode) {
          if (_lastScanTimes.containsKey(rawValue)) {
            final lastScan = _lastScanTimes[rawValue]!;
            if (now.difference(lastScan).inSeconds < 2) {
              continue;
            }
          }
          _lastScanTimes[rawValue] = now;
          _lastScannedBarcode = rawValue;

          _vibrate();

          if (mounted) {
            context.read<BillingBloc>().add(ScanBarcodeEvent(rawValue));
          }
        } else {
          _isScanned = true;
          _vibrate();
          if (mounted) {
            if (context.canPop()) {
              context.pop(rawValue);
            } else {
              context.go('/');
            }
          }
        }
        break;
      }
    }
  }

  Future<void> _vibrate() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          widget.isSaleMode ? 'Scanner pour vendre' : 'Scanner un code',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off_rounded, color: Colors.white);
                  case TorchState.on:
                    return const Icon(Icons.flash_on_rounded, color: Color(0xFFFFD700));
                  default:
                    return const Icon(Icons.flash_off_rounded, color: Colors.white);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: BlocListener<BillingBloc, BillingState>(
        listenWhen: (prev, curr) => 
          widget.isSaleMode && (prev.cartItems != curr.cartItems || prev.error != curr.error),
        listener: (context, state) {
          if (state.error != null) {
            _vibrate(); // Vibrate on error too for tactile feedback
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.error!, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 310), // Show above the cart panel
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (_lastScannedBarcode != null) {
            final item = state.cartItems.where((i) => i.product.barcode == _lastScannedBarcode).firstOrNull;
            if (item != null) {
              setState(() {
                _lastScannedName = item.product.name;
                _lastScannedPrice = item.product.price;
                _showPopup = true;
              });
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _showPopup = false);
              });
            }
          }
        },
        child: Stack(
          children: [
            if (_isCheckingPermission)
               const Center(child: CircularProgressIndicator(color: Colors.white))
            else if (!_hasPermission)
              _buildNoPermissionUI()
            else
              MobileScanner(
                controller: controller,
                onDetect: _onDetect,
                errorBuilder: (context, error, child) {
                  return _buildErrorUI(error);
                },
              ),
            
            // Overlay de ciblage décalé vers le haut pour laisser de la place au panier
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15,
              left: (MediaQuery.of(context).size.width - 260) / 2,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Stack(
                  children: [
                    _buildCorner(Alignment.topLeft),
                    _buildCorner(Alignment.topRight),
                    _buildCorner(Alignment.bottomLeft),
                    _buildCorner(Alignment.bottomRight),
                  ],
                ),
              ),
            ),

            // Pop-up Feedback (Animated on Scan)
            if (widget.isSaleMode)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                bottom: _showPopup ? 300 : -100, // Even higher to be safe
                left: 20,
                right: 20,
                child: _buildFeedbackPopup(),
              ),

            // Cart Summary Panel (Permanent in Sale Mode)
            if (widget.isSaleMode)
              _buildCartPanel(),
            
            // Instructions
            if (!widget.isSaleMode)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Alignez le code-barres',
                      style: GoogleFonts.ibmPlexSans(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPanel() {
    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, shopState) {
        String currency = 'FCFA';
        if (shopState is ShopLoaded) {
          currency = shopState.shop.currency;
        }
        return BlocBuilder<BillingBloc, BillingState>(
          builder: (context, state) {
            return DraggableScrollableSheet(
              initialChildSize: 0.5, // 50% de l'écran par défaut
              minChildSize: 0.3, 
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(color: Colors.black38, blurRadius: 25, offset: Offset(0, -5))
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Panier',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                Text(
                                  '${state.cartItems.length} articles',
                                  style: GoogleFonts.ibmPlexSans(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                            Text(
                              'Total: $currency${state.totalAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold, 
                                fontSize: 20, 
                                color: AppTheme.primaryColor
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 24, indent: 20, endIndent: 20),
                      Expanded(
                        child: state.cartItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shopping_basket_outlined, color: Colors.grey[200], size: 30),
                                const SizedBox(height: 4),
                                Text('Panier vide', style: TextStyle(color: Colors.grey[300], fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.cartItems.length,
                            itemBuilder: (context, index) {
                              final item = state.cartItems[index];
                              return _buildCartItem(item, currency);
                            },
                          ),
                      ),
                      _buildFinishButton(state, currency),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCartItem(CartItem item, String currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.02)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('$currency${item.product.price.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 2)],
            ),
            child: Row(
              children: [
                _buildQtyBtn(Icons.remove, () {
                  context.read<BillingBloc>().add(UpdateQuantityEvent(item.product.id, item.quantity - 1));
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                _buildQtyBtn(Icons.add, () {
                  context.read<BillingBloc>().add(UpdateQuantityEvent(item.product.id, item.quantity + 1));
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 14, color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildFinishButton(BillingState state, String currency) {
    bool isEmpty = state.cartItems.isEmpty;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 15 + (bottomPadding > 0 ? bottomPadding : 5)),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: ElevatedButton(
        onPressed: isEmpty ? null : () => context.push('/checkout'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52), // Réduit de 58 à 52
          backgroundColor: isEmpty ? Colors.grey[100] : AppTheme.primaryColor,
          elevation: isEmpty ? 0 : 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 20, color: isEmpty ? Colors.grey[300] : Colors.white),
            const SizedBox(width: 10),
            Text(
              'Terminer la vente - $currency${state.totalAmount.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 14, color: isEmpty ? Colors.grey[400] : Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPermissionUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 80, color: Colors.white24),
            const SizedBox(height: 24),
            Text(
              'Accès caméra requis', 
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 12),
            Text(
              'Nous avons besoin de votre caméra pour scanner les produits.', 
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(color: Colors.white60)
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _initScanner, 
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              child: const Text('Autoriser l\'accès')
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorUI(MobileScannerException error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
           const SizedBox(height: 16),
           Text('Erreur: ${error.errorCode}', style: const TextStyle(color: Colors.white70)),
           const SizedBox(height: 8),
           ElevatedButton(onPressed: () => controller.start(), child: const Text('Réessayer')),
        ],
      ),
    );
  }

  Widget _buildFeedbackPopup() {
    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, shopState) {
        String currency = 'FCFA';
        if (shopState is ShopLoaded) {
          currency = shopState.shop.currency;
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25), 
                blurRadius: 15, 
                offset: const Offset(0, 8)
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _lastScannedName ?? 'Produit', 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    Text(
                      '$currency${_lastScannedPrice?.toStringAsFixed(0)} - Ajouté au panier', 
                      style: GoogleFonts.ibmPlexSans(fontSize: 12, color: Colors.grey[600])
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCorner(Alignment alignment) {
    final bool isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final bool isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Align(
      alignment: alignment,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: Colors.white, width: 5) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: Colors.white, width: 5) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Colors.white, width: 5) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: Colors.white, width: 5) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
