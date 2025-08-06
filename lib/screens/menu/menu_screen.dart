import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/menu_item.dart';
import '../../services/menu_service.dart';
import '../../services/user_service.dart';
import '../../utils/currency.dart';
import 'package:go_router/go_router.dart';
import 'menu_item_details_screen.dart';

class MenuScreen extends StatefulWidget {
  final VoidCallback? onCartUpdated;
  
  const MenuScreen({super.key, this.onCartUpdated});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final MenuService _menuService = MenuService();
  final UserService _userService = UserService();

  List<MenuItem> _menuItems = [];
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkAdminStatus();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load categories and menu items in parallel
      final categoriesResult = await _menuService.getCategories();
      final menuItemsResult = await _menuService.getMenuItems();

      setState(() {
        _categories = categoriesResult;
        _menuItems = menuItemsResult;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load menu: $e';
      });
    }
  }

  List<MenuItem> get _filteredMenuItems {
    List<MenuItem> filtered = _menuItems;

    // If there's a search query, search across ALL categories
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               item.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    } else {
      // Only apply category filter if there's no search query
      if (_selectedCategoryId != null) {
        filtered = filtered.where((item) {
          // Find the category name for the selected category ID
          final selectedCategory = _categories.firstWhere(
            (cat) => cat['id'] == _selectedCategoryId,
            orElse: () => <String, dynamic>{},
          );
          return item.category == selectedCategory['name'];
        }).toList();
      }
    }

    return filtered;
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

  void _navigateToItemDetails(MenuItem menuItem) {
    context.go('/menu-item/${menuItem.id}', extra: {
      'menuItem': menuItem,
      'onCartUpdated': widget.onCartUpdated,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
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
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search menu items...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Category filter
          if (_categories.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1, // +1 for "All" option
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // "All" option
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategoryId == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId = null;
                          });
                        },
                      ),
                    );
                  }

                  final category = _categories[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(category['name']),
                      selected: _selectedCategoryId == category['id'],
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryId = selected ? category['id'] : null;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

          // Menu items
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredMenuItems.isEmpty
                        ? const Center(child: Text('No items found'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _filteredMenuItems.length,
                            itemBuilder: (context, index) {
                              final menuItem = _filteredMenuItems[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16.0),
                                child: InkWell(
                                  onTap: () => _navigateToItemDetails(menuItem),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                      // Image
                                      if (menuItem.imageUrl != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CachedNetworkImage(
                                            imageUrl: menuItem.imageUrl!,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              width: 70,
                                              height: 70,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.restaurant),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              width: 70,
                                              height: 70,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.error),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 12),
                                      
                                      // Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              menuItem.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              menuItem.description,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Chip(
                                                    label: Text(
                                                      menuItem.category,
                                                      style: const TextStyle(fontSize: 10),
                                                    ),
                                                    backgroundColor: Colors.orange[100],
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  CurrencyUtils.formatPrice(menuItem.price),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Add to cart button
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        height: 36,
                                        child: ElevatedButton(
                                          onPressed: () => _navigateToItemDetails(menuItem),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.deepOrange,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                          ),
                                          child: const Text('Details'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
} 