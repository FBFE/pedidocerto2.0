/// Converte mensagens de erro do Supabase para texto amigável em português.
String mensagemErroAuthAmigavel(String mensagem) {
  final m = mensagem.toLowerCase();
  if (m.contains('email rate limit') || m.contains('rate limit exceeded')) {
    return 'Muitas tentativas de envio de e-mail no momento. '
        'Aguarde alguns minutos e tente novamente.';
  }
  if (m.contains('invalid login') || m.contains('invalid email')) {
    return 'E-mail ou senha inválidos. Verifique e tente novamente.';
  }
  if (m.contains('email not confirmed') || m.contains('not confirmed')) {
    return 'Confirme seu e-mail antes de entrar. Verifique sua caixa de entrada e o spam.';
  }
  if (m.contains('already registered') || m.contains('already exists')) {
    return 'Este e-mail já está cadastrado. Faça login ou use "Esqueci minha senha".';
  }
  if (m.contains('password')) {
    return 'A senha deve ter no mínimo 6 caracteres.';
  }
  return mensagem;
}
