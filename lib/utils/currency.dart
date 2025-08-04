class CurrencyUtils {
  // UK currency formatting
  static const String currencySymbol = '£';
  static const String currencyCode = 'GBP';
  
  /// Format a price with UK pound symbol
  static String formatPrice(double price) {
    return '$currencySymbol${price.toStringAsFixed(2)}';
  }
  
  /// Format a price with currency code (for longer descriptions)
  static String formatPriceWithCode(double price) {
    return '${price.toStringAsFixed(2)} $currencyCode';
  }
  
  /// Standard delivery fee in UK pounds
  static const double deliveryFee = 2.50; // £2.50 instead of $3.00
  
  /// Format delivery fee
  static String formatDeliveryFee() {
    return formatPrice(deliveryFee);
  }
}