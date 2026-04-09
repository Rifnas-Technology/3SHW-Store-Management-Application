import 'dart:math';
import 'package:intl/intl.dart';

class ProductUtils {
  static final _currencyFormatter = NumberFormat("#,##0.00", "en_US");

  /// Formats a numeric string into currency format with commas and 2 decimals.
  /// Example: "85200" -> "85,200.00"
  static String formatCurrency(String value) {
    try {
      final number = double.parse(value.replaceAll(',', ''));
      return _currencyFormatter.format(number);
    } catch (e) {
      return value; // Return original if parsing fails
    }
  }
  // Mapping for price encoding
  static final Map<String, String> _encodingMap = {
    '1': 'P',
    '2': 'Q',
    '3': 'R',
    '4': 'S',
    '5': 'T',
    '6': 'U',
    '7': 'V',
    '8': 'W',
    '9': 'X',
    '0': 'Y',
  };

  /// Generates a Product ID with 3 capital letters and 4 digits.
  /// Example: SSS1001
  static String generateProductID() {
    final random = Random();
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    
    String prefix = '';
    for (int i = 0; i < 3; i++) {
      prefix += letters[random.nextInt(letters.length)];
    }
    
    String suffix = '';
    for (int i = 0; i < 4; i++) {
      suffix += random.nextInt(10).toString();
    }
    
    return '$prefix$suffix';
  }

  /// Encodes a numeric price string according to the user mapping.
  /// P-1, Q-2, R-3, S-4, T-5, U-6, V-7, W-8, X-9, Y-0
  static String encodePrice(String price) {
    String encoded = '';
    for (int i = 0; i < price.length; i++) {
      String char = price[i];
      if (_encodingMap.containsKey(char)) {
        encoded += _encodingMap[char]!;
      } else if (char == '.') {
        encoded += '.'; // Keep decimal point if present
      }
    }
    return encoded;
  }
}
