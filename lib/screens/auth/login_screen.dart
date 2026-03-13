import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_errors.dart';
import 'auth_layout.dart';
import 'auth_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onNavigateToRegister,
    this.onLoginSuccess,
  });

  final VoidCallback? onNavigateToRegister;
  final VoidCallback? onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _manterConectado = false;
  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    _erro = null;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) widget.onLoginSuccess?.call();
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
          _erro = e.toString();
          _loading = false;
        });
      }
    }
    if (mounted && _loading) setState(() => _loading = false);
  }

  Future<void> _esqueciMinhaSenha() async {
    final email = _emailController.text.trim();
    String? emailParaEnvio = email.isNotEmpty ? email : null;

    if (emailParaEnvio == null && mounted) {
      final controller = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Redefinir senha'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Informe o e-mail da sua conta. Enviaremos um link para redefinir a senha.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    hintText: 'seu@email.com',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) Navigator.of(context).pop(v.trim());
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final e = controller.text.trim();
                  if (e.isEmpty) return;
                  Navigator.of(context).pop(e);
                },
                child: const Text('Enviar'),
              ),
            ],
          );
        },
      );
      emailParaEnvio = result;
    }

    if (emailParaEnvio == null || emailParaEnvio.isEmpty) return;

    setState(() {
      _erro = null;
      _loading = true;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(emailParaEnvio);
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se este e-mail estiver cadastrado, você receberá um link para redefinir a senha. Verifique a caixa de entrada e o spam.',
            ),
            duration: Duration(seconds: 6),
          ),
        );
      }
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
          _erro = e.toString();
          _loading = false;
        });
      }
    }
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
                    'Login',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                    controller: _passwordController,
                    obscureText: true,
                    decoration: authInputDecoration(
                      labelText: 'Senha',
                      hintText: '••••••••',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe a senha';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _manterConectado,
                          onChanged: (v) =>
                              setState(() => _manterConectado = v ?? false),
                          activeColor: const Color(0xFF1B4965),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Mantenha-me conectado',
                        style:
                            TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                      ),
                    ],
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
                    onPressed: _entrar,
                    label: 'ENTRAR',
                    loading: _loading,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: authTextLink(
                      text: 'Esqueci minha senha',
                      onTap: _esqueciMinhaSenha,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Não tem conta? ',
                          style:
                              TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                        ),
                        authTextLink(
                          text: 'Criar conta',
                          onTap: widget.onNavigateToRegister ?? () {},
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
