import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/menu_item.dart';
import '../../services/menu_service.dart';

class MenuItemFormScreen extends StatefulWidget {
  final MenuItem? menuItem; // null for new item, not null for editing
  final String? menuItemId; // ID for loading existing item

  const MenuItemFormScreen({super.key, this.menuItem, this.menuItemId});

  @override
  State<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends State<MenuItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final MenuService _menuService = MenuService();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Form state
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  bool _isAvailable = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.menuItem != null) {
      _initializeForm();
    } else if (widget.menuItemId != null) {
      _loadMenuItem();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _menuService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _initializeForm() {
    if (widget.menuItem != null) {
      // Editing existing item
      _nameController.text = widget.menuItem!.name;
      _descriptionController.text = widget.menuItem!.description;
      _priceController.text = widget.menuItem!.price.toString();
      _imageUrlController.text = widget.menuItem!.imageUrl ?? '';
      _isAvailable = widget.menuItem!.isAvailable;

      // Find the category ID
      final category = _categories.firstWhere(
        (cat) => cat['name'] == widget.menuItem!.category,
        orElse: () => <String, dynamic>{},
      );
      _selectedCategoryId = category['id'];
    }
  }

  Future<void> _loadMenuItem() async {
    try {
      final menuItem = await _menuService.getMenuItemById(widget.menuItemId!);
      setState(() {
        _nameController.text = menuItem.name;
        _descriptionController.text = menuItem.description;
        _priceController.text = menuItem.price.toString();
        _imageUrlController.text = menuItem.imageUrl ?? '';
        _isAvailable = menuItem.isAvailable;

        // Find the category ID
        final category = _categories.firstWhere(
          (cat) => cat['name'] == menuItem.category,
          orElse: () => <String, dynamic>{},
        );
        _selectedCategoryId = category['id'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load menu item: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/admin/menu');
      }
    }
  }

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final price = double.parse(_priceController.text);
      final imageUrl = _imageUrlController.text.isEmpty ? null : _imageUrlController.text;

      if (widget.menuItem == null) {
        // Creating new item
        await _menuService.createMenuItem(
          name: _nameController.text,
          description: _descriptionController.text,
          price: price,
          categoryId: _selectedCategoryId!,
          imageUrl: imageUrl,
          isAvailable: _isAvailable,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu item created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/admin/menu');
        }
      } else {
        // Updating existing item
        await _menuService.updateMenuItem(
          id: widget.menuItem!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          price: price,
          categoryId: _selectedCategoryId,
          imageUrl: imageUrl,
          isAvailable: _isAvailable,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu item updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/admin/menu');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save menu item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.menuItem != null || widget.menuItemId != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Menu Item' : 'Add Menu Item'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/menu'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price field
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price *',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Price must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['id'],
                          child: Text(category['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Image URL field
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL (optional)',
                        border: OutlineInputBorder(),
                        hintText: 'https://example.com/image.jpg',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Available switch
                    SwitchListTile(
                      title: const Text('Available'),
                      subtitle: const Text('Make this item available for ordering'),
                      value: _isAvailable,
                      onChanged: (value) {
                        setState(() {
                          _isAvailable = value;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveMenuItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Saving...'),
                              ],
                            )
                                                     : Text(isEditing ? 'Update Item' : 'Create Item'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 