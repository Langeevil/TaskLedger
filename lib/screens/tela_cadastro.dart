import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _controladorNome = TextEditingController();
  final _controladorTelefone = TextEditingController();
  final _controladorEmail = TextEditingController();
  final _controladorSenha = TextEditingController();
  final _controladorConfirmarSenha = TextEditingController();
  final _autenticacao = FirebaseAuth.instance;

  // Formatadores de máscara
  final _mascaraTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _ocultarSenha = true;
  bool _ocultarConfirmarSenha = true;
  bool _temTextoSenha = false;
  bool _temTextoConfirmarSenha = false;

  @override
  void initState() {
    super.initState();
    // Listeners para detectar mudanças nos campos de senha
    _controladorSenha.addListener(() {
      setState(() {
        _temTextoSenha = _controladorSenha.text.isNotEmpty;
      });
    });
    _controladorConfirmarSenha.addListener(() {
      setState(() {
        _temTextoConfirmarSenha = _controladorConfirmarSenha.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorTelefone.dispose();
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    _controladorConfirmarSenha.dispose();
    super.dispose();
  }

  void _cadastrarUsuario() async {
    if (_chaveFormulario.currentState!.validate()) {
      try {
        // 1. Criar usuário no Firebase Authentication
        UserCredential credencial = await _autenticacao
            .createUserWithEmailAndPassword(
              email: _controladorEmail.text.trim(),
              password: _controladorSenha.text,
            );

        // 2. Salvar dados adicionais no Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credencial.user!.uid)
            .set({
              'nome': _controladorNome.text,
              'telefone': _controladorTelefone.text,
              'email': _controladorEmail.text,
              'senha': _controladorSenha.text,
              'confirmaSenha': _controladorConfirmarSenha.text,
              'uid': credencial.user!.uid,
              'dataCriacao': DateTime.now(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cadastro realizado com sucesso!'),
              backgroundColor: Color(0xFF6366F1),
            ),
          );

          // Limpar campos após sucesso
          _controladorNome.clear();
          _controladorTelefone.clear();
          _controladorEmail.clear();
          _controladorSenha.clear();
          _controladorConfirmarSenha.clear();

          // Voltar para a tela anterior
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context);
          });
        }
      } on FirebaseAuthException catch (e) {
        String mensagemErro = 'Erro ao cadastrar';

        if (e.code == 'weak-password') {
          mensagemErro = 'Senha muito fraca';
        } else if (e.code == 'email-already-in-use') {
          mensagemErro = 'E-mail já cadastrado';
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
      }
    }
  }

  bool _temMinimoCaracteres(String senha) => senha.trim().length >= 8;

  bool _temLetraMaiuscula(String senha) => RegExp(r'[A-Z]').hasMatch(senha);

  bool _temLetraMinuscula(String senha) => RegExp(r'[a-z]').hasMatch(senha);

  bool _temNumero(String senha) => RegExp(r'[0-9]').hasMatch(senha);

  bool _temCaractereEspecial(String senha) {
    return RegExp(r'[!@#$%^&*(),.?\":{}|<>_\-\\/\[\];+=~`]').hasMatch(senha);
  }

  bool _senhaAtendeRequisitos(String senha) {
    return _temMinimoCaracteres(senha) &&
        _temLetraMaiuscula(senha) &&
        _temLetraMinuscula(senha) &&
        _temNumero(senha) &&
        _temCaractereEspecial(senha);
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
                          'Criar Conta',
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
                          'Preencha os dados para começar',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // FORMULÁRIO
                        Form(
                          key: _chaveFormulario,
                          child: Column(
                            children: [
                              // CAMPO NOME
                              _construirCampoTexto(
                                controlador: _controladorNome,
                                label: 'Nome',
                                icon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                                aoEnviar: (_) =>
                                    FocusScope.of(context).nextFocus(),
                                validador: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Digite seu nome';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // CAMPO TELEFONE
                              _construirCampoTexto(
                                controlador: _controladorTelefone,
                                label: 'Telefone',
                                icon: Icons.phone_outlined,
                                tipoTeclado: TextInputType.phone,
                                formatador: _mascaraTelefone,
                                textInputAction: TextInputAction.next,
                                aoEnviar: (_) =>
                                    FocusScope.of(context).nextFocus(),
                                validador: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Digite seu telefone';
                                  }
                                  if (value
                                          .replaceAll(RegExp(r'[^0-9]'), '')
                                          .length <
                                      11) {
                                    return 'Telefone inválido';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

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

                              const SizedBox(height: 20),

                              // CAMPO SENHA
                              _construirCampoTexto(
                                controlador: _controladorSenha,
                                label: 'Senha',
                                icon: Icons.lock_outline,
                                ocultarTexto: _ocultarSenha,
                                textInputAction: TextInputAction.next,
                                aoEnviar: (_) =>
                                    FocusScope.of(context).nextFocus(),
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
                                  if (!_senhaAtendeRequisitos(value)) {
                                    return 'Sua senha nao atende aos requisitos';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),
                              _construirCardRequisitosSenha(),

                              const SizedBox(height: 20),

                              // CAMPO REPETIR SENHA
                              _construirCampoTexto(
                                controlador: _controladorConfirmarSenha,
                                label: 'Repetir Senha',
                                icon: Icons.lock_outline,
                                ocultarTexto: _ocultarConfirmarSenha,
                                textInputAction: TextInputAction.done,
                                aoEnviar: (_) {
                                  FocusScope.of(context).unfocus();
                                  _cadastrarUsuario();
                                },
                                iconeSufixo: _temTextoConfirmarSenha
                                    ? GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _ocultarConfirmarSenha =
                                                !_ocultarConfirmarSenha;
                                          });
                                        },
                                        child: Icon(
                                          _ocultarConfirmarSenha
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
                                    return 'Confirme sua senha';
                                  }
                                  if (value != _controladorSenha.text) {
                                    return 'As senhas não conferem';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 40),

                              // BOTÃO CADASTRAR
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
                                    onPressed: () {
                                      _cadastrarUsuario();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.person_add),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Cadastrar',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // LINK VOLTAR
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Já tem conta? ',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: const Text(
                                      'Entre aqui',
                                      style: TextStyle(
                                        color: Color(0xFF6366F1),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 40),
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

  Widget _construirCardRequisitosSenha() {
    final senha = _controladorSenha.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF11182E).withOpacity(0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Requisitos da senha',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _construirItemRequisito(
            'Pelo menos 8 caracteres',
            _temMinimoCaracteres(senha),
          ),
          _construirItemRequisito(
            'Uma letra maiúscula',
            _temLetraMaiuscula(senha),
          ),
          _construirItemRequisito(
            'Uma letra minúscula',
            _temLetraMinuscula(senha),
          ),
          _construirItemRequisito('Um número', _temNumero(senha)),
          _construirItemRequisito(
            'Um caractere especial',
            _temCaractereEspecial(senha),
          ),
        ],
      ),
    );
  }

  Widget _construirItemRequisito(String texto, bool concluido) {
    final cor = concluido ? const Color(0xFF10B981) : Colors.white54;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            concluido
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            size: 18,
            color: cor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: cor,
                fontSize: 13,
                fontWeight: concluido ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
