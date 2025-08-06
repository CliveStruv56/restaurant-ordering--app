import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import '../../services/user_service.dart';
import '../../utils/currency.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onCartUpdated;
  final VoidCallback? onSwitchToMenu;
  
  const CartScreen({super.key, this.onCartUpdated, this.onSwitchToMenu});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final UserService _userService = UserService();
  
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  double _total = 0.0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
    _checkAdminStatus();
  }


  Future<void> _loadCart() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final cartItems = await _cartService.getCartItems();
      final total = await _cartService.getCartTotal();

      setState(() {
        _cartItems = cartItems;
        _total = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        await _cartService.removeFromCart(item.id);
      } else {
        await _cartService.updateQuantity(item.id, newQuantity);
      }
      await _loadCart(); // Reload cart data
      
      // Notify parent that cart was updated
      widget.onCartUpdated?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update quantity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      await _cartService.removeFromCart(item.id);
      await _loadCart(); // Reload cart data
      
      // Notify parent that cart was updated
      widget.onCartUpdated?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed from cart'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearCart() async {
    try {
      await _cartService.clearCart();
      await _loadCart(); // Reload cart data
      
      // Notify parent that cart was updated
      widget.onCartUpdated?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart cleared'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _proceedToCheckout() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to checkout screen
    context.go('/checkout');
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await _userService.isAdmin();
      setState(() {
        _isAdmin = isAdmin;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                context.go('/admin');
              },
              tooltip: 'Admin Panel',
            ),
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearCart,
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCartContent(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some delicious items to get started!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: widget.onSwitchToMenu ?? () => context.go('/home?tab=menu'),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Browse Menu'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        // Cart items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item image placeholder (since imageUrl is not in CartItem anymore)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.restaurant),
                      ),
                      const SizedBox(width: 12),
                      
                      // Item details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            
                            // Show selected options if any
                            if (item.selectedOptions.isNotEmpty) ...[
                              ...item.selectedOptions.map((option) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '• ${option.optionName}${option.priceAdjustment > 0 ? ' (+${CurrencyUtils.formatPrice(option.priceAdjustment)})' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )),
                              const SizedBox(height: 4),
                            ],
                            
                            Text(
                              '${CurrencyUtils.formatPrice(item.basePrice / item.quantity)} each',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            if (item.specialInstructions?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Note: ${item.specialInstructions}',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Quantity controls
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _updateQuantity(item, item.quantity - 1),
                                icon: const Icon(Icons.remove),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  minimumSize: const Size(32, 32),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _updateQuantity(item, item.quantity + 1),
                                icon: const Icon(Icons.add),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  minimumSize: const Size(32, 32),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            CurrencyUtils.formatPrice(item.totalPrice),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      
                      // Remove button
                      IconButton(
                        onPressed: () => _removeItem(item),
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Order summary
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total (${_cartItems.length} items)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    CurrencyUtils.formatPrice(_total),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceedToCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Proceed to Checkout',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 