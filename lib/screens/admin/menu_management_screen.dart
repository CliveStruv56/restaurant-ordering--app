import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/menu_item.dart';
import '../../services/menu_service.dart';
import '../../services/user_service.dart';
import '../../utils/currency.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final MenuService _menuService = MenuService();
  final UserService _userService = UserService();
  
  List<MenuItem> _menuItems = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _selectedCategoryId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final isAdmin = await _userService.isAdmin();
      if (isAdmin) {
        setState(() {
          _isAdmin = true;
        });
        await _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin access required'),
              backgroundColor: Colors.red,
            ),
          );
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/home');
      }
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

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
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<MenuItem> get _filteredMenuItems {
    List<MenuItem> filtered = _menuItems;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedCategoryId != null) {
      final selectedCategory = _categories.firstWhere(
        (cat) => cat['id'] == _selectedCategoryId,
        orElse: () => <String, dynamic>{},
      );
      filtered = filtered.where((item) {
        return item.category == selectedCategory['name'];
      }).toList();
    }

    return filtered;
  }

  Future<void> _deleteMenuItem(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _menuService.deleteMenuItem(item.id);
        
        // Remove from local list
        setState(() {
          _menuItems.removeWhere((i) => i.id == item.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editMenuItem(MenuItem item) {
    context.go('/admin/menu/edit/${item.id}');
  }

  void _addNewMenuItem() {
    context.go('/admin/menu/add');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewMenuItem,
            tooltip: 'Add New Item',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isAdmin
              ? const Center(child: Text('Access Denied'))
              : Column(
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
                          itemCount: _categories.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
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
                      child: _filteredMenuItems.isEmpty
                          ? const Center(child: Text('No items found'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _filteredMenuItems.length,
                              itemBuilder: (context, index) {
                                final menuItem = _filteredMenuItems[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16.0),
                                  child: ListTile(
                                    leading: menuItem.imageUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              menuItem.imageUrl!,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.restaurant),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.restaurant),
                                          ),
                                    title: Text(
                                      menuItem.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(menuItem.description),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Chip(
                                              label: Text(CurrencyUtils.formatPrice(menuItem.price)),
                                              backgroundColor: Colors.green[100],
                                            ),
                                            const SizedBox(width: 8),
                                            Chip(
                                              label: Text(menuItem.category),
                                              backgroundColor: Colors.blue[100],
                                            ),
                                            if (!menuItem.isAvailable)
                                              const Chip(
                                                label: Text('Unavailable'),
                                                backgroundColor: Colors.red,
                                                labelStyle: TextStyle(color: Colors.white),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            _editMenuItem(menuItem);
                                            break;
                                          case 'delete':
                                            _deleteMenuItem(menuItem);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
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