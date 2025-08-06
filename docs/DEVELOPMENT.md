# Development Guide

## Prerequisites

### Required Software
- **Flutter SDK**: 3.0.0 or higher
- **Dart SDK**: 3.0.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Xcode** (for iOS development on macOS)
- **Git** for version control
- **Postman** or similar for API testing

### Accounts Needed
- **Supabase** account for backend services
- **Google Play Console** account (for Android deployment)
- **Apple Developer** account (for iOS deployment)

## Environment Setup

### 1. Clone the Repository
```bash
git clone [repository-url]
cd cursor-test-app
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Configure Supabase
Create a `lib/config/supabase_config.dart` file:
```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 4. Set Up Environment Variables
Create a `.env` file in the project root:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
STRIPE_PUBLISHABLE_KEY=your_stripe_key
```

### 5. Run Database Migrations
In Supabase SQL Editor, run these scripts in order:
1. `create_tables.sql` - Basic table structure
2. `menu_options_system.sql` - Options system
3. `setup_rls_security_fixed.sql` - Security policies

## Development Workflow

### Running the App

#### Android
```bash
# Check connected devices
flutter devices

# Run on Android emulator
flutter run

# Run on specific device
flutter run -d device_id

# Run in release mode
flutter run --release
```

#### iOS
```bash
# Open iOS Simulator
open -a Simulator

# Run on iOS
flutter run

# Run on specific iOS version
flutter run -d iPhone_14_Pro
```

### Hot Reload & Hot Restart
- **r** - Hot reload (updates UI instantly)
- **R** - Hot restart (restarts app state)
- **q** - Quit
- **p** - Show performance overlay
- **o** - Toggle platform (iOS/Android)

## Code Structure

### Adding a New Feature

1. **Create Model** (`lib/models/`)
```dart
class NewFeature {
  final String id;
  final String name;
  
  NewFeature({required this.id, required this.name});
  
  factory NewFeature.fromJson(Map<String, dynamic> json) {
    return NewFeature(
      id: json['id'],
      name: json['name'],
    );
  }
}
```

2. **Create Service** (`lib/services/`)
```dart
class NewFeatureService {
  final SupabaseClient _client = Supabase.instance.client;
  
  Future<List<NewFeature>> getFeatures() async {
    final response = await _client
        .from('features')
        .select('*');
    
    return response.map((item) => NewFeature.fromJson(item)).toList();
  }
}
```

3. **Create Screen** (`lib/screens/`)
```dart
class NewFeatureScreen extends StatefulWidget {
  @override
  _NewFeatureScreenState createState() => _NewFeatureScreenState();
}
```

4. **Add Route** (`lib/main.dart`)
```dart
GoRoute(
  path: '/new-feature',
  builder: (context, state) => NewFeatureScreen(),
),
```

### State Management Guidelines

#### Local State
Use `StatefulWidget` for UI-only state:
```dart
class _MyWidgetState extends State<MyWidget> {
  bool _isLoading = false;
  
  void _handleTap() {
    setState(() {
      _isLoading = true;
    });
  }
}
```

#### Service State
Use singleton services for shared state:
```dart
class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();
  
  final List<CartItem> _items = [];
  
  List<CartItem> get items => List.unmodifiable(_items);
}
```

## Testing

### Unit Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/menu_service_test.dart

# Run with coverage
flutter test --coverage
```

### Widget Tests
```dart
testWidgets('MenuItem displays correctly', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MenuItemWidget(item: testMenuItem),
    ),
  );
  
  expect(find.text('Test Item'), findsOneWidget);
  expect(find.text('\$9.99'), findsOneWidget);
});
```

### Integration Tests
```bash
# Run integration tests
flutter drive --target=test_driver/app.dart
```

## Debugging

### Flutter Inspector
- Use Flutter Inspector in VS Code/Android Studio
- Inspect widget tree
- View widget properties
- Debug layout issues

### Logging
```dart
import '../utils/logger.dart';

// Debug logging
Logger.debug('Loading menu items');

// Error logging
Logger.error('Failed to load menu', error);

// Info logging
Logger.info('Order placed successfully');
```

### Common Issues

#### Build Errors
```bash
# Clean build
flutter clean
flutter pub get
flutter run

# Reset iOS pods
cd ios
pod deintegrate
pod install
cd ..
```

#### Supabase Connection
- Check internet connection
- Verify Supabase URL and anon key
- Check RLS policies
- Monitor Supabase dashboard logs

## Database Management

### Running SQL Scripts
1. Go to Supabase Dashboard
2. Navigate to SQL Editor
3. Paste and run scripts
4. Check table data in Table Editor

### Creating Migrations
```sql
-- migrations/001_add_new_feature.sql
CREATE TABLE IF NOT EXISTS new_features (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- Add RLS
ALTER TABLE new_features ENABLE ROW LEVEL SECURITY;
```

## API Development

### Adding New Endpoints
Since we use Supabase, "endpoints" are database operations:

```dart
// Get data
final response = await _client
    .from('table_name')
    .select('*')
    .eq('column', value);

// Insert data
final response = await _client
    .from('table_name')
    .insert({'column': value});

// Update data
final response = await _client
    .from('table_name')
    .update({'column': value})
    .eq('id', id);

// Delete data
await _client
    .from('table_name')
    .delete()
    .eq('id', id);
```

### Using RPC Functions
```dart
final response = await _client
    .rpc('function_name', params: {'param': value});
```

## Build & Deployment

### Android Build
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle for Play Store
flutter build appbundle --release
```

### iOS Build
```bash
# Open in Xcode
open ios/Runner.xcworkspace

# Build for iOS
flutter build ios --release

# Archive for App Store
flutter build ipa
```

### Version Management
Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1  # version+buildNumber
```

## Code Style Guidelines

### Naming Conventions
- **Classes**: PascalCase (`MenuItem`, `OrderService`)
- **Variables**: camelCase (`isLoading`, `menuItems`)
- **Constants**: lowerCamelCase with `const` (`const maxItems = 10`)
- **Files**: snake_case (`menu_item.dart`, `order_service.dart`)

### Code Formatting
```bash
# Format all Dart files
flutter format .

# Check formatting
flutter format --set-exit-if-changed .
```

### Best Practices
1. Keep widgets small and focused
2. Extract complex logic to services
3. Use `const` constructors when possible
4. Handle errors gracefully
5. Add meaningful comments
6. Write tests for critical features

## Troubleshooting

### Performance Issues
```bash
# Profile app performance
flutter run --profile

# Analyze app size
flutter build apk --analyze-size
```

### Memory Leaks
- Dispose controllers in `dispose()`
- Cancel subscriptions
- Clear references to large objects

### Network Issues
- Implement retry logic
- Handle offline scenarios
- Cache critical data

## Resources

### Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [Supabase Documentation](https://supabase.io/docs)
- [Dart Documentation](https://dart.dev/guides)

### Community
- Flutter Discord
- Stack Overflow
- GitHub Issues

### Learning
- Flutter Cookbook
- Dart Tutorials
- Supabase Examples

## Contributing

### Code Review Checklist
- [ ] Code follows style guidelines
- [ ] Tests are included
- [ ] Documentation is updated
- [ ] No sensitive data exposed
- [ ] Performance impact considered
- [ ] Error handling implemented

### Pull Request Process
1. Create feature branch
2. Make changes
3. Run tests
4. Update documentation
5. Submit PR with description
6. Address review feedback
7. Merge after approval