# Database Documentation

## Schema Overview

The database uses PostgreSQL via Supabase with Row Level Security (RLS) enabled for all tables.

## Core Tables

### users
Stores user account information and profiles.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key, matches auth.users | PK, FK |
| email | VARCHAR | User email address | NOT NULL, UNIQUE |
| full_name | VARCHAR | User's full name | |
| phone | VARCHAR | Phone number | |
| address | TEXT | Delivery address | |
| role | VARCHAR | User role (customer, staff, admin) | DEFAULT 'customer' |
| preferences | JSONB | User preferences and settings | DEFAULT '{}' |
| created_at | TIMESTAMP | Account creation time | DEFAULT NOW() |
| updated_at | TIMESTAMP | Last update time | DEFAULT NOW() |

**RLS Policies:**
- Users can view and update their own profile
- Admins can view and manage all users

### categories
Menu categories for organizing items.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| name | VARCHAR | Category name | NOT NULL, UNIQUE |
| description | TEXT | Category description | |
| image_url | VARCHAR | Category image URL | |
| sort_order | INTEGER | Display order | DEFAULT 0 |
| is_active | BOOLEAN | Show/hide category | DEFAULT true |
| created_at | TIMESTAMP | Creation time | DEFAULT NOW() |

**RLS Policies:**
- Public read access
- Admin-only write access

### menu_items
Individual menu items available for ordering.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| name | VARCHAR | Item name | NOT NULL |
| description | TEXT | Item description | |
| price | DECIMAL(10,2) | Base price | NOT NULL, CHECK > 0 |
| category_id | UUID | Category reference | FK categories(id) |
| image_url | VARCHAR | Item image URL | |
| tags | TEXT[] | Searchable tags | DEFAULT '{}' |
| customizations | JSONB | Legacy customization data | |
| is_available | BOOLEAN | Availability status | DEFAULT true |
| created_at | TIMESTAMP | Creation time | DEFAULT NOW() |
| updated_at | TIMESTAMP | Last update time | DEFAULT NOW() |

**Indexes:**
- idx_menu_items_category_id ON category_id
- idx_menu_items_is_available ON is_available

**RLS Policies:**
- Public read access for available items
- Admin-only write access

### orders
Customer orders with status tracking.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| user_id | UUID | Customer reference | FK users(id) |
| table_number | VARCHAR | Restaurant table number | NOT NULL |
| status | VARCHAR | Order status | DEFAULT 'pending' |
| total_amount | DECIMAL(10,2) | Order total | NOT NULL |
| notes | TEXT | Special instructions | |
| delivery_time | TIME | Requested delivery time | |
| payment_method | VARCHAR | Payment type | |
| payment_status | VARCHAR | Payment status | DEFAULT 'pending' |
| created_at | TIMESTAMP | Order time | DEFAULT NOW() |
| updated_at | TIMESTAMP | Last update | DEFAULT NOW() |

**Status Values:** pending, confirmed, preparing, ready, delivered, cancelled

**RLS Policies:**
- Users can view their own orders
- Users can create orders for themselves
- Admins can view and manage all orders

### order_items
Individual items within an order.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| order_id | UUID | Order reference | FK orders(id) CASCADE |
| menu_item_id | UUID | Menu item reference | FK menu_items(id) |
| quantity | INTEGER | Item quantity | NOT NULL, CHECK > 0 |
| price | DECIMAL(10,2) | Price at order time | NOT NULL |
| notes | TEXT | Item-specific notes | |
| created_at | TIMESTAMP | Creation time | DEFAULT NOW() |

**RLS Policies:**
- Users can view items from their orders
- Users can create items for their orders
- Admins can manage all order items

## Options System Tables

### option_groups
Groups of options (e.g., "Size", "Milk Type").

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| name | VARCHAR | Group name | NOT NULL |
| description | TEXT | Group description | |
| selection_type | VARCHAR | single/multiple | NOT NULL |
| is_required | BOOLEAN | Must select option | DEFAULT false |
| icon_url | VARCHAR | Group icon | |
| sort_order | INTEGER | Display order | DEFAULT 0 |
| created_at | TIMESTAMP | Creation time | DEFAULT NOW() |
| updated_at | TIMESTAMP | Last update | DEFAULT NOW() |

