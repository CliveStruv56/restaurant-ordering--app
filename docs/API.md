# API Documentation

## Overview

This application uses Supabase as the backend, which provides a RESTful API automatically generated from the PostgreSQL database schema. All API endpoints require authentication except where noted.

## Base Configuration

```dart
final supabase = Supabase.instance.client;

// Base URL: https://[PROJECT_ID].supabase.co
// Headers:
// - apikey: [ANON_KEY]
// - Authorization: Bearer [JWT_TOKEN]
```

## Authentication

### Sign Up
```dart
final response = await supabase.auth.signUp(
  email: 'user@example.com',
  password: 'password123',
  data: {'full_name': 'John Doe'}, // Additional metadata
);
```

### Sign In
```dart
final response = await supabase.auth.signInWithPassword(
  email: 'user@example.com',
  password: 'password123',
);
```

### Sign Out
```dart
await supabase.auth.signOut();
```

### Get Current User
```dart
final user = supabase.auth.currentUser;
final session = supabase.auth.currentSession;
```

## Menu Management

### Get All Categories
```dart
final categories = await supabase
    .from('categories')
    .select('*')
    .eq('is_active', true)
    .order('sort_order');
```

**Response:**
```json
[
  {
    "id": "uuid",
    "name": "Appetizers",
    "description": "Start your meal",
    "image_url": "https://...",
    "sort_order": 1,
    "is_active": true
  }
]
```

### Get Menu Items
```dart
// All items
final items = await supabase
    .from('menu_items')
    .select('*, categories(name)')
    .eq('is_available', true)
    .order('name');

// By category
final items = await supabase
    .from('menu_items')
    .select('*, categories(name)')
    .eq('category_id', categoryId)
    .eq('is_available', true);
```

**Response:**
```json
[
  {
    "id": "uuid",
    "name": "Margherita Pizza",
    "description": "Classic pizza",
    "price": 18.00,
    "category_id": "uuid",
    "image_url": "https://...",
    "tags": ["pizza", "vegetarian"],
    "is_available": true,
    "categories": {
      "name": "Pizza"
    }
  }
]
```

### Search Menu Items
```dart
final items = await supabase
    .from('menu_items')
    .select('*, categories(name)')
    .or('name.ilike.%$query%,description.ilike.%$query%')
    .eq('is_available', true);
```

## Options System

### Get Option Groups for Category
```dart
// Using RPC function
final options = await supabase
    .rpc('get_menu_item_options', params: {
      'menu_item_id': menuItemId
    });

// Direct query
final optionGroups = await supabase
    .from('category_option_groups')
    .select('''
      option_group_id,
      option_groups!inner(
        id, name, description, selection_type, is_required,
        options(id, name, price_adjustment, is_default, is_available)
      )
    ''')
    .eq('category_id', categoryId)
    .order('sort_order');
```

**Response:**
```json
[
  {
    "option_group_id": "uuid",
    "option_groups": {
      "id": "uuid",
      "name": "Size",
      "selection_type": "single",
      "is_required": true,
      "options": [
        {
          "id": "uuid",
          "name": "Small",
          "price_adjustment": 0,
          "is_default": true
        }
      ]
    }
  }
]
```

## Order Management

### Create Order
```dart
// 1. Create order
final orderResponse = await supabase
    .from('orders')
    .insert({
      'user_id': userId,
      'table_number': tableNumber,
      'total_amount': totalAmount,
      'notes': specialInstructions,
      'delivery_time': deliveryTime,
    })
    .select()
    .single();

// 2. Add order items
final orderItems = cartItems.map((item) => {
  'order_id': orderResponse['id'],
  'menu_item_id': item.menuItemId,
  'quantity': item.quantity,
  'price': item.price,
  'notes': item.notes,
}).toList();

await supabase.from('order_items').insert(orderItems);

// 3. Add selected options
for (final item in orderItemsWithIds) {
  final selectedOptions = item.selectedOptions.map((opt) => {
    'order_item_id': item.id,
    'option_id': opt.optionId,
    'price_adjustment': opt.priceAdjustment,
  }).toList();
  
  await supabase.from('selected_options').insert(selectedOptions);
}
```

### Get User Orders
```dart
final orders = await supabase
    .from('orders')
    .select('*, order_items(*, menu_items(name))')
    .eq('user_id', userId)
    .order('created_at', ascending: false);
```

**Response:**
```json
[
  {
    "id": "uuid",
    "table_number": "A5",
    "status": "preparing",
    "total_amount": 45.50,
    "created_at": "2025-01-15T10:30:00Z",
    "order_items": [
      {
        "id": "uuid",
        "quantity": 2,
        "price": 18.00,
        "menu_items": {
          "name": "Margherita Pizza"
        }
      }
    ]
  }
]
```

