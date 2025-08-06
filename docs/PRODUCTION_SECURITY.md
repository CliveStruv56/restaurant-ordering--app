# Production Security Implementation Guide

## Current Status: Demo Mode (INSECURE)

⚠️ **WARNING**: RLS is currently DISABLED for demo purposes. This means:
- Any user can access any other user's data
- No access controls are in place
- NOT suitable for production use

## Production Implementation Strategy

### 1. **Proper User Authentication Flow**

#### Instead of Manual User Creation:
```dart
// Current demo approach (INSECURE)
await _supabase.from('users').insert(userData);
```

#### Production approach:
```dart
// Use Supabase Auth Admin API
final response = await _supabase.auth.admin.createUser(
  UserAttributes(
    email: email,
    password: password,
    emailConfirm: true,
    userMetadata: {
      'full_name': fullName,
      'role': role,
    },
  ),
);
```

### 2. **JWT-Based Role Management**

#### The Problem with Our Current Approach:
- RLS policies that query the `users` table create infinite recursion
- `EXISTS (SELECT 1 FROM users WHERE...)` causes the policy to call itself

#### The Solution:
- Store role information in JWT token claims
- Use `auth.jwt() ->> 'role'` instead of querying users table
- No recursion because we're not querying the protected table

### 3. **Recommended Production Architecture**

#### A. Authentication Service Layer:
```dart
class ProductionAuthService {
  // Create users via Supabase Auth Admin API
  Future<User> createUser({
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _supabase.auth.admin.createUser(
      UserAttributes(
        email: email,
        password: password,
        userMetadata: {
          'role': role,
          ...?metadata,
        },
      ),
    );
    return response.user!;
  }
  
  // Role-based access control
  Future<bool> hasRole(String role) async {
    final user = _supabase.auth.currentUser;
    return user?.userMetadata?['role'] == role;
  }
}
```

#### B. Database Triggers:
```sql
-- Automatically create user profile when auth user is created
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO users (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

### 4. **Secure RLS Policies (Non-Recursive)**

```sql
-- Use JWT claims instead of querying users table
CREATE POLICY "admins_view_all_users" ON users
    FOR SELECT
    USING (
        auth.uid() = id  -- Users see themselves
        OR 
        (auth.jwt() ->> 'role') = 'admin'  -- Admins see everyone
    );
```

### 5. **Migration Plan from Demo to Production**

#### Phase 1: Implement Proper Auth
1. Set up Supabase Auth Admin API keys
2. Implement `ProductionAuthService`
3. Create database triggers for user profile creation

#### Phase 2: Migrate Existing Data
1. For existing demo users, create proper auth entries
2. Update JWT tokens with role information
3. Test admin access with new auth system

#### Phase 3: Re-enable Security
1. Apply `production_rls_setup.sql`
2. Test all user management functions
3. Verify no infinite recursion occurs

#### Phase 4: Security Audit
1. Test access controls with different user roles
2. Verify customers can't see other customers
3. Verify only admins can manage users
4. Test edge cases and unauthorized access attempts

### 6. **Environment Configuration**

#### Development/Demo:
```env
# Relaxed security for testing
SUPABASE_RLS_ENABLED=false
DEMO_MODE=true
```

#### Production:
```env
# Strict security
SUPABASE_RLS_ENABLED=true
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
DEMO_MODE=false
```

### 7. **Security Checklist for Production**

- [ ] RLS enabled on all sensitive tables
- [ ] JWT-based policies (no recursive queries)
- [ ] Proper auth user creation (no manual inserts)
- [ ] Role-based access controls tested
- [ ] No demo users in production database
- [ ] Service role keys secured
- [ ] Regular security audits scheduled

## Immediate Next Steps

For your current demo, you can continue with RLS disabled, but before production:

1. **Review the `production_rls_setup.sql` script**
2. **Plan the authentication refactor**
3. **Test the JWT-based approach in development**
4. **Gradually migrate to proper auth system**

The current demo mode allows you to develop and test the UI/UX, but remember to implement proper security before any real users access the system!