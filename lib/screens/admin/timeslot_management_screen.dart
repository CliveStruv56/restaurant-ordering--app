import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/timeslot_service.dart';
import '../../services/user_service.dart';
import '../../models/timeslot.dart';

class TimeslotManagementScreen extends StatefulWidget {
  const TimeslotManagementScreen({super.key});

  @override
  State<TimeslotManagementScreen> createState() => _TimeslotManagementScreenState();
}

class _TimeslotManagementScreenState extends State<TimeslotManagementScreen> {
  final TimeslotService _timeslotService = TimeslotService();
  final UserService _userService = UserService();
  
  bool _isLoading = true;
  bool _isAdmin = false;
  List<Timeslot> _timeslots = [];
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final isAdmin = await _userService.isAdmin();
      if (isAdmin) {
        setState(() {
          _isAdmin = true;
        });
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
      
      // Load timeslots for selected date and stats in parallel
      final timeslotsResult = await _timeslotService.getTimeslotsForDate(_selectedDate);
      final statsResult = await _timeslotService.getTimeslotStats();
      
      setState(() {
        _timeslots = timeslotsResult;
        _stats = statsResult;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadData();
    }
  }

  Future<void> _generateTimeslotsForDate() async {
    try {
      final result = await _timeslotService.generateTimeslotsForDate(_selectedDate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated $result timeslots for ${_formatDate(_selectedDate)}'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      }
    } catch (e) {
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

  Future<void> _deleteTimeslotsForDate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Timeslots'),
        content: Text('Are you sure you want to delete all timeslots for ${_formatDate(_selectedDate)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _timeslotService.deleteTimeslotsForDate(_selectedDate);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted timeslots for ${_formatDate(_selectedDate)}'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete timeslots: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleTimeslotAvailability(Timeslot timeslot) async {
    try {
      await _timeslotService.updateTimeslotAvailability(
        timeslot.id,
        !timeslot.isAvailable,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Timeslot ${timeslot.isAvailable ? 'disabled' : 'enabled'}'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update timeslot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateTimeslotCapacity(Timeslot timeslot) async {
    final controller = TextEditingController(text: timeslot.maxOrders.toString());
    
    final newCapacity = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Capacity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Max Orders',
            helperText: 'Maximum orders for this timeslot',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              Navigator.of(context).pop(value);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (newCapacity != null && newCapacity != timeslot.maxOrders) {
      try {
        await _timeslotService.updateTimeslotCapacity(timeslot.id, newCapacity);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Timeslot capacity updated'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update capacity: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(String time) {
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

  Color _getTimeslotColor(Timeslot timeslot) {
    if (!timeslot.isAvailable) return Colors.grey;
    if (timeslot.currentOrders >= timeslot.maxOrders) return Colors.red;
    if (timeslot.capacityPercentage > 0.8) return Colors.orange;
    if (timeslot.capacityPercentage > 0.5) return Colors.yellow;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeslot Management'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats and controls
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Slots',
                              _stats['total_timeslots']?.toString() ?? '0',
                              Icons.schedule,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Available',
                              _stats['available_timeslots']?.toString() ?? '0',
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Occupied',
                              _stats['occupied_timeslots']?.toString() ?? '0',
                              Icons.people,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date selector and actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectDate,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(_formatDate(_selectedDate)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _generateTimeslotsForDate,
                            icon: const Icon(Icons.add),
                            label: const Text('Generate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _timeslots.isNotEmpty ? _deleteTimeslotsForDate : null,
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Divider(),
                
                // Timeslots list
                Expanded(
                  child: _timeslots.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No timeslots for ${_formatDate(_selectedDate)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Generate timeslots using the button above',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _timeslots.length,
                          itemBuilder: (context, index) {
                            final timeslot = _timeslots[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getTimeslotColor(timeslot),
                                  child: Text(
                                    '${timeslot.currentOrders}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  _formatTime(timeslot.time),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${timeslot.currentOrders}/${timeslot.maxOrders} orders',
                                    ),
                                    if (!timeslot.isAvailable)
                                      const Text(
                                        'DISABLED',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Text(
                                        timeslot.isAvailable ? 'Disable' : 'Enable',
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'capacity',
                                      child: Text('Update Capacity'),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'toggle':
                                        _toggleTimeslotAvailability(timeslot);
                                        break;
                                      case 'capacity':
                                        _updateTimeslotCapacity(timeslot);
                                        break;
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}