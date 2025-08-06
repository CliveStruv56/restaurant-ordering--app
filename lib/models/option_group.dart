class OptionGroup {
  final String id;
  final String name;
  final String? description;
  final String selectionType; // 'single' or 'multiple'
  final bool isRequired;
  final int sortOrder;
  final String? iconUrl;
  final List<Option> options;

  OptionGroup({
    required this.id,
    required this.name,
    this.description,
    required this.selectionType,
    required this.isRequired,
    required this.sortOrder,
    this.iconUrl,
    this.options = const [],
  });

  factory OptionGroup.fromJson(Map<String, dynamic> json) {
    return OptionGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      selectionType: json['selection_type'] ?? 'single',
      isRequired: json['is_required'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      iconUrl: json['icon_url'],
      options: json['options'] != null
          ? (json['options'] as List)
              .map((option) => Option.fromJson(option))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'selection_type': selectionType,
      'is_required': isRequired,
      'sort_order': sortOrder,
      'icon_url': iconUrl,
      'options': options.map((option) => option.toJson()).toList(),
    };
  }

  OptionGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? selectionType,
    bool? isRequired,
    int? sortOrder,
    String? iconUrl,
    List<Option>? options,
  }) {
    return OptionGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      selectionType: selectionType ?? this.selectionType,
      isRequired: isRequired ?? this.isRequired,
      sortOrder: sortOrder ?? this.sortOrder,
      iconUrl: iconUrl ?? this.iconUrl,
      options: options ?? this.options,
    );
  }

  @override
  String toString() {
    return 'OptionGroup(id: $id, name: $name, selectionType: $selectionType, isRequired: $isRequired)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OptionGroup && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Option {
  final String id;
  final String optionGroupId;
  final String name;
  final String? description;
  final double priceAdjustment;
  final String? iconUrl;
  final bool isAvailable;
  final bool isDefault;
  final String? dependsOnOptionId;
  final int sortOrder;

  Option({
    required this.id,
    required this.optionGroupId,
    required this.name,
    this.description,
    required this.priceAdjustment,
    this.iconUrl,
    required this.isAvailable,
    required this.isDefault,
    this.dependsOnOptionId,
    required this.sortOrder,
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['id'] ?? '',
      optionGroupId: json['option_group_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      priceAdjustment: (json['price_adjustment'] is int)
          ? (json['price_adjustment'] as int).toDouble()
          : (json['price_adjustment'] as num?)?.toDouble() ?? 0.0,
      iconUrl: json['icon_url'],
      isAvailable: json['is_available'] ?? true,
      isDefault: json['is_default'] ?? false,
      dependsOnOptionId: json['depends_on_option_id'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'option_group_id': optionGroupId,
      'name': name,
      'description': description,
      'price_adjustment': priceAdjustment,
      'icon_url': iconUrl,
      'is_available': isAvailable,
      'is_default': isDefault,
      'depends_on_option_id': dependsOnOptionId,
      'sort_order': sortOrder,
    };
  }

  Option copyWith({
    String? id,
    String? optionGroupId,
    String? name,
    String? description,
    double? priceAdjustment,
    String? iconUrl,
    bool? isAvailable,
    bool? isDefault,
    String? dependsOnOptionId,
    int? sortOrder,
  }) {
    return Option(
      id: id ?? this.id,
      optionGroupId: optionGroupId ?? this.optionGroupId,
      name: name ?? this.name,
      description: description ?? this.description,
      priceAdjustment: priceAdjustment ?? this.priceAdjustment,
      iconUrl: iconUrl ?? this.iconUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isDefault: isDefault ?? this.isDefault,
      dependsOnOptionId: dependsOnOptionId ?? this.dependsOnOptionId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'Option(id: $id, name: $name, priceAdjustment: $priceAdjustment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Option && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}