import 'package:firebase_auth/firebase_auth.dart';

import '../models/usuario_model.dart';
import 'user_service.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, UserService? userService})
    : _auth = auth ?? FirebaseAuth.instance,
      _userService = userService ?? UserService();

  final FirebaseAuth _auth;
  final UserService _userService;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String senha,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: senha);
  }

  Future<void> signOut() => _auth.signOut();

  Future<UserCredential> signUp({
    required String nome,
    required String telefone,
    required String email,
    required String senha,
    required String confirmaSenha,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );

    await _userService.createUser(
      UsuarioModel(
        uid: credential.user!.uid,
        nome: nome,
        telefone: telefone,
        email: email,
        dataCriacao: DateTime.now(),
      ),
    );

    await _userService.updatePasswordSnapshot(
      uid: credential.user!.uid,
      senha: senha,
      confirmaSenha: confirmaSenha,
    );

    return credential;
  }

  Future<void> verifyBeforeUpdateEmail(String email) {
    return _auth.currentUser!.verifyBeforeUpdateEmail(email);
  }

  Future<void> updatePassword({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;

    if (user == null || email == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Usuario nao autenticado.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: senhaAtual,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(novaSenha);
  }
}
