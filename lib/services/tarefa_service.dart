import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tarefa_model.dart';
import '../utils/app_date_utils.dart';

class TarefaService {
  TarefaService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _firestore.collection('tarefas');

  Future<List<TarefaModel>> listByUser(String uid) async {
    final query = await _tasksCollection.where('uid', isEqualTo: uid).get();

    final tasks = query.docs
        .map((doc) => TarefaModel.fromMap(doc.data(), id: doc.id))
        .toList();

    tasks.sort((a, b) => AppDateUtils.compareNullable(a.prazo, b.prazo));
    return tasks;
  }

  Future<void> create(TarefaModel task) {
    return _tasksCollection.add({
      'uid': task.uid,
      'titulo': task.titulo,
      'descricao': task.descricao,
      'status': task.status,
      'prioridade': task.prioridade,
      'prazo': task.prazo != null ? Timestamp.fromDate(task.prazo!) : null,
      'atualizadoEm': FieldValue.serverTimestamp(),
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(TarefaModel task) {
    return _tasksCollection.doc(task.id).update({
      'uid': task.uid,
      'titulo': task.titulo,
      'descricao': task.descricao,
      'status': task.status,
      'prioridade': task.prioridade,
      'prazo': task.prazo != null ? Timestamp.fromDate(task.prazo!) : null,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus({
    required String id,
    required String status,
  }) {
    return _tasksCollection.doc(id).update({
      'status': status,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) => _tasksCollection.doc(id).delete();
}
