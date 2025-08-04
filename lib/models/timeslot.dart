class Timeslot {
  final String id;
  final DateTime date;
  final String time; // Format: HH:mm
  final bool isAvailable;
  final int maxOrders;
  final int currentOrders;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? hasCapacity; // From view
  final bool? restaurantOpen; // From view

  Timeslot({
    required this.id,
    required this.date,
    required this.time,
    required this.isAvailable,
    required this.maxOrders,
    required this.currentOrders,
    required this.createdAt,
    required this.updatedAt,
    this.hasCapacity,
    this.restaurantOpen,
  });

  factory Timeslot.fromJson(Map<String, dynamic> json) {
    return Timeslot(
      id: json['id'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      isAvailable: json['is_available'] ?? true,
      maxOrders: json['max_orders'] ?? 10,
      currentOrders: json['current_orders'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      hasCapacity: json['has_capacity'],
      restaurantOpen: json['restaurant_open'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0], // Date only
      'time': time,
      'is_available': isAvailable,
      'max_orders': maxOrders,
      'current_orders': currentOrders,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get formatted date and time for display
  String get displayDateTime {
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = dayNames[date.weekday - 1]; // Dart weekday: 1=Mon, 7=Sun
    final formattedDate = '${date.day}/${date.month}/${date.year}';
    
    // Format time properly (remove seconds if present)
    final timeParts = time.split(':');
    final formattedTime = '${timeParts[0]}:${timeParts[1]}';
    
    return '$dayName, $formattedDate at $formattedTime';
  }

  /// Get formatted time for display (12-hour format)
  String get displayTime {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    
    if (hour == 0) {
      return '12:${minute}am';
    } else if (hour < 12) {
      return '$hour:${minute}am';
    } else if (hour == 12) {
      return '12:${minute}pm';
    } else {
      return '${hour - 12}:${minute}pm';
    }
  }

  /// Check if this timeslot is bookable
  bool get isBookable {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    
    // For today, check if the time has passed
    if (isToday) {
      final timeParts = time.split(':');
      final slotHour = int.parse(timeParts[0]);
      final slotMinute = int.parse(timeParts[1]);
      final slotDateTime = DateTime(date.year, date.month, date.day, slotHour, slotMinute);
      
      // Only bookable if at least 15 minutes in the future
      if (slotDateTime.isBefore(now.add(const Duration(minutes: 15)))) {
        return false;
      }
    }
    
    // For past dates, not bookable
    if (date.isBefore(DateTime(now.year, now.month, now.day))) {
      return false;
    }
    
    return isAvailable && 
           (hasCapacity ?? (currentOrders < maxOrders)) &&
           (restaurantOpen ?? true);
  }

  /// Get remaining capacity
  int get remainingCapacity {
    return maxOrders - currentOrders;
  }

  /// Get capacity percentage (0.0 to 1.0)
  double get capacityPercentage {
    if (maxOrders == 0) return 0.0;
    return currentOrders / maxOrders;
  }
}