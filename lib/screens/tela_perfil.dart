import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';

class TelaPerfil extends StatelessWidget {
  const TelaPerfil({
    super.key,
    required this.dadosUsuario,
    required this.onPerfilAtualizado,
  });

  final Map<String, dynamic> dadosUsuario;
  final ValueChanged<Map<String, dynamic>> onPerfilAtualizado;

  String _obterPrimeiroNome(String? nomeCompleto) {
    if (nomeCompleto == null || nomeCompleto.trim().isEmpty) {
      return 'Usuário';
    }

    return nomeCompleto.trim().split(RegExp(r'\s+')).first;
  }

  void _abrirModalEditarPerfil(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ModalEditarPerfil(
          dadosUsuario: dadosUsuario,
          onPerfilAtualizado: onPerfilAtualizado,
        );
      },
    );
  }

  void _abrirModalAlterarSenha(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _ModalAlterarSenha();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perfil',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _obterPrimeiroNome(dadosUsuario['nome']?.toString()),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dadosUsuario['email'] ?? 'email@exemplo.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _construirCampoInfoPerfil(
              label: 'Nome',
              valor: dadosUsuario['nome'] ?? 'Não informado',
              icone: Icons.person,
            ),
            const SizedBox(height: 16),
            _construirCampoInfoPerfil(
              label: 'E-mail',
              valor: dadosUsuario['email'] ?? 'Não informado',
              icone: Icons.email,
            ),
            const SizedBox(height: 16),
            _construirCampoInfoPerfil(
              label: 'Telefone',
              valor: dadosUsuario['telefone'] ?? 'Não informado',
              icone: Icons.phone,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _abrirModalEditarPerfil(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text(
                    'Editar Perfil',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _abrirModalAlterarSenha(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    width: 1.5,
                  ),
                  backgroundColor: const Color(0xFF1A1F3A).withOpacity(0.55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.lock_reset),
                label: const Text(
                  'Alterar Senha',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _construirCampoInfoPerfil({
    required String label,
    required String valor,
    required IconData icone,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.5),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: const Color(0xFF6366F1), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalEditarPerfil extends StatefulWidget {
  const _ModalEditarPerfil({
    required this.dadosUsuario,
    required this.onPerfilAtualizado,
  });

  final Map<String, dynamic> dadosUsuario;
  final ValueChanged<Map<String, dynamic>> onPerfilAtualizado;

  @override
  State<_ModalEditarPerfil> createState() => _ModalEditarPerfilState();
}

class _ModalEditarPerfilState extends State<_ModalEditarPerfil> {
  final _formKey = GlobalKey<FormState>();
  final _controladorNome = TextEditingController();
  final _controladorEmail = TextEditingController();
  final _controladorTelefone = TextEditingController();
  final _authService = AuthService();
  final _userService = UserService();
  final _mascaraTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool _salvando = false;
  bool _perfilAtualizado = false;
  String _mensagemSucesso = 'Seus dados foram atualizados com sucesso.';

  @override
  void initState() {
    super.initState();
    _controladorNome.text = widget.dadosUsuario['nome']?.toString() ?? '';
    _controladorEmail.text = widget.dadosUsuario['email']?.toString() ?? '';
    _controladorTelefone.text =
        widget.dadosUsuario['telefone']?.toString() ?? '';
  }

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorEmail.dispose();
    _controladorTelefone.dispose();
    super.dispose();
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final usuario = _authService.currentUser;
    final uid = widget.dadosUsuario['uid']?.toString();

    if (usuario == null || uid == null || uid.isEmpty) {
      _mostrarMensagem('Usuário não autenticado.');
      return;
    }

    final nome = _controladorNome.text.trim();
    final email = _controladorEmail.text.trim();
    final telefone = _controladorTelefone.text.trim();
    final emailAtual = widget.dadosUsuario['email']?.toString().trim() ?? '';

    setState(() {
      _salvando = true;
    });

    try {
      final atualizacoes = <String, dynamic>{
        'nome': nome,
        'telefone': telefone,
      };

      if (email != emailAtual) {
        await _authService.verifyBeforeUpdateEmail(email);
        atualizacoes['email'] = email;
      }

      await _userService.updateProfile(
        uid: uid,
        nome: nome,
        telefone: telefone,
        email: email != emailAtual ? email : null,
      );

      if (!mounted) {
        return;
      }

      widget.onPerfilAtualizado({...atualizacoes, 'uid': uid});

      final houveAlteracaoEmail = email != emailAtual;

      setState(() {
        _salvando = false;
        _perfilAtualizado = true;
        _mensagemSucesso = houveAlteracaoEmail
            ? 'Confirme o novo e-mail na sua caixa de entrada.'
            : 'Seus dados foram atualizados com sucesso.';
      });

      await Future.delayed(const Duration(milliseconds: 1800));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      if (houveAlteracaoEmail) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Perfil atualizado. Confirme o novo e-mail na sua caixa de entrada.',
            ),
            backgroundColor: Color(0xFF6366F1),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      if (e.code == 'requires-recent-login') {
        _mostrarMensagem('Faça login novamente para alterar seu e-mail.');
      } else if (e.code == 'email-already-in-use') {
        _mostrarMensagem('Este e-mail já está em uso.');
      } else if (e.code == 'invalid-email') {
        _mostrarMensagem('Digite um e-mail válido.');
      } else {
        _mostrarMensagem('Não foi possível atualizar o perfil.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _mostrarMensagem('Ocorreu um erro ao atualizar o perfil.');
    } finally {
      if (mounted && !_perfilAtualizado) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alturaMaxima = MediaQuery.of(context).size.height * 0.65;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(maxHeight: alturaMaxima),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1729),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              child: _perfilAtualizado
                  ? _construirSucessoPerfil()
                  : SingleChildScrollView(
                      key: const ValueKey('formulario_edicao'),
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 44,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Editar Perfil',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Atualize seus dados principais.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.65),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _construirCampoTexto(
                              controlador: _controladorNome,
                              label: 'Nome',
                              icone: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              aoEnviar: (_) =>
                                  FocusScope.of(context).nextFocus(),
                              validador: (valor) {
                                if (valor == null || valor.trim().isEmpty) {
                                  return 'Digite seu nome';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _construirCampoTexto(
                              controlador: _controladorEmail,
                              label: 'E-mail',
                              icone: Icons.email_outlined,
                              tipoTeclado: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              aoEnviar: (_) =>
                                  FocusScope.of(context).nextFocus(),
                              validador: (valor) {
                                if (valor == null || valor.trim().isEmpty) {
                                  return 'Digite seu e-mail';
                                }
                                if (!valor.contains('@')) {
                                  return 'Digite um e-mail válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _construirCampoTexto(
                              controlador: _controladorTelefone,
                              label: 'Telefone',
                              icone: Icons.phone_outlined,
                              tipoTeclado: TextInputType.phone,
                              formatador: _mascaraTelefone,
                              textInputAction: TextInputAction.done,
                              aoEnviar: (_) {
                                FocusScope.of(context).unfocus();
                                if (!_salvando) {
                                  _salvarPerfil();
                                }
                              },
                              validador: (valor) {
                                if (valor == null || valor.trim().isEmpty) {
                                  return 'Digite seu telefone';
                                }
                                if (valor
                                        .replaceAll(RegExp(r'[^0-9]'), '')
                                        .length <
                                    11) {
                                  return 'Digite um telefone válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),
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
                                      ).withOpacity(0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _salvando ? null : _salvarPerfil,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _salvando
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text(
                                          'Salvar alterações',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirCampoTexto({
    required TextEditingController controlador,
    required String label,
    required IconData icone,
    TextInputType tipoTeclado = TextInputType.text,
    MaskTextInputFormatter? formatador,
    required String? Function(String?) validador,
    TextInputAction? textInputAction,
    ValueChanged<String>? aoEnviar,
  }) {
    return TextFormField(
      controller: controlador,
      keyboardType: tipoTeclado,
      inputFormatters: formatador != null ? [formatador] : [],
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
        prefixIcon: Icon(
          icone,
          color: const Color(0xFF6366F1).withOpacity(0.7),
        ),
        filled: true,
        fillColor: const Color(0xFF1A1F3A).withOpacity(0.75),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF6366F1).withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF6366F1).withOpacity(0.25),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.6)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.8), width: 2),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
      ),
    );
  }

  Widget _construirSucessoPerfil() {
    return SizedBox(
      key: const ValueKey('sucesso_edicao'),
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Perfil Atualizado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _mensagemSucesso,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalAlterarSenha extends StatefulWidget {
  const _ModalAlterarSenha();

  @override
  State<_ModalAlterarSenha> createState() => _ModalAlterarSenhaState();
}

class _ModalAlterarSenhaState extends State<_ModalAlterarSenha> {
  final _formKey = GlobalKey<FormState>();
  final _controladorSenhaAtual = TextEditingController();
  final _controladorNovaSenha = TextEditingController();
  final _controladorConfirmarSenha = TextEditingController();
  final _authService = AuthService();
  final _userService = UserService();

  bool _ocultarSenhaAtual = true;
  bool _ocultarNovaSenha = true;
  bool _ocultarConfirmarSenha = true;
  bool _salvando = false;
  bool _senhaAlterada = false;

  @override
  void dispose() {
    _controladorSenhaAtual.dispose();
    _controladorNovaSenha.dispose();
    _controladorConfirmarSenha.dispose();
    super.dispose();
  }

  Future<void> _confirmarAlteracao() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final usuario = _authService.currentUser;
    final email = usuario?.email;
    final uid = usuario?.uid;

    if (usuario == null || email == null || uid == null || uid.isEmpty) {
      _mostrarMensagem('Usuário não autenticado.');
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final novaSenha = _controladorNovaSenha.text.trim();
      await _authService.updatePassword(
        senhaAtual: _controladorSenhaAtual.text.trim(),
        novaSenha: novaSenha,
      );
      await _userService.updatePasswordSnapshot(
        uid: uid,
        senha: novaSenha,
        confirmaSenha: _controladorConfirmarSenha.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _salvando = false;
        _senhaAlterada = true;
      });

      await Future.delayed(const Duration(milliseconds: 1800));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _salvando = false;
      });

      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _mostrarMensagem('A senha atual está incorreta.');
      } else if (e.code == 'weak-password') {
        _mostrarMensagem('A nova senha está muito fraca.');
      } else if (e.code == 'requires-recent-login') {
        _mostrarMensagem('Faça login novamente para alterar sua senha.');
      } else {
        _mostrarMensagem('Não foi possível alterar a senha.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _salvando = false;
      });
      _mostrarMensagem('Ocorreu um erro ao alterar a senha.');
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alturaMaxima = MediaQuery.of(context).size.height * 0.62;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(maxHeight: alturaMaxima),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1729),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              child: _senhaAlterada
                  ? _construirSucesso()
                  : _construirFormulario(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirFormulario(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('formulario'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Alterar Senha',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Digite sua senha atual e defina uma nova senha.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 24),
            _construirCampoSenha(
              controlador: _controladorSenhaAtual,
              label: 'Senha atual',
              ocultarTexto: _ocultarSenhaAtual,
              textInputAction: TextInputAction.next,
              aoEnviar: (_) => FocusScope.of(context).nextFocus(),
              onAlternarVisibilidade: () {
                setState(() {
                  _ocultarSenhaAtual = !_ocultarSenhaAtual;
                });
              },
              validador: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Digite sua senha atual';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _construirCampoSenha(
              controlador: _controladorNovaSenha,
              label: 'Nova senha',
              ocultarTexto: _ocultarNovaSenha,
              textInputAction: TextInputAction.next,
              aoEnviar: (_) => FocusScope.of(context).nextFocus(),
              onAlternarVisibilidade: () {
                setState(() {
                  _ocultarNovaSenha = !_ocultarNovaSenha;
                });
              },
              validador: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Digite a nova senha';
                }
                if (valor.trim().length < 6) {
                  return 'A senha deve ter pelo menos 6 caracteres';
                }
                if (valor.trim() == _controladorSenhaAtual.text.trim()) {
                  return 'A nova senha deve ser diferente da atual';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _construirCampoSenha(
              controlador: _controladorConfirmarSenha,
              label: 'Confirmar senha',
              ocultarTexto: _ocultarConfirmarSenha,
              textInputAction: TextInputAction.done,
              aoEnviar: (_) {
                FocusScope.of(context).unfocus();
                if (!_salvando) {
                  _confirmarAlteracao();
                }
              },
              onAlternarVisibilidade: () {
                setState(() {
                  _ocultarConfirmarSenha = !_ocultarConfirmarSenha;
                });
              },
              validador: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Confirme a nova senha';
                }
                if (valor.trim() != _controladorNovaSenha.text.trim()) {
                  return 'As senhas não conferem';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _salvando ? null : _confirmarAlteracao,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _salvando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Confirmar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirCampoSenha({
    required TextEditingController controlador,
    required String label,
    required bool ocultarTexto,
    required VoidCallback onAlternarVisibilidade,
    required String? Function(String?) validador,
    TextInputAction? textInputAction,
    ValueChanged<String>? aoEnviar,
  }) {
    return TextFormField(
      controller: controlador,
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
        prefixIcon: Icon(
          Icons.lock_outline,
          color: const Color(0xFF6366F1).withOpacity(0.7),
        ),
        suffixIcon: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          descendantsAreFocusable: false,
          child: IconButton(
            onPressed: onAlternarVisibilidade,
            icon: Icon(
              ocultarTexto ? Icons.visibility_off : Icons.visibility,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF1A1F3A).withOpacity(0.75),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF6366F1).withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF6366F1).withOpacity(0.25),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.6)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.8), width: 2),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
      ),
    );
  }

  Widget _construirSucesso() {
    return SizedBox(
      key: const ValueKey('sucesso_senha'),
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Senha Alterada',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sua senha foi atualizada com sucesso.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
