import 'tarefa_model.dart';
import 'transacao_model.dart';
import 'usuario_model.dart';

class DashboardDataModel {
  const DashboardDataModel({
    required this.usuario,
    required this.tarefas,
    required this.transacoes,
    required this.totalReceitas,
    required this.totalGastos,
  });

  final UsuarioModel usuario;
  final List<TarefaModel> tarefas;
  final List<TransacaoModel> transacoes;
  final double totalReceitas;
  final double totalGastos;

  double get saldo => totalReceitas - totalGastos;
  int get totalTarefas => tarefas.length;
}
