
class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? categoryId;  // Add categoryId field
  final String? imageUrl;
  final bool isAvailable;
  final List<String> tags;
  final Map<String, dynamic>? customizations;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.categoryId,  // Add categoryId parameter
    this.imageUrl,
    this.isAvailable = true,
    this.tags = const [],
    this.customizations,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    // Handle Supabase data structure where category might be nested
    String categoryName = '';
    String? categoryId;
    
    if (json['categories'] != null && json['categories'] is Map) {
      categoryName = json['categories']['name'] ?? '';
      // We don't have category ID from the nested structure
    } else if (json['category'] != null) {
      categoryName = json['category'];
    }
    
    // Get the category_id directly from the JSON
    categoryId = json['category_id'];

    return MenuItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] is int) 
          ? (json['price'] as int).toDouble() 
          : (json['price'] as num).toDouble(),
      category: categoryName,
      categoryId: categoryId,  // Add categoryId to constructor
      imageUrl: json['image_url'],
      isAvailable: json['is_available'] ?? true,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'])
          : [],
      customizations: json['customizations'] != null 
          ? Map<String, dynamic>.from(json['customizations'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'category_id': categoryId,  // Add categoryId to JSON
      'image_url': imageUrl,
      'is_available': isAvailable,
      'tags': tags,
      'customizations': customizations,
    };
  }

  MenuItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
    List<String>? tags,
    Map<String, dynamic>? customizations,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      tags: tags ?? this.tags,
      customizations: customizations ?? this.customizations,
    );
  }

  @override
  String toString() {
    return 'MenuItem(id: $id, name: $name, price: $price, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 