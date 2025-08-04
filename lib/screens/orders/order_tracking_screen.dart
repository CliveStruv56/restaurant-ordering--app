import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/currency.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // Mock order data (in a real app, this would come from Supabase)
  final Map<String, dynamic> _order = {
    'id': '12345',
    'status': 'preparing', // 'confirmed', 'preparing', 'ready', 'completed'
    'estimatedTime': '25-30 minutes',
    'orderType': 'pickup',
    'items': [
      {'name': 'Margherita Pizza', 'quantity': 1, 'price': 18.00},
      {'name': 'Caesar Salad', 'quantity': 1, 'price': 12.00},
      {'name': 'Italian Soda', 'quantity': 2, 'price': 4.50},
    ],
    'total': 39.00,
    'orderTime': DateTime.now().subtract(const Duration(minutes: 15)),
    'estimatedReadyTime': DateTime.now().add(const Duration(minutes: 10)),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            _buildOrderHeader(),
            const SizedBox(height: 24),

            // Order status timeline
            _buildOrderTimeline(),
            const SizedBox(height: 24),

            // Order details
            _buildOrderDetails(),
            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order #12345',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _order['orderType'] == 'pickup' ? Icons.store : Icons.delivery_dining,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  _order['orderType'] == 'pickup' ? 'Pickup' : 'Delivery',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Text(
                  'Est. Ready: ${_formatTime(_order['estimatedReadyTime'])}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTimeline() {
    final status = _order['status'];
    final steps = [
      {'title': 'Order Confirmed', 'description': 'Your order has been received', 'completed': true},
      {'title': 'Preparing', 'description': 'Chef is cooking your food', 'completed': status == 'preparing' || status == 'ready' || status == 'completed'},
      {'title': 'Ready', 'description': 'Your order is ready for pickup', 'completed': status == 'ready' || status == 'completed'},
      {'title': 'Completed', 'description': 'Order picked up', 'completed': status == 'completed'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == steps.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline dot
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: (step['completed'] as bool?) == true ? Colors.green : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: (step['completed'] as bool?) == true
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  
                  // Step content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (step['completed'] as bool?) == true ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step['description'] as String,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        if (!isLast) const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Order items
            ...(_order['items'] as List).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${item['quantity']}x ${item['name']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      CurrencyUtils.formatPrice((item['price'] * item['quantity']).toDouble()),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            )),
            
            const Divider(),
            
            // Total
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    CurrencyUtils.formatPrice(_order['total'].toDouble()),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement contact restaurant functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact restaurant functionality coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            icon: const Icon(Icons.phone),
            label: const Text('Contact Restaurant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/home?tab=menu'),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Order Again'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (_order['status']) {
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (_order['status']) {
      case 'confirmed':
        return 'CONFIRMED';
      case 'preparing':
        return 'PREPARING';
      case 'ready':
        return 'READY';
      case 'completed':
        return 'COMPLETED';
      default:
        return 'UNKNOWN';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
} 