### Update Order Status (Admin)
```dart
await supabase
    .from('orders')
    .update({'status': newStatus})
    .eq('id', orderId);
```

**Status Values:**
- `pending` - Order placed
- `confirmed` - Restaurant confirmed
- `preparing` - Being prepared
- `ready` - Ready for pickup/delivery
- `delivered` - Completed
- `cancelled` - Cancelled

## User Management

### Get User Profile
```dart
final profile = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single();
```

### Update User Profile
```dart
await supabase
    .from('users')
    .update({
      'full_name': fullName,
      'phone': phone,
      'address': address,
      'preferences': preferences,
    })
    .eq('id', userId);
```

### Check Admin Status
```dart
final profile = await supabase
    .from('users')
    .select('role')
    .eq('id', userId)
    .single();

final isAdmin = profile['role'] == 'admin';
```

## Restaurant Settings

### Get Restaurant Info
```dart
final settings = await supabase
    .from('restaurant_settings')
    .select('*')
    .single();
```

### Get Opening Hours
```dart
final hours = await supabase
    .from('opening_hours')
    .select('*')
    .order('day_of_week');
```

### Get Available Time Slots
```dart
final slots = await supabase
    .from('available_timeslots')
    .select('*')
    .gte('available_slots', 1)
    .order('start_time');
```

## Real-time Subscriptions

### Order Status Updates
```dart
final subscription = supabase
    .from('orders')
    .stream(primaryKey: ['id'])
    .eq('user_id', userId)
    .listen((List<Map<String, dynamic>> data) {
      // Handle order updates
    });

// Don't forget to cancel when done
subscription.cancel();
```

### Kitchen Orders (Admin)
```dart
final subscription = supabase
    .from('orders')
    .stream(primaryKey: ['id'])
    .in('status', ['pending', 'confirmed', 'preparing'])
    .order('created_at')
    .listen((List<Map<String, dynamic>> data) {
      // Update kitchen display
    });
```

## Error Handling

### Common Error Types
```dart
try {
  final response = await supabase.from('table').select();
} on PostgrestException catch (e) {
  // Database errors
  print('Database error: ${e.message}');
  print('Details: ${e.details}');
  print('Hint: ${e.hint}');
  print('Code: ${e.code}');
} on AuthException catch (e) {
  // Authentication errors
  print('Auth error: ${e.message}');
} catch (e) {
  // Other errors
  print('Unexpected error: $e');
}
```

### Error Codes
- `23505` - Unique violation
- `23503` - Foreign key violation
- `42501` - Insufficient privileges
- `42P01` - Table does not exist
- `PGRST301` - JWT expired

## Rate Limiting

Supabase enforces rate limits:
- **Anonymous requests**: 100 requests per minute
- **Authenticated requests**: 1000 requests per minute
- **Batch operations**: Limit to 1000 records

## Best Practices

### 1. Use Select Sparingly
```dart
// Bad - fetches all columns
final items = await supabase.from('menu_items').select('*');

// Good - fetch only needed columns
final items = await supabase
    .from('menu_items')
    .select('id, name, price, image_url');
```

### 2. Batch Operations
```dart
// Bad - multiple requests
for (final item in items) {
  await supabase.from('table').insert(item);
}

// Good - single batch insert
await supabase.from('table').insert(items);
```

### 3. Use RLS Policies
Ensure Row Level Security is enabled and properly configured:
```sql
-- Example policy
CREATE POLICY "Users can view own orders" ON orders
  FOR SELECT USING (auth.uid() = user_id);
```

### 4. Handle Offline State
```dart
if (!await hasInternetConnection()) {
  // Use cached data
  return getCachedMenuItems();
}
```

### 5. Implement Retry Logic
```dart
Future<T> retryOperation<T>(Future<T> Function() operation) async {
  int attempts = 0;
  while (attempts < 3) {
    try {
      return await operation();
    } catch (e) {
      attempts++;
      if (attempts >= 3) rethrow;
      await Future.delayed(Duration(seconds: attempts));
    }
  }
  throw Exception('Operation failed after 3 attempts');
}
```

## Testing

### Using Postman
1. Set base URL: `https://[PROJECT_ID].supabase.co/rest/v1`
2. Add headers:
   - `apikey`: Your anon key
   - `Authorization`: Bearer [JWT token]
   - `Content-Type`: application/json

### Example Requests

**GET Menu Items:**
```
GET /menu_items?is_available=eq.true&select=*,categories(name)
```

**POST Create Order:**
```json
POST /orders
{
  "user_id": "uuid",
  "table_number": "A5",
  "total_amount": 45.50,
  "notes": "No onions please"
}
```

**PATCH Update Order:**
```json
PATCH /orders?id=eq.uuid
{
  "status": "confirmed"
}
```