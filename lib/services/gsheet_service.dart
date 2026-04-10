import 'package:gsheets/gsheets.dart';

class GSheetService {
  // IMPORTANT: REPLACE THIS with your actual Spreadsheet ID from the browser URL
  static const String _spreadsheetId = '';

  // Your Service Account Credentials - Using Map to avoid JSON parsing issues on web
  static const Map<String, dynamic> _credentialsMap = {
      "type": ",
      "project_id": "",
      "private_key_id": "",
      "private_key": "",
      "client_email": "",
      "client_id": "105943707653710040844",
      "auth_uri": "",
      "token_uri": "",
      "auth_provider_x509_cert_url": "",
      "client_x509_cert_url": "",
      "universe_domain": ""
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