### options
Individual options within groups.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| option_group_id | UUID | Group reference | FK option_groups(id) CASCADE |
| name | VARCHAR | Option name | NOT NULL |
| description | TEXT | Option description | |
| price_adjustment | DECIMAL(10,2) | Price modifier | DEFAULT 0 |
| icon_url | VARCHAR | Option icon | |
| is_available | BOOLEAN | Availability | DEFAULT true |
| is_default | BOOLEAN | Pre-selected | DEFAULT false |
| depends_on_option_id | UUID | Conditional display | FK options(id) |
| sort_order | INTEGER | Display order | DEFAULT 0 |
| created_at | TIMESTAMP | Creation time | DEFAULT NOW() |
| updated_at | TIMESTAMP | Last update | DEFAULT NOW() |

### category_option_groups
Links option groups to menu categories.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| category_id | UUID | Category reference | FK categories(id) CASCADE |
| option_group_id | UUID | Option group reference | FK option_groups(id) CASCADE |
| sort_order | INTEGER | Display order | DEFAULT 0 |
| is_required | BOOLEAN | Override group requirement | |
| created_at | TIMESTAMP | Creation time | DEFAULT NOW() |

**Unique Constraint:** (category_id, option_group_id)

### selected_options
Options selected for order items.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| order_item_id | UUID | Order item reference | FK order_items(id) CASCADE |
| option_id | UUID | Selected option | FK options(id) |
| quantity | INTEGER | Option quantity | DEFAULT 1 |
| price_adjustment | DECIMAL(10,2) | Price at order time | NOT NULL |
| created_at | TIMESTAMP | Creation time | DEFAULT NOW() |

## Configuration Tables

### restaurant_settings
Global restaurant configuration.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| restaurant_name | VARCHAR | Restaurant name | NOT NULL |
| address | TEXT | Physical address | |
| phone | VARCHAR | Contact number | |
| email | VARCHAR | Contact email | |
| currency | VARCHAR | Currency code | DEFAULT 'USD' |
| tax_rate | DECIMAL(5,2) | Tax percentage | DEFAULT 0 |
| delivery_fee | DECIMAL(10,2) | Delivery charge | DEFAULT 0 |
| min_order_amount | DECIMAL(10,2) | Minimum order | DEFAULT 0 |
| max_advance_days | INTEGER | Order ahead limit | DEFAULT 7 |
| time_zone | VARCHAR | Restaurant timezone | DEFAULT 'UTC' |
| created_at | TIMESTAMP | Creation time | DEFAULT NOW() |
| updated_at | TIMESTAMP | Last update | DEFAULT NOW() |

### opening_hours
Restaurant operating hours by day.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| day_of_week | INTEGER | Day (0=Sunday) | NOT NULL, CHECK 0-6 |
| open_time | TIME | Opening time | NOT NULL |
| close_time | TIME | Closing time | NOT NULL |
| is_closed | BOOLEAN | Closed all day | DEFAULT false |
| created_at | TIMESTAMP | Creation time | DEFAULT NOW() |

**Unique Constraint:** day_of_week

### timeslots
Available ordering time slots.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| id | UUID | Primary key | PK, DEFAULT uuid_generate_v4() |
| start_time | TIME | Slot start time | NOT NULL |
| end_time | TIME | Slot end time | NOT NULL |
| max_orders | INTEGER | Order limit | DEFAULT 10 |
| is_active | BOOLEAN | Slot availability | DEFAULT true |
| days_of_week | INTEGER[] | Available days | DEFAULT '{0,1,2,3,4,5,6}' |
| created_at | TIMESTAMP | Creation time | DEFAULT NOW() |

## Views

### category_options_view
Denormalized view of categories with their option groups.

```sql
CREATE VIEW category_options_view AS
SELECT 
    c.id as category_id,
    c.name as category_name,
    og.id as option_group_id,
    og.name as option_group_name,
    og.selection_type,
    og.is_required,
    cog.sort_order
FROM categories c
JOIN category_option_groups cog ON c.id = cog.category_id
JOIN option_groups og ON cog.option_group_id = og.id
WHERE c.is_active = true
ORDER BY c.sort_order, cog.sort_order;
```

