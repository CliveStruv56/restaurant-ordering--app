# Architecture Overview

## System Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│  Flutter App    │────▶│   Supabase     │────▶│  PostgreSQL     │
│  (iOS/Android)  │     │   (Backend)     │     │  (Database)     │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │                        │
         │                       │                        │
         ▼                       ▼                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Local Storage  │     │   Auth Service  │     │   RLS Policies  │
│  (Cart, Prefs)  │     │   (JWT Tokens)  │     │   (Security)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## Frontend Architecture (Flutter)

### Layer Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── menu_item.dart
│   ├── order.dart
│   ├── cart_item.dart
│   └── option_group.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── menu_service.dart
│   ├── order_service.dart
│   ├── cart_service.dart
│   └── user_service.dart
├── screens/                  # UI screens
│   ├── auth/
│   ├── menu/
│   ├── cart/
│   ├── orders/
│   └── admin/
├── widgets/                  # Reusable components
│   ├── common/
│   └── specific/
└── utils/                    # Utilities
    ├── constants.dart
    ├── validators.dart
    └── logger.dart
```

### State Management
- **Local State**: StatefulWidget for component-specific state
- **Cart State**: Singleton service with SharedPreferences persistence
- **Auth State**: Supabase Auth with stream-based updates
- **Global State**: Service classes with dependency injection pattern

### Navigation
- **GoRouter** for declarative routing
- Deep linking support for QR codes
- Route guards for authentication
- Named routes for type safety

## Backend Architecture (Supabase)

### Database Schema
```sql
-- Core Tables
users (id, email, full_name, role, preferences)
categories (id, name, description, sort_order)
menu_items (id, name, description, price, category_id)
orders (id, user_id, table_number, status, total)
order_items (id, order_id, menu_item_id, quantity)

-- Options System
option_groups (id, name, selection_type, is_required)
options (id, option_group_id, name, price_adjustment)
category_option_groups (category_id, option_group_id)
selected_options (id, order_item_id, option_id)

-- Configuration
restaurant_settings (id, name, address, phone)
opening_hours (id, day_of_week, open_time, close_time)
timeslots (id, start_time, end_time, max_orders)
```

### Security Model
- **Row Level Security (RLS)**: Database-level access control
- **JWT Authentication**: Secure token-based auth
- **Role-based Access**: customer, staff, admin roles
- **API Rate Limiting**: Prevent abuse

### Real-time Features
- Order status updates
- Kitchen notifications
- Inventory changes
- Live dashboard updates

## Data Flow

### Order Placement Flow
```
1. Customer scans QR code → Opens app with table number
2. Browse menu → Select items → Configure options
3. Add to cart → Review order → Place order
4. Payment processing → Order confirmation
5. Kitchen notification → Order preparation
6. Status updates → Customer notifications
7. Order completion → Feedback request
```

### Authentication Flow
```
1. User opens app → Check saved session
2. No session → Show auth screen
3. Login/Register → Supabase Auth
4. Receive JWT → Store securely
5. Auto-refresh tokens → Maintain session
6. Logout → Clear tokens and data
```

## Technology Stack

### Frontend
- **Flutter**: 3.x (Cross-platform framework)
- **Dart**: 3.x (Programming language)
- **GoRouter**: Navigation
- **SharedPreferences**: Local storage
- **HTTP**: Network requests

### Backend
- **Supabase**: Backend as a Service
- **PostgreSQL**: Relational database
- **PostgREST**: RESTful API
- **GoTrue**: Authentication
- **Realtime**: WebSocket server

### Development Tools
- **VS Code / Android Studio**: IDEs
- **Flutter DevTools**: Debugging
- **Postman**: API testing
- **pgAdmin**: Database management
- **Git**: Version control

## Design Patterns

### Repository Pattern
```dart
abstract class Repository<T> {
  Future<List<T>> getAll();
  Future<T> getById(String id);
  Future<T> create(T item);
  Future<T> update(T item);
  Future<void> delete(String id);
}
```

### Service Pattern
```dart
class MenuService {
  final SupabaseClient _client;
  
  Future<List<MenuItem>> getMenuItems() async {
    // Business logic here
  }
}
```

### Model Pattern
```dart
class MenuItem {
  final String id;
  final String name;
  // ... other properties
  
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    // JSON parsing
  }
}
```

## Performance Considerations

### Caching Strategy
- Menu data cached for offline access
- Image caching with expiration
- API response caching
- Cart persistence

### Optimization Techniques
- Lazy loading for images
- Pagination for large lists
- Debouncing for search
- Query optimization

### Monitoring
- Crash reporting (Sentry/Crashlytics)
- Performance monitoring
- User analytics
- Error tracking

## Deployment Architecture

### Mobile App
- Google Play Store (Android)
- Apple App Store (iOS)
- Code signing and certificates
- Version management

### Backend
- Supabase Cloud hosting
- Auto-scaling database
- CDN for static assets
- Backup strategies

## Security Best Practices

### Data Protection
- Encrypt sensitive data
- Secure API endpoints
- Input validation
- SQL injection prevention

### Authentication
- Strong password requirements
- Token expiration
- Secure storage
- Session management

### Compliance
- GDPR compliance
- PCI DSS for payments
- Data retention policies
- Privacy policy

## Scalability Plan

### Horizontal Scaling
- Load balancing
- Database replication
- Caching layers
- CDN implementation

### Vertical Scaling
- Resource monitoring
- Performance profiling
- Query optimization
- Code optimization

## Disaster Recovery

### Backup Strategy
- Daily automated backups
- Point-in-time recovery
- Geographic redundancy
- Test restore procedures

### Incident Response
- Monitoring alerts
- Response procedures
- Communication plan
- Post-mortem process