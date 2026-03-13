import 'package:flutter/material.dart';

import '../theme/pedido_certo_theme.dart';

/// Item do menu lateral (label + ícone + ação).
class SidebarMenuItem {
  const SidebarMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
    this.visible = true,
  });

  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool visible;
}

/// Bloco de menu com título e itens (podendo ser expansível).
class SidebarMenuBlock {
  const SidebarMenuBlock({
    required this.title,
    required this.items,
    this.icon,
  });

  final String title;
  final List<SidebarMenuItem> items;
  final IconData? icon;
}

/// Menu lateral do administrador com blocos: Gestão de Pessoas, Processos, Administradores.
/// Suporta modo expandido (com labels) e recolhido (só ícones) para responsividade.
class AdminSidebarMenu extends StatelessWidget {
  const AdminSidebarMenu({
    super.key,
    required this.selectedId,
    required this.menuBlocks,
    required this.userName,
    required this.userEmail,
    required this.onConfiguracoesUsuario,
    required this.onSair,
    this.appTitle = 'Pedido Certo',
    this.expanded = true,
    this.onToggleExpand,
  });

  final String? selectedId;
  final List<SidebarMenuBlock> menuBlocks;
  final String userName;
  final String userEmail;
  final VoidCallback onConfiguracoesUsuario;
  final VoidCallback onSair;
  final String appTitle;
  /// true = menu largo com textos; false = menu estreito só com ícones.
  final bool expanded;
  /// Chamado ao tocar no botão expandir/recolher. Se null, o botão não é exibido.
  final VoidCallback? onToggleExpand;

  static const double sidebarWidth = 260;
  static const double sidebarWidthCollapsed = 56;

  double get width => expanded ? sidebarWidth : sidebarWidthCollapsed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        border: Border(
          right: BorderSide(color: PedidoCertoTheme.mediumGray.withValues(alpha: 0.3)),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Logo / Título + botão expandir-recolher
          Padding(
            padding: EdgeInsets.fromLTRB(expanded ? 20 : 5, 24, expanded ? 12 : 5, 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: expanded ? 40 : 20,
                  height: expanded ? 40 : 20,
                  decoration: BoxDecoration(
                    color: PedidoCertoTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      'PC',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: expanded ? 14 : 9,
                      ),
                    ),
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      appTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onToggleExpand != null)
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white70),
                      onPressed: onToggleExpand,
                      tooltip: 'Recolher menu',
                    ),
                ] else ...[
                  const SizedBox(width: 4),
                  if (onToggleExpand != null)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      icon: const Icon(Icons.menu, color: Colors.white70, size: 18),
                      onPressed: onToggleExpand,
                      tooltip: 'Expandir menu',
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          // Blocos de menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: expanded ? 0 : 5),
              children: [
                for (final block in menuBlocks) ...[
                  if (expanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        block.title.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ...block.items.where((e) => e.visible).map((item) {
                    final isSelected = selectedId == item.id;
                    final row = Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: item.onTap,
                        child: Container(
                          color: isSelected
                              ? PedidoCertoTheme.primaryBlue.withValues(alpha: 0.2)
                              : null,
                          padding: EdgeInsets.symmetric(
                            horizontal: expanded ? 16 : 6,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                            mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: isSelected
                                    ? PedidoCertoTheme.primaryBlue
                                    : Colors.white70,
                              ),
                              if (expanded) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                    return expanded
                        ? row
                        : Tooltip(message: item.label, child: row);
                  }),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          // Rodapé: Configuração do usuário + Sair
          Padding(
            padding: EdgeInsets.all(expanded ? 16 : 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (context) {
                    final configRow = Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onConfiguracoesUsuario,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: expanded ? 12 : 5,
                          ),
                          child: Row(
                            mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: expanded ? 18 : 14,
                                backgroundColor: PedidoCertoTheme.primaryBlue.withValues(alpha: 0.3),
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: expanded ? 16 : 12,
                                  ),
                                ),
                              ),
                              if (expanded) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Configuração do usuário',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.settings_outlined,
                                  size: 20,
                                  color: Colors.white70,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                    return expanded
                        ? configRow
                        : Tooltip(message: 'Configuração do usuário', child: configRow);
                  },
                ),
                const SizedBox(height: 8),
                if (expanded)
                  OutlinedButton.icon(
                    onPressed: onSair,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sair'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  )
                else
                  Tooltip(
                    message: 'Sair',
                    child: IconButton(
                      onPressed: onSair,
                      icon: const Icon(Icons.logout, color: Colors.white70, size: 22),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
