// ignore_for_file: avoid_print, empty_catches
import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

// Configuração
const supabaseUrl = 'https://bwdyzdhguwknbcagdado.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ3ZHl6ZGhndXdrbmJjYWdkYWRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxMjc4MTIsImV4cCI6MjA4NzcwMzgxMn0.K8r2jN4b9AH6fev9zUfQ5yJa7hb42MvepC78dPAkXtw';
final supabase = SupabaseClient(supabaseUrl, supabaseKey);

const basePath = r'c:\Users\fabianoeugenio\Downloads\TabelaUnificada';

void main() async {
  print('Iniciando importação de tabelas complementares SIGTAP...');

  await importarGrupos();
  await importarSubGrupos();
  await importarFormaOrganizacao();
  await importarProcedimentoCompativel();

  print('Todas as importações concluídas com sucesso!');
  exit(0);
}

Future<void> importarGrupos() async {
  print('\n--- Importando Grupos ---');
  final file = File('$basePath\\tb_grupo.txt');
  if (!await file.exists()) {
    print('Arquivo tb_grupo.txt não encontrado.');
    return;
  }
  final lines = await file.readAsLines(encoding: latin1);
  List<Map<String, dynamic>> batch = [];

  for (String line in lines) {
    if (line.trim().isEmpty) continue;
    try {
      batch.add({
        'co_grupo': line.substring(0, 2).trim(),
        'no_grupo': line.substring(2, 102).trim(),
        'dt_competencia': line.substring(102, 108).trim(),
      });
    } catch (e) {
      print('Erro na linha: $e');
    }
  }
  if (batch.isNotEmpty) {
    await supabase.from('sigtap_grupo').upsert(batch);
    print('Grupos inseridos: ${batch.length}');
  }
}

Future<void> importarSubGrupos() async {
  print('\n--- Importando Sub-Grupos ---');
  final file = File('$basePath\\tb_sub_grupo.txt');
  if (!await file.exists()) {
    print('Arquivo tb_sub_grupo.txt não encontrado.');
    return;
  }
  final lines = await file.readAsLines(encoding: latin1);
  List<Map<String, dynamic>> batch = [];
  int count = 0;

  for (String line in lines) {
    if (line.trim().isEmpty) continue;
    try {
      batch.add({
        'co_grupo': line.substring(0, 2).trim(),
        'co_sub_grupo': line.substring(2, 4).trim(),
        'no_sub_grupo': line.substring(4, 104).trim(),
        'dt_competencia': line.substring(104, 110).trim(),
      });
      if (batch.length >= 1000) {
        await supabase
            .from('sigtap_sub_grupo')
            .upsert(batch, onConflict: 'co_grupo, co_sub_grupo');
        count += batch.length;
        print('Inseridos $count sub-grupos...');
        batch.clear();
      }
    } catch (e) {}
  }
  if (batch.isNotEmpty) {
    await supabase
        .from('sigtap_sub_grupo')
        .upsert(batch, onConflict: 'co_grupo, co_sub_grupo');
    count += batch.length;
    print('Sub-grupos inseridos: $count');
  }
}

Future<void> importarFormaOrganizacao() async {
  print('\n--- Importando Forma de Organização ---');
  final file = File('$basePath\\tb_forma_organizacao.txt');
  if (!await file.exists()) {
    print('Arquivo tb_forma_organizacao.txt não encontrado.');
    return;
  }
  final lines = await file.readAsLines(encoding: latin1);
  List<Map<String, dynamic>> batch = [];
  int count = 0;

  for (String line in lines) {
    if (line.trim().isEmpty) continue;
    try {
      batch.add({
        'co_grupo': line.substring(0, 2).trim(),
        'co_sub_grupo': line.substring(2, 4).trim(),
        'co_forma_organizacao': line.substring(4, 6).trim(),
        'no_forma_organizacao': line.substring(6, 106).trim(),
        'dt_competencia': line.substring(106, 112).trim(),
      });
      if (batch.length >= 1000) {
        await supabase.from('sigtap_forma_organizacao').upsert(batch,
            onConflict: 'co_grupo, co_sub_grupo, co_forma_organizacao');
        count += batch.length;
        print('Inseridos $count formas de organizacao...');
        batch.clear();
      }
    } catch (e) {}
  }
  if (batch.isNotEmpty) {
    await supabase.from('sigtap_forma_organizacao').upsert(batch,
        onConflict: 'co_grupo, co_sub_grupo, co_forma_organizacao');
    count += batch.length;
    print('Formas de organização inseridas: $count');
  }
}

Future<void> importarProcedimentoCompativel() async {
  print('\n--- Importando Procedimentos Compatíveis (OPME, etc) ---');
  final file = File('$basePath\\rl_procedimento_compativel.txt');
  if (!await file.exists()) {
    print('Arquivo rl_procedimento_compativel.txt não encontrado.');
    return;
  }
  final lines = await file.readAsLines(encoding: latin1);
  List<Map<String, dynamic>> batch = [];
  int count = 0;

  for (String line in lines) {
    if (line.trim().isEmpty) continue;
    try {
      batch.add({
        'co_procedimento_principal': line.substring(0, 10).trim(),
        'co_registro_principal': line.substring(10, 12).trim(),
        'co_procedimento_compativel': line.substring(12, 22).trim(),
        'co_registro_compativel': line.substring(22, 24).trim(),
        'tp_compatibilidade': line.substring(24, 25).trim(),
        'qt_permitida': int.tryParse(line.substring(25, 29).trim()) ?? 0,
        'dt_competencia': line.substring(29, 35).trim(),
      });
      if (batch.length >= 2000) {
        // Usa upsert e trata conflito para não duplicar quando mudar de competência
        await supabase.from('sigtap_procedimento_compativel').upsert(
              batch,
              onConflict:
                  'co_procedimento_principal, co_procedimento_compativel',
            );
        count += batch.length;
        print('Inseridos $count compativeis...');
        batch.clear();
      }
    } catch (e) {}
  }
  if (batch.isNotEmpty) {
    await supabase.from('sigtap_procedimento_compativel').upsert(
          batch,
          onConflict: 'co_procedimento_principal, co_procedimento_compativel',
        );
    count += batch.length;
    print('Compatíveis inseridos: $count');
  }
}
