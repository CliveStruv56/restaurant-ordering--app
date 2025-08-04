import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartService {
  static const String _cartKey = 'cart_items';
  
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

  // Add item to cart
  Future<void> addToCart(MenuItem menuItem, {int quantity = 1, String? specialInstructions}) async {
    try {
      final cartItems = await getCartItems();
      
      // Check if item already exists in cart
      final existingIndex = cartItems.indexWhere((item) => item.menuItem.id == menuItem.id);
      
      if (existingIndex != -1) {
        // Update quantity of existing item
        final existingItem = cartItems[existingIndex];
        cartItems[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
        );
      } else {
        // Add new item
        cartItems.add(CartItem(
          menuItem: menuItem,
          quantity: quantity,
          specialInstructions: specialInstructions,
        ));
      }
      
      await saveCartItems(cartItems);
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String menuItemId) async {
    try {
      final cartItems = await getCartItems();
      cartItems.removeWhere((item) => item.menuItem.id == menuItemId);
      await saveCartItems(cartItems);
    } catch (e) {
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  // Update item quantity
  Future<void> updateQuantity(String menuItemId, int quantity) async {
    try {
      final cartItems = await getCartItems();
      final index = cartItems.indexWhere((item) => item.menuItem.id == menuItemId);
      
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

  // Update special instructions
  Future<void> updateSpecialInstructions(String menuItemId, String? specialInstructions) async {
    try {
      final cartItems = await getCartItems();
      final index = cartItems.indexWhere((item) => item.menuItem.id == menuItemId);
      
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

  // Check if item is in cart
  Future<bool> isItemInCart(String menuItemId) async {
    try {
      final cartItems = await getCartItems();
      return cartItems.any((item) => item.menuItem.id == menuItemId);
    } catch (e) {
      return false;
    }
  }

  // Get item quantity in cart
  Future<int> getItemQuantity(String menuItemId) async {
    try {
      final cartItems = await getCartItems();
      final item = cartItems.firstWhere(
        (item) => item.menuItem.id == menuItemId,
        orElse: () => CartItem(menuItem: MenuItem(id: '', name: '', description: '', price: 0, category: ''), quantity: 0),
      );
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }
} 