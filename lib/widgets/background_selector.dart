import 'package:flutter/material.dart';

/// Um item de plano de fundo: asset (path local) ou URL (rede).
class BackgroundItem {
  const BackgroundItem({
    required this.pathOrUrl,
    this.isAsset = true,
    this.label,
  });

  final String pathOrUrl;
  final bool isAsset;
  final String? label;
}

/// Seletor horizontal de planos de fundo (assets ou URLs).
/// Permite trocar o fundo da tela principal; a persistência fica a cargo do chamador.
class BackgroundSelector extends StatelessWidget {
  const BackgroundSelector({
    super.key,
    required this.onBackgroundSelected,
    required this.currentBackground,
    required this.backgrounds,
    this.title = 'Escolha o plano de fundo',
  });

  final void Function(String pathOrUrl) onBackgroundSelected;
  final String? currentBackground;
  final List<BackgroundItem> backgrounds;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: backgrounds.length,
            itemBuilder: (context, index) {
              final item = backgrounds[index];
              final path = item.pathOrUrl;
              final isSelected = path == currentBackground;

              return GestureDetector(
                onTap: () => onBackgroundSelected(path),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (path.isEmpty)
                        Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Center(
                            child: Text(
                              'Nenhum',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        )
                      else if (item.isAsset)
                        Image.asset(
                          path,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child:
                                const Icon(Icons.image_not_supported, size: 32),
                          ),
                        )
                      else
                        Image.network(
                          path,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: const Icon(Icons.broken_image, size: 32),
                          ),
                        ),
                      if (isSelected)
                        Container(
                          color: Colors.black.withValues(alpha: 0.35),
                          child: const Center(
                            child: Icon(Icons.check_circle,
                                color: Colors.white, size: 40),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
