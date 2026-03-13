import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../modules/usuarios/models/usuario_model.dart';
import '../../modules/usuarios/repositories/usuario_repository.dart';
import 'auth_errors.dart';
import 'auth_layout.dart';
import 'auth_styles.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.onNavigateToLogin,
    this.onRegisterSuccess,
  });

  final VoidCallback? onNavigateToLogin;
  final VoidCallback? onRegisterSuccess;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    _erro = null;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final email = _emailController.text.trim();
      final nome = _nomeController.text.trim();
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: _senhaController.text,
        data: {'nome': nome},
      );
      if (!mounted) return;
      try {
        await UsuarioRepository().createUsuario(UsuarioModel(
          nome: nome,
          email: email,
          perfilSistema: 'pendente_aprovacao',
        ));
      } catch (_) {
        // Se falhar (ex.: RLS), o usuário ainda pode completar perfil na tela "Meus dados"
      }
      if (!mounted) return;
      setState(() => _loading = false);
      await _mostrarPopupSucesso();
      if (mounted) widget.onRegisterSuccess?.call();
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _erro = mensagemErroAuthAmigavel(e.message);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = mensagemErroAuthAmigavel(e.toString());
          _loading = false;
        });
      }
    }
    if (mounted && _loading) setState(() => _loading = false);
  }

  Future<void> _mostrarPopupSucesso() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE8F5E9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Cadastro realizado!',
              style: TextStyle(color: Color(0xFF1B5E20), fontSize: 20),
            ),
          ],
        ),
        content: const Text(
          'Sua conta foi criada com sucesso.\n\n'
          'Seu acesso está pendente de aprovação. Na próxima tela você pode editar suas informações. '
          'Após aprovação por um administrador, você poderá acessar o painel do sistema.',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK',
                style: TextStyle(
                    color: Colors.green.shade700, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AuthCardHeader(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Criar conta',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nomeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: authInputDecoration(
                      labelText: 'Nome',
                      hintText: 'Seu nome completo',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe o nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: authInputDecoration(
                      labelText: 'E-mail',
                      hintText: 'seu@email.com',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe o e-mail';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senhaController,
                    obscureText: true,
                    decoration: authInputDecoration(
                      labelText: 'Senha',
                      hintText: 'Mínimo 6 caracteres',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe a senha';
                      if (v.length < 6) {
                        return 'Senha deve ter no mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmarSenhaController,
                    obscureText: true,
                    decoration: authInputDecoration(
                      labelText: 'Confirmar senha',
                      hintText: 'Repita a senha',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirme a senha';
                      if (v != _senhaController.text) {
                        return 'As senhas não conferem';
                      }
                      return null;
                    },
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _erro!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 20),
                  authPrimaryButton(
                    onPressed: _cadastrar,
                    label: 'CRIAR CONTA',
                    loading: _loading,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Já tem conta? ',
                          style:
                              TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                        ),
                        authTextLink(
                          text: 'Entrar',
                          onTap: widget.onNavigateToLogin ?? () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
