import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_errors.dart';
import 'auth_layout.dart';
import 'auth_styles.dart';

/// Tela exibida quando o usuário chega pelo link "Redefinir senha" do e-mail.
/// Permite definir a nova senha e completa o fluxo de recovery.
class NovaSenhaScreen extends StatefulWidget {
  const NovaSenhaScreen({super.key, required this.onSucesso});

  final VoidCallback onSucesso;

  @override
  State<NovaSenhaScreen> createState() => _NovaSenhaScreenState();
}

class _NovaSenhaScreenState extends State<NovaSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _redefinir() async {
    _erro = null;
    if (!_formKey.currentState!.validate()) return;
    final senha = _senhaController.text;
    if (senha.length < 6) {
      setState(() => _erro = 'A senha deve ter no mínimo 6 caracteres.');
      return;
    }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: senha),
      );
      if (mounted) {
        widget.onSucesso();
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _erro = mensagemErroAuthAmigavel(e.message);
          _loading = false;
        });
      }
      return;
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.toString();
          _loading = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _loading = false);
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
                    'Nova senha',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Defina uma nova senha para acessar sua conta.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _senhaController,
                    obscureText: true,
                    decoration: authInputDecoration(
                      labelText: 'Nova senha',
                      hintText: '••••••••',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe a nova senha';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmarController,
                    obscureText: true,
                    decoration: authInputDecoration(
                      labelText: 'Confirmar nova senha',
                      hintText: '••••••••',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Confirme a nova senha';
                      }
                      if (v != _senhaController.text) {
                        return 'As senhas não coincidem';
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
                    onPressed: _redefinir,
                    label: 'REDEFINIR SENHA',
                    loading: _loading,
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
