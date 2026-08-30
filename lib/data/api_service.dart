import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://pazaryerisaas-production.up.railway.app/api',
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 25),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
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

  Future<Map<String, dynamic>?> upgradeSubscriptionPlan(String planName, {int durationMonths = 1}) async {
    try {
      final response = await _dio.post('/tenant/upgrade-plan', data: {
        'planName': planName,
        'durationMonths': durationMonths,
      });
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

  Future<Map<String, dynamic>?> batchSyncAll({
    required String scope,
    List<String>? productIds,
    List<String>? categoryNames,
    String? syncOperation = 'all',
  }) async {
    try {
      final response = await _dio.post('/products/batch-sync-all', data: {
        'scope': scope,
        'productIds': productIds,
        'categoryNames': categoryNames,
        'syncOperation': syncOperation,
      });
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

  Future<Map<String, dynamic>?> seedDemoProducts() async {
    try {
      final response = await _dio.post('/products/seed-demo-products');
      return response.data;
    } catch (e) {
      return null;
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

  Future<Map<String, dynamic>?> askAiAssistant(String message) async {
    try {
      final response = await _dio.post('/aiassistant/chat', data: {
        'message': message,
      });
      if (response.data != null && response.data is Map<String, dynamic>) {
        return response.data;
      }
    } catch (e) {
      // Backend gecikmesi veya anlık kesinti durumunda akıllı yerel yanıt
    }

    final msg = message.toLowerCase();
    if (msg.contains('temsilci') || msg.contains('whatsapp') || msg.contains('destek') || msg.contains('çağrı') || msg.contains('telefon')) {
      return {
        'reply': '📞 Müşteri Temsilcisi & Canlı Destek Kanallarımız:\n\nUzman ekibimizle dilediğiniz an iletişime geçebilirsiniz:\n* 🟢 WhatsApp Destek Hattı: 7/24 anlık mesajlaşma\n* 📞 Çağrı Merkezi: 0850 000 00 00\n* ✉️ E-Posta: destek@pazaryeri.com',
        'suggestedActions': [
          {'label': '🟢 WhatsApp Canlı Destek', 'actionType': 'open_whatsapp_support'},
          {'label': '📞 Müşteri Temsilcisine Bağlan', 'actionType': 'open_support_channels'},
        ],
        'quickPrompts': ['1 Ay ücretsiz deneme nedir?', 'Trendyol mağazamı nasıl bağlarım?']
      };
    } else if (msg.contains('trendyol') || msg.contains('hepsiburada') || msg.contains('mağaza') || msg.contains('pazaryeri') || msg.contains('bağla') || msg.contains('api')) {
      return {
        'reply': '🔗 Pazaryeri Mağazası Bağlama Rehberi (Trendyol & Hepsiburada):\n\nPazaryerinizi bağlamak yalnızca 1 dakikanızı alır:\n1. Sağ üstteki "Pazaryeri Bağla" butonuna tıklayın.\n2. Açılan listeden mağazanızı seçin (Trendyol, Hepsiburada, Amazon TR, N11, Pazarama vb.).\n3. Satıcı panelinizden temin ettiğiniz Satıcı ID (Merchant ID), API Key ve API Secret bilgilerinizi girip "Bağla" butonuna basın.\n4. Sistem API bağlantınızı 1 saniyede test ederek tüm sipariş ve ürünlerinizi anında merkeze çeker.',
        'suggestedActions': [
          {'label': '🚀 1 Ay Ücretsiz Başla', 'actionType': 'go_register'},
          {'label': '📞 Müşteri Temsilcisine Bağlan', 'actionType': 'open_support_channels'}
        ],
        'quickPrompts': ['2 Al 1 Öde nasıl açılır?', 'Stoklar nasıl eşitlenir?']
      };
    } else if (msg.contains('2 al 1') || msg.contains('kampanya') || msg.contains('promosyon') || msg.contains('indirim') || msg.contains('bogo')) {
      return {
        'reply': '🔥 2 Al 1 Öde & Promosyon Kampanyası Tanımlama:\n\nPazaryeri SaaS panelinde ürünlerinize tek tıkla kampanya kurgusu atayabilirsiniz:\n\n1. Ürün Kataloğu sekmesindeki "+ Yeni Ürün & Kampanya Ekle" butonuna tıklayın.\n2. "🎯 Pazaryeri Kampanyası" seçeneğinden "🔥 2 Al 1 Öde (BOGO)" seçeneğini seçin.\n3. Canlı hesaplayıcı, ürünün satış fiyatına göre müşterinin sepetteki birim maliyetini otomatik hesaplar.\n4. Kaydettiğinizde sistem kampanya etiketini ve sepet indirim kurgusunu Trendyol & Hepsiburada ya otomatik entegre eder.',
        'suggestedActions': [
          {'label': '🚀 Hemen Ücretsiz Başla', 'actionType': 'go_register'},
          {'label': '📞 Müşteri Temsilcisine Bağlan', 'actionType': 'open_support_channels'}
        ],
        'quickPrompts': ['Stok senkronizasyonu nasıl çalışır?', '1 Ay ücretsiz deneme nedir?']
      };
    } else if (msg.contains('ücretsiz') || msg.contains('fiyat') || msg.contains('deneme') || msg.contains('paket') || msg.contains('kapsıyor')) {
      return {
        'reply': '🎁 30 Gün Boyunca Kredi Kartsız %100 Ücretsiz Deneme!\n\nRoaTech\'i kredi kartı girmeden hemen deneyebilirsiniz:\n* 30 Gün Ücretsiz Kullanım\n* 3 Aktif Pazaryeri Bağlantısı (Trendyol, Hepsiburada, Amazon TR vb.)\n* 50 Ürün Kotası & Sınırsız Senkronizasyon\n* 1.2s Gerçek Zamanlı Stok Eşitleme\n* GİB E-Fatura & Kargo Barkodu Basımı',
        'suggestedActions': [
          {'label': '🚀 30 Gün Ücretsiz Başla', 'actionType': 'go_register'},
          {'label': '📞 Müşteri Temsilcisine Bağlan', 'actionType': 'open_support_channels'}
        ],
        'quickPrompts': ['Trendyol mağazamı nasıl bağlarım?', '2 Al 1 Öde nasıl açılır?']
      };
    } else if (msg.contains('stok') || msg.contains('senkron') || msg.contains('eşitle') || msg.contains('1.2')) {
      return {
        'reply': '⚡ Işık Hızında (1.2s) Çok Kanallı Stok Eşitleme:\n\n* Otomatik Düşüş: Trendyol veya Hepsiburada dan 1 adet sipariş geldiğinde, ürünün stoğu 1.2 saniye içinde tüm bağlı diğer kanallarda otomatik düşürülür.\n* Sıfır Çift Satış (Overselling Zero): Stok tükenmesi kaynaklı cezai iptalleri engeller.\n* Tek Tıkla Dağıtım: Ürünler sayfasındaki "⚡ Hızlı Stok Dağıt" butonu ile tüm envanterinizi dilediğiniz an eşitleyebilirsiniz.',
        'suggestedActions': [
          {'label': '🚀 Ücretsiz Başla', 'actionType': 'go_register'},
          {'label': '📞 Müşteri Temsilcisine Bağlan', 'actionType': 'open_support_channels'}
        ],
        'quickPrompts': ['Pazaryeri nasıl bağlanır?', 'Kâr marjımı nasıl hesaplarım?']
      };
    }

    return {
      'reply': 'Merhaba! Ben sizin AI Pazaryeri Danışmanınızım. 🤖\n\nSize aşağıdaki konularda 7/24 rehberlik edebilirim:\n* 🛒 2 Al 1 Öde & Promosyon Kampanyası Tanımlama\n* 🔗 Pazaryeri Mağaza Bağlantıları (Trendyol, Hepsiburada vb.)\n* ⚡ 1.2 Saniyelik Hızlı Stok Eşitleme Mantığı\n* 📑 GİB E-Fatura & Kargo Barkodu Basımı\n* 🖩 Akıllı Komisyon & Kârlı Fiyatlandırma Robotu\n* 🎁 30 Gün Ücretsiz Deneme Paketi Detayları\n\nBana sormak istediğiniz konuyu yazabilir veya aşağıdaki hızlı butonlara basabilirsiniz!',
      'suggestedActions': [
        {'label': '🚀 30 Gün Ücretsiz Başla', 'actionType': 'go_register'},
        {'label': '📞 Müşteri Temsilcisine Bağlan', 'actionType': 'open_support_channels'}
      ],
      'quickPrompts': ['1 Ay ücretsiz deneme nedir?', '2 Al 1 Öde nasıl açılır?', 'Stok senkronizasyonu nasıl çalışır?']
    };
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

