import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/menu_item.dart';
import '../../models/option_group.dart';
import '../../models/selected_option.dart';
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import '../../services/menu_service.dart';

class MenuItemDetailsScreen extends StatefulWidget {
  final MenuItem menuItem;
  final VoidCallback? onCartUpdated;

  const MenuItemDetailsScreen({
    Key? key,
    required this.menuItem,
    this.onCartUpdated,
  }) : super(key: key);

  @override
  State<MenuItemDetailsScreen> createState() => _MenuItemDetailsScreenState();
}

class _MenuItemDetailsScreenState extends State<MenuItemDetailsScreen> {
  final MenuService _menuService = MenuService();
  final CartService _cartService = CartService();
  
  List<OptionGroup> _optionGroups = [];
  Map<String, List<SelectedOption>> _selectedOptions = {};
  int _quantity = 1;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadOptionGroups();
  }

  Future<void> _loadOptionGroups() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print('[DEBUG MenuItemDetails] Loading options for menu item: ${widget.menuItem.id}');
      print('[DEBUG MenuItemDetails] Menu item name: ${widget.menuItem.name}');
      print('[DEBUG MenuItemDetails] Menu item category: ${widget.menuItem.category}');
      
      final optionGroups = await _menuService.getMenuItemOptions(widget.menuItem.id);
      
      print('[DEBUG MenuItemDetails] Loaded ${optionGroups.length} option groups');
      for (final group in optionGroups) {
        print('[DEBUG MenuItemDetails] Option group: ${group.name} (${group.options.length} options)');
      }
      
      setState(() {
        _optionGroups = optionGroups;
        _selectedOptions = {};
        
        // Set default selections
        for (final group in _optionGroups) {
          _selectedOptions[group.id] = [];
          
          // Add default options
          final defaultOptions = group.options.where((o) => o.isDefault).toList();
          for (final option in defaultOptions) {
            _selectedOptions[group.id]!.add(SelectedOption.fromOption(option));
          }
          
          // If required group has no defaults, select first available option
          if (group.isRequired && _selectedOptions[group.id]!.isEmpty && group.options.isNotEmpty) {
            _selectedOptions[group.id]!.add(SelectedOption.fromOption(group.options.first));
          }
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load options: $e';
        _isLoading = false;
      });
    }
  }

  void _onOptionSelected(OptionGroup group, Option option) {
    setState(() {
      if (group.selectionType == 'single') {
        // Single selection - replace all selections in this group
        _selectedOptions[group.id] = [SelectedOption.fromOption(option)];
      } else {
        // Multiple selection - toggle this option
        final currentSelections = _selectedOptions[group.id] ?? [];
        final selectedOption = SelectedOption.fromOption(option);
        
        if (currentSelections.any((s) => s.optionId == option.id)) {
          // Remove if already selected
          _selectedOptions[group.id] = currentSelections
              .where((s) => s.optionId != option.id)
              .toList();
        } else {
          // Add if not selected
          _selectedOptions[group.id] = [...currentSelections, selectedOption];
        }
      }
    });
  }

  bool _isOptionSelected(OptionGroup group, Option option) {
    final selections = _selectedOptions[group.id] ?? [];
    return selections.any((s) => s.optionId == option.id);
  }

  bool _isOptionVisible(Option option) {
    // Check if option has dependencies
    if (option.dependsOnOptionId == null) return true;
    
    // Check if dependency is satisfied
    for (final selections in _selectedOptions.values) {
      if (selections.any((s) => s.optionId == option.dependsOnOptionId)) {
        return true;
      }
    }
    return false;
  }

  double _calculateTotalPrice() {
    double basePrice = widget.menuItem.price;
    double optionsPrice = 0.0;
    
    for (final selections in _selectedOptions.values) {
      for (final selection in selections) {
        optionsPrice += selection.priceAdjustment;
      }
    }
    
    return (basePrice + optionsPrice) * _quantity;
  }

  List<SelectedOption> _getAllSelectedOptions() {
    List<SelectedOption> allOptions = [];
    for (final selections in _selectedOptions.values) {
      allOptions.addAll(selections);
    }
    return allOptions;
  }

  bool _canAddToCart() {
    // Check if all required groups have selections
    for (final group in _optionGroups) {
      if (group.isRequired) {
        final selections = _selectedOptions[group.id] ?? [];
        if (selections.isEmpty) return false;
      }
    }
    return true;
  }

  Future<void> _addToCart() async {
    if (!_canAddToCart()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all required options'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final cartItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        menuItemId: widget.menuItem.id,
        name: widget.menuItem.name,
        price: widget.menuItem.price,
        quantity: _quantity,
        selectedOptions: _getAllSelectedOptions(),
      );

      await _cartService.addToCart(cartItem);
      
      if (widget.onCartUpdated != null) {
        widget.onCartUpdated!();
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.menuItem.name} added to cart'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.menuItem.name),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/home?tab=menu');
            }
          },
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/home?tab=menu'),
            icon: const Icon(Icons.restaurant_menu, color: Colors.white),
            label: const Text('Menu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOptionGroups,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Menu Item Header
                            _buildMenuItemHeader(),
                            const SizedBox(height: 24),
                            
                            // Option Groups
                            ..._optionGroups.map((group) => _buildOptionGroup(group)),
                            
                            const SizedBox(height: 24),
                            
                            // Quantity Selector
                            _buildQuantitySelector(),
                            
                            const SizedBox(height: 100), // Space for bottom bar
                          ],
                        ),
                      ),
                    ),
                    
                    // Add to Cart Bottom Bar
                    _buildAddToCartBar(),
                  ],
                ),
    );
  }

  Widget _buildMenuItemHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.menuItem.imageUrl != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(widget.menuItem.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (widget.menuItem.imageUrl != null) const SizedBox(height: 16),
            
            Text(
              widget.menuItem.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              widget.menuItem.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              '\$${widget.menuItem.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionGroup(OptionGroup group) {
    final visibleOptions = group.options.where(_isOptionVisible).toList();
    if (visibleOptions.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (group.iconUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Image.network(
                      group.iconUrl!,
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.fastfood, size: 24),
                    ),
                  ),
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (group.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            if (group.description != null) ...[
              const SizedBox(height: 8),
              Text(
                group.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            ...visibleOptions.map((option) => _buildOptionTile(group, option)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(OptionGroup group, Option option) {
    final isSelected = _isOptionSelected(group, option);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: option.isAvailable ? () => _onOptionSelected(group, option) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
          ),
          child: Row(
            children: [
              if (group.selectionType == 'single')
                Radio<bool>(
                  value: true,
                  groupValue: isSelected,
                  onChanged: option.isAvailable ? (value) => _onOptionSelected(group, option) : null,
                )
              else
                Checkbox(
                  value: isSelected,
                  onChanged: option.isAvailable ? (value) => _onOptionSelected(group, option) : null,
                ),
              
              const SizedBox(width: 12),
              
              if (option.iconUrl != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Image.network(
                    option.iconUrl!,
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.circle, size: 32),
                  ),
                ),
                
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: option.isAvailable ? null : Colors.grey,
                      ),
                    ),
                    if (option.description != null)
                      Text(
                        option.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: option.isAvailable ? Colors.grey[600] : Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              
              if (option.priceAdjustment != 0)
                Text(
                  option.priceAdjustment > 0 
                      ? '+\$${option.priceAdjustment.toStringAsFixed(2)}'
                      : '-\$${(-option.priceAdjustment).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: option.priceAdjustment > 0 ? Colors.green : Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quantity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _quantity.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddToCartBar() {
    final totalPrice = _calculateTotalPrice();
    final canAdd = _canAddToCart();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: canAdd ? _addToCart : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAdd ? Theme.of(context).primaryColor : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Add to Cart - \$${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}