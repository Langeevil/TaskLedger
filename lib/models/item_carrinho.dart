import 'produto_compra.dart';

class ItemCarrinho {
  ItemCarrinho({required this.produto, this.quantidade = 1});

  final ProdutoCompra produto;
  int quantidade;

  double get subtotal => produto.preco * quantidade;
}
