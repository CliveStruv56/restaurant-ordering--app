class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Remove any leading/trailing whitespace
    value = value.trim();
    
    // Check for valid email format
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    // Check for common SQL injection patterns
    if (_containsSQLInjectionPatterns(value)) {
      return 'Invalid characters detected in email';
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    if (value.length > 128) {
      return 'Password is too long';
    }
    
    // Check for common SQL injection patterns
    if (_containsSQLInjectionPatterns(value)) {
      return 'Invalid characters detected in password';
    }
    
    return null;
  }
  
  // Strong password validation (optional, for registration)
  static String? validateStrongPassword(String? value) {
    final basicValidation = validatePassword(value);
    if (basicValidation != null) return basicValidation;
    
    if (!RegExp(r'[A-Z]').hasMatch(value!)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }
  
  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    
    // Remove any leading/trailing whitespace
    value = value.trim();
    
    // Remove common phone number formatting characters
    final cleanedPhone = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    
    // Check if it contains only digits
    if (!RegExp(r'^\d+$').hasMatch(cleanedPhone)) {
      return 'Please enter a valid phone number';
    }
    
    // Check length (between 10 and 15 digits)
    if (cleanedPhone.length < 10 || cleanedPhone.length > 15) {
      return 'Please enter a valid phone number';
    }
    
    // Check for SQL injection patterns
    if (_containsSQLInjectionPatterns(value)) {
      return 'Invalid characters detected in phone number';
    }
    
    return null;
  }
  
  // General text input validation
  static String? validateText(String? value, String fieldName, 
      {int? minLength, int? maxLength, bool required = true}) {
    if (required && (value == null || value.isEmpty)) {
      return '$fieldName is required';
    }
    
    if (value != null && value.isNotEmpty) {
      // Remove any leading/trailing whitespace
      value = value.trim();
      
      if (minLength != null && value.length < minLength) {
        return '$fieldName must be at least $minLength characters';
      }
      
      if (maxLength != null && value.length > maxLength) {
        return '$fieldName must be less than $maxLength characters';
      }
      
      // Check for SQL injection patterns
      if (_containsSQLInjectionPatterns(value)) {
        return 'Invalid characters detected in $fieldName';
      }
      
      // Check for script injection patterns
      if (_containsScriptInjectionPatterns(value)) {
        return 'Invalid content detected in $fieldName';
      }
    }
    
    return null;
  }
  
  // Price validation
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    
    // Try to parse as double
    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }
    
    if (price < 0) {
      return 'Price cannot be negative';
    }
    
    if (price > 99999.99) {
      return 'Price is too high';
    }
    
    return null;
  }
  
  // Check for common SQL injection patterns
  static bool _containsSQLInjectionPatterns(String value) {
    final sqlPatterns = [
      RegExp(r"'.*--", caseSensitive: false),
      RegExp(r"'.*or.*'.*=.*'", caseSensitive: false),
      RegExp(r"'.*or.*1.*=.*1", caseSensitive: false),
      RegExp(r"admin'.*--", caseSensitive: false),
      RegExp(r"union.*select", caseSensitive: false),
      RegExp(r"drop.*table", caseSensitive: false),
      RegExp(r"insert.*into", caseSensitive: false),
      RegExp(r"delete.*from", caseSensitive: false),
      RegExp(r"update.*set", caseSensitive: false),
      RegExp(r"exec\(", caseSensitive: false),
      RegExp(r"execute\(", caseSensitive: false),
      RegExp(r"script.*>", caseSensitive: false),
      RegExp(r"javascript:", caseSensitive: false),
    ];
    
    for (final pattern in sqlPatterns) {
      if (pattern.hasMatch(value.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }
  
  // Check for script injection patterns
  static bool _containsScriptInjectionPatterns(String value) {
    final scriptPatterns = [
      RegExp(r"<script", caseSensitive: false),
      RegExp(r"</script>", caseSensitive: false),
      RegExp(r"javascript:", caseSensitive: false),
      RegExp(r"on\w+\s*=", caseSensitive: false), // onclick=, onload=, etc.
      RegExp(r"<iframe", caseSensitive: false),
      RegExp(r"<embed", caseSensitive: false),
      RegExp(r"<object", caseSensitive: false),
    ];
    
    for (final pattern in scriptPatterns) {
      if (pattern.hasMatch(value)) {
        return true;
      }
    }
    
    return false;
  }
  
  // Sanitize input (remove potentially dangerous characters)
  static String sanitizeInput(String input) {
    // Remove any HTML/Script tags
    input = input.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Escape single quotes for SQL safety
    input = input.replaceAll("'", "''");
    
    // Remove any null bytes
    input = input.replaceAll('\x00', '');
    
    return input.trim();
  }
}