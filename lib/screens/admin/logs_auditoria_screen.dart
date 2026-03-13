import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../modules/audit/models/audit_log_model.dart';
import '../../modules/audit/repositories/audit_log_repository.dart';
import '../../modules/usuarios/repositories/usuario_repository.dart';
import '../../widgets/constrained_content.dart';

/// Tela de trilha de auditoria (logs). Apenas administradores.
/// Permite listar registros de CREATE, UPDATE, DELETE e restaurar (rollback).
class LogsAuditoriaScreen extends StatefulWidget {
  const LogsAuditoriaScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<LogsAuditoriaScreen> createState() => _LogsAuditoriaScreenState();
}

class _LogsAuditoriaScreenState extends State<LogsAuditoriaScreen> {
  final _repo = AuditLogRepository();
  final _usuarioRepo = UsuarioRepository();

  List<AuditLogModel> _logs = [];
  bool _carregando = true;
  String? _erro;
  String? _filtroEntidade;
  String? _filtroAcao;

  static const _entidades = [
    ('', 'Todas'),
    ('dfd', 'DFD'),
    ('atas', 'Atas'),
    ('usuarios', 'Usuários'),
    ('fornecedores', 'Fornecedores'),
    ('unidades_hospitalares', 'Unidades'),
  ];

  static const _acoes = [
    ('', 'Todas'),
    ('CREATE', 'Adicionar'),
    ('UPDATE', 'Editar'),
    ('DELETE', 'Excluir'),
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await _repo.getLogs(
        entityName: _filtroEntidade?.isEmpty == true ? null : _filtroEntidade,
        action: _filtroAcao?.isEmpty == true ? null : _filtroAcao,
        limit: 200,
      );
      if (mounted) {
        setState(() {
          _logs = lista;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.toString();
          _carregando = false;
        });
      }
    }
  }

  Future<void> _restaurar(AuditLogModel log) async {
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar restauração'),
        content: Text(
          'Deseja restaurar este registro?\n\n'
          'Entidade: ${log.entityName}\n'
          'Ação original: ${AuditLogModel.actionLabel(log.action)}\n\n'
          'Esta ação pode sobrescrever dados atuais. Confirme apenas se tiver certeza.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sim, restaurar')),
        ],
      ),
    );
    if (confirm1 != true) return;

    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Última confirmação'),
        content: const Text(
          'Restauração é uma ação crítica. Tem certeza absoluta?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim, tenho certeza'),
          ),
        ],
      ),
    );
    if (confirm2 != true) return;

    try {
      await _repo.restore(log);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restauração concluída.'), backgroundColor: Colors.green),
        );
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao restaurar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _nomeUsuario(String? userId) async {
    if (userId == null) return null;
    try {
      final u = await _usuarioRepo.getUsuarioById(userId);
      return u?.nome;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)
            : null,
        title: const Text('Trilha de auditoria'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregando ? null : _carregar, tooltip: 'Atualizar'),
        ],
      ),
      body: ConstrainedContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _filtroEntidade?.isEmpty == true ? null : _filtroEntidade,
                      decoration: const InputDecoration(
                        labelText: 'Entidade',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _entidades.map((e) => DropdownMenuItem(value: e.$1.isEmpty ? null : e.$1, child: Text(e.$2))).toList(),
                      onChanged: (v) {
                        setState(() {
                          _filtroEntidade = v ?? '';
                          _carregando = true;
                        });
                        _carregar();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _filtroAcao?.isEmpty == true ? null : _filtroAcao,
                      decoration: const InputDecoration(
                        labelText: 'Ação',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _acoes.map((e) => DropdownMenuItem(value: e.$1.isEmpty ? null : e.$1, child: Text(e.$2))).toList(),
                      onChanged: (v) {
                        setState(() {
                          _filtroAcao = v ?? '';
                          _carregando = true;
                        });
                        _carregar();
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_erro!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _logs.isEmpty
                      ? const Center(child: Text('Nenhum registro de auditoria.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _logs.length,
                          itemBuilder: (context, i) {
                            final log = _logs[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: log.action == 'CREATE'
                                      ? Colors.green
                                      : log.action == 'UPDATE'
                                          ? Colors.blue
                                          : Colors.red,
                                  child: Icon(
                                    log.action == 'CREATE'
                                        ? Icons.add
                                        : log.action == 'UPDATE'
                                            ? Icons.edit
                                            : Icons.delete,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  '${AuditLogModel.actionLabel(log.action)} · ${log.entityName}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  'ID: ${log.entityId ?? '—'}${log.createdAt != null ? '\n${DateFormat('dd/MM/yyyy HH:mm:ss').format(log.createdAt!.toLocal())}' : ''}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.info_outline),
                                      tooltip: 'Detalhes',
                                      onPressed: () => _mostrarDetalhe(log),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.restore),
                                      tooltip: 'Restaurar',
                                      onPressed: () => _restaurar(log),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDetalhe(AuditLogModel log) async {
    final nomeUser = await _nomeUsuario(log.userId);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detalhe do log'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _linha('Ação', AuditLogModel.actionLabel(log.action)),
              _linha('Entidade', log.entityName),
              _linha('ID do registro', log.entityId ?? '—'),
              _linha('Usuário', nomeUser ?? log.userId ?? '—'),
              _linha('Data/hora', log.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm:ss').format(log.createdAt!.toLocal()) : '—'),
              if (log.oldValue != null && log.oldValue!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Valor anterior (old_value):', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: double.maxFinite,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                  child: SelectableText(log.oldValue.toString(), style: const TextStyle(fontSize: 11)),
                ),
              ],
              if (log.newValue != null && log.newValue!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Valor novo (new_value):', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: double.maxFinite,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                  child: SelectableText(log.newValue.toString(), style: const TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Widget _linha(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
