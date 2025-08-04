import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timeslot.dart';
import '../models/restaurant_settings.dart';
import '../utils/logger.dart';

class TimeslotService {
  final SupabaseClient _client = Supabase.instance.client;

  // Restaurant Settings Methods
  
  /// Get all restaurant settings
  Future<Map<String, String>> getRestaurantSettings() async {
    try {
      final response = await _client
          .from('restaurant_settings')
          .select('setting_key, setting_value');

      final Map<String, String> settings = {};
      for (final setting in response) {
        settings[setting['setting_key']] = setting['setting_value'];
      }
      
      return settings;
    } catch (e) {
      Logger.error('Error fetching restaurant settings', e);
      rethrow;
    }
  }

  /// Get a specific setting value
  Future<String?> getSetting(String key) async {
    try {
      final response = await _client
          .from('restaurant_settings')
          .select('setting_value')
          .eq('setting_key', key)
          .maybeSingle();

      return response?['setting_value'];
    } catch (e) {
      Logger.error('Error fetching setting: $key', e);
      return null;
    }
  }

  /// Update a restaurant setting
  Future<void> updateSetting(String key, String value) async {
    try {
      await _client
          .from('restaurant_settings')
          .upsert({
            'setting_key': key,
            'setting_value': value,
            'updated_at': DateTime.now().toIso8601String(),
          }, 
          onConflict: 'setting_key');
      
      Logger.info('Updated setting: $key = $value');
    } catch (e) {
      Logger.error('Error updating setting: $key', e);
      rethrow;
    }
  }

  /// Update multiple settings at once
  Future<void> updateSettings(Map<String, String> settings) async {
    try {
      // Update each setting individually to avoid constraint issues
      for (final entry in settings.entries) {
        await updateSetting(entry.key, entry.value);
      }
      
      Logger.info('Updated ${settings.length} settings');
    } catch (e) {
      Logger.error('Error updating multiple settings', e);
      rethrow;
    }
  }

  // Opening Hours Methods

  /// Get all opening hours
  Future<List<OpeningHours>> getOpeningHours() async {
    try {
      final response = await _client
          .from('opening_hours')
          .select('*')
          .order('day_of_week');

      return response.map((item) => OpeningHours.fromJson(item)).toList();
    } catch (e) {
      Logger.error('Error fetching opening hours', e);
      rethrow;
    }
  }

  /// Update opening hours for a specific day
  Future<void> updateOpeningHours(int dayOfWeek, bool isOpen, String openTime, String closeTime) async {
    try {
      await _client
          .from('opening_hours')
          .upsert({
            'day_of_week': dayOfWeek,
            'is_open': isOpen,
            'open_time': openTime,
            'close_time': closeTime,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'day_of_week');
      
      Logger.info('Updated opening hours for day $dayOfWeek');
    } catch (e) {
      Logger.error('Error updating opening hours', e);
      rethrow;
    }
  }

  // Timeslot Methods

  /// Get available timeslots for a date range
  Future<List<Timeslot>> getAvailableTimeslots({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      // Try to use the view first
      try {
        var queryBuilder = _client
            .from('available_timeslots')
            .select('*');

        if (startDate != null) {
          queryBuilder = queryBuilder.gte('date', startDate.toIso8601String().split('T')[0]);
        }

        if (endDate != null) {
          queryBuilder = queryBuilder.lte('date', endDate.toIso8601String().split('T')[0]);
        }

        var finalQuery = queryBuilder.order('date').order('time');

        if (limit != null) {
          finalQuery = finalQuery.limit(limit);
        }

        final response = await finalQuery;
        return response.map((item) => Timeslot.fromJson(item)).toList();
      } catch (viewError) {
        // Fallback to timeslots table if view doesn't exist
        Logger.info('Using timeslots table directly (view not found)');
        
        var queryBuilder = _client
            .from('timeslots')
            .select('*')
            .eq('is_available', true);

        if (startDate != null) {
          queryBuilder = queryBuilder.gte('date', startDate.toIso8601String().split('T')[0]);
        } else {
          // Default to today or later
          queryBuilder = queryBuilder.gte('date', DateTime.now().toIso8601String().split('T')[0]);
        }

        if (endDate != null) {
          queryBuilder = queryBuilder.lte('date', endDate.toIso8601String().split('T')[0]);
        }

        var finalQuery = queryBuilder.order('date').order('time');

        if (limit != null) {
          finalQuery = finalQuery.limit(limit);
        }

        final response = await finalQuery;
        return response.map((item) => Timeslot.fromJson(item)).toList();
      }
    } catch (e) {
      Logger.error('Error fetching available timeslots', e);
      rethrow;
    }
  }

  /// Get timeslots for a specific date
  Future<List<Timeslot>> getTimeslotsForDate(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final now = DateTime.now();
      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      
      var query = _client
          .from('timeslots')
          .select('*')
          .eq('date', dateString);
      
      // If it's today, only show future timeslots
      if (isToday) {
        final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
        query = query.gt('time', currentTime);
      }
      
      final response = await query.order('time');

      return response.map((item) => Timeslot.fromJson(item)).toList();
    } catch (e) {
      Logger.error('Error fetching timeslots for date: $date', e);
      rethrow;
    }
  }

