import 'option_group.dart';

class SelectedOption {
  final String optionId;
  final String optionGroupId;
  final String optionName;
  final double priceAdjustment;
  final String? iconUrl;

  SelectedOption({
    required this.optionId,
    required this.optionGroupId,
    required this.optionName,
    required this.priceAdjustment,
    this.iconUrl,
  });

  factory SelectedOption.fromOption(Option option) {
    return SelectedOption(
      optionId: option.id,
      optionGroupId: option.optionGroupId,
      optionName: option.name,
      priceAdjustment: option.priceAdjustment,
      iconUrl: option.iconUrl,
    );
  }

  factory SelectedOption.fromJson(Map<String, dynamic> json) {
    return SelectedOption(
      optionId: json['option_id'] ?? '',
      optionGroupId: json['option_group_id'] ?? '',
      optionName: json['option_name'] ?? '',
      priceAdjustment: (json['price_adjustment'] is int)
          ? (json['price_adjustment'] as int).toDouble()
          : (json['price_adjustment'] as num?)?.toDouble() ?? 0.0,
      iconUrl: json['icon_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'option_id': optionId,
      'option_group_id': optionGroupId,
      'option_name': optionName,
      'price_adjustment': priceAdjustment,
      'icon_url': iconUrl,
    };
  }

  SelectedOption copyWith({
    String? optionId,
    String? optionGroupId,
    String? optionName,
    double? priceAdjustment,
    String? iconUrl,
  }) {
    return SelectedOption(
      optionId: optionId ?? this.optionId,
      optionGroupId: optionGroupId ?? this.optionGroupId,
      optionName: optionName ?? this.optionName,
      priceAdjustment: priceAdjustment ?? this.priceAdjustment,
      iconUrl: iconUrl ?? this.iconUrl,
    );
  }

  @override
  String toString() {
    return 'SelectedOption(optionId: $optionId, optionName: $optionName, priceAdjustment: $priceAdjustment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectedOption && 
           other.optionId == optionId && 
           other.optionGroupId == optionGroupId;
  }

  @override
  int get hashCode => optionId.hashCode ^ optionGroupId.hashCode;
}