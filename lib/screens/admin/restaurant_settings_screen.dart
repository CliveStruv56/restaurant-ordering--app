import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/timeslot_service.dart';
import '../../services/user_service.dart';
import '../../models/restaurant_settings.dart';
import '../../utils/logger.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  State<RestaurantSettingsScreen> createState() => _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {
  final TimeslotService _timeslotService = TimeslotService();
  final UserService _userService = UserService();
  
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Settings controllers
  final _restaurantNameController = TextEditingController();
  final _restaurantPhoneController = TextEditingController();
  final _restaurantEmailController = TextEditingController();
  final _timeslotIntervalController = TextEditingController();
  final _bufferStartController = TextEditingController();
  final _bufferEndController = TextEditingController();
  final _maxOrdersController = TextEditingController();
  final _advanceBookingController = TextEditingController();
  
  List<OpeningHours> _openingHours = [];
  Map<String, String> _settings = {};

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _restaurantPhoneController.dispose();
    _restaurantEmailController.dispose();
    _timeslotIntervalController.dispose();
    _bufferStartController.dispose();
    _bufferEndController.dispose();
    _maxOrdersController.dispose();
    _advanceBookingController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final isAdmin = await _userService.isAdmin();
      if (isAdmin) {
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
      setState(() => _isLoading = true);
      
      // Load settings and opening hours in parallel
      final settingsResult = await _timeslotService.getRestaurantSettings();
      final openingHoursResult = await _timeslotService.getOpeningHours();
      
      setState(() {
        _settings = settingsResult;
        _openingHours = openingHoursResult;
        _populateControllers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _populateControllers() {
    _restaurantNameController.text = _settings['restaurant_name'] ?? 'Restaurant Name';
    _restaurantPhoneController.text = _settings['restaurant_phone'] ?? '+44 123 456 7890';
    _restaurantEmailController.text = _settings['restaurant_email'] ?? 'info@restaurant.com';
    _timeslotIntervalController.text = _settings['timeslot_interval_minutes'] ?? '15';
    _bufferStartController.text = _settings['buffer_start_minutes'] ?? '30';
    _bufferEndController.text = _settings['buffer_end_minutes'] ?? '30';
    _maxOrdersController.text = _settings['max_orders_per_slot'] ?? '10';
    _advanceBookingController.text = _settings['advance_booking_days'] ?? '7';
  }

  Future<void> _saveSettings() async {
    try {
      setState(() => _isSaving = true);
      
      // Prepare settings to update
      final updatedSettings = {
        'restaurant_name': _restaurantNameController.text.trim(),
        'restaurant_phone': _restaurantPhoneController.text.trim(),
        'restaurant_email': _restaurantEmailController.text.trim(),
        'timeslot_interval_minutes': _timeslotIntervalController.text.trim(),
        'buffer_start_minutes': _bufferStartController.text.trim(),
        'buffer_end_minutes': _bufferEndController.text.trim(),
        'max_orders_per_slot': _maxOrdersController.text.trim(),
        'advance_booking_days': _advanceBookingController.text.trim(),
      };
      
      // Validate numeric fields
      final numericFields = {
        'timeslot_interval_minutes': 'Timeslot Interval',
        'buffer_start_minutes': 'Start Buffer',
        'buffer_end_minutes': 'End Buffer',
        'max_orders_per_slot': 'Max Orders per Slot',
        'advance_booking_days': 'Advance Booking Days',
      };
      
      for (final entry in numericFields.entries) {
        final value = updatedSettings[entry.key]!;
        if (int.tryParse(value) == null || int.parse(value) < 0) {
          throw Exception('${entry.value} must be a positive number');
        }
      }
      
      // Check if timeslot-related settings changed
      final timeslotSettingsChanged = 
        updatedSettings['timeslot_interval_minutes'] != _settings['timeslot_interval_minutes'] ||
        updatedSettings['buffer_start_minutes'] != _settings['buffer_start_minutes'] ||
        updatedSettings['buffer_end_minutes'] != _settings['buffer_end_minutes'] ||
        updatedSettings['advance_booking_days'] != _settings['advance_booking_days'];
      
      
      // Update settings
      await _timeslotService.updateSettings(updatedSettings);
      
      // Save opening hours
      for (final hours in _openingHours) {
        await _timeslotService.updateOpeningHours(
          hours.dayOfWeek,
          hours.isOpen,
          hours.openTime,
          hours.closeTime,
        );
      }
      
      // Auto-regenerate timeslots if relevant settings changed
      String message = 'Settings saved successfully';
      if (timeslotSettingsChanged) {
        try {
          // Clear existing future timeslots and regenerate with new settings
          await _timeslotService.deleteFutureTimeslots();
          final slotsGenerated = await _timeslotService.generateUpcomingTimeslots();
          
          // Build a more descriptive message based on what changed
          if (updatedSettings['advance_booking_days'] != _settings['advance_booking_days']) {
            message = 'Settings saved and timeslots regenerated for ${updatedSettings['advance_booking_days']} days ahead';
          } else {
            message = 'Settings saved and $slotsGenerated timeslots regenerated with new ${updatedSettings['timeslot_interval_minutes']}-minute intervals';
          }
        } catch (e) {
          message = 'Settings saved, but failed to regenerate timeslots: $e';
        }
      }
      
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateTimeslots() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // First save any pending settings changes
      final updatedSettings = {
        'restaurant_name': _restaurantNameController.text.trim(),
        'restaurant_phone': _restaurantPhoneController.text.trim(),
        'restaurant_email': _restaurantEmailController.text.trim(),
        'timeslot_interval_minutes': _timeslotIntervalController.text.trim(),
        'buffer_start_minutes': _bufferStartController.text.trim(),
        'buffer_end_minutes': _bufferEndController.text.trim(),
        'max_orders_per_slot': _maxOrdersController.text.trim(),
        'advance_booking_days': _advanceBookingController.text.trim(),
      };
      
      // Log what we're trying to set
      Logger.info('Updating timeslot interval to: ${updatedSettings['timeslot_interval_minutes']} minutes');
      
      // Update settings first to ensure new values are used
      await _timeslotService.updateSettings(updatedSettings);
      
      // Small delay to ensure database has committed the changes
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verify the setting was saved
      final verifyInterval = await _timeslotService.getSetting('timeslot_interval_minutes');
      Logger.info('Verified interval in database: $verifyInterval minutes');
      
      // Clear existing future timeslots
      Logger.info('Clearing existing timeslots...');
      await _timeslotService.deleteFutureTimeslots();
      
      // Generate new timeslots with updated settings
      Logger.info('Generating new timeslots...');
      final result = await _timeslotService.generateUpcomingTimeslots();
      
      // Update local settings cache
      _settings = updatedSettings;
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated $result timeslots with ${updatedSettings['timeslot_interval_minutes']}-minute intervals'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate timeslots: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _runMaintenance() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // First save settings
      final updatedSettings = {
        'restaurant_name': _restaurantNameController.text.trim(),
        'restaurant_phone': _restaurantPhoneController.text.trim(),
        'restaurant_email': _restaurantEmailController.text.trim(),
        'timeslot_interval_minutes': _timeslotIntervalController.text.trim(),
        'buffer_start_minutes': _bufferStartController.text.trim(),
        'buffer_end_minutes': _bufferEndController.text.trim(),
        'max_orders_per_slot': _maxOrdersController.text.trim(),
        'advance_booking_days': _advanceBookingController.text.trim(),
      };
      
      await _timeslotService.updateSettings(updatedSettings);
      
      // Trigger maintenance
      final result = await _timeslotService.triggerTimeslotMaintenance();
      
      // Update local settings cache
      _settings = updatedSettings;
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        final slotsCreated = result['slots_created'] ?? 0;
        final slotsDeleted = result['slots_deleted'] ?? 0;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maintenance complete: Created $slotsCreated slots, deleted $slotsDeleted old slots'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maintenance failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Settings'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          if (!_isLoading && !_isSaving)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Information
                  _buildSectionCard(
                    'Restaurant Information',
                    Icons.restaurant,
                    [
                      _buildTextField(
                        'Restaurant Name',
                        _restaurantNameController,
                        'Enter restaurant name',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Phone Number',
                        _restaurantPhoneController,
                        '+44 123 456 7890',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Email Address',
                        _restaurantEmailController,
                        'info@restaurant.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Timeslot Settings
                  _buildSectionCard(
                    'Timeslot Configuration',
                    Icons.schedule,
                    [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'Slot Interval (minutes)',
                              _timeslotIntervalController,
                              '15',
                              keyboardType: TextInputType.number,
                              helperText: 'Time between each slot',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              'Max Orders per Slot',
                              _maxOrdersController,
                              '10',
                              keyboardType: TextInputType.number,
                              helperText: 'Orders allowed per slot',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'Start Buffer (minutes)',
                              _bufferStartController,
                              '30',
                              keyboardType: TextInputType.number,
                              helperText: 'Buffer at start of day',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              'End Buffer (minutes)',
                              _bufferEndController,
                              '30',
                              keyboardType: TextInputType.number,
                              helperText: 'Buffer at end of day',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Advance Booking (days)',
                        _advanceBookingController,
                        '7',
                        keyboardType: TextInputType.number,
                        helperText: 'How many days ahead customers can book',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _generateTimeslots,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Generate Timeslots'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _runMaintenance,
                              icon: const Icon(Icons.auto_fix_high),
                              label: const Text('Run Maintenance'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Opening Hours - Show next X days with dates
                  _buildSectionCard(
                    'Opening Hours (Next ${_advanceBookingController.text} Days)',
                    Icons.access_time,
                    [
                      ..._buildNextDaysOpeningHours(),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Save All Settings'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.red[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  List<Widget> _buildNextDaysOpeningHours() {
    final List<Widget> rows = [];
    final int daysToShow = int.tryParse(_advanceBookingController.text) ?? 7;
    final today = DateTime.now();
    
    for (int i = 0; i < daysToShow && i < 14; i++) { // Cap at 14 days max
      final date = today.add(Duration(days: i));
      // Dart weekday: 1=Mon, 7=Sun. PostgreSQL DOW: 0=Sun, 1=Mon, 6=Sat
      final dayOfWeek = date.weekday == 7 ? 0 : date.weekday;
      
      // Find opening hours for this day
      final hours = _openingHours.firstWhere(
        (h) => h.dayOfWeek == dayOfWeek,
        orElse: () => OpeningHours(
          id: '',
          dayOfWeek: dayOfWeek,
          isOpen: false,
          openTime: '09:00',
          closeTime: '22:00',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      rows.add(_buildOpeningHoursRowWithDate(hours, date));
    }
    
    return rows;
  }

  Widget _buildOpeningHoursRowWithDate(OpeningHours hours, DateTime date) {
    final dateStr = '${date.day}/${date.month}';
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = dayNames[date.weekday - 1];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dayName $dateStr',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (date.day == DateTime.now().day && date.month == DateTime.now().month)
                  const Text(
                    'Today',
                    style: TextStyle(fontSize: 10, color: Colors.blue),
                  ),
              ],
            ),
          ),
          Switch(
            value: hours.isOpen,
            onChanged: (value) {
              setState(() {
                final index = _openingHours.indexWhere((h) => h.id == hours.id);
                if (index >= 0) {
                  _openingHours[index] = OpeningHours(
                    id: hours.id,
                    dayOfWeek: hours.dayOfWeek,
                    isOpen: value,
                    openTime: hours.openTime,
                    closeTime: hours.closeTime,
                    createdAt: hours.createdAt,
                    updatedAt: DateTime.now(),
                  );
                }
              });
            },
          ),
          const SizedBox(width: 16),
          if (hours.isOpen) ...[
            Expanded(
              child: TextFormField(
                initialValue: hours.openTime,
                decoration: const InputDecoration(
                  labelText: 'Open',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  final index = _openingHours.indexWhere((h) => h.id == hours.id);
                  if (index >= 0) {
                    _openingHours[index] = OpeningHours(
                      id: hours.id,
                      dayOfWeek: hours.dayOfWeek,
                      isOpen: hours.isOpen,
                      openTime: value,
                      closeTime: hours.closeTime,
                      createdAt: hours.createdAt,
                      updatedAt: DateTime.now(),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: hours.closeTime,
                decoration: const InputDecoration(
                  labelText: 'Close',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  final index = _openingHours.indexWhere((h) => h.id == hours.id);
                  if (index >= 0) {
                    _openingHours[index] = OpeningHours(
                      id: hours.id,
                      dayOfWeek: hours.dayOfWeek,
                      isOpen: hours.isOpen,
                      openTime: hours.openTime,
                      closeTime: value,
                      createdAt: hours.createdAt,
                      updatedAt: DateTime.now(),
                    );
                  }
                },
              ),
            ),
          ] else
            const Expanded(
              child: Text(
                'Closed',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

}