### available_timeslots
View of currently available ordering slots.

```sql
CREATE VIEW available_timeslots AS
SELECT 
    ts.*,
    COALESCE(order_counts.count, 0) as current_orders,
    (ts.max_orders - COALESCE(order_counts.count, 0)) as available_slots
FROM timeslots ts
LEFT JOIN (
    SELECT delivery_time, COUNT(*) as count
    FROM orders
    WHERE date = CURRENT_DATE
    AND status NOT IN ('cancelled', 'delivered')
    GROUP BY delivery_time
) order_counts ON ts.start_time = order_counts.delivery_time
WHERE ts.is_active = true
AND EXTRACT(DOW FROM CURRENT_DATE) = ANY(ts.days_of_week);
```

## Functions

### get_menu_item_options
RPC function to get all options for a menu item based on its category.

```sql
CREATE OR REPLACE FUNCTION get_menu_item_options(menu_item_id UUID)
RETURNS TABLE (
    option_group_id UUID,
    option_group_name VARCHAR,
    selection_type VARCHAR,
    is_required BOOLEAN,
    option_id UUID,
    option_name VARCHAR,
    price_adjustment DECIMAL,
    is_default BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        og.id, og.name, og.selection_type, og.is_required,
        o.id, o.name, o.price_adjustment, o.is_default
    FROM menu_items mi
    JOIN category_option_groups cog ON mi.category_id = cog.category_id
    JOIN option_groups og ON cog.option_group_id = og.id
    JOIN options o ON og.id = o.option_group_id
    WHERE mi.id = menu_item_id
    AND o.is_available = true
    ORDER BY cog.sort_order, og.sort_order, o.sort_order;
END;
$$ LANGUAGE plpgsql;
```

## Indexes

### Performance Indexes
```sql
-- Menu item searches
CREATE INDEX idx_menu_items_name_search ON menu_items USING gin(to_tsvector('english', name));
CREATE INDEX idx_menu_items_tags ON menu_items USING gin(tags);

-- Order lookups
CREATE INDEX idx_orders_user_id_created ON orders(user_id, created_at DESC);
CREATE INDEX idx_orders_status ON orders(status) WHERE status != 'delivered';

-- Option relationships
CREATE INDEX idx_options_group_id ON options(option_group_id);
CREATE INDEX idx_selected_options_order_item ON selected_options(order_item_id);
```

## Migrations

### Migration Naming Convention
```
YYYYMMDD_HHMMSS_description.sql
Example: 20250805_143000_add_option_system.sql
```

### Migration Template
```sql
-- Migration: Add new feature
-- Date: YYYY-MM-DD
-- Author: Name

BEGIN;

-- Add your changes here
ALTER TABLE ...

-- Add RLS policies if needed
ALTER TABLE new_table ENABLE ROW LEVEL SECURITY;

-- Verify changes
SELECT 'Migration complete' as status;

COMMIT;
```

## Backup and Recovery

### Backup Strategy
- Daily automated backups via Supabase
- Point-in-time recovery available
- Export critical data weekly

### Recovery Procedures
1. Identify backup point
2. Test in staging environment
3. Coordinate downtime
4. Execute recovery
5. Verify data integrity

## Performance Tuning

### Query Optimization
- Use appropriate indexes
- Avoid N+1 queries
- Batch operations when possible
- Monitor slow queries

### Maintenance Tasks
```sql
-- Update statistics
ANALYZE;

-- Vacuum tables
VACUUM ANALYZE menu_items;
VACUUM ANALYZE orders;

-- Reindex if needed
REINDEX TABLE menu_items;
```

## Security Considerations

### RLS Best Practices
1. Enable RLS on all tables
2. Default deny, explicit allow
3. Test policies thoroughly
4. Avoid recursive policies
5. Use service role sparingly

### Data Privacy
- Hash sensitive data
- Implement data retention
- Audit access logs
- Regular security reviews