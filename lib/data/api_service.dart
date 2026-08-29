import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://pazaryerisaas-production.up.railway.app/api',
      connectTimeout: const Duration(seconds: 5),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<String?> register(String email, String password, String companyName) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'companyName': companyName,
      });
      final token = response.data['token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
      }
      return token;
    } catch (e) {
      return null;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password
      });
      final token = response.data['token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
      }
      return token;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDashboardMetrics() async {
    try {
      final response = await _dio.get('/tenant/dashboard');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>?> getProducts() async {
    try {
      final response = await _dio.get('/products');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createProduct(String title, String sku, double price, int stockQuantity) async {
    try {
      final response = await _dio.post('/products', data: {
        'title': title,
        'sku': sku,
        'price': price,
        'stockQuantity': stockQuantity,
      });
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createRichProduct(Map<String, dynamic> productData) async {
    try {
      final response = await _dio.post('/products/rich', data: productData);
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProductDetails(String productId) async {
    try {
      final response = await _dio.get('/products/$productId');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> uploadProductToTrendyol(String productId) async {
    try {
      final response = await _dio.post('/products/$productId/upload-trendyol');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      final response = await _dio.put('/products/$productId', data: productData);
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      final response = await _dio.delete('/products/$productId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadImage(String base64Data, String fileName) async {
    try {
      final response = await _dio.post('/products/upload-image', data: {
        'base64Data': base64Data,
        'fileName': fileName,
      });
      return response.data?['imageUrl'];
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>?> getMarketplaceConnections() async {
    try {
      final response = await _dio.get('/marketplaces');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> connectMarketplace({
    required int marketplaceType,
    String? storeName,
    String? sellerId,
    String? apiKey,
    String? apiSecret,
  }) async {
    try {
      final response = await _dio.post('/marketplaces/connect', data: {
        'marketplaceType': marketplaceType,
        'storeName': storeName,
        'sellerId': sellerId,
        'apiKey': apiKey,
        'apiSecret': apiSecret,
      });
      return response.data;
    } on DioException catch (e) {
      return {'error': e.response?.data?['message'] ?? e.message};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<bool> deleteMarketplaceConnection(String id) async {
    try {
      final response = await _dio.delete('/marketplaces/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleMarketplaceConnection(String id, bool isActive) async {
    try {
      final response = await _dio.patch('/marketplaces/$id/toggle');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> toggleMarketplaceStatus(String id) async {
    try {
      final response = await _dio.post('/marketplaces/$id/toggle-status');
      return response.data;
    } on DioException catch (e) {
      return {'error': e.response?.data?['message'] ?? e.message};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> validateMarketplace(String id) async {
    try {
      final response = await _dio.post('/marketplaces/$id/validate');
      return response.data;
    } catch (e) {
      return {'isValid': false, 'message': 'Baglanti hatasi'};
    }
  }

  Future<List<dynamic>?> getMarketplaceOrders() async {
    try {
      final response = await _dio.get('/marketplaces/orders');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> syncProduct(String connectionId, String productId) async {
    try {
      final response = await _dio.post('/marketplaces/$connectionId/sync/$productId');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> broadcastStock(String productId, int newStock) async {
    try {
      final response = await _dio.post('/sync/stock/$productId', data: {'newStock': newStock});
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>?> calculatePricing(double baseCost, double profitMargin, double shippingCost, double vat) async {
    try {
      final response = await _dio.post('/pricing/calculate', data: {
        'baseCost': baseCost,
        'targetProfitMarginPercent': profitMargin,
        'shippingCost': shippingCost,
        'vatPercent': vat
      });
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFinancialSummary() async {
    try {
      final response = await _dio.get('/analytics/financial-summary');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  String getInvoiceUrl(String orderId) {
    return 'https://pazaryerisaas-production.up.railway.app/api/invoices/$orderId/html';
  }

  String getShippingLabelUrl(String orderId) {
    return 'https://pazaryerisaas-production.up.railway.app/api/invoices/$orderId/label';
  }
}

