import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/user_service.dart';
import '../../utils/currency.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final UserService _userService = UserService();
  
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  bool _isAdmin = false;

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
        await _loadOrderDetails();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin access required'),
              backgroundColor: Colors.red,
            ),
          );
          context.go('/admin');
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
        context.go('/admin');
      }
    }
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final order = await _userService.getOrderById(widget.orderId);
      
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load order details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      await _userService.updateOrderStatus(widget.orderId, newStatus);
      await _loadOrderDetails(); // Refresh order details

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

  String _formatCurrency(double amount) {
    return CurrencyUtils.formatPrice(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_order?['order_number'] ?? 'Loading...'}'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/orders'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isAdmin
              ? const Center(child: Text('Access Denied'))
              : _order == null
                  ? const Center(child: Text('Order not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order Status Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Status',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      Chip(
                                        label: Text(_order!['status']),
                                        backgroundColor: _getStatusColor(_order!['status']),
                                        labelStyle: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Status Update Buttons
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
                                        onPressed: () => _updateOrderStatus(status),
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
                          ),
                          const SizedBox(height: 16),

                          // Customer Information
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Customer Information',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Name: ${_order!['users']['full_name']}'),
                                  Text('Email: ${_order!['users']['email']}'),
                                  Text('Order Type: ${_order!['order_type']}'),
                                  Text('Payment Method: ${_order!['payment_method']}'),
                                  if (_order!['delivery_address'] != null)
                                    Text('Delivery Address: ${_order!['delivery_address']}'),
                                  if (_order!['special_instructions'] != null)
                                    Text('Special Instructions: ${_order!['special_instructions']}'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Order Items
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order Items',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 16),
                                  ...(_order!['order_items'] as List).map<Widget>((item) {
                                    return ListTile(
                                      title: Text(item['menu_item_name'] ?? 'Unknown Item'),
                                      subtitle: Text('Quantity: ${item['quantity']}'),
                                      trailing: Text(_formatCurrency(item['total_price'])),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Order Summary
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order Summary',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Subtotal:'),
                                      Text(_formatCurrency(_order!['subtotal'])),
                                    ],
                                  ),
                                  if (_order!['delivery_fee'] > 0) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Delivery Fee:'),
                                        Text(_formatCurrency(_order!['delivery_fee'])),
                                      ],
                                    ),
                                  ],
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total:',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      Text(
                                        _formatCurrency(_order!['total']),
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Order Timeline
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order Timeline',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Created: ${_formatDateTime(DateTime.parse(_order!['created_at']))}'),
                                  if (_order!['estimated_ready_time'] != null)
                                    Text('Estimated Ready: ${_formatDateTime(DateTime.parse(_order!['estimated_ready_time']))}'),
                                  if (_order!['updated_at'] != null)
                                    Text('Last Updated: ${_formatDateTime(DateTime.parse(_order!['updated_at']))}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
} 