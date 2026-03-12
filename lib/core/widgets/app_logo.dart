import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showText = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: (color ?? const Color(0xFF6C63FF)).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.25),
            child: Image.asset(
              'assets/icons/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            'Don Shop',
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.w900,
              color: color ?? const Color(0xFF6C63FF),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}
