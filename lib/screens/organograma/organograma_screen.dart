import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/constrained_content.dart';
import '../../modules/unidades_lotacao/models/governo_model.dart';
import '../../modules/unidades_lotacao/models/secretaria_adjunta_model.dart';
import '../../modules/unidades_lotacao/models/secretaria_model.dart';
import '../../modules/unidades_lotacao/models/setor_model.dart';
import '../../modules/unidades_lotacao/models/unidade_hospitalar_model.dart';
import '../../modules/unidades_lotacao/repositories/governo_repository.dart';
import '../../modules/unidades_lotacao/repositories/secretaria_adjunta_repository.dart';
import '../../modules/unidades_lotacao/repositories/secretaria_repository.dart';
import '../../modules/unidades_lotacao/repositories/setor_repository.dart';
import '../../modules/unidades_lotacao/repositories/unidade_hospitalar_repository.dart';
import '../unidades/unidade_hospitalar_form_screen.dart';
import 'governo_form_screen.dart';
import 'organograma_tree.dart'; // OrganogramaData
import 'organograma_tree_expansivel.dart';

class OrganogramaScreen extends StatefulWidget {
  const OrganogramaScreen({
    super.key,
    this.onAbrirMeusDados,
    this.onSair,
  });

  final VoidCallback? onAbrirMeusDados;
  final VoidCallback? onSair;

  @override
  State<OrganogramaScreen> createState() => _OrganogramaScreenState();
}

class _OrganogramaScreenState extends State<OrganogramaScreen> {
  final _governoRepo = GovernoRepository();
  final _secretariaRepo = SecretariaRepository();
  final _adjuntaRepo = SecretariaAdjuntaRepository();
  final _unidadeRepo = UnidadeHospitalarRepository();
  final _setorRepo = SetorRepository();

