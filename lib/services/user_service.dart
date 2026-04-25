import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/usuario_model.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<UsuarioModel> getOrCreateUser({
    required String uid,
    required String email,
  }) async {
    final document = await _usersCollection.doc(uid).get();

    if (!document.exists) {
      final user = UsuarioModel(
        uid: uid,
        nome: 'Usuário',
        email: email,
        telefone: 'Não informado',
        dataCriacao: DateTime.now(),
      );

      await _usersCollection.doc(uid).set(user.toMap());
      return user;
    }

    return UsuarioModel.fromMap(
      document.data() ?? <String, dynamic>{},
      fallbackUid: uid,
      fallbackEmail: email,
    );
  }

  Future<void> createUser(UsuarioModel user) {
    return _usersCollection.doc(user.uid).set(user.toMap());
  }

  Future<void> updateProfile({
    required String uid,
    required String nome,
    required String telefone,
    String? email,
  }) async {
    final updates = <String, dynamic>{'nome': nome, 'telefone': telefone};
    if (email != null) {
      updates['email'] = email;
    }

    await _usersCollection.doc(uid).update(updates);
  }

  Future<void> updatePasswordSnapshot({
    required String uid,
    required String senha,
    required String confirmaSenha,
  }) {
    return _usersCollection.doc(uid).update({
      'senha': senha,
      'confirmaSenha': confirmaSenha,
    });
  }

  Future<void> updateViewedNotifications({
    required String uid,
    required List<String> notificacoesVisualizadas,
  }) {
    return _usersCollection.doc(uid).update({
      'notificacoesVisualizadas': notificacoesVisualizadas,
    });
  }
}
