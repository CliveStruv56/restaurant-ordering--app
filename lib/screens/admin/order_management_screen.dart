import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/user_service.dart';
import '../../utils/currency.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final UserService _userService = UserService();
  
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String _selectedStatus = 'all';

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
        await _loadOrders();
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

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final orders = await _userService.getAllOrders();
      
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedStatus == 'all') {
      return _orders;
    }
    return _orders.where((order) => order['status'] == _selectedStatus).toList();
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _userService.updateOrderStatus(orderId, newStatus);
      
      // Refresh the orders list to get updated data
      await _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isAdmin
              ? const Center(child: Text('Access Denied'))
              : Column(
                  children: [
                    // Status filter
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Text('Filter by status: '),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _selectedStatus,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All')),
                              DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                              DropdownMenuItem(value: 'preparing', child: Text('Preparing')),
                              DropdownMenuItem(value: 'ready', child: Text('Ready')),
                              DropdownMenuItem(value: 'completed', child: Text('Completed')),
                              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Orders list
                    Expanded(
                      child: _filteredOrders.isEmpty
                          ? const Center(child: Text('No orders found'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = _filteredOrders[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16.0),
                                  child: ExpansionTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Order #${order['order_number']}',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                order['user']['full_name'],
                                                style: TextStyle(color: Colors.grey[600]),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Chip(
                                          label: Text(order['status']),
                                          backgroundColor: _getStatusColor(order['status']),
                                          labelStyle: const TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${order['order_type']} • ${CurrencyUtils.formatPrice(order['total'])}'),
                                        Text('Created: ${_formatDateTime(order['created_at'])}'),
                                      ],
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Order details
                                            const Text(
                                              'Order Details',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 8),
                                            Text('Customer: ${order['user']['full_name']}'),
                                            Text('Email: ${order['user']['email']}'),
                                            Text('Payment: ${order['payment_method']}'),
                                            if (order['special_instructions'] != null)
                                              Text('Special Instructions: ${order['special_instructions']}'),
                                            const SizedBox(height: 16),

                                            // View Details button
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: () => context.go('/admin/orders/${order['id']}'),
                                                    icon: const Icon(Icons.visibility),
                                                    label: const Text('View Details'),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.blue,
                                                      foregroundColor: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),

                                            // Status update
                                            const Text(
                                              'Update Status',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              children: [
                                                'confirmed',
                                                'preparing',
                                                'ready',
                                                'completed',
                                                'cancelled',
                                              ].map((status) {
                                                return ElevatedButton(
                                                  onPressed: () => _updateOrderStatus(order['id'], status),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: _getStatusColor(status),
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  child: Text(status),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
} 