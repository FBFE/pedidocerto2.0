import 'package:flutter/material.dart';

/// Largura máxima (usado apenas quando [expandFullWidth] é false).
const kContentMaxWidth = 1200.0;

/// Padding horizontal padrão do conteúdo.
const kContentPadding = 24.0;

/// Envolve o conteúdo com padding. Por padrão usa toda a largura da página (expandFullWidth: true).
/// Se [expandFullWidth] for false, limita a [maxWidth] e centraliza.
class ConstrainedContent extends StatelessWidget {
  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: kContentPadding),
    this.expandFullWidth = true,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  /// Quando true, o conteúdo ocupa toda a largura disponível (tela cheia).
  final bool expandFullWidth;

  @override
  Widget build(BuildContext context) {
    final padded = Padding(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: kContentPadding),
      child: child,
    );
    if (expandFullWidth) {
      return padded;
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padded,
      ),
    );
  }
}
