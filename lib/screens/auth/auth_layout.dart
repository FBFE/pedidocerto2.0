import 'dart:ui';
import 'package:flutter/material.dart';

/// Fundo azul com padrão de rede/constelação e card branco central (estilo da tela de login).
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    this.cardWidth = 420,
    this.cardMaxWidth = 420,
  });

  final Widget child;
  final double cardWidth;
  final double cardMaxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(context),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardMaxWidth),
                child: _buildCard(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A73E8), // Primary Blue (Style Guide)
            Color(0xFF0D47A1),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _NetworkPatternPainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          width: cardWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Cabeçalho do card: logo à esquerda e padrão geométrico à direita.
class AuthCardHeader extends StatelessWidget {
  const AuthCardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFC1121F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'C',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pedido Certo 2.0',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0xFF415A77).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xFF415A77).withValues(alpha: 0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    final points = <Offset>[];
    for (var x = 0.0; x < size.width + spacing; x += spacing) {
      for (var y = 0.0; y < size.height + spacing; y += spacing) {
        points.add(Offset(x, y));
      }
    }

    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        if ((points[i] - points[j]).distance < spacing * 1.8) {
          canvas.drawLine(points[i], points[j], linePaint);
        }
      }
    }
    for (final p in points) {
      canvas.drawCircle(p, 2, dotPaint);
    }

    final glowPaint = Paint()
      ..color = const Color(0xFF778DA9).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 30; i++) {
      final x = (i * 137.5) % (size.width + 50) - 25;
      final y = (i * 89.3) % (size.height + 50) - 25;
      canvas.drawCircle(Offset(x, y), 3, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
