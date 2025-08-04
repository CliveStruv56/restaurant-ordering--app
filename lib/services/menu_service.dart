import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_item.dart';

class MenuService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get all menu items from Supabase
  Future<List<MenuItem>> getMenuItems() async {
    try {
      final response = await _client
          .from('menu_items')
          .select('*, categories(name)')
          .eq('is_available', true)
          .order('name');

      return response.map((item) => MenuItem.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching menu items: $e');
      // Fallback to sample data if Supabase fails
      return getSampleMenuItems();
    }
  }

  // Get menu items by category
  Future<List<MenuItem>> getMenuItemsByCategory(String categoryId) async {
    try {
      final response = await _client
          .from('menu_items')
          .select('*, categories(name)')
          .eq('category_id', categoryId)
          .eq('is_available', true)
          .order('name');

      return response.map((item) => MenuItem.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching menu items by category: $e');
      return [];
    }
  }

  // Get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select('*')
          .order('sort_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Search menu items
  Future<List<MenuItem>> searchMenuItems(String query) async {
    try {
      final response = await _client
          .from('menu_items')
          .select('*, categories(name)')
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .eq('is_available', true)
          .order('name');

      return response.map((item) => MenuItem.fromJson(item)).toList();
    } catch (e) {
      print('Error searching menu items: $e');
      return [];
    }
  }

  // Create a new menu item
  Future<MenuItem> createMenuItem({
    required String name,
    required String description,
    required double price,
    required String categoryId,
    String? imageUrl,
    List<String>? tags,
    Map<String, List<String>>? customizations,
    bool isAvailable = true,
  }) async {
    try {
      // First get the category name
      final categoryResponse = await _client
          .from('categories')
          .select('name')
          .eq('id', categoryId)
          .single();

      final categoryName = categoryResponse['name'] as String;

      final response = await _client.from('menu_items').insert({
        'name': name,
        'description': description,
        'price': price,
        'category_id': categoryId,
        'image_url': imageUrl,
        'tags': tags,
        'customizations': customizations,
        'is_available': isAvailable,
      }).select('*, categories(name)').single();

      return MenuItem.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create menu item: $e');
    }
  }

  // Update an existing menu item
  Future<MenuItem> updateMenuItem({
    required String id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? imageUrl,
    List<String>? tags,
    Map<String, List<String>>? customizations,
    bool? isAvailable,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (tags != null) updateData['tags'] = tags;
      if (customizations != null) updateData['customizations'] = customizations;
      if (isAvailable != null) updateData['is_available'] = isAvailable;

      // If category is being updated
      if (categoryId != null) {
        updateData['category_id'] = categoryId;
      }

      final response = await _client
          .from('menu_items')
          .update(updateData)
          .eq('id', id)
          .select('*, categories(name)')
          .single();

      return MenuItem.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update menu item: $e');
    }
  }

  // Delete a menu item
  Future<void> deleteMenuItem(String id) async {
    try {
      await _client.from('menu_items').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete menu item: $e');
    }
  }

  // Get a single menu item by ID
  Future<MenuItem> getMenuItemById(String id) async {
    try {
      final response = await _client
          .from('menu_items')
          .select('*, categories(name)')
          .eq('id', id)
          .single();

      return MenuItem.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get menu item: $e');
    }
  }

  // Create a new category
  Future<Map<String, dynamic>> createCategory({
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final response = await _client.from('categories').insert({
        'name': name,
        'description': description,
        'image_url': imageUrl,
      }).select().single();

      return response;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  // Update a category
  Future<Map<String, dynamic>> updateCategory({
    required String id,
    String? name,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (imageUrl != null) updateData['image_url'] = imageUrl;

      final response = await _client
          .from('categories')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // Delete a category
  Future<void> deleteCategory(String id) async {
    try {
      // First check if there are any menu items using this category
      final menuItems = await _client
          .from('menu_items')
          .select('id')
          .eq('category_id', id);

      if (menuItems.isNotEmpty) {
        throw Exception('Cannot delete category: It has associated menu items');
      }

      await _client.from('categories').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Get sample menu items (fallback)
  List<MenuItem> getSampleMenuItems() {
    return [
      MenuItem(
        id: '1',
        name: 'Margherita Pizza',
        description: 'Classic pizza with tomato sauce, mozzarella, and basil',
        price: 18.00,
        category: 'Pizza',
        imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
        isAvailable: true,
        tags: ['pizza', 'vegetarian'],
        customizations: {
          'size': ['small', 'medium', 'large'],
          'crust': ['thin', 'thick'],
        },
      ),
      MenuItem(
        id: '2',
        name: 'Spaghetti Carbonara',
        description: 'Classic pasta with eggs, cheese, pancetta, and black pepper',
        price: 16.00,
        category: 'Pasta',
        imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=400',
        isAvailable: true,
        tags: ['pasta', 'italian'],
        customizations: {
          'pasta': ['spaghetti', 'fettuccine', 'linguine'],
        },
      ),
      MenuItem(
        id: '3',
        name: 'Grilled Salmon',
        description: 'Atlantic salmon with seasonal vegetables and lemon butter sauce',
        price: 24.00,
        category: 'Main Courses',
        imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400',
        isAvailable: true,
        tags: ['seafood', 'healthy'],
        customizations: {
          'cooking': ['medium rare', 'medium', 'well done'],
        },
      ),
      MenuItem(
        id: '4',
        name: 'Caesar Salad',
        description: 'Romaine lettuce, parmesan cheese, croutons, and caesar dressing',
        price: 12.00,
        category: 'Salads',
        imageUrl: 'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400',
        isAvailable: true,
        tags: ['salad', 'healthy'],
        customizations: {
          'dressing': ['caesar', 'light caesar'],
        },
      ),
      MenuItem(
        id: '5',
        name: 'Tiramisu',
        description: 'Classic Italian dessert with coffee-soaked ladyfingers and mascarpone',
        price: 8.00,
        category: 'Desserts',
        imageUrl: 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400',
        isAvailable: true,
        tags: ['dessert', 'italian'],
        customizations: {
          'coffee': ['regular', 'decaf'],
        },
      ),
    ];
  }
} 