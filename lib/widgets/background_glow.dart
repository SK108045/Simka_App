import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BackgroundGlow extends StatelessWidget {
  final Widget child;

  const BackgroundGlow({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Mesmerizing Background Glows ──────────────────────────
        Positioned(
          top: -150,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.fireRed.withValues(alpha: 0.15),
            ),
          ),
        ),
        Positioned(
          top: 200,
          right: -200,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.emberOrange.withValues(alpha: 0.12),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(color: Colors.transparent),
          ),
        ),
        // ── Main Content ──────────────────────────────────────────
        child,
      ],
    );
  }
}
