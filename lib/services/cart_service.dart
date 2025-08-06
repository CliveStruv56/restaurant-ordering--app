import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/selected_option.dart';

class CartService {
  static const String _cartKey = 'cart_items';

  // Helper method to compare selected options
  bool _areOptionsEqual(List<SelectedOption> options1, List<SelectedOption> options2) {
    if (options1.length != options2.length) return false;
    
    for (final option1 in options1) {
      final matchingOption = options2.firstWhere(
        (option2) => option1.optionId == option2.optionId && 
                    option1.optionGroupId == option2.optionGroupId,
        orElse: () => SelectedOption(
          optionId: '',
          optionGroupId: '',
          optionName: '',
          priceAdjustment: 0,
        ),
      );
      if (matchingOption.optionId.isEmpty) return false;
    }
    
    return true;
  }
  
  // Get cart items from local storage
  Future<List<CartItem>> getCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      
      if (cartJson == null) return [];
      
      final List<dynamic> cartList = json.decode(cartJson);
      return cartList.map((item) => CartItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // Save cart items to local storage
  Future<void> saveCartItems(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(items.map((item) => item.toJson()).toList());
      await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      throw Exception('Failed to save cart items: $e');
    }
  }

  // Add item to cart (new signature with CartItem)
  Future<void> addToCart(CartItem cartItem) async {
    try {
      final cartItems = await getCartItems();
      
      // For items with options, we need to compare the full configuration
      // Items with different options should be treated as separate items
      final existingIndex = cartItems.indexWhere((item) => 
        item.menuItemId == cartItem.menuItemId && 
        _areOptionsEqual(item.selectedOptions, cartItem.selectedOptions));
      
      if (existingIndex != -1) {
        // Update quantity of existing item
        final existingItem = cartItems[existingIndex];
        cartItems[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + cartItem.quantity,
        );
      } else {
        // Add new item
        cartItems.add(cartItem);
      }
      
      await saveCartItems(cartItems);
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  // Legacy method for backward compatibility
  Future<void> addMenuItemToCart(MenuItem menuItem, {int quantity = 1, String? specialInstructions}) async {
    final cartItem = CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      menuItemId: menuItem.id,
      name: menuItem.name,
      price: menuItem.price,
      quantity: quantity,
      specialInstructions: specialInstructions,
    );
    await addToCart(cartItem);
  }

  // Remove item from cart by cart item ID
  Future<void> removeFromCart(String cartItemId) async {
    try {
      final cartItems = await getCartItems();
      cartItems.removeWhere((item) => item.id == cartItemId);
      await saveCartItems(cartItems);
    } catch (e) {
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  // Update item quantity by cart item ID
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    try {
      final cartItems = await getCartItems();
      final index = cartItems.indexWhere((item) => item.id == cartItemId);
      
      if (index != -1) {
        if (quantity <= 0) {
          cartItems.removeAt(index);
        } else {
          cartItems[index] = cartItems[index].copyWith(quantity: quantity);
        }
        await saveCartItems(cartItems);
      }
    } catch (e) {
      throw Exception('Failed to update quantity: $e');
    }
  }

  // Update special instructions by cart item ID
  Future<void> updateSpecialInstructions(String cartItemId, String? specialInstructions) async {
    try {
      final cartItems = await getCartItems();
      final index = cartItems.indexWhere((item) => item.id == cartItemId);
      
      if (index != -1) {
        cartItems[index] = cartItems[index].copyWith(specialInstructions: specialInstructions);
        await saveCartItems(cartItems);
      }
    } catch (e) {
      throw Exception('Failed to update special instructions: $e');
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      await saveCartItems([]);
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  // Get cart total
  Future<double> getCartTotal() async {
    try {
      final cartItems = await getCartItems();
      return cartItems.fold<double>(0.0, (total, item) => total + item.totalPrice);
    } catch (e) {
      return 0.0;
    }
  }

  // Get cart item count
  Future<int> getCartItemCount() async {
    try {
      final cartItems = await getCartItems();
      return cartItems.fold<int>(0, (total, item) => total + item.quantity);
    } catch (e) {
      return 0;
    }
  }

  // Check if menu item is in cart
  Future<bool> isItemInCart(String menuItemId) async {
    try {
      final cartItems = await getCartItems();
      return cartItems.any((item) => item.menuItemId == menuItemId);
    } catch (e) {
      return false;
    }
  }

  // Get total quantity for a menu item (sum of all variants)
  Future<int> getItemQuantity(String menuItemId) async {
    try {
      final cartItems = await getCartItems();
      return cartItems
          .where((item) => item.menuItemId == menuItemId)
          .fold<int>(0, (total, item) => total + item.quantity);
    } catch (e) {
      return 0;
    }
  }
} 