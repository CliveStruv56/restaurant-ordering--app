import 'selected_option.dart';

class CartItem {
  final String id;
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? specialInstructions;
  final List<SelectedOption> selectedOptions;
  final Map<String, dynamic>? customizations;

  CartItem({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.specialInstructions,
    this.selectedOptions = const [],
    this.customizations,
  });

  double get basePrice => price * quantity;
  double get optionsPrice {
    double total = 0.0;
    for (final option in selectedOptions) {
      total += option.priceAdjustment;
    }
    return total * quantity;
  }
  double get totalPrice => basePrice + optionsPrice;

  CartItem copyWith({
    String? id,
    String? menuItemId,
    String? name,
    double? price,
    int? quantity,
    String? specialInstructions,
    List<SelectedOption>? selectedOptions,
    Map<String, dynamic>? customizations,
  }) {
    return CartItem(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      customizations: customizations ?? this.customizations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_item_id': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'special_instructions': specialInstructions,
      'selected_options': selectedOptions.map((option) => option.toJson()).toList(),
      'customizations': customizations,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      menuItemId: json['menu_item_id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] is int) 
          ? (json['price'] as int).toDouble() 
          : (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
      specialInstructions: json['special_instructions'] as String?,
      selectedOptions: json['selected_options'] != null
          ? (json['selected_options'] as List)
              .map((option) => SelectedOption.fromJson(option))
              .toList()
          : [],
      customizations: json['customizations'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'CartItem(id: $id, name: $name, quantity: $quantity, totalPrice: $totalPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 