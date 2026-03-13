import 'package:flutter/material.dart';

import '../theme/pedido_certo_theme.dart';

/// Cards de KPI para a tela inicial (estilo dashboard).
class DashboardKpis extends StatelessWidget {
  const DashboardKpis({
    super.key,
    required this.totalUnidades,
    required this.totalUsuarios,
    this.onlineCount,
    this.ultimosAcessos,
    this.loading = false,
    this.totalDfd = 0,
    this.totalAtas = 0,
    this.totalFornecedores = 0,
    this.totalEquipamentos = 0,
    this.totalMedicamentos = 0,
    this.totalProcedimentos = 0,
  });

  final int totalUnidades;
  final int totalUsuarios;
  final int? onlineCount;
  final List<String>? ultimosAcessos;
  final bool loading;
  final int totalDfd;
  final int totalAtas;
  final int totalFornecedores;
  final int totalEquipamentos;
  final int totalMedicamentos;
  final int totalProcedimentos;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visão geral',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Resumo do sistema Pedido Certo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: PedidoCertoTheme.labelGray,
                ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 16.0;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _KpiCard(
                    title: 'Unidades hospitalares',
                    value: '$totalUnidades',
                    subtitle: 'cadastradas',
                    icon: Icons.business,
                    color: PedidoCertoTheme.primaryBlue,
                  ),
                  _KpiCard(
                    title: 'Usuários do sistema',
                    value: '$totalUsuarios',
                    subtitle: 'total',
                    icon: Icons.people,
                    color: PedidoCertoTheme.tealAccent,
                  ),
                  _KpiCard(
                    title: 'Online agora',
                    value: onlineCount != null ? '$onlineCount' : '—',
                    subtitle: onlineCount != null ? 'usuários' : 'Em breve',
                    icon: Icons.wifi,
                    color: PedidoCertoTheme.successGreen,
                  ),
                  _KpiCard(
                    title: 'Últimos acessos',
                    value: ultimosAcessos != null && ultimosAcessos!.isNotEmpty
                        ? '${ultimosAcessos!.length}'
                        : '—',
                    subtitle: ultimosAcessos != null && ultimosAcessos!.isNotEmpty
                        ? 'registros'
                        : 'Em breve',
                    icon: Icons.history,
                    color: PedidoCertoTheme.warningOrange,
                  ),
                  _KpiCard(
                    title: 'DFD',
                    value: '$totalDfd',
                    subtitle: 'registrados',
                    icon: Icons.assignment_outlined,
                    color: const Color(0xFF5C6BC0),
                  ),
                  _KpiCard(
                    title: 'Atas',
                    value: '$totalAtas',
                    subtitle: 'cadastradas',
                    icon: Icons.gavel,
                    color: const Color(0xFF7E57C2),
                  ),
                  _KpiCard(
                    title: 'Fornecedores',
                    value: '$totalFornecedores',
                    subtitle: 'cadastrados',
                    icon: Icons.store,
                    color: const Color(0xFF546E7A),
                  ),
                  _KpiCard(
                    title: 'Equipamentos (RENEM)',
                    value: '$totalEquipamentos',
                    subtitle: 'registrados',
                    icon: Icons.precision_manufacturing,
                    color: const Color(0xFF00838F),
                  ),
                  _KpiCard(
                    title: 'Medicamentos (CATMED)',
                    value: '$totalMedicamentos',
                    subtitle: 'registrados',
                    icon: Icons.medication,
                    color: const Color(0xFF00695C),
                  ),
                  _KpiCard(
                    title: 'Procedimentos (SIGTAP)',
                    value: '$totalProcedimentos',
                    subtitle: 'registrados',
                    icon: Icons.medical_services_outlined,
                    color: const Color(0xFF2E7D32),
                  ),
                ],
              );
            },
          ),
          if (ultimosAcessos != null && ultimosAcessos!.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              'Últimos usuários que acessaram',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ultimosAcessos!.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: PedidoCertoTheme.primaryBlue.withValues(alpha: 0.12),
                      child: Text(
                        ultimosAcessos![i].isNotEmpty
                            ? ultimosAcessos![i][0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: PedidoCertoTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(ultimosAcessos![i]),
                  );
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: 32),
            Text(
              'Últimos usuários que acessaram',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Indicador em breve',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PedidoCertoTheme.labelGray,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PedidoCertoTheme.radiusCard),
        side: const BorderSide(color: PedidoCertoTheme.borderGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const Spacer(),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PedidoCertoTheme.labelGray,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF374151),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
