import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/cart_item.dart';
import '../../models/timeslot.dart';
import '../../services/cart_service.dart';
import '../../services/timeslot_service.dart';
import '../../utils/currency.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final TimeslotService _timeslotService = TimeslotService();
  
  List<CartItem> _cartItems = [];
  double _subtotal = 0.0;
  double _deliveryFee = 0.0;
  double _total = 0.0;
  bool _isLoading = true;
  
  // Order options
  String _orderType = 'pickup'; // 'pickup' or 'delivery'
  Timeslot? _selectedTimeslot;
  String _paymentMethod = 'card'; // 'card', 'cash', 'digital_wallet'
  String _specialInstructions = '';
  
  // Available timeslots from backend
  List<Timeslot> _availableTimeslots = [];
  
  // Day selection
  DateTime? _selectedDate;
  Map<DateTime, List<Timeslot>> _timeslotsByDate = {};

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // First, get the advance booking days setting
      final advanceBookingDaysStr = await _timeslotService.getSetting('advance_booking_days');
      final advanceBookingDays = int.tryParse(advanceBookingDaysStr ?? '7') ?? 7;

      // Load cart items and available timeslots in parallel
      final cartItemsResult = await _cartService.getCartItems();
      final subtotalResult = await _cartService.getCartTotal();
      final timeslotsResult = await _timeslotService.getAvailableTimeslots(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: advanceBookingDays)),
      );
      
      // Calculate delivery fee (free for pickup, £2.50 for delivery)
      final deliveryFee = _orderType == 'delivery' ? CurrencyUtils.deliveryFee : 0.0;
      final total = subtotalResult + deliveryFee;

      // Filter and group timeslots by date
      final Map<DateTime, List<Timeslot>> groupedSlots = {};
      final Map<String, Timeslot> uniqueSlots = {};
      
      for (final slot in timeslotsResult) {
        if (slot.isBookable) {
          final key = '${slot.date.toIso8601String().split('T')[0]}_${slot.time}';
          if (!uniqueSlots.containsKey(key)) {
            uniqueSlots[key] = slot;
            
            // Group by date
            final dateKey = DateTime(slot.date.year, slot.date.month, slot.date.day);
            groupedSlots.putIfAbsent(dateKey, () => []).add(slot);
          }
        }
      }
      
      // Sort slots within each date
      for (final dateSlots in groupedSlots.values) {
        dateSlots.sort((a, b) => a.time.compareTo(b.time));
      }
      
      // Sort all slots for the main list
      final sortedSlots = uniqueSlots.values.toList()
        ..sort((a, b) {
          final dateCompare = a.date.compareTo(b.date);
          if (dateCompare != 0) return dateCompare;
          return a.time.compareTo(b.time);
        });

      setState(() {
        _cartItems = cartItemsResult;
        _subtotal = subtotalResult;
        _deliveryFee = deliveryFee;
        _total = total;
        _availableTimeslots = sortedSlots;
        _timeslotsByDate = groupedSlots;
        
        // Auto-select first available date
        if (groupedSlots.isNotEmpty && _selectedDate == null) {
          _selectedDate = groupedSlots.keys.first;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load cart data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateOrderType(String orderType) {
    setState(() {
      _orderType = orderType;
      _selectedTimeslot = null; // Reset timeslot when order type changes
      _deliveryFee = orderType == 'delivery' ? CurrencyUtils.deliveryFee : 0.0;
      _total = _subtotal + _deliveryFee;
    });
  }

  void _updateTimeslot(Timeslot? timeslot) {
    setState(() {
      _selectedTimeslot = timeslot;
    });
  }

  void _updatePaymentMethod(String paymentMethod) {
    setState(() {
      _paymentMethod = paymentMethod;
    });
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today, ${date.day}/${date.month}';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow, ${date.day}/${date.month}';
    } else {
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = dayNames[date.weekday - 1];
      return '$dayName, ${date.day}/${date.month}';
    }
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    } else {
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return dayNames[date.weekday - 1];
    }
  }

  Future<void> _placeOrder() async {
    // Validate required fields
    if (_selectedTimeslot == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a collection time'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_cartItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your cart is empty'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Check if timeslot is still available
    final isStillAvailable = await _timeslotService.isTimeslotAvailable(_selectedTimeslot!.id);
    if (!isStillAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected time slot is no longer available. Please choose another.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      await _loadCartData(); // Refresh timeslots
      return;
    }

    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // In a real app, you would create the order in the database here
      // For now, we'll simulate the process
      await Future.delayed(const Duration(seconds: 2));

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Clear cart after successful order
      await _cartService.clearCart();

      // Navigate to order confirmation with order data
      if (mounted) {
        final orderData = {
          'orderNumber': DateTime.now().millisecondsSinceEpoch.toString().substring(8),
          'orderType': _orderType,
          'paymentMethod': _paymentMethod,
          'selectedTimeslot': _selectedTimeslot?.toJson(),
          'total': _total,
          'subtotal': _subtotal,
          'deliveryFee': _deliveryFee,
          'cartItems': _cartItems.map((item) => {
            'name': item.menuItem.name,
            'quantity': item.quantity,
            'price': item.totalPrice,
          }).toList(),
        };
        
        context.go('/order-confirmation', extra: orderData);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
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
        title: const Text('Checkout'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCheckoutContent(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some items to your cart to checkout',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/home?tab=menu'),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Browse Menu'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary
          _buildOrderSummary(),
          const SizedBox(height: 24),

          // Order Type Selection
          _buildOrderTypeSelection(),
          const SizedBox(height: 24),

          // Time Slot Selection
          _buildTimeslotSelection(),
          const SizedBox(height: 24),

          // Payment Method Selection
          _buildPaymentMethodSelection(),
          const SizedBox(height: 24),

          // Special Instructions
          _buildSpecialInstructions(),
          const SizedBox(height: 24),

          // Order Total
          _buildOrderTotal(),
          const SizedBox(height: 24),

          // Place Order Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Place Order',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Cart items
            ...(_cartItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${item.quantity}x ${item.menuItem.name}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      CurrencyUtils.formatPrice(item.totalPrice),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ))),
            
            const Divider(),
            
            // Totals
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('Subtotal'),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    CurrencyUtils.formatPrice(_subtotal),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('Delivery Fee'),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    CurrencyUtils.formatPrice(_deliveryFee),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    CurrencyUtils.formatPrice(_total),
                    style: const TextStyle(
                      fontSize: 18,
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

  Widget _buildOrderTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Pickup'),
                    subtitle: const Text('Free'),
                    value: 'pickup',
                    groupValue: _orderType,
                    onChanged: (value) => _updateOrderType(value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Delivery'),
                    subtitle: Text('${CurrencyUtils.formatDeliveryFee()} fee'),
                    value: 'delivery',
                    groupValue: _orderType,
                    onChanged: (value) => _updateOrderType(value!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeslotSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _orderType == 'pickup' ? Icons.store : Icons.delivery_dining,
                  color: Colors.deepOrange,
                ),
                const SizedBox(width: 8),
                Text(
                  _orderType == 'pickup' ? 'Collection Time' : 'Delivery Time',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_timeslotsByDate.isEmpty)
                  TextButton.icon(
                    onPressed: _loadCartData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (_timeslotsByDate.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(24.0),
                child: const Column(
                  children: [
                    Icon(Icons.schedule, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No available time slots',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Please try again later or contact the restaurant',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                _orderType == 'pickup' 
                  ? 'Choose a day, then select your collection time:'
                  : 'Choose a day, then select your delivery time:',
                style: const TextStyle(color: Colors.grey),
              ),
              
              const SizedBox(height: 16),
              
              // Day picker buttons
              _buildDayPicker(),
              
              const SizedBox(height: 16),
              
              // Time slots for selected day
              if (_selectedDate != null) _buildTimeSlots(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayPicker() {
    final sortedDates = _timeslotsByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: sortedDates.map((date) {
        final isSelected = _selectedDate?.day == date.day && 
                         _selectedDate?.month == date.month && 
                         _selectedDate?.year == date.year;
        final slotsCount = _timeslotsByDate[date]?.length ?? 0;
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedDate = date;
              // Clear selected slot if changing days
              if (_selectedTimeslot?.date.day != date.day) {
                _selectedTimeslot = null;
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isSelected ? Colors.deepOrange : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.deepOrange : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getDayLabel(date),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$slotsCount slots',
                  style: TextStyle(
                    fontSize: 8,
                    color: isSelected ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSlots() {
    final selectedDateSlots = _timeslotsByDate[_selectedDate] ?? [];
    
    if (selectedDateSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: const Text(
          'No available slots for this day',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available times for ${_getDateLabel(_selectedDate!)}:',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: selectedDateSlots.length,
            itemBuilder: (context, index) {
              final timeslot = selectedDateSlots[index];
              final isSelected = _selectedTimeslot?.id == timeslot.id;
              final isLowCapacity = timeslot.remainingCapacity < 3;
              
              return InkWell(
                onTap: () => _updateTimeslot(timeslot),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.deepOrange 
                        : isLowCapacity 
                            ? Colors.orange[50] 
                            : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.deepOrange 
                          : isLowCapacity 
                              ? Colors.orange[300]! 
                              : Colors.green[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timeslot.displayTime,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${timeslot.remainingCapacity} left',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected 
                              ? Colors.white70 
                              : isLowCapacity 
                                  ? Colors.orange[700] 
                                  : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('Credit/Debit Card'),
              subtitle: const Text('Visa, Mastercard, American Express'),
              value: 'card',
              groupValue: _paymentMethod,
              onChanged: (value) => _updatePaymentMethod(value!),
            ),
            RadioListTile<String>(
              title: const Text('Cash'),
              subtitle: const Text('Pay when you receive your order'),
              value: 'cash',
              groupValue: _paymentMethod,
              onChanged: (value) => _updatePaymentMethod(value!),
            ),
            RadioListTile<String>(
              title: const Text('Digital Wallet'),
              subtitle: const Text('Apple Pay, Google Pay'),
              value: 'digital_wallet',
              groupValue: _paymentMethod,
              onChanged: (value) => _updatePaymentMethod(value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Special Instructions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Any special requests or dietary requirements...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => _specialInstructions = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTotal() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text(CurrencyUtils.formatPrice(_subtotal)),
              ],
            ),
            const SizedBox(height: 8),
            if (_deliveryFee > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delivery Fee'),
                  Text(CurrencyUtils.formatPrice(_deliveryFee)),
                ],
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  CurrencyUtils.formatPrice(_total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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