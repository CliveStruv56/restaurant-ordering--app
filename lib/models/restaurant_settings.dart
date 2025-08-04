class RestaurantSettings {
  final String id;
  final String settingKey;
  final String settingValue;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  RestaurantSettings({
    required this.id,
    required this.settingKey,
    required this.settingValue,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RestaurantSettings.fromJson(Map<String, dynamic> json) {
    return RestaurantSettings(
      id: json['id'],
      settingKey: json['setting_key'],
      settingValue: json['setting_value'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'setting_key': settingKey,
      'setting_value': settingValue,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class OpeningHours {
  final String id;
  final int dayOfWeek; // 0 = Sunday, 6 = Saturday
  final bool isOpen;
  final String openTime; // Format: HH:mm
  final String closeTime; // Format: HH:mm
  final DateTime createdAt;
  final DateTime updatedAt;

  OpeningHours({
    required this.id,
    required this.dayOfWeek,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      id: json['id'],
      dayOfWeek: json['day_of_week'],
      isOpen: json['is_open'],
      openTime: json['open_time'],
      closeTime: json['close_time'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_of_week': dayOfWeek,
      'is_open': isOpen,
      'open_time': openTime,
      'close_time': closeTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get dayName {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek];
  }
}