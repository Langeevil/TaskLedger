import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transacao_model.dart';
import '../utils/app_date_utils.dart';

class TransacaoService {
  TransacaoService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firestore.collection('transacoes');

  Future<List<TransacaoModel>> listByUser(String uid) async {
    final query = await _transactionsCollection
        .where('uid', isEqualTo: uid)
        .get();

    final transactions = query.docs
        .map((doc) => TransacaoModel.fromMap(doc.data(), id: doc.id))
        .toList();

    transactions.sort((a, b) => AppDateUtils.compareNullable(b.data, a.data));
    return transactions;
  }

  Future<void> create(TransacaoModel transaction) {
    return _transactionsCollection.add({
      'uid': transaction.uid,
      'titulo': transaction.titulo,
      'tipo': transaction.tipo,
      'categoria': transaction.categoria,
      'valor': transaction.valor,
      'data': transaction.data != null
          ? Timestamp.fromDate(transaction.data!)
          : null,
      'observacao': transaction.observacao,
      'comprovanteBase64': transaction.comprovanteBase64,
      'atualizadoEm': FieldValue.serverTimestamp(),
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(TransacaoModel transaction) {
    return _transactionsCollection.doc(transaction.id).update({
      'uid': transaction.uid,
      'titulo': transaction.titulo,
      'tipo': transaction.tipo,
      'categoria': transaction.categoria,
      'valor': transaction.valor,
      'data': transaction.data != null
          ? Timestamp.fromDate(transaction.data!)
          : null,
      'observacao': transaction.observacao,
      'comprovanteBase64': transaction.comprovanteBase64,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) => _transactionsCollection.doc(id).delete();
}
