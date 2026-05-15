import 'produto_planejado.dart';

class ItemCarrinho {
  ItemCarrinho({required this.produto, this.quantidade = 1});

  final ProdutoPlanejado produto;
  int quantidade;

  double get subtotal => produto.preco * quantidade;
}
