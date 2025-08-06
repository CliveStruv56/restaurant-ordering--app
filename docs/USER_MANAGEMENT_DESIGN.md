# User Management System Design

## Overview
A comprehensive user management system for restaurant administrators to handle customer accounts, staff management, and user analytics.

## Features & Structure

### 1. User Management Dashboard

#### User List View
- **Search & Filter**
  - Search by name, email, phone
  - Filter by role (customer, staff, admin)
  - Filter by status (active, inactive, banned)
  - Filter by registration date
  - Filter by last activity

- **User Cards Display**
  - Profile photo/avatar
  - Name, email, phone
  - Role badge with color coding
  - Status indicators:
    - 🟢 Online (active session)
    - 🟡 Has active order
    - 🔵 Has upcoming booking
    - ⚪ Inactive
  - Last seen timestamp
  - Total orders count
  - Account creation date

### 2. Individual User Management

#### User Profile View
- **Basic Information**
  - Full name, email, phone
  - Profile photo
  - Address(es)
  - Registration date
  - Last login
  - Account status

- **Role & Permissions**
  - Current role (customer/staff/admin)
  - Role change history
  - Permission overrides
  - Access restrictions

- **Activity Summary**
  - Total orders placed
  - Total amount spent
  - Average order value
  - Favorite items
  - Last order date
  - Login frequency

#### Quick Actions Panel
- **Account Management**
  - Edit profile information
  - Change role/permissions
  - Reset password (send email)
  - Suspend/activate account
  - Delete account (with confirmation)

- **Communication**
  - Send notification
  - Email customer
  - View message history
  - Set customer notes/tags

### 3. User Creation & Onboarding

#### Add New User Form
- **Basic Details**
  - Full name (required)
  - Email (required, unique)
  - Phone number
  - Role selection
  - Initial password (auto-generated or custom)

- **Advanced Options**
  - Send welcome email
  - Require password change on first login
  - Set account expiry date (for temp staff)
  - Assign to specific location/shift

#### Bulk User Management
- Import users from CSV
- Bulk role changes
- Bulk notifications
- Export user data

### 4. User Analytics & Insights

#### Dashboard Metrics
- Total users by role
- New registrations (daily/weekly/monthly)
- User activity trends
- Top customers by orders/spending
- Inactive user identification

#### Customer Insights
- Order patterns and preferences
- Peak activity times
- Loyalty metrics
- Churn risk indicators

## Implementation Structure

### Database Schema Updates

```sql
-- Add user status and activity tracking
ALTER TABLE users ADD COLUMN IF NOT EXISTS status VARCHAR DEFAULT 'active';
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS tags VARCHAR[];

-- User activity log
CREATE TABLE user_activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  activity_type VARCHAR NOT NULL, -- login, logout, order_placed, etc.
  details JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- User sessions for online status
CREATE TABLE user_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  session_token VARCHAR UNIQUE NOT NULL,
  last_activity TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Flutter Implementation

#### New Screens Structure
```
lib/screens/admin/user_management/
├── user_management_screen.dart     # Main user list
├── user_details_screen.dart        # Individual user view
├── user_form_screen.dart          # Add/edit user
├── user_analytics_screen.dart     # User insights
└── widgets/
    ├── user_card.dart             # User list item
    ├── user_status_indicator.dart # Online/order status
    ├── user_quick_actions.dart    # Action buttons
    └── user_stats_widget.dart     # User statistics
```

#### Service Layer Updates
```dart
// Enhanced UserService methods
class UserService {
  // User CRUD operations
  Future<User> createUser(CreateUserRequest request);
  Future<void> updateUser(String userId, UpdateUserRequest request);
  Future<void> deleteUser(String userId, {bool hardDelete = false});
  
  // User management
  Future<void> suspendUser(String userId, String reason);
  Future<void> activateUser(String userId);
  Future<void> resetPassword(String userId);
  Future<void> sendWelcomeEmail(String userId);
  
  // User analytics
  Future<UserStats> getUserStats(String userId);
  Future<List<UserActivity>> getUserActivity(String userId);
  Future<List<Order>> getUserOrders(String userId);
  
  // Bulk operations
  Future<void> bulkUpdateRole(List<String> userIds, String newRole);
  Future<void> bulkSendNotification(List<String> userIds, String message);
  
  // Session management
  Future<bool> isUserOnline(String userId);
  Future<List<UserSession>> getActiveSessions(String userId);
  Future<void> terminateSession(String sessionId);
}
```

### UI/UX Design Principles

#### User Status Indicators
- **🟢 Online**: Active session within last 5 minutes
- **🟡 Active Order**: Has pending/preparing order
- **🔵 Upcoming Booking**: Has reservation today/tomorrow  
- **🟠 Recently Active**: Last seen within 24 hours
- **⚪ Inactive**: No recent activity
- **🔴 Suspended**: Account suspended

#### Role-Based Access
- **Super Admin**: Full user management access
- **Manager**: Can manage customers and staff (not other admins)
- **Staff**: Can view customer info, cannot modify
- **Customer**: Cannot access user management

#### Security Considerations
- Audit log for all user management actions
- Confirmation dialogs for destructive operations
- Rate limiting on password reset requests
- Two-factor authentication for admin actions
- Data privacy compliance (GDPR/CCPA)

## User Workflows

### 1. Daily Admin Workflow
1. Check dashboard for new registrations
2. Review active orders and their customers
3. Handle customer service issues
4. Monitor suspicious activity

### 2. Customer Service Workflow
1. Search for customer by email/phone
2. View order history and preferences
3. Process refunds or corrections
4. Update customer notes

### 3. Staff Management Workflow
1. Add new staff member
2. Set appropriate role and permissions
3. Send welcome credentials
4. Monitor staff activity and performance

## Phase 1 Implementation (Immediate)
- [ ] Enhanced user list with status indicators
- [ ] User details screen with basic info
- [ ] Add/edit user functionality
- [ ] Role management
- [ ] Password reset capability

## Phase 2 Implementation (Short-term)
- [ ] User activity tracking
- [ ] Session management
- [ ] User analytics dashboard
- [ ] Bulk operations
- [ ] Advanced search and filters

## Phase 3 Implementation (Future)
- [ ] Customer communication system
- [ ] Advanced analytics and insights
- [ ] Automated user lifecycle management
- [ ] Integration with loyalty program
- [ ] Customer segmentation tools

## Success Metrics
- Reduced customer service response time
- Improved user onboarding completion rate
- Better customer retention through proactive management
- Streamlined staff administration
- Enhanced security through better user monitoring