import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_item.dart';
import '../models/option_group.dart';

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
      await _client
          .from('categories')
          .select('name')
          .eq('id', categoryId)
          .single();

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

  // Get menu item options by category ID - simplified approach
  Future<List<OptionGroup>> getMenuItemOptionsByCategoryId(String categoryId) async {
    try {
      print('[DEBUG] Getting options for category ID: $categoryId');
      
      // Step 1: Get unique option group IDs for this category
      final categoryMappings = await _client
          .from('category_option_groups')
          .select('option_group_id, sort_order')
          .eq('category_id', categoryId)
          .order('sort_order');
      
      print('[DEBUG] Found ${categoryMappings.length} option group mappings');
      
      if (categoryMappings.isEmpty) {
        print('[DEBUG] No option groups found for category: $categoryId');
        return [];
      }

      final optionGroups = <OptionGroup>[];
      final processedGroupIds = <String>{};
      
      // Step 2: Get each option group individually to avoid duplicates
      for (final mapping in categoryMappings) {
        final groupId = mapping['option_group_id'] as String;
        
        // Skip duplicates
        if (processedGroupIds.contains(groupId)) {
          print('[DEBUG] Skipping duplicate group mapping for ID: $groupId');
          continue;
        }
        processedGroupIds.add(groupId);
        
        try {
          print('[DEBUG] Loading option group: $groupId');
          final optionGroup = await getOptionGroupById(groupId);
          optionGroups.add(optionGroup);
          print('[DEBUG] Added option group: ${optionGroup.name} with ${optionGroup.options.length} options');
        } catch (e) {
          print('[ERROR] Failed to load option group $groupId: $e');
        }
      }
      
      // Sort by sort_order
      optionGroups.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      
      print('[DEBUG] Total unique option groups loaded: ${optionGroups.length}');
      return optionGroups;
    } catch (e) {
      print('[ERROR] Error fetching category options: $e');
      print('[ERROR] Error type: ${e.runtimeType}');
      return [];
    }
  }

  // Get menu item options (wrapper that gets categoryId first)
  Future<List<OptionGroup>> getMenuItemOptions(String menuItemId) async {
    try {
      print('[DEBUG] Getting menu item details to find category ID: $menuItemId');
      
      // First get the menu item to find its category_id
      final menuItemResponse = await _client
          .from('menu_items')
          .select('category_id')
          .eq('id', menuItemId)
          .single();
      
      final categoryId = menuItemResponse['category_id'] as String?;
      if (categoryId == null) {
        print('[DEBUG] Menu item has no category_id: $menuItemId');
        return [];
      }
      
      print('[DEBUG] Found category ID: $categoryId for menu item: $menuItemId');
      return await getMenuItemOptionsByCategoryId(categoryId);
    } catch (e) {
      print('[ERROR] Error in getMenuItemOptions: $e');
      return [];
    }
  }

  // Legacy RPC function approach (keeping for reference)
  Future<List<OptionGroup>> getMenuItemOptionsRPC(String menuItemId) async {
    try {
      final response = await _client.rpc('get_menu_item_options', 
        params: {'menu_item_id': menuItemId});

      final Map<String, OptionGroup> optionGroupsMap = {};
      
      for (final row in response) {
        final groupId = row['option_group_id'] as String;
        
        if (!optionGroupsMap.containsKey(groupId)) {
          optionGroupsMap[groupId] = OptionGroup(
            id: groupId,
            name: row['option_group_name'] as String,
            selectionType: row['selection_type'] as String,
            isRequired: row['is_required'] as bool,
            sortOrder: 0,
            options: [],
          );
        }
        
        final option = Option(
          id: row['option_id'] as String,
          optionGroupId: groupId,
          name: row['option_name'] as String,
          priceAdjustment: (row['price_adjustment'] as num).toDouble(),
          iconUrl: row['icon_url'] as String?,
          isAvailable: true,
          isDefault: row['is_default'] as bool,
          dependsOnOptionId: row['depends_on_option_id'] as String?,
          sortOrder: 0,
        );
        
        optionGroupsMap[groupId] = optionGroupsMap[groupId]!.copyWith(
          options: [...optionGroupsMap[groupId]!.options, option],
        );
      }
      
      return optionGroupsMap.values.toList();
    } catch (e) {
      print('Error fetching menu item options: $e');
      return [];
    }
  }

  // Get all option groups
  Future<List<OptionGroup>> getOptionGroups() async {
    try {
      print('[DEBUG] Fetching option groups from database...');
      final response = await _client
          .from('option_groups')
          .select('*')
          .order('sort_order');

      print('[DEBUG] Raw response from option_groups query: $response');
      
      if (response.isEmpty) {
        print('[DEBUG] No option groups found in database');
        return [];
      }

      final optionGroups = <OptionGroup>[];
      
      for (final groupData in response) {
        print('[DEBUG] Processing option group: ${groupData['name']}');
        
        // Get options for this group separately
        final optionsResponse = await _client
            .from('options')
            .select('*')
            .eq('option_group_id', groupData['id'])
            .eq('is_available', true)
            .order('sort_order');
        
        print('[DEBUG] Found ${optionsResponse.length} options for group ${groupData['name']}');
        
        final options = optionsResponse.map((optData) => Option.fromJson(optData)).toList();
        
        final optionGroup = OptionGroup.fromJson({
          ...groupData,
          'options': options.map((o) => o.toJson()).toList(),
        });
        
        optionGroups.add(optionGroup);
        print('[DEBUG] Added option group: ${optionGroup.name} with ${options.length} options');
      }
      
      print('[DEBUG] Total option groups loaded: ${optionGroups.length}');
      return optionGroups;
    } catch (e) {
      print('[ERROR] Error fetching option groups: $e');
      print('[ERROR] Error type: ${e.runtimeType}');
      print('[ERROR] Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Create option group
  Future<OptionGroup> createOptionGroup({
    required String name,
    String? description,
    required String selectionType,
    required bool isRequired,
    String? iconUrl,
  }) async {
    try {
      print('[DEBUG] Creating option group: $name');
      print('[DEBUG] Selection type: $selectionType, Required: $isRequired');
      
      final response = await _client.from('option_groups').insert({
        'name': name,
        'description': description,
        'selection_type': selectionType,
        'is_required': isRequired,
        'icon_url': iconUrl,
      }).select().single();

      print('[DEBUG] Option group created successfully: ${response['id']}');
      print('[DEBUG] Full response data: $response');
      
      final optionGroup = OptionGroup.fromJson(response);
      print('[DEBUG] Parsed option group: ${optionGroup.toString()}');
      return optionGroup;
    } catch (e) {
      print('[ERROR] Failed to create option group: $e');
      print('[ERROR] Error type: ${e.runtimeType}');
      throw Exception('Failed to create option group: $e');
    }
  }

  // Update option group
  Future<OptionGroup> updateOptionGroup({
    required String id,
    String? name,
    String? description,
    String? selectionType,
    bool? isRequired,
    String? iconUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (selectionType != null) updateData['selection_type'] = selectionType;
      if (isRequired != null) updateData['is_required'] = isRequired;
      if (iconUrl != null) updateData['icon_url'] = iconUrl;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('option_groups')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return OptionGroup.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update option group: $e');
    }
  }

  // Delete option group
  Future<void> deleteOptionGroup(String id) async {
    try {
      await _client.from('option_groups').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete option group: $e');
    }
  }

  // Get option group by ID
  Future<OptionGroup> getOptionGroupById(String id) async {
    try {
      print('[DEBUG] Getting option group by ID: $id');
      
      // Get the option group
      final response = await _client
          .from('option_groups')
          .select('*')
          .eq('id', id)
          .single();

      print('[DEBUG] Found option group: ${response['name']}');
      
      // Get options for this group separately with DISTINCT on important fields
      final optionsResponse = await _client
          .from('options')
          .select('*')
          .eq('option_group_id', id)
          .eq('is_available', true)
          .order('sort_order');
      
      print('[DEBUG] Found ${optionsResponse.length} raw options for group');
      
      // Remove duplicates based on name and price_adjustment
      final uniqueOptions = <Option>[];
      final seenOptionKeys = <String>{};
      
      for (final optData in optionsResponse) {
        final option = Option.fromJson(optData);
        final optionKey = '${option.name}_${option.priceAdjustment}';
        
        if (!seenOptionKeys.contains(optionKey)) {
          uniqueOptions.add(option);
          seenOptionKeys.add(optionKey);
        } else {
          print('[DEBUG] Skipping duplicate option: ${option.name} (price: ${option.priceAdjustment})');
        }
      }
      
      print('[DEBUG] Filtered to ${uniqueOptions.length} unique options for group');
      final options = uniqueOptions;
      
      final optionGroup = OptionGroup.fromJson({
        ...response,
        'options': options.map((o) => o.toJson()).toList(),
      });
      
      print('[DEBUG] Returning option group with ${optionGroup.options.length} options');
      return optionGroup;
    } catch (e) {
      print('[ERROR] Failed to get option group: $e');
      print('[ERROR] Error type: ${e.runtimeType}');
      throw Exception('Failed to get option group: $e');
    }
  }

  // Create option
  Future<Option> createOption({
    required String optionGroupId,
    required String name,
    String? description,
    required double priceAdjustment,
    String? iconUrl,
    required bool isDefault,
    required bool isAvailable,
    String? dependsOnOptionId,
  }) async {
    try {
      print('[DEBUG] Creating option: $name');
      print('[DEBUG] Option group ID: $optionGroupId');
      print('[DEBUG] Price adjustment: $priceAdjustment');
      print('[DEBUG] Is default: $isDefault, Is available: $isAvailable');
      
      final response = await _client.from('options').insert({
        'option_group_id': optionGroupId,
        'name': name,
        'description': description,
        'price_adjustment': priceAdjustment,
        'icon_url': iconUrl,
        'is_default': isDefault,
        'is_available': isAvailable,
        'depends_on_option_id': dependsOnOptionId,
      }).select().single();

      print('[DEBUG] Option created successfully: ${response['id']}');
      print('[DEBUG] Full response: $response');
      
      final option = Option.fromJson(response);
      print('[DEBUG] Parsed option: ${option.name}');
      return option;
    } catch (e) {
      print('[ERROR] Failed to create option: $e');
      print('[ERROR] Error type: ${e.runtimeType}');
      throw Exception('Failed to create option: $e');
    }
  }

  // Update option
  Future<Option> updateOption({
    required String id,
    String? name,
    String? description,
    double? priceAdjustment,
    String? iconUrl,
    bool? isDefault,
    bool? isAvailable,
    String? dependsOnOptionId,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (priceAdjustment != null) updateData['price_adjustment'] = priceAdjustment;
      if (iconUrl != null) updateData['icon_url'] = iconUrl;
      if (isDefault != null) updateData['is_default'] = isDefault;
      if (isAvailable != null) updateData['is_available'] = isAvailable;
      if (dependsOnOptionId != null) updateData['depends_on_option_id'] = dependsOnOptionId;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('options')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return Option.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update option: $e');
    }
  }

  // Delete option
  Future<void> deleteOption(String id) async {
    try {
      await _client.from('options').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete option: $e');
    }
  }

  // Update option sort order
  Future<void> updateOptionSortOrder(String id, int sortOrder) async {
    try {
      await _client
          .from('options')
          .update({'sort_order': sortOrder})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to update option sort order: $e');
    }
  }

  // Get category-option group associations
  Future<Map<String, List<String>>> getCategoryOptionAssociations() async {
    try {
      final response = await _client
          .from('category_option_groups')
          .select('category_id, option_group_id');
      
      final Map<String, List<String>> associations = {};
      for (final row in response) {
        final categoryId = row['category_id'] as String;
        final optionGroupId = row['option_group_id'] as String;
        
        if (!associations.containsKey(categoryId)) {
          associations[categoryId] = [];
        }
        associations[categoryId]!.add(optionGroupId);
      }
      
      return associations;
    } catch (e) {
      print('Error fetching category option associations: $e');
      return {};
    }
  }

  // Update category option groups
  Future<void> updateCategoryOptionGroups(String categoryId, List<String> optionGroupIds) async {
    try {
      // Delete existing associations
      await _client
          .from('category_option_groups')
          .delete()
          .eq('category_id', categoryId);
      
      // Insert new associations
      if (optionGroupIds.isNotEmpty) {
        final associations = optionGroupIds.asMap().entries.map((entry) => {
          'category_id': categoryId,
          'option_group_id': entry.value,
          'sort_order': entry.key,
          'is_required': false, // Can be customized later
        }).toList();
        
        await _client
            .from('category_option_groups')
            .insert(associations);
      }
    } catch (e) {
      throw Exception('Failed to update category option groups: $e');
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