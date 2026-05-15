import '../models/produto_compra.dart';
import 'tela_cadastro_produto_compra.dart';

class TelaEditarProdutoCompra extends TelaCadastroProdutoCompra {
  const TelaEditarProdutoCompra({super.key, required ProdutoCompra produto})
    : super(produto: produto);
}
