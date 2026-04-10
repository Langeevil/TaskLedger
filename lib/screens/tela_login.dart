import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'tela_cadastro.dart';
import 'tela_dashboard.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorEmail = TextEditingController();
  final _controladorSenha = TextEditingController();
  final _autenticacao = FirebaseAuth.instance;

  bool _ocultarSenha = true;
  bool _carregando = false;
  bool _temTextoSenha = false;

  @override
  void initState() {
    super.initState();
    // Listener para detectar mudanças no campo de senha
    _controladorSenha.addListener(() {
      setState(() {
        _temTextoSenha = _controladorSenha.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    super.dispose();
  }

  void _fazerLogin() async {
    if (_chaveFormulario.currentState!.validate()) {
      setState(() {
        _carregando = true;
      });

      try {
        await _autenticacao.signInWithEmailAndPassword(
          email: _controladorEmail.text.trim(),
          password: _controladorSenha.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login realizado com sucesso!'),
              backgroundColor: Color(0xFF6366F1),
            ),
          );

          // Navegar para o dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const TelaDashboard()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String mensagemErro = 'Erro ao fazer login';

        if (e.code == 'user-not-found') {
          mensagemErro = 'Usuário não encontrado';
        } else if (e.code == 'wrong-password') {
          mensagemErro = 'Senha incorreta';
        } else if (e.code == 'invalid-email') {
          mensagemErro = 'E-mail inválido';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensagemErro), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _carregando = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0E27),
              const Color(0xFF1A1F3A).withOpacity(0.8),
              const Color(0xFF0F1729),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),

                        // BOTÃO VOLTAR
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // TÍTULO
                        const Text(
                          'Bem-vindo',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // SUBTÍTULO
                        Text(
                          'Entre na sua conta TaskLedger',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 60),

                        // FORMULÁRIO
                        Form(
                          key: _chaveFormulario,
                          child: Column(
                            children: [
                              // CAMPO EMAIL
                              _construirCampoTexto(
                                controlador: _controladorEmail,
                                label: 'E-mail',
                                icon: Icons.email_outlined,
                                tipoTeclado: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                aoEnviar: (_) =>
                                    FocusScope.of(context).nextFocus(),
                                validador: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Digite seu e-mail';
                                  }
                                  if (!value.contains('@')) {
                                    return 'E-mail inválido';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 30),

                              // CAMPO SENHA
                              _construirCampoTexto(
                                controlador: _controladorSenha,
                                label: 'Senha',
                                icon: Icons.lock_outline,
                                ocultarTexto: _ocultarSenha,
                                textInputAction: TextInputAction.done,
                                aoEnviar: (_) {
                                  FocusScope.of(context).unfocus();
                                  if (!_carregando) {
                                    _fazerLogin();
                                  }
                                },
                                iconeSufixo: _temTextoSenha
                                    ? GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _ocultarSenha = !_ocultarSenha;
                                          });
                                        },
                                        child: Icon(
                                          _ocultarSenha
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: const Color(
                                            0xFF6366F1,
                                          ).withOpacity(0.6),
                                        ),
                                      )
                                    : null,
                                validador: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Digite sua senha';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 50),

                              // BOTÃO ENTRAR
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF6366F1,
                                        ).withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _carregando ? null : _fazerLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _carregando
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Entrar',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              // LINK CADASTRO
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Não tem conta? ',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const TelaCadastro(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Cadastre-se',
                                      style: TextStyle(
                                        color: Color(0xFF6366F1),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _construirCampoTexto({
    required TextEditingController controlador,
    required String label,
    required IconData icon,
    TextInputType tipoTeclado = TextInputType.text,
    bool ocultarTexto = false,
    Widget? iconeSufixo,
    String? Function(String?)? validador,
    MaskTextInputFormatter? formatador,
    TextInputAction? textInputAction,
    ValueChanged<String>? aoEnviar,
  }) {
    return TextFormField(
      controller: controlador,
      keyboardType: tipoTeclado,
      inputFormatters: formatador != null ? [formatador] : [],
      obscureText: ocultarTexto,
      validator: validador,
      textInputAction: textInputAction,
      onFieldSubmitted: aoEnviar,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1).withOpacity(0.6)),
        suffixIcon: iconeSufixo,
        filled: true,
        fillColor: const Color(0xFF1A1F3A).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF6366F1).withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.7), width: 2),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
      ),
    );
  }
}
