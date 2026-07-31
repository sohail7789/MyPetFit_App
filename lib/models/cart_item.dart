import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}
