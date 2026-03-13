import 'package:flutter/material.dart';

import '../../modules/atas/models/ata_model.dart';
import '../../modules/atas/repositories/ata_repository.dart';

/// Edita apenas o cabeçalho da ata (número, modalidade, vigência, etc.).
class EditarAtaScreen extends StatefulWidget {
  final AtaModel ata;

  const EditarAtaScreen({super.key, required this.ata});

  @override
  State<EditarAtaScreen> createState() => _EditarAtaScreenState();
}

class _EditarAtaScreenState extends State<EditarAtaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = AtaRepository();
  final _numeroAta = TextEditingController();
  final _numeroModalidade = TextEditingController();
  final _detalhamento = TextEditingController();
  final _anoCompetencia = TextEditingController();
  final _numeroProcesso = TextEditingController();
  final _linkProcesso = TextEditingController();
  final _statusVigencia = TextEditingController();

  String? _modalidade;
  DateTime? _vigenciaInicio;
  DateTime? _vigenciaFim;
  String? _tipoAta;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final a = widget.ata;
    _numeroAta.text = a.numeroAta;
    _numeroModalidade.text = a.numeroModalidade ?? '';
    _detalhamento.text = a.detalhamento ?? '';
    _anoCompetencia.text = a.anoCompetencia?.toString() ?? '';
    _numeroProcesso.text = a.numeroProcessoAdministrativo ?? '';
    _linkProcesso.text = a.linkProcessoAdministrativo ?? '';
    _statusVigencia.text = a.statusVigencia ?? '';
    _modalidade = a.modalidade;
    _vigenciaInicio = a.vigenciaInicio;
    _vigenciaFim = a.vigenciaFim;
    _tipoAta = a.tipoAta;
  }

  @override
  void dispose() {
    _numeroAta.dispose();
    _numeroModalidade.dispose();
    _detalhamento.dispose();
    _anoCompetencia.dispose();
    _numeroProcesso.dispose();
    _linkProcesso.dispose();
    _statusVigencia.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    _erro = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_modalidade == null || _modalidade!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione a modalidade.')));
      return;
    }
    if (_tipoAta == null || _tipoAta!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione o tipo da ata.')));
      return;
    }
    setState(() => _salvando = true);
    try {
      final ataAtualizada = AtaModel(
        id: widget.ata.id,
        createdAt: widget.ata.createdAt,
        usuarioCadastrouNome: widget.ata.usuarioCadastrouNome,
        usuarioCadastrouMatricula: widget.ata.usuarioCadastrouMatricula,
        dataHoraRegistro: widget.ata.dataHoraRegistro,
        numeroAta: _numeroAta.text.trim(),
        modalidade: _modalidade,
        numeroModalidade: _numeroModalidade.text.trim().isEmpty ? null : _numeroModalidade.text.trim(),
        vigenciaInicio: _vigenciaInicio,
        vigenciaFim: _vigenciaFim,
        statusVigencia: _statusVigencia.text.trim().isEmpty ? null : _statusVigencia.text.trim(),
        detalhamento: _detalhamento.text.trim().isEmpty ? null : _detalhamento.text.trim(),
        anoCompetencia: int.tryParse(_anoCompetencia.text.trim()),
        numeroProcessoAdministrativo: _numeroProcesso.text.trim().isEmpty ? null : _numeroProcesso.text.trim(),
        linkProcessoAdministrativo: _linkProcesso.text.trim().isEmpty ? null : _linkProcesso.text.trim(),
        tipoAta: _tipoAta,
        orgao: widget.ata.orgao,
        objeto: widget.ata.objeto,
        classificacao: widget.ata.classificacao,
      );
      await _repo.updateAta(ataAtualizada);
      if (!mounted) return;
      Navigator.of(context).pop(ataAtualizada);
    } catch (e) {
      if (mounted) setState(() {
        _salvando = false;
        _erro = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar ata'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_erro!, style: const TextStyle(color: Colors.red)),
              ),
            _section('Identificação da ata', [
              _textField(_numeroAta, 'Número da ata', obrigatorio: true),
              _dropdown('Modalidade', _modalidade, AtaModel.modalidades, (v) => setState(() => _modalidade = v)),
              _textField(_numeroModalidade, 'Número da modalidade'),
            ]),
            _section('Vigência', [
              _dateField('Data início vigência', _vigenciaInicio, (d) => setState(() => _vigenciaInicio = d)),
              _dateField('Data fim vigência', _vigenciaFim, (d) => setState(() => _vigenciaFim = d)),
              _textField(_statusVigencia, 'Status da vigência'),
            ]),
            _section('Detalhamento', [
              _textField(_detalhamento, 'Detalhamento', maxLines: 3),
              _textField(_anoCompetencia, 'Ano competência', keyboardType: TextInputType.number),
              _textField(_numeroProcesso, 'Número do processo administrativo'),
              _textField(_linkProcesso, 'Link do processo administrativo'),
            ]),
            _section('Tipo da ata', [
              _dropdown('Tipo (medicamento / material / opme)', _tipoAta, AtaModel.tiposAta, (v) => setState(() => _tipoAta = v)),
            ]),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon: _salvando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: Text(_salvando ? 'Salvando...' : 'Salvar'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String label, {bool obrigatorio = false, int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (obrigatorio ? ' *' : ''),
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: obrigatorio ? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null : null,
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> opcoes, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value?.isEmpty == true ? null : value,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: opcoes.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, void Function(DateTime?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(value == null ? label : '${label}: ${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (d != null) onChanged(d);
        },
      ),
    );
  }
}
