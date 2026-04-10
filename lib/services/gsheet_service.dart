import 'package:gsheets/gsheets.dart';

class GSheetService {
  // IMPORTANT: REPLACE THIS with your actual Spreadsheet ID from the browser URL
  static const String _spreadsheetId = '1YSOmMxvvOzEig9NiBVeBO6-D-gUtjU2qZTNuOQqIlqU';

  // Your Service Account Credentials - Using Map to avoid JSON parsing issues on web
  static const Map<String, dynamic> _credentialsMap = {
      "type": "service_account",
      "project_id": "sss-hardware",
      "private_key_id": "f0de4f65a6e9cf5f8ce7628e6ac43284a8791491",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDEAMYY3rncTYpN\nPQq6dfH+H+kgmk9UddpcJygDoIwxRzooi89wnsIuI5M2y9hKEev/7WR/hyz/Mci1\nJnq9ovivVvU54Lj5mSE8e2apR5FugotqPa5fGaidj2EjiYGEz5HpyUiCzo3YVc+8\nBWmDv9Od38jn62mzFpX5DR01Fyi7ZVL2vjFgTSo1KactYjexr8EyxVjOGvI1QH06\npqzNZbxgzXesZp9MKUlF77/KqBaGO6fQ1AwvqHMysywkh/BD2TYDwCrpFqCK+/sR\nElWHSinqzj7PThTrdbmoi8cl5HFR1S7kTtICYADKOnnhNr/v1ntG+yKIl5Z9i0fF\ntD3qZJbBAgMBAAECggEAAnj7BsXKhPGyeLJ4L+18ecb3xypDLW7WLBrvWYpdMmLy\nZCANZB+QlgnrWcHdDuQmfMJHJgezxN1hKY3cdwd3CSk46zu/QaDRp0RsQV7ugf0i\nGptAF6GIe8JbCJp7uIvwzIj2QfYummfMuNO9psSU/BUeYPSajwCOMEfe0jRiVmjV\nZlKXBseKiZBMSQFu6LC28NnbbG4NYur8M8gGx7fCUYoI5N3kgBHt8ZHSyLU/8X5b\ncutdipyzMnVv/ejQ0z8XOuYSqAJrdWy6kgV89UeQJn9XmDb/Jo7oGQLeQhECdutv\n9vfIBSd8h2k9WkHELl0euXbU1x33BIok0mRCM9SwAQKBgQDwm4UdDYnZonkj9Z04\nJEmA5tpUJBGfXt3+2IA6UlXPOPYHSuj27CtlYVfu8WIuSBPiqNj3i07NubHn7s7w\nMPaoSAruubUlZPHVQXSbsr/mCjqQetYqOmbV+G+5271F5BGNJAu7mjDlL6JC9C5s\ynY3fMHYELQSIgv8JBddgjGPAQKBgQDQisHB66E7o7GQ02BjwxWz2gfil3cSmFcn\nhcQdj9+wEB8kjEnBd8djY9oz7QCnh177fafMROeF/pNbexDKLRN8KgDFkKne5x+X\nmxzrXj+pf/g1yFND7h4++0lou6IDHoZvYqw3U6r8q8YxWnSkiuyVqlAcRQMi+Ob+\nDc8qOt7HwQKBgFHVc1bITgRZgD48wXZg0ScoXUWU5vF/gJ224RX0/v517yfX0Jh7\Bt96VkAMlUoMdcb3iqPXG7xY1it+S5/h52Kg7ib3vqazSJUxqAl0qFQDUpvlS4Yd\nSvCniMh79koZIecRRXRPIyYwJ04CYu/ZhI+mvP9R3wzzy4O8er3xFA4BAoGASZAI\n1S0XTQBrTJkjsU1JxI2upmGjoS2X4Nsw2PS9hU/KjIvoIJTuAsNgX1zFFFOOT8x9\nenL78KpitKxuucK40t3GM+rZ4UVKQaJ3yxcOAe6gUeh+ZsICbVkbBhTaC5ui9Hus\nIEAlWsgFO7ea2cgfuJPBepdlidqfMRMR9uWZXIECgYEAoGgfv//AlvQ2DclFlhrW\n0sAE5D56qjXRd95GPbaEw1D8VZ/IZ6uumub1WKa7xnwqaGdUo/4MAeORDcqe14xJ\nBsQtYScGoV/9XGFXtA53+GAp0WwpquEiiXkMk1hzsCxmRPoZQ9AghZRtmXRATWE8\nf5mRXKp9UvZeSdEJB0B65mE=\n-----END PRIVATE KEY-----\n",
      "client_email": "sss-hardware@sss-hardware.iam.gserviceaccount.com",
      "client_id": "105943707653710040844",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/sss-hardware%40sss-hardware.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
  };

