import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/timeslot.dart';
import '../../utils/currency.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic>? orderData;
  
  const OrderConfirmationScreen({super.key, this.orderData});

  String get _orderNumber => orderData?['orderNumber']?.toString() ?? '12345';
  String get _orderType => orderData?['orderType']?.toString() ?? 'Pickup';
  String get _paymentMethod => orderData?['paymentMethod']?.toString() ?? 'Credit Card';
  
  Timeslot? get _selectedTimeslot {
    final timeslotData = orderData?['selectedTimeslot'];
    if (timeslotData != null) {
      return Timeslot.fromJson(timeslotData);
    }
    return null;
  }
  
  String get _formattedPaymentMethod {
    switch (_paymentMethod) {
      case 'card':
        return 'Credit Card';
      case 'cash':
        return 'Cash';
      case 'digital_wallet':
        return 'Digital Wallet';
      default:
        return _paymentMethod;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false, // Disable back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 60,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 32),
            
            // Order confirmed text
            const Text(
              'Order Confirmed!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Thank you for your order. We\'re preparing your food now.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Order details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Order number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order #'),
                        Text(
                          _orderNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Pickup/Delivery time
                    if (_selectedTimeslot != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_orderType == 'pickup' ? 'Pickup Time' : 'Delivery Time'),
                          Expanded(
                            child: Text(
                              _selectedTimeslot!.displayDateTime,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Order type
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order Type'),
                        Text(
                          _orderType == 'pickup' ? 'Pickup' : 'Delivery',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Payment method
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment'),
                        Text(
                          _formattedPaymentMethod,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Next steps
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What\'s Next?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    const Row(
                      children: [
                        Icon(Icons.timer, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'We\'ll notify you when your order is ready',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Icon(
                          _orderType == 'pickup' ? Icons.location_on : Icons.delivery_dining,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _orderType == 'pickup'
                                ? 'Pick up your order at our restaurant'
                                : 'We\'ll deliver your order to your address',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    const Row(
                      children: [
                        Icon(Icons.receipt, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Show your order number to collect',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/home?tab=menu'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Order Again'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 