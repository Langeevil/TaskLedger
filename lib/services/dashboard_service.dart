import '../models/dashboard_data_model.dart';
import '../models/transacao_model.dart';
import 'tarefa_service.dart';
import 'transacao_service.dart';
import 'user_service.dart';

class DashboardService {
  DashboardService({
    UserService? userService,
    TarefaService? tarefaService,
    TransacaoService? transacaoService,
  }) : _userService = userService ?? UserService(),
       _tarefaService = tarefaService ?? TarefaService(),
       _transacaoService = transacaoService ?? TransacaoService();

  final UserService _userService;
  final TarefaService _tarefaService;
  final TransacaoService _transacaoService;

  Future<DashboardDataModel> carregarDados({
    required String uid,
    required String email,
  }) async {
    final usuario = await _userService.getOrCreateUser(uid: uid, email: email);
    final tarefas = await _tarefaService.listByUser(uid);
    final transacoes = await _transacaoService.listByUser(uid);

    double totalReceitas = 0;
    double totalGastos = 0;

    for (final transacao in transacoes) {
      _sumTotals(transacao, onReceita: (value) {
        totalReceitas += value;
      }, onDespesa: (value) {
        totalGastos += value;
      });
    }

    return DashboardDataModel(
      usuario: usuario,
      tarefas: tarefas,
      transacoes: transacoes,
      totalReceitas: totalReceitas,
      totalGastos: totalGastos,
    );
  }

  void _sumTotals(
    TransacaoModel transacao, {
    required void Function(double value) onReceita,
    required void Function(double value) onDespesa,
  }) {
    final tipo = transacao.tipo.toLowerCase();
    if (tipo == 'receita') {
      onReceita(transacao.valor);
    } else if (tipo == 'despesa') {
      onDespesa(transacao.valor);
    }
  }
}
