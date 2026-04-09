import 'package:gsheets/gsheets.dart';

class GSheetService {
  // IMPORTANT: REPLACE THIS with your actual Spreadsheet ID from the browser URL
  static const String _spreadsheetId = '1YSOmMxvvOzEig9NiBVeBO6-D-gUtjU2qZTNuOQqIlqU';

  // Your Service Account Credentials - Corrected formatting (no literal newlines in the key)
  static const String _credentials = r'''
{
  "type": "service_account",
  "project_id": "sss-hardware",
  "private_key_id": "54fd4b132bf6e628d53ca036f001b9628dd632ab",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC83Kx1zL3+oGKG\nLq7/YU2BsKOeXHjmnBxAad/0lGltWiYrEm7I9oPS9Re7IaRGskEHHCfi7twjeoN8\nQBtYHzN1mNrZoTCrhvzf9XMOzXNsVUrjAeVjd1QTbLgRb69UqQ4SakzVTr4YFMid\n78hAw+w8ROdi+zFNvV+jcRYP9o/stx7tAopOwL+XcBmyvEfs2hIN9aJugZp/DWnK\n2rrS1p6fd/m0tHFUHbAIiv1mpIRujpINbxuDvFhb94bGnNg4bF9jH/o6Js/2bBUs\nWqz39JSLsDo8h+PjYToGmSoWyWEjWCJyUC7/C1HnX+DzbFrN1dUv+YQGSL+GCMFo\nAl+D/B4BAgMBAAECggEAEDQjYc9UBRV6o9uRLR0KkCl5EvGzzR6wt9VoScI1UhSt\neKg8tBDzxMo9eSiM688zEBVE1iNl5MSypPA/yFg+Sy/MUGa+18CdpT4YWzlFAWhH\nTrcPbhtuAw/4B5rxoThd74uKQF+LT2KdHHEsWQ4rkGIzCLAs4z1vsq9VqWn0oDun\nIoAaF+Mh9FK59A5Yd7u8LscrhVTMbE1zC2RJ2tsmUWVKIwkY2gZgtQgi4FP7I674\nj6iE4ER7jrRZ7y78MSpcnLhKNojVA847Hc9hglg3icvQ/yZjKJicQeTd286ozU75\ndXsSODQEl/KxYWcWamDOAcJUlkPQOX3b5CFf+Ybg/wKBgQD7NqPx+hu1GYrjHY53\nttC/reQkDWbFZoGjDrsoFaYZ4JTlxvuiLdF7ScioXK5oUs1isjP7oNzihxbq88ZZ\nMAOduDtkmBfI3I43t77iPYF54RDmR5hSSHZhHYMPAR3v/c7GBtFg5C/IfQH6I6M9\nDnrFbmPxFZSLlezGqafVl0UbowKBgQDAdeXTdxtwF0nPtJpWXYAh8oaIwoGjwtBT\nn3aLYSsXu5qj6c+b5swrPcqKA1vOnmbSfqvd+mEzvuvqjmOkBJzZ9gEkQH8QXB9W\nu/9i73zgGdM7gmntmqebsH8FzLeAiWnxEL19Kk3BMIwskoc8p8jb7yC/NHZxmaWG\n36dB4Us6CwKBgAa3NzrIzOTSgfwAVkatBHebVnYARbcRPnX1dttjeMVIU7Kw1xlG\n0ErTdiHKGH+BdywkR296pW0I33v4eFz6A567xhqyVjBwdPzYVKoHquZvNdxyHYhV\nl5SRDWfhR8OarWRt2jsU3pIlhWACg+Kl+HI+uT1Arm/s2h+VeX8kRByxAoGAD2Nd\n1OKZFwVFqY3PKUigjhZOG3Ex3F4fOhBt8gb64xLk8mYna1ewy2RNZWuPU53mqr3m\nEAGM9A433rEz1lFoGSVKQhPGFRDIkK7HZKmxWlm2QfPTdGQBMrmR7mzH30cdaWDl\nRbS0MtYm3wl4NqlTrgIYpDEVp0+ZpIcNYH8a/LECgYAqdx5JZfRxujmwjrjG8w+9\nW/92BncmCJmIIRsSeGlgXH8HtDIReA5jr9M/5m5p3yXdXzqkiiFx0sjAZE9RoYaZ\nT2aZCZRgYfISCbMMh/7YjcSgegwJkdpA0DlnUFltpWXi9U8Weow3JauMfhIGMuQm\n93zjINq8WIA+NlxoqohxGA==\n-----END PRIVATE KEY-----\n",
  "client_email": "sss-hardware@sss-hardware.iam.gserviceaccount.com",
  "client_id": "105943707653710040844",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/sss-hardware%40sss-hardware.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''';

  static final _gsheets = GSheets(_credentials);
  static Worksheet? _worksheet;
  static List<Map<String, String>>? _cachedProducts;

  /// Initializes the worksheet. Creates it if it doesn't exist.
  static Future<void> init() async {
    try {
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
    } catch (e) {
      print('GSheet Error: $e');
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
    } catch (e) {
      print('Get All Products Error: $e');
      return _cachedProducts ?? [];
    }
  }

  /// Use this to manually trigger a fresh sync from Google Sheets
  static void clearCache() {
    _cachedProducts = null;
  }
}
