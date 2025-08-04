# Restaurant Ordering App

A Flutter-based mobile application for restaurant food ordering with comprehensive admin management features.

## Features

### Customer Features
- 📱 **User Authentication**: Secure login and registration with Supabase
- 🍕 **Menu Browsing**: Browse menu items by category with search functionality
- 🛒 **Shopping Cart**: Add items to cart with quantity management
- ⏰ **Timeslot Booking**: Select pickup/delivery time slots
- 💳 **Checkout**: Complete orders with multiple payment options
- 📦 **Order Tracking**: Track order status in real-time

### Admin Features
- 📊 **Admin Dashboard**: Comprehensive restaurant management
- 🍔 **Menu Management**: Add, edit, and delete menu items with images
- ⏱️ **Timeslot Management**: Configure booking intervals and advance days
- 🏪 **Restaurant Settings**: Manage opening hours and business details
- 📈 **Order Management**: View and manage customer orders

## Tech Stack

- **Frontend**: Flutter/Dart
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **State Management**: Stateful Widgets with callbacks
- **Navigation**: GoRouter
- **Database**: PostgreSQL with Row Level Security (RLS)

## Prerequisites

- Flutter SDK (3.32.8 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Supabase account

## Installation

1. **Clone the repository**
   ```bash
   git clone <your-github-repo-url>
   cd "cursor_test_app"
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   - Copy `.env.example` to `.env`
   - Add your Supabase credentials:
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```

4. **Set up the database**
   - Run the SQL scripts in your Supabase SQL editor:
     - `database_setup.sql` - Core tables
     - `COMPLETE_TIMESLOT_SOLUTION.sql` - Timeslot system
     - `admin_rls_policies_secure.sql` - Security policies

5. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── models/          # Data models
├── screens/         # UI screens
│   ├── auth/        # Authentication screens
│   ├── admin/       # Admin panel screens
│   ├── cart/        # Shopping cart
│   ├── checkout/    # Checkout process
│   ├── menu/        # Menu display
│   └── profile/     # User profile
├── services/        # Business logic and API calls
├── utils/           # Utility functions
└── config/          # App configuration

supabase/
└── *.sql           # Database setup scripts
```

## Key Features Implementation

### Timeslot System
- Dynamic generation based on restaurant settings
- Configurable booking intervals (15, 30, 45, 60 minutes)
- Advance booking days configuration
- Automatic daily maintenance

### Cart Management
- Local storage with SharedPreferences
- Real-time cart count updates
- Persistent cart across app sessions

### Security
- Row Level Security (RLS) policies
- Secure admin role management
- Environment variable protection

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is proprietary software. All rights reserved.

## Contact

Clive Struver - clive@platform91.com

## Acknowledgments

- Built with Flutter and Supabase
- UI components from Material Design
- Icons from Flutter's built-in icon library# restaurant-ordering--app
