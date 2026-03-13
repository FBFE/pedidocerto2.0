// ignore_for_file: avoid_print
import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://bwdyzdhguwknbcagdado.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ3ZHl6ZGhndXdrbmJjYWdkYWRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxMjc4MTIsImV4cCI6MjA4NzcwMzgxMn0.K8r2jN4b9AH6fev9zUfQ5yJa7hb42MvepC78dPAkXtw'
  );

  try {
    print('Limpando tabela renem_equipamentos...');
    await supabase.from('renem_equipamentos').delete().neq('cod_item', '0');
    print('Tabela limpa com sucesso!');
  } catch (e) {
    print('Erro: $e');
  }
}