  static final _gsheets = GSheets(_credentialsMap);
  static Worksheet? _worksheet;
  static List<Map<String, String>>? _cachedProducts;
  
  /// Initializes the worksheet. Creates it if it doesn't exist.
  static Future<void> init() async {
    try {
      print('--- GSheet Diagnostic Start ---');
      print('Current Source Time (Local): ${DateTime.now()}');
      print('Current Source Time (UTC): ${DateTime.now().toUtc()}');
      print('Spreadsheet ID: $_spreadsheetId');
      print('Key Length: ${_credentialsMap['private_key']?.length}');
      print('Client Email: ${_credentialsMap['client_email']}');
      
      if (_worksheet != null) return;
      final ss = await _gsheets.spreadsheet(_spreadsheetId);
      _worksheet = ss.worksheetByTitle('product list') ??
                   await ss.addWorksheet('product list');
      
      // Check if headers exist, if not add them
      final headers = await _worksheet!.values.row(1);
      if (headers.isEmpty) {
        await _worksheet!.values.insertRow(1, [
          'Product ID',
          'Product Name',
          'QR Data',
          'Cost Price (Digit)',
          'Cost Price (Encoded)',
          'Selling Price',
          'Date Added'
        ]);
      }
    } catch (e, stack) {
      print('GSheet Error (Init): $e');
      print('Stack Trace: $stack');
      rethrow;
    }
  }

  /// Appends a new product row and updates the local cache.
  static Future<String?> saveProduct({
    required String id,
    required String name,
    required String qrData,
    required String costPrice,
    required String encodedPrice,
    required String sellingPrice,
  }) async {
    try {
      if (_worksheet == null) await init();
      
      final Map<String, String> newProduct = {
        'id': id,
        'name': name,
        'qrData': qrData,
        'costDigit': costPrice,
        'costEncoded': encodedPrice,
        'sellingPrice': sellingPrice,
        'date': DateTime.now().toIso8601String(),
      };

      final success = await _worksheet!.values.appendRow([
        id,
        name,
        qrData,
        costPrice,
        encodedPrice,
        sellingPrice,
        newProduct['date']!,
      ]);

      if (success) {
        // Optimistic Update: Add to cache immediately
        if (_cachedProducts != null) {
          _cachedProducts!.add(newProduct);
        } else {
          _cachedProducts = [newProduct];
        }
        return null;
      }
      return 'Failed to append row to worksheet.';
    } catch (e) {
      print('Save Product Error: $e');
      return e.toString();
    }
  }

  /// Fetches a product by its ID, prioritizing the local cache for speed.
  static Future<Map<String, String>?> getProductById(String id) async {
    try {
      // Check cache first
      if (_cachedProducts != null) {
        final cached = _cachedProducts!.where((p) => p['id'] == id).toList();
        if (cached.isNotEmpty) return cached.first;
      }

      // If not in cache or cache empty, fetch all (and populate cache)
      final all = await getAllProducts();
      final found = all.where((p) => p['id'] == id).toList();
      return found.isNotEmpty ? found.first : null;
    } catch (e) {
      print('Get Product Error: $e');
      return null;
    }
  }

  /// Fetches all products. Returns a cached List if available for near-instant access.
  static Future<List<Map<String, String>>> getAllProducts({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedProducts != null) {
        return _cachedProducts!;
      }

      if (_worksheet == null) await init();
      
      final allRows = await _worksheet!.values.allRows();
      if (allRows.length <= 1) {
        _cachedProducts = [];
        return [];
      }

      List<Map<String, String>> products = [];
      // Skip headers (row 0)
      for (int i = 1; i < allRows.length; i++) {
        final row = allRows[i];
        if (row.isNotEmpty) {
          products.add({
            'id': row[0],
            'name': row.length > 1 ? row[1] : '',
            'qrData': row.length > 2 ? row[2] : '',
            'costDigit': row.length > 3 ? row[3] : '',
            'costEncoded': row.length > 4 ? row[4] : '',
            'sellingPrice': row.length > 5 ? row[5] : '',
          });
        }
      }
      
      _cachedProducts = products;
      return products;
    } catch (e, stack) {
      print('Get All Products Error: $e');
      print('Stack Trace: $stack');
      return _cachedProducts ?? [];
    }
  }

  /// Use this to manually trigger a fresh sync from Google Sheets
  static void clearCache() {
    _cachedProducts = null;
  }
}