  GovernoModel? _governo;
  OrganogramaData? _data;
  String? _erro;
  bool _carregando = true;

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
      final gov = await _governoRepo.getFirst();
      if (gov == null) {
        setState(() {
          _governo = null;
          _data = null;
          _carregando = false;
        });
        return;
      }
      final secretarias = await _secretariaRepo.getByGovernoId(gov.id!);
      final adjuntasBySecretaria = <String, List<SecretariaAdjuntaModel>>{};
      final unidadesBySecretaria = <String, List<UnidadeHospitalarModel>>{};
      for (final s in secretarias) {
        if (s.id != null) {
          adjuntasBySecretaria[s.id!] =
              await _adjuntaRepo.getBySecretariaId(s.id!);
          unidadesBySecretaria[s.id!] =
              await _unidadeRepo.getBySecretariaId(s.id!);
        }
      }
      final setoresByAdjunta = <String, List<SetorModel>>{};
      final setoresByUnidade = <String, List<SetorModel>>{};
      for (final list in adjuntasBySecretaria.values) {
        for (final a in list) {
          if (a.id != null) {
            setoresByAdjunta[a.id!] =
                await _setorRepo.getBySecretariaAdjuntaId(a.id!);
          }
        }
      }
      for (final list in unidadesBySecretaria.values) {
        for (final u in list) {
          if (u.id != null) {
            setoresByUnidade[u.id!] =
                await _setorRepo.getByUnidadeHospitalarId(u.id!);
          }
        }
      }
      setState(() {
        _governo = gov;
        _data = OrganogramaData(
          governo: gov,
          secretarias: secretarias,
          adjuntasBySecretaria: adjuntasBySecretaria,
          unidadesBySecretaria: unidadesBySecretaria,
          setoresByAdjunta: setoresByAdjunta,
          setoresByUnidade: setoresByUnidade,
        );
        _carregando = false;
      });
    } catch (e, st) {
      setState(() {
        _erro = '$e\n$st';
        _carregando = false;
      });
    }
  }

  Future<void> _cadastrarOuEditarGoverno({GovernoModel? gov}) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => GovernoFormScreen(
          governo: gov ?? _governo,
          onSaved: _carregar,
        ),
      ),
    );
    if (ok == true && mounted) _carregar();
  }

  Future<void> _adicionarSecretaria() async {
    if (_governo?.id == null) return;
    final nomeCtrl = TextEditingController();
    final siglaCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Secretaria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
                autofocus: true),
            const SizedBox(height: 12),
            TextField(
                controller: siglaCtrl,
                decoration:
                    const InputDecoration(labelText: 'Sigla (opcional)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (nomeCtrl.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _secretariaRepo.insert(SecretariaModel(
        governoId: _governo!.id,
        nome: nomeCtrl.text.trim(),
        sigla: siglaCtrl.text.trim().isEmpty ? null : siglaCtrl.text.trim(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Secretaria adicionada')));
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _escolherAdjuntaOuUnidade(SecretariaModel secretaria) async {
    final escolha = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar sob esta Secretaria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Secretaria Adjunta'),
                onTap: () => Navigator.pop(context, 'adjunta')),
            ListTile(
                leading: const Icon(Icons.business),
                title: const Text('Unidade Hospitalar'),
                onTap: () => Navigator.pop(context, 'unidade')),
          ],
        ),
      ),
    );
    if (escolha == 'adjunta' && mounted) _adicionarAdjunta(secretaria.id!);
    if (escolha == 'unidade' && mounted) _adicionarUnidade(secretaria);
  }

  Future<void> _adicionarAdjunta(String secretariaId) async {
    final nomeCtrl = TextEditingController();
    final siglaCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Secretaria Adjunta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
                autofocus: true),
            const SizedBox(height: 12),
            TextField(
                controller: siglaCtrl,
                decoration:
                    const InputDecoration(labelText: 'Sigla (opcional)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                if (nomeCtrl.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Salvar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _adjuntaRepo.insert(SecretariaAdjuntaModel(
        secretariaId: secretariaId,
        nome: nomeCtrl.text.trim(),
        sigla: siglaCtrl.text.trim().isEmpty ? null : siglaCtrl.text.trim(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Secretaria Adjunta adicionada')));
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _adicionarUnidade(SecretariaModel secretaria) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => UnidadeHospitalarFormScreen(
          unidade:
              UnidadeHospitalarModel(secretariaId: secretaria.id!, nome: ''),
          onSaved: _carregar,
        ),
      ),
    );
    if (ok == true && mounted) _carregar();
  }

  Future<void> _adicionarSetor(String parentId, bool isAdjunta) async {
    final nomeCtrl = TextEditingController();
    final siglaCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdjunta
            ? 'Novo Setor (Secretaria Adjunta)'
            : 'Novo Setor (Unidade)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
                autofocus: true),
            const SizedBox(height: 12),
            TextField(
                controller: siglaCtrl,
                decoration:
                    const InputDecoration(labelText: 'Sigla (opcional)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                if (nomeCtrl.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Salvar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _setorRepo.insert(SetorModel(
        nome: nomeCtrl.text.trim(),
        sigla: siglaCtrl.text.trim().isEmpty ? null : siglaCtrl.text.trim(),
        secretariaAdjuntaId: isAdjunta ? parentId : null,
        unidadeHospitalarId: isAdjunta ? null : parentId,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Setor adicionado')));
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _editarSecretaria(SecretariaModel s) async {
    final nomeCtrl = TextEditingController(text: s.nome);
    final siglaCtrl = TextEditingController(text: s.sigla ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Secretaria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome')),
            const SizedBox(height: 12),
            TextField(
                controller: siglaCtrl,
                decoration: const InputDecoration(labelText: 'Sigla')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                if (nomeCtrl.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Salvar')),
        ],
      ),
    );
    if (ok != true || !mounted || s.id == null) return;
    try {
      await _secretariaRepo.update(SecretariaModel(
          id: s.id,
          governoId: s.governoId,
          nome: nomeCtrl.text.trim(),
          sigla: siglaCtrl.text.trim().isEmpty ? null : siglaCtrl.text.trim(),
          descricao: s.descricao));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Secretaria atualizada')));
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _editarAdjunta(SecretariaAdjuntaModel a) async {
    final nomeCtrl = TextEditingController(text: a.nome);
    final siglaCtrl = TextEditingController(text: a.sigla ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Secretaria Adjunta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome')),
            const SizedBox(height: 12),
            TextField(
                controller: siglaCtrl,
                decoration: const InputDecoration(labelText: 'Sigla')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                if (nomeCtrl.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Salvar')),
        ],
      ),
    );
    if (ok != true || !mounted || a.id == null) return;
    try {
      await _adjuntaRepo.update(SecretariaAdjuntaModel(
          id: a.id,
          secretariaId: a.secretariaId,
          nome: nomeCtrl.text.trim(),
          sigla: siglaCtrl.text.trim().isEmpty ? null : siglaCtrl.text.trim(),
          descricao: a.descricao));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Atualizada')));
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _editarUnidade(UnidadeHospitalarModel u) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (context) =>
              UnidadeHospitalarFormScreen(unidade: u, onSaved: _carregar)),
    );
    if (ok == true && mounted) _carregar();
  }

  Future<void> _editarSetor(SetorModel s) async {
    final nomeCtrl = TextEditingController(text: s.nome);
    final siglaCtrl = TextEditingController(text: s.sigla ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Setor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome')),
            const SizedBox(height: 12),
            TextField(
                controller: siglaCtrl,
                decoration: const InputDecoration(labelText: 'Sigla')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () {
                if (nomeCtrl.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Salvar')),
        ],
      ),
    );
    if (ok != true || !mounted || s.id == null) return;
    try {
      await _setorRepo.update(SetorModel(
          id: s.id,
          nome: nomeCtrl.text.trim(),
          sigla: siglaCtrl.text.trim().isEmpty ? null : siglaCtrl.text.trim(),
          descricao: s.descricao,
          secretariaAdjuntaId: s.secretariaAdjuntaId,
          unidadeHospitalarId: s.unidadeHospitalarId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Setor atualizado')));
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _alterarVinculoSecretaria(SecretariaModel s) async {
    final governos = await _governoRepo.getAll();
    if (!mounted) return;
    if (governos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum Governo cadastrado')));
      return;
    }
    final g = await showDialog<GovernoModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar vínculo da Secretaria'),
        content: SizedBox(
            width: 320,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: governos.length,
                itemBuilder: (context, i) => ListTile(
                    title: Text(governos[i].nome),
                    subtitle: governos[i].sigla != null
                        ? Text(governos[i].sigla!)
                        : null,
                    onTap: () => Navigator.pop(context, governos[i])))),
      ),
    );
    if (g == null || !mounted || s.id == null) return;
    try {
      await _secretariaRepo.update(SecretariaModel(
          id: s.id,
          governoId: g.id,
          nome: s.nome,
          sigla: s.sigla,
          descricao: s.descricao));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Vínculo atualizado')));
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _alterarVinculoAdjunta(SecretariaAdjuntaModel a) async {
    final secretarias = await _secretariaRepo.getAll();
    if (!mounted) return;
    if (secretarias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma Secretaria disponível')));
      return;
    }
    final s = await showDialog<SecretariaModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar vínculo da Secretaria Adjunta'),
        content: SizedBox(
            width: 320,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: secretarias.length,
                itemBuilder: (context, i) => ListTile(
                    title: Text(secretarias[i].nome),
                    onTap: () => Navigator.pop(context, secretarias[i])))),
      ),
    );
    if (s == null || !mounted || a.id == null) return;
    try {
      await _adjuntaRepo.update(SecretariaAdjuntaModel(
          id: a.id,
          secretariaId: s.id!,
          nome: a.nome,
          sigla: a.sigla,
          descricao: a.descricao));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Vínculo atualizado')));
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _alterarVinculoUnidade(UnidadeHospitalarModel u) async {
    final secretarias = await _secretariaRepo.getAll();
    if (!mounted) return;
    if (secretarias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma Secretaria disponível')));
      return;
    }
    final s = await showDialog<SecretariaModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar vínculo da Unidade'),
        content: SizedBox(
            width: 320,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: secretarias.length,
                itemBuilder: (context, i) => ListTile(
                    title: Text(secretarias[i].nome),
                    onTap: () => Navigator.pop(context, secretarias[i])))),
      ),
    );
    if (s == null || !mounted || u.id == null) return;
    try {
      final atual = UnidadeHospitalarModel(
        id: u.id,
        secretariaId: s.id!,
        nome: u.nome,
        cnes: u.cnes,
        cnpj: u.cnpj,
        nomeEmpresarial: u.nomeEmpresarial,
        naturezaJuridica: u.naturezaJuridica,
        cep: u.cep,
        logradouro: u.logradouro,
        numero: u.numero,
        bairro: u.bairro,
        municipio: u.municipio,
        uf: u.uf,
        complemento: u.complemento,
        classificacaoEstabelecimento: u.classificacaoEstabelecimento,
        gestao: u.gestao,
        tipoEstrutura: u.tipoEstrutura,
        latitude: u.latitude,
        longitude: u.longitude,
        responsavelTecnico: u.responsavelTecnico,
        telefone: u.telefone,
        email: u.email,
        cadastradoEm: u.cadastradoEm,
        atualizacaoBaseLocal: u.atualizacaoBaseLocal,
        ultimaAtualizacaoNacional: u.ultimaAtualizacaoNacional,
        horarioFuncionamento: u.horarioFuncionamento,
        dataDesativacao: u.dataDesativacao,
        motivoDesativacao: u.motivoDesativacao,
        logoUrl: u.logoUrl,
        sigla: u.sigla,
        descricao: u.descricao,
      );
      await _unidadeRepo.update(atual);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Vínculo atualizado')));
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _alterarVinculoSetor(SetorModel setor) async {
    final adjuntas = await _adjuntaRepo.getAll();
    final unidades = await _unidadeRepo.getAll();
    if (!mounted) return;
    if (adjuntas.isEmpty && unidades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nenhuma Secretaria Adjunta ou Unidade disponível')));
      return;
    }
    final escolha = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar vínculo do Setor'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vincular a:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (adjuntas.isNotEmpty) ...[
                  const Text('Secretaria Adjunta',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ...adjuntas.map((a) => ListTile(
                      dense: true,
                      title: Text(a.nome,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.pop(context, 'adjunta:${a.id}'))),
                ],
                if (unidades.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Unidade Hospitalar',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ...unidades.map((u) => ListTile(
                      dense: true,
                      title: Text(u.nome,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.pop(context, 'unidade:${u.id}'))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (escolha == null || !mounted || setor.id == null) return;
    final parts = escolha.split(':');
    if (parts.length != 2) return;
    final isAdjunta = parts[0] == 'adjunta';
    final parentId = parts[1];
    try {
      await _setorRepo.update(SetorModel(
          id: setor.id,
          nome: setor.nome,
          sigla: setor.sigla,
          descricao: setor.descricao,
          secretariaAdjuntaId: isAdjunta ? parentId : null,
          unidadeHospitalarId: isAdjunta ? null : parentId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vínculo do setor atualizado')));
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organograma'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop()),
        actions: [
          if (widget.onAbrirMeusDados != null)
            IconButton(
                icon: const Icon(Icons.person),
                tooltip: 'Meus dados',
                onPressed: widget.onAbrirMeusDados),
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _carregando ? null : _carregar),
          if (widget.onSair != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                widget.onSair?.call();
              },
            ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? ConstrainedContent(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Erro ao carregar',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Expanded(
                              child: SingleChildScrollView(
                                  child: SelectableText(_erro!,
                                      style: const TextStyle(fontSize: 12)))),
                        ],
                      ),
                    ),
                  ),
                )
              : _governo == null
                  ? ConstrainedContent(child: _buildCadastreGoverno())
                  : _data == null
                      ? const Center(child: CircularProgressIndicator())
                      : ConstrainedContent(
                          child: OrganogramaTreeExpansivel(
                            data: _data!,
                            governoRepo: _governoRepo,
                            unidadeRepo: _unidadeRepo,
                            onGovernoEdit: () =>
                                _cadastrarOuEditarGoverno(gov: _governo),
                            onAddSecretaria: _adicionarSecretaria,
                            onAddFilhoSecretaria: _escolherAdjuntaOuUnidade,
                            onSecretariaEdit: _editarSecretaria,
                            onAdjuntaEdit: _editarAdjunta,
                            onUnidadeEdit: _editarUnidade,
                            onSetorAdd: _adicionarSetor,
                            onSetorEdit: _editarSetor,
                            onAlterarVinculoSecretaria:
                                _alterarVinculoSecretaria,
                            onAlterarVinculoAdjunta: _alterarVinculoAdjunta,
                            onAlterarVinculoUnidade: _alterarVinculoUnidade,
                            onAlterarVinculoSetor: _alterarVinculoSetor,
                          ),
                        ),
    );
  }

  Widget _buildCadastreGoverno() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance,
                size: 80,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.6)),
            const SizedBox(height: 24),
            Text('Cadastre o Governo primeiro',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'O Governo é a raiz do organograma. Depois você adiciona Secretarias, Secretarias Adjuntas, Unidades Hospitalares e Setores.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
                onPressed: () => _cadastrarOuEditarGoverno(),
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar Governo')),
          ],
        ),
      ),
    );
  }
}
