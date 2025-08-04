import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  final int quantity;
  final String? specialInstructions;
  final Map<String, dynamic>? customizations;

  CartItem({
    required this.menuItem,
    required this.quantity,
    this.specialInstructions,
    this.customizations,
  });

  double get totalPrice => menuItem.price * quantity;

  CartItem copyWith({
    MenuItem? menuItem,
    int? quantity,
    String? specialInstructions,
    Map<String, dynamic>? customizations,
  }) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      customizations: customizations ?? this.customizations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_item': menuItem.toJson(),
      'quantity': quantity,
      'special_instructions': specialInstructions,
      'customizations': customizations,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      menuItem: MenuItem.fromJson(json['menu_item'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      specialInstructions: json['special_instructions'] as String?,
      customizations: json['customizations'] as Map<String, dynamic>?,
    );
  }
} 