  /// Generate timeslots for a specific date
  Future<int> generateTimeslotsForDate(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      
      final response = await _client
          .rpc('generate_timeslots_for_date', params: {
            'target_date': dateString,
          });

      Logger.info('Generated ${response ?? 0} timeslots for $dateString');
      return response ?? 0;
    } catch (e) {
      Logger.error('Error generating timeslots for date: $date', e);
      rethrow;
    }
  }

  /// Generate timeslots for the next 7 days
  Future<int> generateUpcomingTimeslots() async {
    try {
      // Log current settings before generation
      final intervalSetting = await getSetting('timeslot_interval_minutes');
      Logger.info('Generating timeslots with interval: ${intervalSetting ?? "default"} minutes');
      
      final response = await _client.rpc('generate_upcoming_timeslots');
      
      Logger.info('Generated ${response ?? 0} upcoming timeslots');
      return response ?? 0;
    } catch (e) {
      Logger.error('Error generating upcoming timeslots', e);
      rethrow;
    }
  }

  /// Get a specific timeslot by ID
  Future<Timeslot?> getTimeslotById(String id) async {
    try {
      final response = await _client
          .from('timeslots')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Timeslot.fromJson(response);
    } catch (e) {
      Logger.error('Error fetching timeslot: $id', e);
      return null;
    }
  }

  /// Update timeslot availability
  Future<void> updateTimeslotAvailability(String id, bool isAvailable) async {
    try {
      await _client
          .from('timeslots')
          .update({
            'is_available': isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      
      Logger.info('Updated timeslot $id availability to $isAvailable');
    } catch (e) {
      Logger.error('Error updating timeslot availability', e);
      rethrow;
    }
  }

  /// Update timeslot capacity
  Future<void> updateTimeslotCapacity(String id, int maxOrders) async {
    try {
      await _client
          .from('timeslots')
          .update({
            'max_orders': maxOrders,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      
      Logger.info('Updated timeslot $id max orders to $maxOrders');
    } catch (e) {
      Logger.error('Error updating timeslot capacity', e);
      rethrow;
    }
  }

  /// Delete timeslots for a specific date
  Future<void> deleteTimeslotsForDate(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      
      await _client
          .from('timeslots')
          .delete()
          .eq('date', dateString);
      
      Logger.info('Deleted timeslots for $dateString');
    } catch (e) {
      Logger.error('Error deleting timeslots for date: $date', e);
      rethrow;
    }
  }

  /// Delete all future timeslots (from today onwards)
  Future<void> deleteFutureTimeslots() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      await _client
          .from('timeslots')
          .delete()
          .gte('date', today);
      
      Logger.info('Deleted all future timeslots from $today');
    } catch (e) {
      Logger.error('Error deleting future timeslots', e);
      rethrow;
    }
  }

  /// Get timeslot statistics
  Future<Map<String, dynamic>> getTimeslotStats() async {
    try {
      // Get total timeslots
      final totalResponse = await _client
          .from('timeslots')
          .select('id')
          .gte('date', DateTime.now().toIso8601String().split('T')[0]);

      // Get occupied timeslots (where current_orders > 0)
      final occupiedResponse = await _client
          .from('timeslots')
          .select('id')
          .gte('date', DateTime.now().toIso8601String().split('T')[0])
          .gt('current_orders', 0);

      // Try to get available timeslots from view, fallback to calculation
      int availableCount = 0;
      try {
        final availableResponse = await _client
            .from('available_timeslots')
            .select('id');
        availableCount = availableResponse.length;
      } catch (viewError) {
        // If view doesn't exist, calculate from timeslots table
        final availableResponse = await _client
            .from('timeslots')
            .select('id')
            .gte('date', DateTime.now().toIso8601String().split('T')[0])
            .eq('is_available', true);
        availableCount = availableResponse.length;
      }

      return {
        'total_timeslots': totalResponse.length,
        'available_timeslots': availableCount,
        'occupied_timeslots': occupiedResponse.length,
      };
    } catch (e) {
      Logger.error('Error fetching timeslot stats', e);
      return {
        'total_timeslots': 0,
        'available_timeslots': 0,
        'occupied_timeslots': 0,
      };
    }
  }

  // Utility Methods

  /// Get next available timeslot
  Future<Timeslot?> getNextAvailableTimeslot() async {
    try {
      final timeslots = await getAvailableTimeslots(
        startDate: DateTime.now(),
        limit: 1,
      );

      return timeslots.isNotEmpty ? timeslots.first : null;
    } catch (e) {
      Logger.error('Error getting next available timeslot', e);
      return null;
    }
  }

  /// Check if a timeslot is still available for booking
  Future<bool> isTimeslotAvailable(String timeslotId) async {
    try {
      final timeslot = await getTimeslotById(timeslotId);
      return timeslot?.isBookable ?? false;
    } catch (e) {
      Logger.error('Error checking timeslot availability', e);
      return false;
    }
  }

  /// Trigger daily maintenance manually (for testing or manual runs)
  Future<Map<String, dynamic>> triggerTimeslotMaintenance() async {
    try {
      Logger.info('Attempting to trigger timeslot maintenance...');
      
      // Try the maintenance function
      final response = await _client.rpc('trigger_timeslot_maintenance');
      Logger.info('Triggered timeslot maintenance: $response');
      
      return Map<String, dynamic>.from(response ?? {});
    } catch (e) {
      Logger.error('Error triggering timeslot maintenance', e);
      
      // Fallback: try to generate timeslots manually
      try {
        Logger.info('Trying fallback maintenance...');
        
        // Delete old timeslots and generate new ones
        await deleteFutureTimeslots();
        final slotsGenerated = await generateUpcomingTimeslots();
        
        return {
          'slots_created': slotsGenerated,
          'slots_deleted': 0,
          'success': true,
          'fallback': true,
        };
      } catch (fallbackError) {
        Logger.error('Fallback maintenance also failed', fallbackError);
        rethrow;
      }
    }
  }

  /// Get maintenance log entries
  Future<List<Map<String, dynamic>>> getMaintenanceLog({int limit = 10}) async {
    try {
      final response = await _client
          .from('timeslot_maintenance_log')
          .select('*')
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching maintenance log', e);
      return [];
    }
  }
}