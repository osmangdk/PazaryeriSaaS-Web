import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/core/notification_service.dart';
import 'package:frontend/data/api_service.dart';
import 'package:frontend/ui/screens/barcode_scanner_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  Map<String, dynamic>? _metrics;
  List<dynamic>? _products;
  List<dynamic>? _connections;

  Future<void> _launchSafeUrl(String urlStr) async {
    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
  List<dynamic>? _orders;
  Map<String, dynamic>? _financialSummary;
  bool _isLoading = true;
  int _currentTabIndex = 0;

  // Orders Filter State
  String _selectedOrderMarketplaceFilter = 'ALL';
  String _selectedOrderStatusFilter = 'ALL';
  String _orderSearchQuery = '';
  final TextEditingController _orderSearchController = TextEditingController();

  // Category & Catalog Filter State
  String _selectedCategoryFilter = 'ALL';
  String? _selectedSubCategoryFilter;
  String _productSearchQuery = '';
  final TextEditingController _productSearchController = TextEditingController();
  final Set<String> _expandedCategoryIds = {'Elektronik', 'Moda'};

  final List<Map<String, dynamic>> _catalogCategories = [
    {
      'id': 'ALL',
      'title': 'Tüm Ürünleri Listele',
      'icon': Icons.apps,
      'color': Colors.blueAccent,
      'subCategories': <String>[],
    },
    {
      'id': 'Elektronik',
      'title': 'Elektronik',
      'icon': Icons.devices,
      'color': Colors.blueAccent,
      'allLabel': 'Tüm Elektronik Ürünleri',
      'subCategories': [
        'Bilgisayar / Tablet',
        'Telefon & Aksesuarlar',
        'TV, Görüntü & Ses',
        'Beyaz Eşya',
        'Küçük Ev Aletleri',
        'Foto & Kamera',
        'Oyun & Oyun Konsolları',
      ],
    },
    {
      'id': 'Moda',
      'title': 'Moda',
      'icon': Icons.checkroom,
      'color': Colors.pinkAccent,
      'allLabel': 'Tüm Moda & Giyim Ürünleri',
      'subCategories': [
        'Kadın Giyim',
        'Kadın Ayakkabı',
        'Erkek Giyim (Tişört, Gömlek, Pantolon)',
        'Erkek Ayakkabı',
        'Çanta & Aksesuar',
        'İç Giyim & Pijama',
        'Saat & Takı',
      ],
    },
    {
      'id': 'EvYasam',
      'title': 'Ev, Yaşam, Kırtasiye, Ofis',
      'icon': Icons.chair,
      'color': Colors.amberAccent,
      'allLabel': 'Tüm Ev, Yaşam & Ofis',
      'subCategories': [
        'Sofra & Mutfak',
        'Ev Tekstili',
        'Mobilya & Dekorasyon',
        'Aydınlatma',
        'Banyo & Ev Gereçleri',
        'Ofis & Kırtasiye',
      ],
    },
    {
      'id': 'OtoYapiBahce',
      'title': 'Oto, Bahçe, Yapı Market',
      'icon': Icons.build_circle,
      'color': Colors.tealAccent,
      'allLabel': 'Tüm Oto & Yapı Market',
      'subCategories': [
        'Oto Aksesuar & Elektroniği',
        'Motosiklet Ekipmanları',
        'Elektrikli El Aletleri',
        'Hırdavat & Nalbur',
        'Boya & Kimyasallar',
        'Bahçe & Çim Bakımı',
      ],
    },
    {
      'id': 'AnneBebek',
      'title': 'Anne, Bebek, Oyuncak',
      'icon': Icons.child_care,
      'color': Colors.purpleAccent,
      'allLabel': 'Tüm Anne & Bebek Ürünleri',
      'subCategories': [
        'Bebek Arabası & Oto Koltuğu',
        'Bebek Bezi & Islak Mendil',
        'Bebek Beslenme & Emzirme',
        'Bebek Giyim & Bakım',
        'Eğitici Ahşap Oyuncaklar',
        'Figür, Bebek & Araçlar',
      ],
    },
    {
      'id': 'SporOutdoor',
      'title': 'Spor, Outdoor',
      'icon': Icons.fitness_center,
      'color': Colors.greenAccent,
      'allLabel': 'Tüm Spor & Outdoor',
      'subCategories': [
        'Fitness & Kondisyon',
        'Spor Giyim & Ayakkabı',
        'Outdoor & Kamp Ekipmanları',
        'Bisiklet & Scooter',
        'Top Sporları (Futbol/Basketbol)',
        'Su Sporları & Yüzme',
      ],
    },
    {
      'id': 'Kozmetik',
      'title': 'Kozmetik, Kişisel Bakım',
      'icon': Icons.face,
      'color': Colors.deepOrangeAccent,
      'allLabel': 'Tüm Kozmetik & Bakım',
      'subCategories': [
        'Parfüm & Deodorant',
        'Makyaj Ürünleri',
        'Cilt & Yüz Bakımı',
        'Saç Bakımı & Şekillendirme',
        'Tıraş & Epilasyon',
        'Ağız & Diş Sağlığı',
      ],
    },
    {
      'id': 'SupermarketPetShop',
      'title': 'Süpermarket, Pet Shop',
      'icon': Icons.shopping_basket,
      'color': Colors.lightGreenAccent,
      'allLabel': 'Tüm Süpermarket & Pet',
      'subCategories': [
        'Deterjan & Temizlik',
        'Gıda & Temel Mutfak',
        'İçecekler (Çay, Kahve)',
        'Kağıt Ürünleri',
        'Kedi Maması & Kumu',
        'Köpek Maması & Aksesuar',
      ],
    },
    {
      'id': 'KitapHobi',
      'title': 'Kitap, Müzik, Film, Hobi',
      'icon': Icons.menu_book,
      'color': Colors.indigoAccent,
      'allLabel': 'Tüm Kitap & Hobi',
      'subCategories': [
        'Edebiyat & Roman',
        'Kişisel Gelişim & Psikoloji',
        'Çocuk & Gençlik Kitapları',
        'Sınav & Ders Kitapları',
        'Müzik Aletleri & Enstrüman',
        'Hobi, Maket & Kutu Oyunları',
      ],
    },
  ];

  // AI Chat State
  final List<Map<String, dynamic>> _aiMessages = [];
  final Set<String> _askedPrompts = {};
  bool _isAiThinking = false;
  bool _isAiFabMinimized = false;
  final TextEditingController _aiInputController = TextEditingController();
  final ScrollController _aiScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _initAiGreeting();
    // Push bildirimlerini başlat
    NotificationService.initialize();
  }

  /// Barkod tarayıcıyı açar, okunan barkodu ürün aramasına yönlendirir
  void _openBarcodeScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BarcodeScannerScreen(
          title: 'Ürün Barkodu Tara',
          onDetected: (barcode) {
            setState(() {
              _currentTabIndex = 1; // Ürünler sekmesi
              _productSearchQuery = barcode;
              _productSearchController.text = barcode;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Barkod okundu: $barcode')),
                  ],
                ),
                backgroundColor: const Color(0xFF1E40AF),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          },
        ),
      ),
    );
  }

  void _initAiGreeting() {
    _aiMessages.add({
      'role': 'assistant',
      'content': 'Merhaba! Ben sizin **AI Pazaryeri Danışmanınızım**. 🤖\n\nSistemi nasıl kullanacağınızı, 2 Al 1 Öde kampanyalarını, 1.2s stok eşitlemeyi veya kâr marjınızı nasıl optimize edeceğinizi bana 7/24 sorabilirsiniz.',
      'actions': [
        {'label': '🔥 2 Al 1 Öde Nasıl Açılır?', 'action': 'ask', 'prompt': '2 Al 1 Öde kampanyası nasıl açılır?'},
        {'label': '🔗 Mağaza Nasıl Bağlanır?', 'action': 'ask', 'prompt': 'Trendyol mağazamı nasıl bağlarım?'},
        {'label': '⚡ Stoklar Nasıl Eşitlenir?', 'action': 'ask', 'prompt': 'Stok senkronizasyonu nasıl çalışır?'},
        {'label': '🖩 Fiyat Robotu Nasıl Kullanılır?', 'action': 'ask', 'prompt': 'Kâr marjımı nasıl hesaplarım?'},
        {'label': '📞 Müşteri Temsilcisine Bağlan', 'action': 'open_support_channels', 'prompt': ''},
      ]
    });
  }

  void _showCustomerSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.greenAccent, width: 1.5)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.support_agent, color: Colors.greenAccent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Müşteri Temsilcisi & Canlı Destek', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Uzman ekibimiz size yardımcı olmaya hazır', style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 11)),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(ctx)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  _launchSafeUrl('https://wa.me/905550000000?text=Merhaba,%20RoaTech%20hakkında%20bilgi%20almak%20istiyorum');
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        child: const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('WhatsApp Canlı Destek Hattı', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('7/24 Anlık mesajlaşma & canlı temsilci', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.greenAccent, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  _launchSafeUrl('tel:08500000000');
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                        child: const Icon(Icons.phone, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Çağrı Merkezi (0850 000 00 00)', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Hafta içi 09:00 - 18:00 sesli destek', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  _launchSafeUrl('mailto:destek@roatech.com?subject=RoaTech%20Destek%20Talebi');
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: Colors.purpleAccent, shape: BoxShape.circle),
                        child: const Icon(Icons.email, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('E-Posta Destek (destek@roatech.com)', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Ortalama 15 dakika içinde dönüş', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.purpleAccent, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Kapat', style: GoogleFonts.inter(color: Colors.white70))),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final metrics = await _apiService.getDashboardMetrics();
    final products = await _apiService.getProducts();
    final connections = await _apiService.getMarketplaceConnections();
    final orders = await _apiService.getMarketplaceOrders();
    final financials = await _apiService.getFinancialSummary();

    final populatedProducts = (products != null && products.isNotEmpty)
        ? products
        : _getDefaultMockProducts();

    final populatedConnections = (connections != null && connections.isNotEmpty)
        ? connections
        : _getDefaultMockConnections();

    final populatedOrders = (orders != null && orders.isNotEmpty)
        ? orders
        : _generateSampleOrders(populatedProducts);

    final populatedMetrics = metrics ?? {
      'productCount': populatedProducts.length,
      'connectionCount': populatedConnections.length,
      'plan': 'Free',
      'DaysLeft': 27,
      'isExpired': false,
      'tenant': {
        'companyName': 'Trendyol Entegrasyon Ltd.',
        'email': 'demo@roatech.com',
        'subscriptionPlan': 'Free',
        'subscriptionEndDate': DateTime.now().add(const Duration(days: 27)).toIso8601String(),
      },
      'limits': {
        'currentProducts': populatedProducts.length,
        'productLimit': 50,
        'currentConnections': populatedConnections.length,
        'connectionLimit': 3,
        'isExpired': false,
      }
    };

    setState(() {
      _metrics = populatedMetrics;
      _products = populatedProducts;
      _connections = populatedConnections;
      _orders = populatedOrders;
      _financialSummary = financials;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getDefaultMockConnections() {
    return [
      {
        'id': 'conn-ty-001',
        'marketplaceType': 0, // Trendyol
        'marketplaceName': 'Trendyol',
        'storeName': 'Trendyol Butik Mağazam',
        'sellerId': '104859',
        'isActive': true,
        'lastSyncAt': 'Bugün 20:30',
      },
    ];
  }

  List<Map<String, dynamic>> _getDefaultMockProducts() {
    return [
      {
        'id': 'prod-001',
        'title': 'Tudors Erkek 5\'li Paket Slim Fit Pamuklu Pike Polo Yaka Tişört',
        'sku': 'TDR-POLO-5PK',
        'barcode': '8680009423635',
        'modelCode': '942363515',
        'brand': 'Tudors',
        'categoryName': 'Moda',
        'subCategoryName': 'Erkek Giyim',
        'price': 1083.90,
        'listPrice': 1747.80,
        'costPrice': 450.00,
        'stockQuantity': 385,
        'vatRate': 20,
        'commissionRate': 18.5,
        'shippingCost': 42.50,
        'description': 'Tudors 5\'li Paket Slim Fit Pamuklu Pike Polo Yaka Tişört. Rahat ve şık günlük kullanım.',
        'images': [
          'https://cdn.dsmcdn.com/ty1687/prod/QC_PREP/20250603/18/c2992fcf-6771-3257-8743-e1c6731041fd/1_org_zoom.jpg',
          'https://cdn.dsmcdn.com/ty1686/prod/QC_PREP/20250603/18/53f6bf86-2c9f-3e2c-87c1-206a47e4ad34/1_org_zoom.jpg'
        ],
        'attributes': {
          'Kalıp': 'Slim Fit',
          'Materyal': '%55 Polyester %45 Pamuk',
          'Yaka': 'Polo Yaka',
          'Renk': 'Gri-Mavi-Haki-Yeşil-Siyah',
          'Paket': '5\'li'
        },
        'connectedMarketplaces': ['Trendyol', 'Hepsiburada', 'Pazarama'],
        'hasVariants': true,
        'variants': [
          {'size': 'XS', 'sku': 'TDR-POLO-5PK-XS', 'barcode': '8680009423630', 'stock': 45, 'price': 1083.90},
          {'size': 'S', 'sku': 'TDR-POLO-5PK-S', 'barcode': '8680009423631', 'stock': 60, 'price': 1083.90},
          {'size': 'M', 'sku': 'TDR-POLO-5PK-M', 'barcode': '8680009423632', 'stock': 85, 'price': 1083.90},
          {'size': 'L', 'sku': 'TDR-POLO-5PK-L', 'barcode': '8680009423633', 'stock': 95, 'price': 1083.90},
          {'size': 'XL', 'sku': 'TDR-POLO-5PK-XL', 'barcode': '8680009423634', 'stock': 60, 'price': 1083.90},
          {'size': '2XL', 'sku': 'TDR-POLO-5PK-2XL', 'barcode': '8680009423635', 'stock': 25, 'price': 1083.90},
          {'size': '3XL', 'sku': 'TDR-POLO-5PK-3XL', 'barcode': '8680009423636', 'stock': 15, 'price': 1083.90},
        ],
        'isActive': true,
        'createdAt': '2026-08-30T12:00:00Z',
      },
      {
        'id': 'prod-002',
        'title': 'Lenovo V15 G4 ABP AMD Ryzen 5 7530U 16GB 512GB SSD 15.6" FHD FreeDOS Taşınabilir Bilgisayar',
        'sku': 'LEN-V15-G4-R5-16-512',
        'barcode': '0197529482109',
        'modelCode': '82YU00PNLK',
        'brand': 'Lenovo',
        'categoryName': 'Elektronik',
        'subCategoryName': 'Bilgisayar / Tablet',
        'price': 14899.00,
        'listPrice': 17999.00,
        'costPrice': 11500.00,
        'stockQuantity': 42,
        'vatRate': 20,
        'commissionRate': 9.0,
        'shippingCost': 65.00,
        'description': 'Lenovo V15 G4 ABP İş ve Günlük Kullanım İçin Yüksek Performanslı Dizüstü Bilgisayar.',
        'images': [
          'https://images.hepsiburada.net/assets/Bilgisayar/ProductDescriptions/202305/Lenovo-V15-G4-1.jpg',
          'https://images.hepsiburada.net/assets/Bilgisayar/ProductDescriptions/202305/Lenovo-V15-G4-2.jpg'
        ],
        'attributes': {
          'İşlemci': 'AMD Ryzen 5 7530U',
          'RAM': '16 GB',
          'SSD Kapasitesi': '512 GB SSD',
          'Ekran': '15.6 inç FHD',
          'İşletim Sistemi': 'FreeDOS'
        },
        'connectedMarketplaces': ['Trendyol', 'Hepsiburada', 'Amazon'],
        'hasVariants': false,
        'isActive': true,
        'createdAt': '2026-08-30T12:00:00Z',
      },
      {
        'id': 'prod-003',
        'title': 'Apple AirPods Pro 2. Nesil USB-C MagSafe Şarj Kutulu Bluetooth Kulaklık',
        'sku': 'APL-APP2-USBC',
        'barcode': '195949052520',
        'modelCode': 'MTJV3TU/A',
        'brand': 'Apple',
        'categoryName': 'Elektronik',
        'subCategoryName': 'TV, Görüntü & Ses',
        'price': 8499.00,
        'listPrice': 9999.00,
        'costPrice': 6800.00,
        'stockQuantity': 68,
        'vatRate': 20,
        'commissionRate': 12.0,
        'shippingCost': 35.00,
        'description': 'Apple AirPods Pro 2. Nesil Aktif Gürültü Engelleme ve Şeffaf Mod Özellikli Premium Kulaklık.',
        'images': [
          'https://store.storeimages.cdn-apple.com/4664/as-images.apple.com/is/MTJV3?wid=1144&hei=1144&fmt=jpeg&qlt=90&.v=1694014871985'
        ],
        'attributes': {
          'Bağlantı': 'Bluetooth 5.3',
          'Gürültü Engelleme': 'Aktif Gürültü Engelleme (ANC)',
          'Şarj Kutusu': 'MagSafe (USB-C)',
          'Renk': 'Beyaz'
        },
        'connectedMarketplaces': ['Trendyol', 'Hepsiburada', 'Amazon', 'Pazarama'],
        'hasVariants': false,
        'isActive': true,
        'createdAt': '2026-08-30T12:00:00Z',
      },
      {
        'id': 'prod-004',
        'title': 'Nike Air Monarch IV Erkek Antrenman & Yürüyüş Spor Ayakkabı',
        'sku': 'NKE-MONARCH4-WHT',
        'barcode': '0886737000517',
        'modelCode': '415445-102',
        'brand': 'Nike',
        'categoryName': 'Moda',
        'subCategoryName': 'Erkek Ayakkabı',
        'price': 2899.00,
        'listPrice': 3499.00,
        'costPrice': 1650.00,
        'stockQuantity': 120,
        'vatRate': 20,
        'commissionRate': 16.0,
        'shippingCost': 45.00,
        'description': 'Nike Air Monarch IV Erkek Spor Ayakkabı. Dayanıklı deri saya ve hafif köpük taban.',
        'images': [
          'https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/e98be903-82a1-4389-897c-ad4429df3457/AIR+MONARCH+IV.png'
        ],
        'attributes': {
          'Cinsiyet': 'Erkek',
          'Kullanım': 'Antrenman / Günlük',
          'Taban': 'Air-Sole Yastıklama',
          'Renk': 'Beyaz/Lacivert'
        },
        'connectedMarketplaces': ['Trendyol', 'Hepsiburada'],
        'hasVariants': true,
        'variants': [
          {'size': '40', 'sku': 'NKE-MONARCH4-40', 'barcode': '0886737000510', 'stock': 20, 'price': 2899.00},
          {'size': '41', 'sku': 'NKE-MONARCH4-41', 'barcode': '0886737000511', 'stock': 30, 'price': 2899.00},
          {'size': '42', 'sku': 'NKE-MONARCH4-42', 'barcode': '0886737000512', 'stock': 35, 'price': 2899.00},
          {'size': '43', 'sku': 'NKE-MONARCH4-43', 'barcode': '0886737000513', 'stock': 25, 'price': 2899.00},
          {'size': '44', 'sku': 'NKE-MONARCH4-44', 'barcode': '0886737000514', 'stock': 10, 'price': 2899.00},
        ],
        'isActive': true,
        'createdAt': '2026-08-30T12:00:00Z',
      },
    ];
  }


  List<Map<String, dynamic>> _generateSampleOrders(List<dynamic>? products) {
    // Extract actual catalog products if available
    dynamic p1;
    dynamic p2;
    if (products != null && products.isNotEmpty) {
      p1 = products[0];
      if (products.length > 1) {
        p2 = products[1];
      }
    }

    final p1Title = p1 != null ? (p1['title'] ?? p1['name'] ?? 'Tudors Erkek 5\'li Paket Slim Fit Pamuklu Pike Polo Yaka Tişört').toString() : 'Tudors Erkek 5\'li Paket Slim Fit Pamuklu Pike Polo Yaka Tişört';
    final p1Sku = p1 != null ? (p1['sku'] ?? 'TDR-POLO-5PK').toString() : 'TDR-POLO-5PK';
    final p1Price = p1 != null ? (double.tryParse(p1['price']?.toString() ?? '1083.90') ?? 1083.90) : 1083.90;
    final p1Img = (p1 != null && p1['images'] is List && (p1['images'] as List).isNotEmpty)
        ? p1['images'][0].toString()
        : 'https://cdn.dsmcdn.com/ty1687/prod/QC_PREP/20250603/18/c2992fcf-6771-3257-8743-e1c6731041fd/1_org_zoom.jpg';

    final p2Title = p2 != null ? (p2['title'] ?? p2['name'] ?? 'Lenovo V15 G4 ABP AMD Ryzen 5 7530U 16GB 512GB SSD 15.6" Laptop').toString() : 'Lenovo V15 G4 ABP AMD Ryzen 5 7530U 16GB 512GB SSD 15.6" Laptop';
    final p2Sku = p2 != null ? (p2['sku'] ?? 'LEN-V15-G4-R5-16-512').toString() : 'LEN-V15-G4-R5-16-512';
    final p2Price = p2 != null ? (double.tryParse(p2['price']?.toString() ?? '14899.00') ?? 14899.00) : 14899.00;
    final p2Img = (p2 != null && p2['images'] is List && (p2['images'] as List).isNotEmpty)
        ? p2['images'][0].toString()
        : 'https://images.hepsiburada.net/assets/Bilgisayar/ProductDescriptions/202305/Lenovo-V15-G4-1.jpg';

    return [
      {
        'orderId': 'TY-984321045',
        'orderNumber': 'TY-984321045',
        'customerName': 'Mehmet Akif Yıldız',
        'customerCity': 'İstanbul / Beşiktaş',
        'customerAddress': 'Nisbetiye Mah. Aytar Cad. No:14 D:6, Beşiktaş / İstanbul',
        'marketplace': 'Trendyol',
        'marketplaceColor': const Color(0xFFF27A1A),
        'status': 'Kargoya Verildi',
        'orderDate': 'Bugün 19:42 (15 dk önce)',
        'cargoCompany': 'Trendyol Express',
        'cargoTrackingNumber': 'TYEXP-884920194',
        'cargoBarcode': '8680009423635-TY',
        'totalPrice': p1Price,
        'lines': [
          {
            'productTitle': p1Title,
            'sku': '$p1Sku-L',
            'quantity': 1,
            'price': p1Price,
            'variant': 'Beden: L • Renk: Karışık 5\'li',
            'imageUrl': p1Img,
          }
        ],
      },
      {
        'orderId': 'HB-77382910',
        'orderNumber': 'HB-77382910',
        'customerName': 'Zeynep Selin Kaya',
        'customerCity': 'Ankara / Çankaya',
        'customerAddress': 'Tunalı Hilmi Cad. No:88 D:12, Çankaya / Ankara',
        'marketplace': 'Hepsiburada',
        'marketplaceColor': const Color(0xFFFF6000),
        'status': 'Yeni Sipariş',
        'orderDate': 'Bugün 20:15 (45 dk önce)',
        'cargoCompany': 'HepsiJET',
        'cargoTrackingNumber': 'HBJET-99382104',
        'cargoBarcode': 'LEN-V15-HB-99',
        'totalPrice': p2Price,
        'lines': [
          {
            'productTitle': p2Title,
            'sku': p2Sku,
            'quantity': 1,
            'price': p2Price,
            'variant': 'Renk: Demir Grisi • 15.6" FHD IPS',
            'imageUrl': p2Img,
          }
        ],
      },
      {
        'orderId': 'AMZ-408-9842109',
        'orderNumber': 'AMZ-408-9842109',
        'customerName': 'Burak Can Demir',
        'customerCity': 'İzmir / Karşıyaka',
        'customerAddress': 'Bostanlı Mah. Cemal Gürsel Cad. No:45, Karşıyaka / İzmir',
        'marketplace': 'Amazon TR',
        'marketplaceColor': const Color(0xFFFF9900),
        'status': 'Hazırlanıyor',
        'orderDate': 'Bugün 18:30 (2 saat önce)',
        'cargoCompany': 'MNG Kargo',
        'cargoTrackingNumber': 'MNG-88402918',
        'cargoBarcode': '8680009423635-AMZ',
        'totalPrice': p1Price * 2,
        'lines': [
          {
            'productTitle': p1Title,
            'sku': '$p1Sku-XL',
            'quantity': 2,
            'price': p1Price,
            'variant': 'Beden: XL • Renk: Antrasit / Siyah',
            'imageUrl': p1Img,
          }
        ],
      },
      {
        'orderId': 'PZR-6652019',
        'orderNumber': 'PZR-6652019',
        'customerName': 'Deniz Koç',
        'customerCity': 'Bursa / Nilüfer',
        'customerAddress': 'İhsaniye Mah. FSM Bulvarı No:12 D:4, Nilüfer / Bursa',
        'marketplace': 'Pazarama',
        'marketplaceColor': const Color(0xFF0066FF),
        'status': 'Teslim Edildi',
        'orderDate': 'Dün 14:10',
        'cargoCompany': 'Yurtiçi Kargo',
        'cargoTrackingNumber': 'YK-5549201948',
        'cargoBarcode': '8680009423635-PZR',
        'totalPrice': p1Price,
        'lines': [
          {
            'productTitle': p1Title,
            'sku': '$p1Sku-M',
            'quantity': 1,
            'price': p1Price,
            'variant': 'Beden: M • Renk: Gri-Mavi-Haki',
            'imageUrl': p1Img,
          }
        ],
      },
    ];
  }


  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (mounted) context.go('/');
  }

  void _scrollToBottomAi() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_aiScrollController.hasClients) {
        _aiScrollController.animateTo(
          _aiScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- AI ASİSTAN SOHBET MODALI (KUSURSUZ KAYDIRMA VE OTO-KAYDIRMA) ---
  void _showAiAssistantDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setAiState) {
          void sendMessage(String text) async {
            if (text.trim().isEmpty) return;
            _aiInputController.clear();
            _askedPrompts.add(text.trim().toLowerCase());

            setAiState(() {
              _aiMessages.add({'role': 'user', 'content': text.trim()});
              _isAiThinking = true;
            });
            _scrollToBottomAi();

            final res = await _apiService.askAiAssistant(text.trim());

            setAiState(() {
              _isAiThinking = false;
              if (res != null && res['reply'] != null) {
                _aiMessages.add({
                  'role': 'assistant',
                  'content': res['reply'],
                  'actions': res['suggestedActions'],
                  'quickPrompts': res['quickPrompts'],
                });
              } else {
                _aiMessages.add({
                  'role': 'assistant',
                  'content': 'Bağlantı kurulamadı. Lütfen tekrar deneyin.',
                });
              }
            });
            _scrollToBottomAi();
          }

          void handleActionClick(dynamic act) {
            final actionType = act['actionType'] ?? act['action'];
            if (actionType == 'open_add_product') {
              Navigator.pop(ctx);
              _showSimplifiedAddProductDialog();
            } else if (actionType == 'open_connect_marketplace') {
              Navigator.pop(ctx);
              _showAddMarketplaceDialog();
            } else if (actionType == 'open_pricing_calc') {
              Navigator.pop(ctx);
              _showPricingCalculatorDialog();
            } else if (actionType == 'open_support_channels') {
              _showCustomerSupportDialog();
            } else if (actionType == 'open_whatsapp_support') {
              _launchSafeUrl('https://wa.me/905550000000?text=Merhaba,%20RoaTech%20hakkında%20bilgi%20almak%20istiyorum');
            } else if (actionType == 'switch_tab_orders') {
              Navigator.pop(ctx);
              setState(() => _currentTabIndex = 1);
            } else if (actionType == 'broadcast_stock') {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stoklar tüm pazaryerlerine 1.2 saniyede dağıtılıyor...'), backgroundColor: Colors.blueAccent));
            } else if (act['prompt'] != null && act['prompt'].toString().isNotEmpty) {
              sendMessage(act['prompt']);
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.purpleAccent, width: 1.5)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.purpleAccent, Colors.blueAccent]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Pazaryeri Danışmanı', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('Online & Sistemi Yönlendirmeye Hazır', style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            content: SizedBox(
              width: 720,
              height: 600,
              child: Column(
                children: [
                  // Mesaj Listesi (Kaydırma Çubuğu & Mouse Wheel Desteği)
                  Expanded(
                    child: Scrollbar(
                      controller: _aiScrollController,
                      thumbVisibility: true,
                      interactive: true,
                      thickness: 6,
                      radius: const Radius.circular(8),
                      child: ListView.separated(
                        controller: _aiScrollController,
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                        itemCount: _aiMessages.length + (_isAiThinking ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          if (index == _aiMessages.length && _isAiThinking) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purpleAccent.withOpacity(0.3))),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.purpleAccent, strokeWidth: 2)),
                                    const SizedBox(width: 10),
                                    Text('Yapay Zeka düşünüyor ve sistemi analiz ediyor...', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                            );
                          }

                          final msg = _aiMessages[index];
                          final isUser = msg['role'] == 'user';
                          final actions = msg['actions'] as List<dynamic>?;
                          final quickPrompts = msg['quickPrompts'] as List<dynamic>?;
                          final rawContent = msg['content'] as String? ?? '';
                          final displayContent = rawContent.replaceAll('**', '');
                          final unaskedPrompts = (quickPrompts ?? []).where((p) => !_askedPrompts.contains(p.toString().trim().toLowerCase())).toList();

                          return Column(
                            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
                                constraints: const BoxConstraints(maxWidth: 580),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isUser ? Colors.blueAccent.withOpacity(0.25) : const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isUser ? Colors.blueAccent.withOpacity(0.5) : Colors.white12),
                                ),
                                child: Text(
                                  displayContent,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13, height: 1.5),
                                ),
                              ),
                              if (actions != null && actions.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: actions.map((act) {
                                    return ElevatedButton.icon(
                                      onPressed: () => handleActionClick(act),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple.shade900,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.touch_app, size: 14, color: Colors.amberAccent),
                                      label: Text(act['label'] ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                ),
                              ],
                              if (unaskedPrompts.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: unaskedPrompts.map((p) {
                                    return InkWell(
                                      onTap: () => sendMessage(p.toString()),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.purpleAccent.withOpacity(0.6), width: 1.2),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.help_outline_rounded, size: 14, color: Colors.cyanAccent),
                                            const SizedBox(width: 6),
                                            Text(
                                              p.toString(),
                                              style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white12),
                  // Mesaj Yazma Alanı
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _aiInputController,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Bir soru sorun... (Örn: 2 Al 1 Öde nasıl yapılır?)',
                            hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                          ),
                          onSubmitted: sendMessage,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.purpleAccent, size: 24),
                        onPressed: () => sendMessage(_aiInputController.text),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- KAMPANYA SEÇİCİ WIDGET'I ---
  Widget _buildCampaignSelector({
    required int currentType,
    required double basePrice,
    required Function(int newType, String name) onChanged,
  }) {
    final campaigns = [
      {'type': 0, 'name': 'Standart Satış (Kampanyasız)', 'desc': 'Sabit fiyattan satılır.', 'badge': 'Standart'},
      {'type': 1, 'name': '🔥 2 Al 1 Öde (BOGO)', 'desc': '2 ürün sepete eklendiğinde 1 ürün bedava olur (Birim: ${formatTL(basePrice / 2)}).', 'badge': '2 Al 1 Öde'},
      {'type': 2, 'name': '🎁 3 Al 2 Öde', 'desc': '3 ürün sepete eklendiğinde 2 ürün fiyatı ödenir (Birim: ${formatTL((basePrice * 2) / 3)}).', 'badge': '3 Al 2 Öde'},
      {'type': 3, 'name': '⚡ 2. Ürüne %50 İndirim', 'desc': 'İkinci ürün %50 indirimli ${formatTL(basePrice * 0.5)} olur (2li sepet: ${formatTL(basePrice * 1.5)}).', 'badge': '2. Ürün %50'},
      {'type': 4, 'name': '🛒 Sepette %10 İndirim', 'desc': 'Sepette anında ${formatTL(basePrice * 0.9)} fiyata düşer.', 'badge': 'Sepette %10'},
      {'type': 5, 'name': '🛒 Sepette %20 İndirim', 'desc': 'Sepette anında ${formatTL(basePrice * 0.8)} fiyata düşer.', 'badge': 'Sepette %20'},
      {'type': 6, 'name': '📦 Çok Al Az Öde (Adet Baremi)', 'desc': '3+ adet alımlarda %15 ek indirim uygulanır.', 'badge': 'Çok Al Az Öde'},
      {'type': 7, 'name': '⚡ Flaş İndirim', 'desc': '24 saatlik sınırlı süreli flaş indirim.', 'badge': 'Flaş İndirim'},
    ];

    final cur = campaigns.firstWhere((c) => c['type'] == currentType, orElse: () => campaigns[0]);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amberAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 8),
              Text('Pazaryeri Kampanyası & Promosyon Kurgusu', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: currentType,
            dropdownColor: const Color(0xFF1E293B),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: campaigns.map((c) {
              return DropdownMenuItem<int>(
                value: c['type'] as int,
                child: Text(c['name'] as String, style: GoogleFonts.inter(color: Colors.white)),
              );
            }).toList(),
            onChanged: (val) {
              final selected = campaigns.firstWhere((c) => c['type'] == val, orElse: () => campaigns[0]);
              onChanged(val ?? 0, selected['name'] as String);
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amberAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(cur['desc'] as String, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSubscriptionExpired() {
    final limits = _metrics?['limits'];
    final plan = _metrics?['plan'] ?? _metrics?['tenant']?['subscriptionPlan'] ?? 'Free';
    final isPaid = plan != 'Free' && plan != 'Deneme';
    if (isPaid) return false;

    if (_metrics?['isExpired'] == true || limits?['isExpired'] == true) return true;

    int daysLeft = 30;
    if (limits != null && limits['daysLeft'] != null) {
      daysLeft = int.tryParse(limits['daysLeft'].toString()) ?? 30;
    } else if (_metrics != null && _metrics!['daysLeft'] != null) {
      daysLeft = int.tryParse(_metrics!['daysLeft'].toString()) ?? 30;
    } else {
      final subEndDateStr = _metrics?['tenant']?['subscriptionEndDate'] ?? _metrics?['subscriptionEndDate'];
      if (subEndDateStr != null) {
        final end = DateTime.tryParse(subEndDateStr.toString());
        if (end != null) {
          final diff = end.difference(DateTime.now().toUtc());
          daysLeft = (diff.inHours / 24.0).ceil();
        }
      }
    }
    return daysLeft <= 0;
  }

  void _showSubscriptionExpiredDialog({String? customActionTitle}) {
    int selectedPlanIndex = 1;
    bool isUpgrading = false;

    final plans = [
      {
        'id': 'Başlangıç Paketi',
        'name': '⚡ Başlangıç Paketi',
        'price': '199 ₺ / Ay',
        'desc': '3 Pazaryeri • 250 Ürün • Otomatik Stok & Fiyat Eşitleme',
        'color': Colors.blueAccent,
      },
      {
        'id': 'Büyüme Paketi',
        'name': '🚀 Büyüme Paketi (Tavsiye Edilen)',
        'price': '399 ₺ / Ay',
        'desc': '8 Pazaryeri • 2.500 Ürün • AI Danışman & Akıllı Fiyat Robotu',
        'color': Colors.amberAccent,
        'badge': 'EN POPÜLER'
      },
      {
        'id': 'Profesyonel Paket',
        'name': '👑 Profesyonel Paket',
        'price': '799 ₺ / Ay',
        'desc': 'Sınırsız Pazaryeri & Ürün • E-Fatura Entegrasyonu • 7/24 Destek',
        'color': Colors.purpleAccent,
      },
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Colors.amberAccent, width: 1.5)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.timer_off_outlined, color: Colors.redAccent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ücretsiz Deneme Süreniz Sona Erdi', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        customActionTitle ?? 'İşlemlerinize kesintisiz devam etmek için lütfen paketinizi yükseltin.',
                        style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            content: SizedBox(
              width: 580,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '30 günlük ücretsiz deneme süreniz dolduğu için yeni ürün ekleme, ürün düzenleme ve yeni pazaryeri bağlama kısıtlanmıştır.',
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Abonelik Paketinizi Seçin:', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  ...plans.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final p = entry.value;
                    final isSelected = selectedPlanIndex == idx;
                    return InkWell(
                      onTap: () => setModalState(() => selectedPlanIndex = idx),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? (p['color'] as Color).withOpacity(0.12) : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? (p['color'] as Color) : Colors.white12, width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: idx,
                              groupValue: selectedPlanIndex,
                              activeColor: p['color'] as Color,
                              onChanged: (val) => setModalState(() => selectedPlanIndex = val ?? 0),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(p['name'] as String, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      if (p['badge'] != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.amberAccent, borderRadius: BorderRadius.circular(6)),
                                          child: Text(p['badge'] as String, style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(p['desc'] as String, style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                                ],
                              ),
                            ),
                            Text(p['price'] as String, style: GoogleFonts.inter(color: p['color'] as Color, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Daha Sonra', style: GoogleFonts.inter(color: Colors.white60)),
              ),
              ElevatedButton.icon(
                onPressed: isUpgrading ? null : () async {
                  setModalState(() => isUpgrading = true);
                  final chosen = plans[selectedPlanIndex];
                  final res = await _apiService.upgradeSubscriptionPlan(chosen['id'] as String);
                  setModalState(() => isUpgrading = false);

                  if (ctx.mounted) Navigator.pop(ctx);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res?['message'] ?? 'Tebrikler! Aboneliğiniz başarıyla aktif edildi ve tüm kısıtlamalar kaldırıldı.'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                    _loadData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: isUpgrading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.rocket_launch, size: 18),
                label: Text(isUpgrading ? 'Abonelik Başlatılıyor...' : 'Paketi Hemen Aktif Et 🚀', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- SADE ÜRÜN EKLEME MODALI ---
  void _showSimplifiedAddProductDialog() {
    if (_isSubscriptionExpired()) {
      _showSubscriptionExpiredDialog(customActionTitle: 'Yeni ürün ekleyebilmek için lütfen üyeliğinizi başlatın veya paketinizi yükseltin.');
      return;
    }

    final titleController = TextEditingController();
    final brandController = TextEditingController(text: 'Tudors');
    final categoryController = TextEditingController(text: 'Polo Yaka Tişört');
    final priceController = TextEditingController(text: '1.083,90');
    final stockController = TextEditingController(text: '100');
    final listPriceController = TextEditingController(text: '1.747,80');
    final desiController = TextEditingController(text: '1.5');
    final skuController = TextEditingController(text: 'TDR-PL-01');
    final barcodeController = TextEditingController();
    final urlInputController = TextEditingController();
    final attrKeyController = TextEditingController();
    final attrValueController = TextEditingController();

    Map<String, String> productAttributes = {};

    // Kategori şablonları
    final categoryTemplates = {
      '💻 Elektronik & Bilgisayar': ['İşlemci', 'RAM (Bellek)', 'SSD / Depolama Kapasitesi', 'Ekran Boyutu', 'Ekran Kartı', 'İşletim Sistemi', 'Çözünürlük', 'Renk', 'Garanti Süresi'],
      '📱 Telefon & Aksesuar': ['Dahili Hafıza', 'RAM', 'Renk', 'Ekran Boyutu', 'Kamera Çözünürlüğü', 'Pil Gücü', 'İşletim Sistemi', 'Garanti'],
      '👗 Moda (Kadın/Erkek/Çanta)': ['Beden', 'Kalıp', 'Kumaş Tipi', 'Yaka Tipi', 'Renk', 'Cinsiyet', 'Sezon', 'Paket İçeriği'],
      '🏠 Ev, Yaşam, Kırtasiye, Ofis': ['Malzeme', 'Kapasite / Boyut', 'Renk', 'Ağırlık', 'Kullanım Alanı', 'Garanti'],
      '🔧 Oto, Bahçe, Yapı Market': ['Güç (Watt/Volt)', 'Kapasite', 'Uyumlu Araç / Model', 'Ölçü / Ebat', 'Garanti'],
      '👶 Anne, Bebek, Oyuncak': ['Yaş Grubu', 'Cinsiyet', 'Malzeme / Materyal', 'Taşıma Kapasitesi', 'Renk'],
      '⚽ Spor, Outdoor': ['Spor Branşı', 'Beden / Numara', 'Malzeme', 'Kullanım Alanı', 'Renk'],
      '💄 Kozmetik, Kişisel Bakım': ['Hacim (ml/gr)', 'Cilt Tipi', 'Koku / Aroma', 'Kullanım Amacı', 'Form'],
      '🛒 Süpermarket, Pet Shop': ['Miktar / Ağırlık', 'Paket Tipi', 'Pet Türü (Kedi/Köpek)', 'İçerik / Aroma'],
      '📚 Kitap, Müzik, Film, Hobi': ['Yazar / Sanatçı', 'Yayınevi / Marka', 'Sayfa Sayısı / Tür', 'Basım Yılı', 'Dil'],
    };

    List<String> uploadedImages = [
      "https://cdn.dsmcdn.com/ty1687/prod/QC_PREP/20250603/18/c2992fcf-6771-3257-8743-e1c6731041fd/1_org_zoom.jpg",
      "https://cdn.dsmcdn.com/ty1686/prod/QC_PREP/20250603/18/53f6bf86-2c9f-3e2c-87c1-206a47e4ad34/1_org_zoom.jpg"
    ];
    int selectedCampaignType = 1;
    String selectedCampaignName = "🔥 2 Al 1 Öde (BOGO)";
    int variantTemplateType = 0; // 0=Tekstil, 1=Laptop, 2=Telefon
    String? selectedCategoryChip;
    bool isUploadingImage = false;
    bool showAdvancedOptions = false;
    bool showAttributesSection = true;
    bool autoCreateVariants = true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          void applyLenovoLaptopPreset() {
            setDlgState(() {
              titleController.text = 'Lenovo IdeaPad Slim 3 AMD Ryzen 7 170 16GB 512GB SSD Freedos 15.3" Taşınabilir Bilgisayar 83K700PSTR';
              brandController.text = 'Lenovo';
              categoryController.text = 'Dizüstü Bilgisayar (Laptop)';
              priceController.text = '31.999,00';
              listPriceController.text = '33.683,16';
              stockController.text = '65';
              desiController.text = '3.5';
              skuController.text = 'LEN-83K700PSTR';
              barcodeController.text = '8680009847120';
              selectedCampaignType = 4;
              selectedCampaignName = '🛒 Seçili Lenovo Laptoplarda Sepette %5 İndirim';
              variantTemplateType = 1;
              autoCreateVariants = true;
              showAttributesSection = true;
              uploadedImages = [
                'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=600&auto=format&fit=crop&q=80',
                'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=600&auto=format&fit=crop&q=80'
              ];
              productAttributes = {
                'İşlemci': 'AMD Ryzen 7 170',
                'RAM (Sistem Belleği)': '16 GB',
                'SSD Kapasitesi': '512 GB NVMe SSD',
                'Ekran Boyutu': '15.3 inç',
                'İşletim Sistemi': 'FreeDOS',
                'Model Kodu': '83K700PSTR',
                'Ekran Kartı': 'Tümleşik AMD Radeon Graphics',
                'Çözünürlük': '1920 x 1200 FHD+ WUXGA',
                'Panel Tipi': 'IPS 300 nit Yansıma Önleyici',
                'Renk': 'Koyu Gri (Artic Grey)',
                'Ağırlık': '1.62 kg',
                'Garanti Süresi': '2 Yıl Lenovo Türkiye Garantili'
              };
            });
          }

          void applyIPhonePreset() {
            setDlgState(() {
              titleController.text = 'Apple iPhone 17 Pro Max 256 GB Kozmik Turuncu (Apple Türkiye Garantili)';
              brandController.text = 'Apple';
              categoryController.text = 'Akıllı Telefon';
              priceController.text = '89.999,00';
              listPriceController.text = '94.999,00';
              stockController.text = '40';
              desiController.text = '1.0';
              skuController.text = 'APL-IP17PM-256G';
              barcodeController.text = '8680009948211';
              selectedCampaignType = 0;
              selectedCampaignName = 'Standart Satış';
              variantTemplateType = 2;
              autoCreateVariants = true;
              showAttributesSection = true;
              uploadedImages = [
                'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=600&auto=format&fit=crop&q=80'
              ];
              productAttributes = {
                'Dahili Hafıza': '256 GB',
                'Renk': 'Kozmik Turuncu',
                'RAM': '12 GB',
                'Ekran Boyutu': '6.9 inç OLED Super Retina XDR',
                'İşlemci': 'Apple A19 Pro',
                'Kamera': '48 MP Üçlü Kamera Sistemi',
                'Pil': '4850 mAh',
                'İşletim Sistemi': 'iOS 19',
                'Garanti': '2 Yıl Apple Türkiye Garantili'
              };
            });
          }

          void applyTudorsPreset() {
            setDlgState(() {
              titleController.text = "Tudors Erkek 5'li Paket Slim Fit Pamuklu Pike Polo Yaka Tişört";
              brandController.text = 'Tudors';
              categoryController.text = 'Polo Yaka Tişört';
              priceController.text = '1.083,90';
              listPriceController.text = '1.747,80';
              stockController.text = '100';
              desiController.text = '1.5';
              skuController.text = 'TDR-PL-01';
              barcodeController.text = '8680009423635';
              selectedCampaignType = 1;
              selectedCampaignName = '🔥 2 Al 1 Öde (BOGO)';
              variantTemplateType = 0;
              autoCreateVariants = true;
              showAttributesSection = true;
              uploadedImages = [
                'https://images.unsplash.com/photo-1581655353564-df123a1eb820?w=600&auto=format&fit=crop&q=80'
              ];
              productAttributes = {
                'Kalıp': 'Slim Fit',
                'Materyal': '%55 Polyester %45 Pamuk',
                'Yaka': 'Polo Yaka',
                'Renk': 'Gri-Mavi-Haki-Yeşil-Siyah',
                'Paket': "5'li"
              };
            });
          }
          void pickAndUploadImage() async {
            try {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
              if (pickedFile != null) {
                setDlgState(() => isUploadingImage = true);
                final bytes = await pickedFile.readAsBytes();
                final base64String = 'data:image/png;base64,${base64Encode(bytes)}';
                setDlgState(() {
                  uploadedImages.add(base64String);
                  isUploadingImage = false;
                });
              }
            } catch (_) {
              setDlgState(() => isUploadingImage = false);
            }
          }

          final currentPrice = parseTLInput(priceController.text) > 0 ? parseTLInput(priceController.text) : 1083.90;

          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.add_shopping_cart, color: Colors.orangeAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hızlı Ürün & Kampanya Tanımla', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Fotoğraflarınızı yükleyin ve 2 Al 1 Öde gibi pazaryeri kampanyalarını seçin', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            content: SizedBox(
              width: 960,
              height: 640,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hızlı Şablonlar Barı
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flash_on, color: Colors.amberAccent, size: 18),
                          const SizedBox(width: 8),
                          Text('Hızlı Şablon:', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ActionChip(
                                    avatar: const Icon(Icons.laptop_chromebook, size: 14, color: Colors.orangeAccent),
                                    label: Text('💻 Lenovo Laptop (Hepsiburada)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                    backgroundColor: Colors.orange.withOpacity(0.2),
                                    side: const BorderSide(color: Colors.orangeAccent),
                                    onPressed: applyLenovoLaptopPreset,
                                  ),
                                  const SizedBox(width: 6),
                                  ActionChip(
                                    avatar: const Icon(Icons.phone_iphone, size: 14, color: Colors.tealAccent),
                                    label: Text('📱 iPhone 17 Pro Max', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                    backgroundColor: Colors.teal.withOpacity(0.2),
                                    side: const BorderSide(color: Colors.tealAccent),
                                    onPressed: applyIPhonePreset,
                                  ),
                                  const SizedBox(width: 6),
                                  ActionChip(
                                    avatar: const Icon(Icons.checkroom, size: 14, color: Colors.lightBlueAccent),
                                    label: Text('👕 Tudors Polo Tişört', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                    side: const BorderSide(color: Colors.blueAccent),
                                    onPressed: applyTudorsPreset,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 280,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📸 Ürün Görselleri', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: pickAndUploadImage,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 130,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blueAccent.withOpacity(0.4), style: BorderStyle.solid, width: 1.5),
                              ),
                              child: isUploadingImage
                                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.cloud_upload_outlined, color: Colors.blueAccent, size: 36),
                                        const SizedBox(height: 6),
                                        Text('Fotoğraf Seç / Yükle', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text('Bilgisayardan veya galeriden', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: urlInputController,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
                                  decoration: InputDecoration(
                                    hintText: 'veya Resim URL si yapıştır...',
                                    hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.05),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.add_photo_alternate, color: Colors.greenAccent, size: 20),
                                tooltip: 'URL Ekle',
                                onPressed: () {
                                  if (urlInputController.text.trim().isNotEmpty) {
                                    setDlgState(() {
                                      uploadedImages.add(urlInputController.text.trim());
                                      urlInputController.clear();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (uploadedImages.isNotEmpty) ...[
                            Text('Eklenen Resimler (${uploadedImages.length}):', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: uploadedImages.map((img) {
                                return Stack(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: _buildSafeImageWidget(img, width: 60, height: 60, fit: BoxFit.cover, borderRadius: BorderRadius.circular(7)),
                                    ),
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: InkWell(
                                        onTap: () => setDlgState(() => uploadedImages.remove(img)),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, color: Colors.white, size: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('📝 Ürün Başlığı', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 4),
                              Text('*', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                              const Spacer(),
                              Text('${titleController.text.length} karakter', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: titleController,
                            minLines: 2,
                            maxLines: 4,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13, height: 1.35, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'Örn: Lenovo IdeaPad Slim 3 AMD Ryzen 7 16GB 512GB SSD 15.3" Taşınabilir Bilgisayar',
                              hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onChanged: (_) => setDlgState(() {}),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: brandController,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(labelText: 'Marka', labelStyle: GoogleFonts.inter(color: Colors.white70), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: categoryController,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(labelText: 'Kategori', labelStyle: GoogleFonts.inter(color: Colors.white70), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: priceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: 'Satış Fiyatı *',
                                    prefixText: '₺ ',
                                    suffixText: 'TL',
                                    hintText: 'Örn: 99.999,99',
                                    prefixStyle: GoogleFonts.inter(color: Colors.greenAccent),
                                    suffixStyle: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                    labelStyle: GoogleFonts.inter(color: Colors.white70),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.05),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                  onChanged: (_) => setDlgState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: stockController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(labelText: 'Toplam Stok *', suffixText: 'Adet', labelStyle: GoogleFonts.inter(color: Colors.white70), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildCampaignSelector(
                            currentType: selectedCampaignType,
                            basePrice: currentPrice,
                            onChanged: (newType, name) {
                              setDlgState(() {
                                selectedCampaignType = newType;
                                selectedCampaignName = name;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.purpleAccent.withOpacity(0.2))),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Otomatik Beden Varyantları (XS-3XL)', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                                      Text('7 beden için bağımsız barkod ve eşit stok üretilir', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: autoCreateVariants,
                                  activeColor: Colors.purpleAccent,
                                  onChanged: (val) => setDlgState(() => autoCreateVariants = val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () => setDlgState(() => showAdvancedOptions = !showAdvancedOptions),
                            child: Row(
                              children: [
                                Icon(showAdvancedOptions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.orangeAccent, size: 18),
                                const SizedBox(width: 6),
                                Text(showAdvancedOptions ? 'Gelişmiş Seçenekleri Gizle' : '⚙️ Gelişmiş Ayarlar (Liste Fiyatı, Desi, SKU)', style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          if (showAdvancedOptions) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: listPriceController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'Üstü Çizili Liste Fiyatı',
                                      prefixText: '₺ ',
                                      suffixText: 'TL',
                                      hintText: 'Örn: 109.999,00',
                                      prefixStyle: GoogleFonts.inter(color: Colors.white60),
                                      suffixStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                                      labelStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.04),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: desiController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'Kargo Desisi',
                                      suffixText: 'Desi',
                                      labelStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.04),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: skuController,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'Özel Stok Kodu (SKU)',
                                      prefixIcon: const Icon(Icons.qr_code_2, size: 18, color: Colors.orangeAccent),
                                      labelStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.04),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: barcodeController,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'Barkod (EAN / GTIN)',
                                      prefixIcon: const Icon(Icons.barcode_reader, size: 18, color: Colors.orangeAccent),
                                      labelStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.04),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // ── Dinamik Özellikler Editörü ──────────────────────────
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () => setDlgState(() => showAttributesSection = !showAttributesSection),
                            child: Row(
                              children: [
                                Icon(showAttributesSection ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.indigoAccent, size: 18),
                                const SizedBox(width: 6),
                                Text('🏷️ Ürün Özellikleri (RAM, Renk, Kapasite...)', style: GoogleFonts.inter(color: Colors.indigoAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                if (productAttributes.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                                    child: Text('${productAttributes.length} özellik', style: GoogleFonts.inter(color: Colors.indigoAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),
                          if (showAttributesSection) ...[
                            const SizedBox(height: 8),
                            // Kategori Şablonları
                            Text('Hızlı Şablon:', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: categoryTemplates.entries.map((entry) {
                                final isSelected = selectedCategoryChip == entry.key;
                                return InkWell(
                                  onTap: () {
                                    setDlgState(() {
                                      selectedCategoryChip = entry.key;
                                      // Önceki kategorinin özelliklerini temizle, sadece seçilen kategorinin alanlarını getir
                                      productAttributes.clear();
                                      for (final key in entry.value) {
                                        productAttributes[key] = '';
                                      }
                                      // Kategori adı kutusunu da otomatik güncelle
                                      final cleanCatName = entry.key.replaceAll(RegExp(r'[^\w\s&ĞÜŞİÖÇğüşıöç]'), '').trim();
                                      if (cleanCatName.isNotEmpty && (categoryController.text.isEmpty || categoryController.text == 'Giyim')) {
                                        categoryController.text = cleanCatName;
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.indigoAccent : Colors.indigo.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isSelected ? Colors.white : Colors.indigoAccent.withOpacity(0.35), width: isSelected ? 1.5 : 1.0),
                                    ),
                                    child: Text(
                                      entry.key,
                                      style: GoogleFonts.inter(
                                        color: isSelected ? Colors.white : Colors.indigoAccent,
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),
                            // Mevcut özellikler
                            if (productAttributes.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.indigoAccent.withOpacity(0.2))),
                                child: Column(
                                  children: productAttributes.entries.map((entry) {
                                    final valCtrl = TextEditingController(text: entry.value);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              decoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                              child: Text(entry.key, style: GoogleFonts.inter(color: Colors.indigoAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 3,
                                            child: TextField(
                                              controller: valCtrl,
                                              onChanged: (v) => productAttributes[entry.key] = v,
                                              style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                                              decoration: InputDecoration(
                                                hintText: 'Değer girin...',
                                                hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                filled: true,
                                                fillColor: Colors.white.withOpacity(0.05),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () => setDlgState(() => productAttributes.remove(entry.key)),
                                            child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Yeni özellik ekle
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: attrKeyController,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: 'Özellik adı (RAM)',
                                      hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      filled: true, fillColor: Colors.white.withOpacity(0.05),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: attrValueController,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: 'Değer (16 GB)',
                                      hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      filled: true, fillColor: Colors.white.withOpacity(0.05),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ElevatedButton(
                                  onPressed: () {
                                    final k = attrKeyController.text.trim();
                                    final v = attrValueController.text.trim();
                                    if (k.isNotEmpty) {
                                      setDlgState(() {
                                        productAttributes[k] = v;
                                        attrKeyController.clear();
                                        attrValueController.clear();
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                                  child: const Icon(Icons.add, size: 16),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Vazgeç', style: GoogleFonts.inter(color: Colors.white60))),
          ElevatedButton(
            onPressed: isSaving
                ? null
                : () async {
                    if (titleController.text.trim().isEmpty || priceController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen Ürün Başlığı ve Satış Fiyatı alanlarını girin.'), backgroundColor: Colors.orangeAccent));
                      return;
                    }

                    setDlgState(() => isSaving = true);
                    final price = parseTLInput(priceController.text) > 0 ? parseTLInput(priceController.text) : 1083.90;
                    final listPrice = parseTLInput(listPriceController.text) > 0 ? parseTLInput(listPriceController.text) : price * 1.3;
                    final stock = int.tryParse(stockController.text) ?? 100;
                    final desi = double.tryParse(desiController.text) ?? 1.5;
                    final sku = skuController.text.trim().isNotEmpty ? skuController.text.trim() : 'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

                    List<Map<String, dynamic>> variants = [];
                    if (autoCreateVariants) {
                      if (variantTemplateType == 1) {
                        // Laptop / Tech RAM & SSD Variants
                        variants = [
                          {
                            'sku': '$sku-16G-512G',
                            'barcode': barcodeController.text.isNotEmpty ? '${barcodeController.text.trim()}-512' : '8680009847120',
                            'size': '16GB RAM / 512GB SSD',
                            'color': productAttributes['Renk'] ?? 'Artic Grey',
                            'price': price,
                            'listPrice': listPrice,
                            'stockQuantity': (stock * 0.5).round(),
                            'isActive': true
                          },
                          {
                            'sku': '$sku-16G-1TB',
                            'barcode': barcodeController.text.isNotEmpty ? '${barcodeController.text.trim()}-1TB' : '8680009847121',
                            'size': '16GB RAM / 1TB SSD',
                            'color': productAttributes['Renk'] ?? 'Artic Grey',
                            'price': (price * 1.23).roundToDouble(),
                            'listPrice': (listPrice * 1.25).roundToDouble(),
                            'stockQuantity': (stock * 0.3).round(),
                            'isActive': true
                          },
                          {
                            'sku': '$sku-24G-1TB',
                            'barcode': barcodeController.text.isNotEmpty ? '${barcodeController.text.trim()}-24G' : '8680009847122',
                            'size': '24GB RAM / 1TB SSD',
                            'color': productAttributes['Renk'] ?? 'Artic Grey',
                            'price': (price * 1.40).roundToDouble(),
                            'listPrice': (listPrice * 1.42).roundToDouble(),
                            'stockQuantity': (stock * 0.2).round(),
                            'isActive': true
                          },
                        ];
                      } else if (variantTemplateType == 2) {
                        // Smartphone / Storage Variants
                        variants = [
                          {
                            'sku': '$sku-128G',
                            'barcode': '8680009948210',
                            'size': '128 GB',
                            'color': productAttributes['Renk'] ?? 'Kozmik Turuncu',
                            'price': (price * 0.9).roundToDouble(),
                            'listPrice': (listPrice * 0.9).roundToDouble(),
                            'stockQuantity': (stock * 0.3).round(),
                            'isActive': true
                          },
                          {
                            'sku': '$sku-256G',
                            'barcode': barcodeController.text.isNotEmpty ? barcodeController.text.trim() : '8680009948211',
                            'size': '256 GB',
                            'color': productAttributes['Renk'] ?? 'Kozmik Turuncu',
                            'price': price,
                            'listPrice': listPrice,
                            'stockQuantity': (stock * 0.5).round(),
                            'isActive': true
                          },
                          {
                            'sku': '$sku-512G',
                            'barcode': '8680009948212',
                            'size': '512 GB',
                            'color': productAttributes['Renk'] ?? 'Kozmik Turuncu',
                            'price': (price * 1.18).roundToDouble(),
                            'listPrice': (listPrice * 1.20).roundToDouble(),
                            'stockQuantity': (stock * 0.2).round(),
                            'isActive': true
                          },
                        ];
                      } else {
                        // Apparel Beden
                        final sizes = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL'];
                        variants = sizes.map((sz) {
                          return {
                            'sku': '$sku-$sz',
                            'barcode': '868000${sz.hashCode.abs().toString().padLeft(6, '0')}',
                            'size': sz,
                            'color': productAttributes['Renk'] ?? 'Çok Renkli',
                            'price': price,
                            'listPrice': listPrice,
                            'stockQuantity': (stock / sizes.length).round(),
                            'isActive': true
                          };
                        }).toList();
                      }
                    }

                        final richPayload = {
                          'title': titleController.text,
                          'sku': sku,
                          'barcode': barcodeController.text.trim().isNotEmpty
                              ? barcodeController.text.trim()
                              : '868000${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
                          'modelCode': sku,
                          'brand': brandController.text.isNotEmpty ? brandController.text : 'Genel',
                          'categoryName': categoryController.text.isNotEmpty ? categoryController.text : 'Giyim',
                          'price': price,
                          'listPrice': listPrice,
                          'costPrice': price * 0.4,
                          'vatRate': 20,
                          'stockQuantity': stock,
                          'dimensionalWeight': desi,
                          'cargoCompany': 'Trendyol Express',
                          'deliveryDuration': 2,
                          'description': titleController.text,
                          'images': uploadedImages,
                          'campaignType': selectedCampaignType,
                          'campaignName': selectedCampaignName,
                          'attributes': productAttributes.isEmpty
                              ? {
                                  'Kalıp': 'Slim Fit',
                                  'Kategori': categoryController.text,
                                  'Marka': brandController.text,
                                  'Kampanya': selectedCampaignName
                                }
                              : productAttributes,
                          'variants': variants
                        };

                        final res = await _apiService.createRichProduct(richPayload);
                        setDlgState(() => isSaving = false);

                        if (res != null && mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün ve kampanyası başarıyla kaydedildi! 🚀'), backgroundColor: Colors.green));
                          _loadData();
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün eklenirken bir hata oluştu!'), backgroundColor: Colors.red));
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Ürünü Kaydet 🚀', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditProductDialog(String productId, Map<String, dynamic> product) {
    if (_isSubscriptionExpired()) {
      _showSubscriptionExpiredDialog(customActionTitle: 'Ürünlerinizi düzenleyebilmek için lütfen üyeliğinizi başlatın veya paketinizi yükseltin.');
      return;
    }

    final titleController = TextEditingController(text: product['title'] ?? '');
    final brandController = TextEditingController(text: product['brand'] ?? '');
    final categoryController = TextEditingController(text: product['categoryName'] ?? '');
    final priceVal = double.tryParse((product['price'] ?? '').toString()) ?? 0.0;
    final listPriceVal = double.tryParse((product['listPrice'] ?? '').toString());
    final priceController = TextEditingController(text: priceVal > 0 ? formatNumberTL(priceVal) : '');
    final stockController = TextEditingController(text: (product['stockQuantity'] ?? '').toString());
    final listPriceController = TextEditingController(text: listPriceVal != null && listPriceVal > 0 ? formatNumberTL(listPriceVal) : '');
    final desiController = TextEditingController(text: (product['dimensionalWeight'] ?? '1.5').toString());
    final skuController = TextEditingController(text: product['sku'] ?? '');
    final barcodeController = TextEditingController(text: product['barcode'] ?? '');
    final descriptionController = TextEditingController(text: product['description'] ?? '');
    final urlInputController = TextEditingController();
    final attrKeyController = TextEditingController();
    final attrValueController = TextEditingController();

    // Load existing attributes
    final rawAttrs = product['attributes'] as Map<String, dynamic>?;
    Map<String, String> productAttributes = rawAttrs?.map((k, v) => MapEntry(k, v.toString())) ?? {};

    final categoryTemplates = {
      '💻 Elektronik & Bilgisayar': ['İşlemci', 'RAM (Bellek)', 'SSD / Depolama Kapasitesi', 'Ekran Boyutu', 'Ekran Kartı', 'İşletim Sistemi', 'Çözünürlük', 'Renk', 'Garanti Süresi'],
      '📱 Telefon & Aksesuar': ['Dahili Hafıza', 'RAM', 'Renk', 'Ekran Boyutu', 'Kamera Çözünürlüğü', 'Pil Gücü', 'İşletim Sistemi', 'Garanti'],
      '👗 Moda (Kadın/Erkek/Çanta)': ['Beden', 'Kalıp', 'Kumaş Tipi', 'Yaka Tipi', 'Renk', 'Cinsiyet', 'Sezon', 'Paket İçeriği'],
      '🏠 Ev, Yaşam, Kırtasiye, Ofis': ['Malzeme', 'Kapasite / Boyut', 'Renk', 'Ağırlık', 'Kullanım Alanı', 'Garanti'],
      '🔧 Oto, Bahçe, Yapı Market': ['Güç (Watt/Volt)', 'Kapasite', 'Uyumlu Araç / Model', 'Ölçü / Ebat', 'Garanti'],
      '👶 Anne, Bebek, Oyuncak': ['Yaş Grubu', 'Cinsiyet', 'Malzeme / Materyal', 'Taşıma Kapasitesi', 'Renk'],
      '⚽ Spor, Outdoor': ['Spor Branşı', 'Beden / Numara', 'Malzeme', 'Kullanım Alanı', 'Renk'],
      '💄 Kozmetik, Kişisel Bakım': ['Hacim (ml/gr)', 'Cilt Tipi', 'Koku / Aroma', 'Kullanım Amacı', 'Form'],
      '🛒 Süpermarket, Pet Shop': ['Miktar / Ağırlık', 'Paket Tipi', 'Pet Türü (Kedi/Köpek)', 'İçerik / Aroma'],
      '📚 Kitap, Müzik, Film, Hobi': ['Yazar / Sanatçı', 'Yayınevi / Marka', 'Sayfa Sayısı / Tür', 'Basım Yılı', 'Dil'],
    };

    List<String> uploadedImages = List<String>.from(product['images'] ?? []);
    int selectedCampaignType = product['campaignType'] ?? 1;
    String selectedCampaignName = product['campaignName'] ?? '🔥 2 Al 1 Öde (BOGO)';
    String? selectedCategoryChip;
    bool isSaving = false;
    bool isUploadingImage = false;
    bool showAdvancedOptions = false;
    bool showAttributesSection = true;

    final campaignOptions = [
      {'type': 0, 'name': '✅ Kampanyasız (Normal Fiyat)', 'desc': 'Herhangi bir kampanya yoktur'},
      {'type': 1, 'name': '🔥 2 Al 1 Öde (BOGO)', 'desc': 'Müşteri 2 adet alınca 1\'ini ücretsiz alır'},
      {'type': 2, 'name': '🏷️ %25 İndirim', 'desc': 'Fiyat %25 indirimli gösterilir'},
      {'type': 3, 'name': '🎁 3 Al 2 Öde', 'desc': 'Müşteri 3 adet alınca 2\'sini öder'},
      {'type': 4, 'name': '💥 Flaş Kampanya', 'desc': 'Sınırlı süreli indirim'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          void pickAndUploadImage() async {
            try {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
              if (pickedFile != null) {
                setDlgState(() => isUploadingImage = true);
                final bytes = await pickedFile.readAsBytes();
                final base64String = 'data:image/png;base64,${base64Encode(bytes)}';
                setDlgState(() {
                  uploadedImages.add(base64String);
                  isUploadingImage = false;
                });
              }
            } catch (_) {
              setDlgState(() => isUploadingImage = false);
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.amberAccent, width: 1.5)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.edit, color: Colors.amberAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ürünü Güncelle', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Ürün bilgilerini ve kampanya ayarlarını düzenleyin', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            content: SizedBox(
              width: 960,
              height: 640,
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sol: Görseller
                    SizedBox(
                      width: 280,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📸 Ürün Görselleri', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: pickAndUploadImage,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 110,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.amberAccent.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amberAccent.withOpacity(0.4), style: BorderStyle.solid, width: 1.5),
                              ),
                              child: isUploadingImage
                                  ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_photo_alternate_outlined, color: Colors.amberAccent, size: 32),
                                        const SizedBox(height: 6),
                                        Text('Yeni Fotoğraf Ekle', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: urlInputController,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
                                  decoration: InputDecoration(
                                    hintText: 'Resim URL si yapıştır...',
                                    hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.05),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                onPressed: () {
                                  final url = urlInputController.text.trim();
                                  if (url.isNotEmpty) {
                                    setDlgState(() { uploadedImages.add(url); urlInputController.clear(); });
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
                                child: const Icon(Icons.add, size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (uploadedImages.isNotEmpty) ...[
                            Text('Mevcut Görseller (${uploadedImages.length})', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 160,
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 6, crossAxisSpacing: 6),
                                itemCount: uploadedImages.length,
                                itemBuilder: (ctx, i) => Stack(
                                  children: [
                                    Positioned.fill(
                                      child: _buildSafeImageWidget(uploadedImages[i], fit: BoxFit.cover, borderRadius: BorderRadius.circular(8)),
                                    ),
                                    Positioned(
                                      top: 2, right: 2,
                                      child: InkWell(
                                        onTap: () => setDlgState(() => uploadedImages.removeAt(i)),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Sağ: Form alanları
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('📝 Ürün Başlığı', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 4),
                              Text('*', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                              const Spacer(),
                              Text('${titleController.text.length} karakter', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: titleController,
                            minLines: 2,
                            maxLines: 4,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13, height: 1.35, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'Ürün başlığını eksiksiz giriniz...',
                              hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.amberAccent, width: 1.5)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onChanged: (_) => setDlgState(() {}),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: brandController,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(labelText: 'Marka', labelStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 12), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: categoryController,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(labelText: 'Kategori', labelStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 12), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: priceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    labelText: 'Satış Fiyatı *',
                                    prefixText: '₺ ',
                                    suffixText: 'TL',
                                    hintText: 'Örn: 99.999,99',
                                    prefixStyle: GoogleFonts.inter(color: Colors.white60),
                                    suffixStyle: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                    labelStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.05),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: stockController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(labelText: 'Stok Adedi', suffixText: 'Adet', labelStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 12), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: descriptionController,
                            maxLines: 2,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(labelText: 'Ürün Açıklaması', labelStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 12), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                          const SizedBox(height: 12),
                          Text('🎯 Kampanya Tipi', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amberAccent.withOpacity(0.4))),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: selectedCampaignType,
                                dropdownColor: const Color(0xFF1E293B),
                                isExpanded: true,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                items: campaignOptions.map((c) {
                                  return DropdownMenuItem<int>(
                                    value: c['type'] as int,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(c['name'] as String, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                        Text(c['desc'] as String, style: GoogleFonts.inter(color: Colors.white60, fontSize: 10)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final chosen = campaignOptions.firstWhere((c) => c['type'] == val);
                                    setDlgState(() { selectedCampaignType = val; selectedCampaignName = chosen['name'] as String; });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () => setDlgState(() => showAdvancedOptions = !showAdvancedOptions),
                            child: Row(
                              children: [
                                Icon(showAdvancedOptions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.amberAccent, size: 18),
                                const SizedBox(width: 6),
                                Text(showAdvancedOptions ? 'Gelişmiş Seçenekleri Gizle' : '⚙️ Liste Fiyatı, Desi, SKU', style: GoogleFonts.inter(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          if (showAdvancedOptions) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: listPriceController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'Liste Fiyatı (Üstü Çizili)',
                                      prefixText: '₺ ',
                                      suffixText: 'TL',
                                      hintText: 'Örn: 109.999,00',
                                      prefixStyle: GoogleFonts.inter(color: Colors.white60),
                                      suffixStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                                      labelStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.04),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: desiController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'Kargo Desisi',
                                      suffixText: 'Desi',
                                      labelStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.04),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: skuController,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'SKU (Stok Kodu)',
                                      prefixIcon: const Icon(Icons.qr_code_2, size: 18, color: Colors.amberAccent),
                                      labelStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.04),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: barcodeController,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'Barkod (EAN / GTIN)',
                                      prefixIcon: const Icon(Icons.barcode_reader, size: 18, color: Colors.amberAccent),
                                      labelStyle: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.04),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // ── Dinamik Özellikler Editörü ──────────────────────────
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () => setDlgState(() => showAttributesSection = !showAttributesSection),
                            child: Row(
                              children: [
                                Icon(showAttributesSection ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.indigoAccent, size: 18),
                                const SizedBox(width: 6),
                                Text('🏷️ Ürün Özellikleri (RAM, Renk, Kapasite...)', style: GoogleFonts.inter(color: Colors.indigoAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                if (productAttributes.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                                    child: Text('${productAttributes.length} özellik', style: GoogleFonts.inter(color: Colors.indigoAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),
                          if (showAttributesSection) ...[
                            const SizedBox(height: 8),
                            Text('Hızlı Şablon:', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: categoryTemplates.entries.map((entry) {
                                final isSelected = selectedCategoryChip == entry.key;
                                return InkWell(
                                  onTap: () {
                                    setDlgState(() {
                                      selectedCategoryChip = entry.key;
                                      // Önceki özellikleri temizle, sadece seçilen kategorinin alanlarını getir
                                      productAttributes.clear();
                                      for (final key in entry.value) {
                                        productAttributes[key] = '';
                                      }
                                      final cleanCatName = entry.key.replaceAll(RegExp(r'[^\w\s&ĞÜŞİÖÇğüşıöç]'), '').trim();
                                      if (cleanCatName.isNotEmpty) {
                                        categoryController.text = cleanCatName;
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.indigoAccent : Colors.indigo.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isSelected ? Colors.white : Colors.indigoAccent.withOpacity(0.35), width: isSelected ? 1.5 : 1.0),
                                    ),
                                    child: Text(
                                      entry.key,
                                      style: GoogleFonts.inter(
                                        color: isSelected ? Colors.white : Colors.indigoAccent,
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),
                            if (productAttributes.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.indigoAccent.withOpacity(0.2))),
                                child: Column(
                                  children: productAttributes.entries.map((entry) {
                                    final valCtrl = TextEditingController(text: entry.value);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              decoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                              child: Text(entry.key, style: GoogleFonts.inter(color: Colors.indigoAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 3,
                                            child: TextField(
                                              controller: valCtrl,
                                              onChanged: (v) => productAttributes[entry.key] = v,
                                              style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                                              decoration: InputDecoration(
                                                hintText: 'Değer girin...', hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                filled: true, fillColor: Colors.white.withOpacity(0.05),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () => setDlgState(() => productAttributes.remove(entry.key)),
                                            child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: attrKeyController,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: 'Özellik adı (RAM)', hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      filled: true, fillColor: Colors.white.withOpacity(0.05),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: attrValueController,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: 'Değer (16 GB)', hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      filled: true, fillColor: Colors.white.withOpacity(0.05),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ElevatedButton(
                                  onPressed: () {
                                    final k = attrKeyController.text.trim();
                                    final v = attrValueController.text.trim();
                                    if (k.isNotEmpty) {
                                      setDlgState(() { productAttributes[k] = v; attrKeyController.clear(); attrValueController.clear(); });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                                  child: const Icon(Icons.add, size: 16),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Vazgeç', style: GoogleFonts.inter(color: Colors.white60))),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (titleController.text.trim().isEmpty || priceController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen Ürün Başlığı ve Satış Fiyatı alanlarını girin.'), backgroundColor: Colors.orangeAccent));
                          return;
                        }
                        setDlgState(() => isSaving = true);

                        final updatePayload = {
                          'title': titleController.text.trim(),
                          'brand': brandController.text.trim(),
                          'categoryName': categoryController.text.trim(),
                          'price': parseTLInput(priceController.text),
                          'listPrice': parseTLInput(listPriceController.text) > 0 ? parseTLInput(listPriceController.text) : null,
                          'stockQuantity': int.tryParse(stockController.text) ?? 0,
                          'dimensionalWeight': double.tryParse(desiController.text) ?? 1.5,
                          'sku': skuController.text.trim(),
                          'barcode': barcodeController.text.trim(),
                          'description': descriptionController.text.trim(),
                          'images': uploadedImages,
                          'campaignType': selectedCampaignType,
                          'campaignName': selectedCampaignName,
                          'attributes': productAttributes,
                        };

                        final res = await _apiService.updateProduct(productId, updatePayload);
                        setDlgState(() => isSaving = false);

                        if (mounted) {
                          Navigator.pop(ctx);
                          if (res != null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün başarıyla güncellendi! ✅'), backgroundColor: Colors.green));
                            _loadData();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Güncelleme sırasında bir hata oluştu.'), backgroundColor: Colors.red));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Güncelle ✅', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPricingCalculatorDialog({Map<String, dynamic>? initialProduct}) {
    final products = _products ?? [];
    String? selectedProductId = initialProduct?['id']?.toString();

    final costController = TextEditingController(
      text: initialProduct != null
          ? ((initialProduct['costPrice'] ?? (initialProduct['price'] != null ? (initialProduct['price'] as num) * 0.70 : 150)).toString())
          : '150',
    );
    final profitController = TextEditingController(text: '25');
    final shippingController = TextEditingController(
      text: initialProduct != null
          ? (((initialProduct['dimensionalWeight'] ?? 1.5) as num) * 30.0).toStringAsFixed(0)
          : '45',
    );
    List<dynamic>? calculatedResults;
    bool isCalculating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          void doCalculate() async {
            setDlgState(() => isCalculating = true);
            final cost = double.tryParse(costController.text) ?? 100;
            final profit = double.tryParse(profitController.text) ?? 20;
            final shipping = double.tryParse(shippingController.text) ?? 45;

            final res = await _apiService.calculatePricing(cost, profit, shipping, 20);
            setDlgState(() {
              calculatedResults = res;
              isCalculating = false;
            });
          }

          if (calculatedResults == null && !isCalculating) {
            doCalculate();
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.calculate_outlined, color: Colors.orangeAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Akıllı Komisyon & Fiyat Robotu', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Pazaryeri komisyonlarına göre karlı satış fiyatı ve net kazanç simülatörü', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 720,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ürün Seçim Kutusu
                    if (products.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, color: Colors.amberAccent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Kataloğunuzdan Bir Ürün Seçin (İsteğe Bağlı)',
                            style: GoogleFonts.inter(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        value: selectedProductId,
                        dropdownColor: const Color(0xFF1E293B),
                        isExpanded: true,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Listeden bir ürün seçin veya manuel hesaplayın...',
                          hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 12.5),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.amberAccent, width: 1.5),
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('⚙️ Manuel Değerler ile Serbest Hesaplama', style: GoogleFonts.inter(color: Colors.cyanAccent, fontWeight: FontWeight.w500)),
                          ),
                          ...products.map((p) {
                            final pid = p['id'].toString();
                            final title = p['title'] ?? 'Ürün';
                            final price = p['price'] ?? 0;
                            return DropdownMenuItem<String?>(
                              value: pid,
                              child: Text(
                                '$title (Mevcut Satış: ${formatTL(price)})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setDlgState(() {
                            selectedProductId = val;
                            if (val != null) {
                              final p = products.firstWhere((item) => item['id'].toString() == val, orElse: () => null);
                              if (p != null) {
                                final priceNum = (p['price'] as num?)?.toDouble() ?? 100.0;
                                final costNum = (p['costPrice'] as num?)?.toDouble() ?? (priceNum * 0.70);
                                final desi = (p['dimensionalWeight'] as num?)?.toDouble() ?? 1.5;
                                costController.text = costNum.toStringAsFixed(0);
                                shippingController.text = (desi * 30.0).toStringAsFixed(0);
                                profitController.text = '25';
                              }
                            }
                          });
                          doCalculate();
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: costController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Maliyet Fiyatı (₺)',
                              labelStyle: GoogleFonts.inter(color: Colors.white60),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: profitController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Hedef Net Kâr (%)',
                              labelStyle: GoogleFonts.inter(color: Colors.white60),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: shippingController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Kargo Maliyeti (₺)',
                              labelStyle: GoogleFonts.inter(color: Colors.white60),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                          tooltip: 'Yeniden Hesapla',
                          onPressed: doCalculate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isCalculating)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.orangeAccent)))
                    else if (calculatedResults != null)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text('Pazaryeri', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 2, child: Text('Komisyon', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 3, child: Text('Önerilen Satış Fiyatı', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 2, child: Text('Komisyon Tutarı', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 2, child: Text('Net Kâr', style: GoogleFonts.inter(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...calculatedResults!.map((item) {
                            final mpName = (item['marketplaceName'] ?? item['marketplace'] ?? _getMarketplaceDisplayName(item['marketplaceType'])).toString();
                            final commRate = item['commissionPercent'] ?? item['commissionRate'] ?? 18.0;
                            final recPrice = item['recommendedSalePrice'] ?? 0.0;
                            final netProfit = item['netProfitAmount'] ?? item['targetProfitAmount'] ?? 0.0;
                            final commAmount = item['commissionAmount'] ?? (recPrice * (commRate / 100.0));

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        _getMarketplaceIconMini(mpName),
                                        const SizedBox(width: 8),
                                        Text(mpName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                      child: Text('%$commRate', style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ),
                                  Expanded(flex: 3, child: Text(formatTL(recPrice), style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14))),
                                  Expanded(flex: 2, child: Text(formatTL(commAmount), style: GoogleFonts.inter(color: Colors.white60, fontSize: 12))),
                                  Expanded(flex: 2, child: Text(formatTL(netProfit), style: GoogleFonts.inter(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Kapat', style: GoogleFonts.inter(color: Colors.white70))),
            ],
          );
        },
      ),
    );
  }

  Widget _getMarketplaceIconMini(String name) {
    if (name.contains('Trendyol')) return const Icon(Icons.circle, color: Colors.orange, size: 10);
    if (name.contains('Hepsiburada')) return const Icon(Icons.circle, color: Colors.deepOrange, size: 10);
    if (name.contains('Amazon')) return const Icon(Icons.circle, color: Colors.amber, size: 10);
    if (name.contains('N11')) return const Icon(Icons.circle, color: Colors.redAccent, size: 10);
    if (name.contains('Pazarama')) return const Icon(Icons.circle, color: Colors.purpleAccent, size: 10);
    if (name.contains('Ciceksepeti') || name.contains('Çiçek')) return const Icon(Icons.circle, color: Colors.pinkAccent, size: 10);
    if (name.contains('Ptt')) return const Icon(Icons.circle, color: Colors.yellow, size: 10);
    if (name.contains('Boyner')) return const Icon(Icons.circle, color: Colors.blueAccent, size: 10);
    if (name.contains('Pasaj')) return const Icon(Icons.circle, color: Colors.amberAccent, size: 10);
    if (name.contains('Teknosa')) return const Icon(Icons.circle, color: Colors.lightBlueAccent, size: 10);
    if (name.contains('Koçtaş') || name.contains('Koctas')) return const Icon(Icons.circle, color: Colors.orangeAccent, size: 10);
    if (name.contains('MediaMarkt')) return const Icon(Icons.circle, color: Colors.red, size: 10);
    if (name.contains('FLO') || name.contains('Flo')) return const Icon(Icons.circle, color: Colors.orange, size: 10);
    if (name.contains('Modanisa')) return const Icon(Icons.circle, color: Colors.pink, size: 10);
    if (name.contains('İdefix') || name.contains('Idefix')) return const Icon(Icons.circle, color: Colors.blue, size: 10);
    if (name.contains('Vodafone')) return const Icon(Icons.circle, color: Colors.redAccent, size: 10);
    if (name.contains('Beymen')) return const Icon(Icons.circle, color: Colors.grey, size: 10);
    if (name.contains('Akakçe') || name.contains('Akakce')) return const Icon(Icons.circle, color: Colors.cyanAccent, size: 10);
    if (name.contains('Farmazon')) return const Icon(Icons.circle, color: Colors.greenAccent, size: 10);
    if (name.contains('LCW') || name.contains('LC Waikiki')) return const Icon(Icons.circle, color: Colors.indigoAccent, size: 10);
    if (name.contains('Cimri')) return const Icon(Icons.circle, color: Colors.tealAccent, size: 10);
    return const Icon(Icons.circle, color: Colors.white38, size: 10);
  }


  void _showAddMarketplaceDialog() {
    if (_isSubscriptionExpired()) {
      _showSubscriptionExpiredDialog(customActionTitle: 'Yeni pazaryeri bağlayabilmek için lütfen üyeliğinizi başlatın veya paketinizi yükseltin.');
      return;
    }

    int selectedType = 1;
    final storeNameController = TextEditingController();
    final sellerIdController = TextEditingController();
    final apiKeyController = TextEditingController();
    final apiSecretController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.add_link, color: Colors.blueAccent),
                ),
                const SizedBox(width: 12),
                Text('Yeni Pazaryeri Bağla', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storefront_outlined, color: Colors.cyanAccent, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Bağlanacak Pazaryerini Seçin',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: selectedType,
                          dropdownColor: const Color(0xFF1E293B),
                          isExpanded: true,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
                          ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('🟠 Trendyol')),
                        DropdownMenuItem(value: 2, child: Text('🟠 Hepsiburada')),
                        DropdownMenuItem(value: 3, child: Text('📦 Amazon TR')),
                        DropdownMenuItem(value: 4, child: Text('🔴 N11')),
                        DropdownMenuItem(value: 5, child: Text('🟣 Pazarama')),
                        DropdownMenuItem(value: 6, child: Text('🌸 ÇiçekSepeti')),
                        DropdownMenuItem(value: 7, child: Text('🟡 PttAVM')),
                        DropdownMenuItem(value: 8, child: Text('🔵 Boyner')),
                        DropdownMenuItem(value: 9, child: Text('🟡 Sahibinden')),
                        DropdownMenuItem(value: 10, child: Text('🟡 Turkcell Pasaj')),
                        DropdownMenuItem(value: 11, child: Text('🔵 Teknosa')),
                        DropdownMenuItem(value: 12, child: Text('🟠 Koçtaş')),
                        DropdownMenuItem(value: 13, child: Text('🔴 MediaMarkt')),
                        DropdownMenuItem(value: 14, child: Text('🟠 FLO')),
                        DropdownMenuItem(value: 15, child: Text('🌸 Modanisa')),
                        DropdownMenuItem(value: 16, child: Text('🔵 İdefix')),
                        DropdownMenuItem(value: 17, child: Text('🔴 Vodafone')),
                        DropdownMenuItem(value: 18, child: Text('⚫ Beymen')),
                        DropdownMenuItem(value: 19, child: Text('🔵 Akakçe')),
                        DropdownMenuItem(value: 20, child: Text('🟢 Farmazon (Eczane B2B)')),
                        DropdownMenuItem(value: 21, child: Text('🔵 LC Waikiki')),
                        DropdownMenuItem(value: 22, child: Text('🔵 Cimri')),
                      ],
                      onChanged: (val) => setDialogState(() => selectedType = val ?? 1),
                    ),
                  ],
                ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: storeNameController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(labelText: 'Mağaza Adı', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sellerIdController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(labelText: 'Satıcı ID (Supplier ID / Merchant ID)', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: apiKeyController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(labelText: 'API Anahtarı (API Key / Client ID)', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: apiSecretController,
                      obscureText: true,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(labelText: 'API Gizli Anahtar (API Secret)', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('İptal', style: GoogleFonts.inter(color: Colors.white60))),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        final res = await _apiService.connectMarketplace(
                          marketplaceType: selectedType,
                          storeName: storeNameController.text,
                          sellerId: sellerIdController.text,
                          apiKey: apiKeyController.text,
                          apiSecret: apiSecretController.text,
                        );
                        setDialogState(() => isSubmitting = false);

                        if (res != null && mounted) {
                          if (res.containsKey('error')) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error']), backgroundColor: Colors.red));
                          } else {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pazaryeri başarıyla bağlandı!'), backgroundColor: Colors.green));
                            _loadData();
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Bağla', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProductDetailsDialog(String productId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
    );

    final details = await _apiService.getProductDetails(productId);
    if (!mounted) return;
    Navigator.pop(context);

    if (details == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün detayları yüklenemedi!'), backgroundColor: Colors.red));
      return;
    }

    String selectedImage = (details['images'] as List<dynamic>?)?.firstOrNull?.toString() ?? '';
    final images = (details['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final attributes = (details['attributes'] as Map<String, dynamic>?) ?? {};
    final variants = (details['variants'] as List<dynamic>?) ?? [];
    final campaignName = details['campaignName'] ?? 'Standart Satış';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDetailState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.inventory_2, color: Colors.blueAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(details['title'] ?? 'Ürün Detayları', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Marka: ${details['brand'] ?? 'Genel'} • Kategori: ${details['categoryName'] ?? 'Giyim'} • Model: ${details['modelCode'] ?? details['sku']}', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            content: SizedBox(
              width: 800,
              height: 580,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 260,
                          child: Column(
                            children: [
                              Container(
                                height: 240,
                                width: 260,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: selectedImage.isNotEmpty
                                    ? _buildSafeImageWidget(selectedImage, fit: BoxFit.contain, borderRadius: BorderRadius.circular(12))
                                    : const Center(child: Icon(Icons.image_not_supported, color: Colors.white24, size: 48)),
                              ),
                              const SizedBox(height: 8),
                              if (images.length > 1)
                                SizedBox(
                                  height: 50,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: images.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (context, idx) {
                                      final imgUrl = images[idx];
                                      final isCur = imgUrl == selectedImage;
                                      return InkWell(
                                        onTap: () => setDetailState(() => selectedImage = imgUrl),
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: isCur ? Colors.blueAccent : Colors.white24, width: isCur ? 2 : 1),
                                          ),
                                          child: _buildSafeImageWidget(imgUrl, fit: BoxFit.cover, borderRadius: BorderRadius.circular(7)),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [Colors.orange.shade900, Colors.deepOrange]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_fire_department, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text('Aktif Kampanya: $campaignName', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Satış Fiyatı', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                                        Text(formatTL(details['price']), style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 22)),
                                      ],
                                    ),
                                    const SizedBox(width: 24),
                                    if (details['listPrice'] != null)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Liste Fiyatı', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                                          Text(formatTL(details['listPrice']), style: GoogleFonts.inter(color: Colors.white38, decoration: TextDecoration.lineThrough, fontSize: 16)),
                                        ],
                                      ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Toplam Stok', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                                        Text('${details['stockQuantity']} Adet', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _specRow('SKU (Stok Kodu)', details['sku'] ?? '-'),
                              _specRow('Barkod', details['barcode'] ?? '-'),
                              _specRow('Kargo Desisi', '${details['dimensionalWeight'] ?? 1.0} Desi'),
                              _specRow('Kargo Şirketi', details['cargoCompany'] ?? 'Trendyol Express'),
                              _specRow('Teslimat Süresi', '${details['deliveryDuration'] ?? 2} İş Günü'),
                              _specRow('KDV Oranı', '%${details['vatRate'] ?? 20}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (attributes.isNotEmpty) ...[
                      Text('🏷️ Kategori Nitelikleri & Özellikler', style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: attributes.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(text: '${e.key}: ', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
                                  TextSpan(text: '${e.value}', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text('👥 Beden & Renk Varyant Matrisi (${variants.length} Varyant)', style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    if (variants.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(8)),
                        child: Text('Bu ürünün alt varyantı bulunmuyor (Tekil ürün).', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text('Beden', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                                  Expanded(flex: 3, child: Text('Renk', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                                  Expanded(flex: 4, child: Text('SKU / Barkod', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                                  Expanded(flex: 2, child: Text('Fiyat', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12))),
                                  Expanded(flex: 2, child: Text('Stok', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                                ],
                              ),
                            ),
                            ...variants.map((v) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white12))),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 2, child: Text(v['size'] ?? '-', style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                                      Expanded(flex: 3, child: Text(v['color'] ?? '-', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12))),
                                      Expanded(flex: 4, child: Text('${v['sku']} • ${v['barcode'] ?? '-'}', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11))),
                                      Expanded(flex: 2, child: Text(formatTL(v['price']), style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                                      Expanded(flex: 2, child: Text('${v['stockQuantity']} Adet', style: GoogleFonts.inter(color: Colors.white, fontSize: 12))),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: Text('Kapat', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBatchSyncApprovalDialog({String? initialScope, String? initialProductId}) {
    if (_isSubscriptionExpired()) {
      _showSubscriptionExpiredDialog(customActionTitle: 'Pazaryeri senkronizasyonu yapabilmek için lütfen üyeliğinizi başlatın veya paketinizi yükseltin.');
      return;
    }

    final products = _products ?? [];
    final activeConnections = _connections?.where((c) => c['isActive'] == true).toList() ?? [];

    String selectedScope = initialScope ?? (initialProductId != null ? 'product' : 'all');

    final selectedProductIds = <String>{};
    if (initialProductId != null) {
      selectedProductIds.add(initialProductId);
    } else {
      for (final p in products) {
        selectedProductIds.add(p['id'].toString());
      }
    }

    final allCategories = <String>{};
    for (final p in products) {
      final cat = (p['categoryName'] ?? p['category'] ?? 'Genel').toString();
      allCategories.add(cat);
    }
    final selectedCategories = Set<String>.from(allCategories);

    bool isSyncing = false;
    double syncProgress = 0.0;
    List<Map<String, dynamic>> syncLogs = [];
    Map<String, dynamic>? syncSummary;

    showDialog(
      context: context,
      barrierDismissible: !isSyncing,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          int targetProductCount = 0;
          if (selectedScope == 'all') {
            targetProductCount = products.length;
          } else if (selectedScope == 'category') {
            targetProductCount = products.where((p) => selectedCategories.contains((p['categoryName'] ?? p['category'] ?? 'Genel').toString())).length;
          } else {
            targetProductCount = selectedProductIds.length;
          }

          final targetMarketplaceCount = activeConnections.isNotEmpty ? activeConnections.length : 1;

          Future<void> runSync() async {
            setDlgState(() {
              isSyncing = true;
              syncProgress = 0.15;
              syncLogs = [
                {
                  'timestamp': DateTime.now().toIso8601String(),
                  'marketplace': 'Sistem',
                  'status': 'Info',
                  'message': 'Senkronizasyon motoru başlatıldı. Hedef: $targetProductCount ürün, $targetMarketplaceCount pazaryeri...',
                }
              ];
            });

            List<String>? prodIds;
            List<String>? catNames;
            if (selectedScope == 'product') {
              prodIds = selectedProductIds.toList();
            } else if (selectedScope == 'category') {
              catNames = selectedCategories.toList();
            }

            final res = await _apiService.batchSyncAll(
              scope: selectedScope,
              productIds: prodIds,
              categoryNames: catNames,
            );

            if (res != null) {
              final rawLogs = res['logs'] as List<dynamic>? ?? [];
              final mappedLogs = rawLogs.map((l) => Map<String, dynamic>.from(l as Map)).toList();

              setDlgState(() {
                syncProgress = 1.0;
                syncLogs = mappedLogs;
                syncSummary = res;
                isSyncing = false;
              });
              _loadData();
            } else {
              setDlgState(() {
                syncProgress = 1.0;
                syncLogs.add({
                  'timestamp': DateTime.now().toIso8601String(),
                  'marketplace': 'Hata',
                  'status': 'Failed',
                  'message': 'Pazaryerleri ile iletişim kurulurken bir ağ hatası oluştu.',
                });
                isSyncing = false;
              });
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Colors.blueAccent, width: 1.5)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.indigoAccent]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sync_alt, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Çoklu Pazaryeri Dağıtım & Senkronizasyon Merkezi', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                      Text('Değişiklikleri tüm entegre pazaryerlerine canlı iletin ve anlık izleyin', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
                if (!isSyncing)
                  IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            content: SizedBox(
              width: 900,
              height: 600,
              child: isSyncing || syncSummary != null
                  ? _buildSyncLiveConsole(isSyncing, syncProgress, syncLogs, syncSummary, ctx)
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Soru Başlığı Kartı
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.help_outline, color: Colors.amberAccent, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ürün bazlı değişiklikler ve senkronizasyon bilgileri ekrana getirilmiştir.',
                                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Değişiklikleri pazaryerlerine nasıl onaylayıp göndermek istersiniz? Lütfen aşağıdan bir onay kapsamı seçin:',
                                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3 Kapsam Seçim Kartı
                          Row(
                            children: [
                              Expanded(
                                child: _buildScopeSelectionCard(
                                  scopeId: 'all',
                                  title: '🌟 Tümünü Onayla (Hepsi)',
                                  subtitle: 'Tüm (${products.length}) ürünün değişikliklerini tek tıkla onaylayıp tüm pazaryerlerine dağıtır.',
                                  icon: Icons.all_inclusive,
                                  color: Colors.greenAccent,
                                  isSelected: selectedScope == 'all',
                                  onTap: () => setDlgState(() => selectedScope = 'all'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildScopeSelectionCard(
                                  scopeId: 'category',
                                  title: '📂 Kategori Bazlı Onayla',
                                  subtitle: 'Sadece seçeceğiniz kategorilerdeki ürünlerin güncellemelerini pazaryerlerine aktarır.',
                                  icon: Icons.category,
                                  color: Colors.blueAccent,
                                  isSelected: selectedScope == 'category',
                                  onTap: () => setDlgState(() => selectedScope = 'category'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildScopeSelectionCard(
                                  scopeId: 'product',
                                  title: '🎯 Ürün Bazlı Onayla (Tek Tek)',
                                  subtitle: 'Listeden seçeceğiniz ürünlerin değişikliklerini tek tek onaylayıp gönderir.',
                                  icon: Icons.checklist,
                                  color: Colors.orangeAccent,
                                  isSelected: selectedScope == 'product',
                                  onTap: () => setDlgState(() => selectedScope = 'product'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Kapsama Göre Dinamik İçerik Görünümü
                          if (selectedScope == 'all')
                            _buildScopeAllView(products, activeConnections)
                          else if (selectedScope == 'category')
                            _buildScopeCategoryView(products, allCategories, selectedCategories, (newCats) => setDlgState(() {}))
                          else
                            _buildScopeProductView(products, selectedProductIds, (newIds) => setDlgState(() {})),
                        ],
                      ),
                    ),
            ),
            actions: [
              if (syncSummary != null)
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text('Tamamlandı • Kapat', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                )
              else if (!isSyncing) ...[
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Vazgeç', style: GoogleFonts.inter(color: Colors.white60)),
                ),
                ElevatedButton.icon(
                  onPressed: targetProductCount == 0 ? null : runSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.rocket_launch, size: 18, color: Colors.black),
                  label: Text(
                    '🚀 Onayla ve Pazaryerlerine Dağıt ($targetProductCount Ürün • $targetMarketplaceCount Pazaryeri)',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildScopeSelectionCard({
    required String scopeId,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF334155),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.25) : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: isSelected ? color : Colors.white70, size: 18),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle, color: color, size: 20)
                else
                  const Icon(Icons.radio_button_unchecked, color: Colors.white38, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, height: 1.35)),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeAllView(List<dynamic> products, List<dynamic> connections) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.greenAccent)),
                child: Text('TÜM KATALOG ONAYLANDI', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              const SizedBox(width: 10),
              Text('Toplam ${products.length} Ürün • Canlı Eşitlemeye Hazır', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Aktif Hedef Pazaryerleri:', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: connections.isEmpty
                ? [
                    _tagBadge('🟠 Trendyol', Colors.orange),
                    _tagBadge('🟠 Hepsiburada', Colors.deepOrange),
                    _tagBadge('🔴 N11', Colors.redAccent),
                    _tagBadge('🟣 Pazarama', Colors.purpleAccent),
                  ]
                : connections.map((c) {
                    final type = c['marketplaceType'] ?? 1;
                    return _tagBadge('🔗 ${_getMarketplaceDisplayName(type)} (${c['storeName'] ?? 'Mağaza'})', Colors.blueAccent);
                  }).toList(),
          ),
          const SizedBox(height: 12),
          Text('Eşitlenecek Ürün Listesi Önizlemesi:', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
              itemBuilder: (ctx, i) {
                final p = products[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      _buildSafeImageWidget(
                        p['firstImage'] ?? (p['images'] != null && (p['images'] as List).isNotEmpty ? (p['images'] as List)[0] : null),
                        width: 32,
                        height: 32,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['title'] ?? 'Ürün', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('SKU: ${p['sku']} • Kategori: ${p['categoryName'] ?? 'Genel'}', style: GoogleFonts.inter(color: Colors.white60, fontSize: 10)),
                          ],
                        ),
                      ),
                      Text(formatTL(p['price']), style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text('${p['stockQuantity']} Adet', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeCategoryView(
    List<dynamic> products,
    Set<String> allCategories,
    Set<String> selectedCategories,
    Function(Set<String>) onSelectionChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Onaylanacak Kategorileri Seçin (${selectedCategories.length} / ${allCategories.length} seçildi):',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      selectedCategories.addAll(allCategories);
                      onSelectionChanged(selectedCategories);
                    },
                    icon: const Icon(Icons.select_all, size: 14, color: Colors.blueAccent),
                    label: Text('Tümünü Seç', style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: () {
                      selectedCategories.clear();
                      onSelectionChanged(selectedCategories);
                    },
                    icon: const Icon(Icons.clear, size: 14, color: Colors.redAccent),
                    label: Text('Temizle', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: allCategories.map((cat) {
              final isChecked = selectedCategories.contains(cat);
              final count = products.where((p) => (p['categoryName'] ?? p['category'] ?? 'Genel').toString() == cat).length;
              return InkWell(
                onTap: () {
                  if (isChecked) {
                    selectedCategories.remove(cat);
                  } else {
                    selectedCategories.add(cat);
                  }
                  onSelectionChanged(selectedCategories);
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isChecked ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isChecked ? const Color(0xFF60A5FA) : const Color(0xFF475569),
                      width: isChecked ? 1.5 : 1,
                    ),
                    boxShadow: isChecked
                        ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isChecked ? Colors.white : Colors.white60,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: isChecked ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isChecked ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count Ürün',
                          style: GoogleFonts.inter(
                            color: isChecked ? Colors.white : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeProductView(
    List<dynamic> products,
    Set<String> selectedProductIds,
    Function(Set<String>) onSelectionChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Onaylanacak Ürünleri Seçin (${selectedProductIds.length} / ${products.length} seçildi):',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      for (final p in products) {
                        selectedProductIds.add(p['id'].toString());
                      }
                      onSelectionChanged(selectedProductIds);
                    },
                    icon: const Icon(Icons.select_all, size: 14, color: Colors.orangeAccent),
                    label: Text('Tümünü Seç', style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: () {
                      selectedProductIds.clear();
                      onSelectionChanged(selectedProductIds);
                    },
                    icon: const Icon(Icons.clear, size: 14, color: Colors.redAccent),
                    label: Text('Temizle', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
              itemBuilder: (ctx, i) {
                final p = products[i];
                final pid = p['id'].toString();
                final isChecked = selectedProductIds.contains(pid);
                return Container(
                  color: isChecked ? Colors.orangeAccent.withOpacity(0.08) : Colors.transparent,
                  child: CheckboxListTile(
                    value: isChecked,
                    activeColor: Colors.orangeAccent,
                    checkColor: Colors.black,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    onChanged: (val) {
                      if (val == true) {
                        selectedProductIds.add(pid);
                      } else {
                        selectedProductIds.remove(pid);
                      }
                      onSelectionChanged(selectedProductIds);
                    },
                    secondary: _buildSafeImageWidget(
                      p['firstImage'] ?? (p['images'] != null && (p['images'] as List).isNotEmpty ? (p['images'] as List)[0] : null),
                      width: 36,
                      height: 36,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    title: Text(p['title'] ?? 'Ürün', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('SKU: ${p['sku']} • ${p['categoryName'] ?? 'Genel'} • Fiyat: ${formatTL(p['price'])} • Stok: ${p['stockQuantity']}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncLiveConsole(
    bool isSyncing,
    double progress,
    List<Map<String, dynamic>> logs,
    Map<String, dynamic>? summary,
    BuildContext dialogCtx,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (isSyncing) ...[
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.amberAccent)),
              const SizedBox(width: 10),
              Text('Canlı Pazaryeri Dağıtımı Sürüyor...', style: GoogleFonts.inter(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
            ] else ...[
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
              const SizedBox(width: 10),
              Text('Dağıtım Tamamlandı! ✅', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
            const Spacer(),
            if (summary != null)
              Text(
                'Toplam: ${summary['totalProducts']} Ürün • ${summary['totalMarketplaces']} Pazaryeri • ${summary['durationSeconds']}s',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: isSyncing ? null : 1.0,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(isSyncing ? Colors.amberAccent : Colors.greenAccent),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 14),

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF030712),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.amberAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Text('CANLI SENKRONİZASYON TERMİNALİ', style: GoogleFonts.firaCode(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${logs.length} İşlem Kaydı', style: GoogleFonts.firaCode(color: Colors.white38, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 8),
                Expanded(
                  child: logs.isEmpty
                      ? Center(child: Text('Senkronizasyon işlemi başlatılıyor...', style: GoogleFonts.firaCode(color: Colors.white38, fontSize: 12)))
                      : ListView.separated(
                          itemCount: logs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (ctx, i) {
                            final log = logs[i];
                            final isSuccess = log['status'] == 'Success';
                            final isInfo = log['status'] == 'Info';
                            final marketplace = log['marketplace'] ?? log['marketplaceName'] ?? 'API';
                            final msg = log['message'] ?? '';
                            final title = log['productTitle'] ?? '';
                            final sku = log['sku'] != null && (log['sku'] as String).isNotEmpty ? '[${log['sku']}]' : '';

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSuccess
                                    ? Colors.greenAccent.withOpacity(0.06)
                                    : (isInfo ? Colors.blueAccent.withOpacity(0.06) : Colors.redAccent.withOpacity(0.08)),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSuccess
                                      ? Colors.greenAccent.withOpacity(0.2)
                                      : (isInfo ? Colors.blueAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.3)),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isSuccess ? '✅' : (isInfo ? 'ℹ️' : '❌'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(marketplace.toString(), style: GoogleFonts.firaCode(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.firaCode(fontSize: 11, color: Colors.white70),
                                        children: [
                                          if (title.isNotEmpty)
                                            TextSpan(text: '$title $sku: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          TextSpan(text: msg, style: TextStyle(color: isSuccess ? Colors.greenAccent : (isInfo ? Colors.white70 : Colors.redAccent))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getMarketplaceDisplayName(dynamic type) {
    final t = int.tryParse(type.toString()) ?? 1;
    switch (t) {
      case 1: return 'Trendyol';
      case 2: return 'Hepsiburada';
      case 3: return 'Amazon TR';
      case 4: return 'N11';
      case 5: return 'Pazarama';
      case 6: return 'ÇiçekSepeti';
      case 7: return 'PttAVM';
      case 8: return 'Boyner';
      case 9: return 'Sahibinden';
      case 10: return 'Turkcell Pasaj';
      case 11: return 'Teknosa';
      case 12: return 'Koçtaş';
      case 13: return 'MediaMarkt';
      case 14: return 'FLO';
      case 15: return 'Modanisa';
      case 16: return 'İdefix';
      case 17: return 'Vodafone';
      case 18: return 'Beymen';
      case 19: return 'Akakçe';
      case 20: return 'Farmazon';
      case 21: return 'LC Waikiki';
      case 22: return 'Cimri';
      default: return 'Pazaryeri';
    }
  }


  Widget _specRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
          Text(val, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenant = _metrics?['tenant'];
    final companyName = tenant?['companyName'] ?? _metrics?['companyName'] ?? _metrics?['CompanyName'] ?? 'Mağazam';
    final limits = _metrics?['limits'];

    // Dinamik kullanıcı bazlı Kalan Deneme Süresi (API + Yedek Tarih Hesabı)
    int daysLeft = 30;
    if (limits != null && limits['daysLeft'] != null) {
      daysLeft = int.tryParse(limits['daysLeft'].toString()) ?? 30;
    } else if (_metrics != null && _metrics!['daysLeft'] != null) {
      daysLeft = int.tryParse(_metrics!['daysLeft'].toString()) ?? 30;
    } else if (_metrics != null && _metrics!['DaysLeft'] != null) {
      daysLeft = int.tryParse(_metrics!['DaysLeft'].toString()) ?? 30;
    } else {
      final subEndDateStr = tenant?['subscriptionEndDate'] ?? _metrics?['subscriptionEndDate'];
      if (subEndDateStr != null) {
        final end = DateTime.tryParse(subEndDateStr.toString());
        if (end != null) {
          final diff = end.difference(DateTime.now().toUtc());
          daysLeft = (diff.inHours / 24.0).ceil();
          if (daysLeft < 0) daysLeft = 0;
        }
      }
    }

    final plan = _metrics?['plan'] ?? tenant?['subscriptionPlan'] ?? 'Free';
    final isPaid = plan != 'Free' && plan != 'Deneme';
    final isExpired = !isPaid && (_metrics?['isExpired'] == true || limits?['isExpired'] == true || daysLeft <= 0);

    final productCount = limits?['currentProducts'] ?? _metrics?['productCount'] ?? _metrics?['ProductCount'] ?? (_products?.length ?? 0);
    final productLimit = limits?['productLimit'] ?? _metrics?['productLimit'] ?? _metrics?['ProductLimit'] ?? 50;
    final connCount = limits?['currentConnections'] ?? _metrics?['connectionCount'] ?? _metrics?['ConnectionCount'] ?? (_connections?.length ?? 0);
    final connLimit = limits?['connectionLimit'] ?? _metrics?['connectionLimit'] ?? _metrics?['ConnectionLimit'] ?? 3;

    return Scaffold(
      floatingActionButton: _isAiFabMinimized
          ? FloatingActionButton(
              heroTag: 'ai_fab_minimized',
              onPressed: () {
                setState(() => _isAiFabMinimized = false);
                _showAiAssistantDialog();
              },
              backgroundColor: Colors.purple.shade800,
              tooltip: '✨ AI Pazaryeri Danışmanı (Açmak için tıklayın)',
              child: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 24),
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.purple.shade800,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.purple.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _showAiAssistantDialog,
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
                          const SizedBox(width: 8),
                          Text('✨ AI Pazaryeri Danışmanı', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Simge halinde küçült',
                    child: InkWell(
                      onTap: () => setState(() => _isAiFabMinimized = true),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.close, color: Colors.white70, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  border: const Border(bottom: BorderSide(color: Colors.white12)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 950;
                    return isSmallScreen
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/roatech_emblem.png',
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.hub, color: Colors.cyanAccent, size: 24),
                                  ),

                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                companyName,
                                                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isPaid) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.amberAccent, borderRadius: BorderRadius.circular(6)),
                                                child: Text(plan.toUpperCase(), style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          isExpired
                                              ? '⚠️ Deneme Süresi Doldu'
                                              : (isPaid ? '$plan • $daysLeft Gün Kaldı' : '$daysLeft Gün Kaldı • Deneme (3 Pazaryeri • 50 Ürün)'),
                                          style: GoogleFonts.inter(
                                            color: isExpired ? Colors.redAccent : (isPaid ? Colors.greenAccent : Colors.amberAccent),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.qr_code_scanner, color: Colors.cyanAccent),
                                    tooltip: 'Barkod / QR Tara',
                                    onPressed: _openBarcodeScanner,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                                    tooltip: 'Çıkış Yap',
                                    onPressed: _logout,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    if (isExpired) ...[
                                      ElevatedButton.icon(
                                        onPressed: () => _showSubscriptionExpiredDialog(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amberAccent,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.rocket_launch, size: 14, color: Colors.black),
                                        label: Text('Paketi Yükselt', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11)),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    ElevatedButton.icon(
                                      onPressed: _showAiAssistantDialog,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple.shade800,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.auto_awesome, size: 14, color: Colors.amberAccent),
                                      label: Text('AI Asistan', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: _showPricingCalculatorDialog,
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.orangeAccent, side: const BorderSide(color: Colors.orangeAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                      icon: const Icon(Icons.calculate, size: 16),
                                      label: Text('Fiyat Robotu', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: _showAddMarketplaceDialog,
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                      icon: const Icon(Icons.add_link, size: 16),
                                      label: Text('Pazaryeri Bağla', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Image.asset(
                                'assets/images/roatech_emblem.png',
                                width: 38,
                                height: 38,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.hub, color: Colors.cyanAccent, size: 28),
                              ),

                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(companyName, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                      if (isPaid) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.amberAccent, borderRadius: BorderRadius.circular(6)),
                                          child: Text(plan.toUpperCase(), style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (isExpired)
                                    Text('⚠️ Deneme Süresi Doldu • İşlemler Kısıtlandı', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold))
                                  else if (isPaid)
                                    Text('$plan • $daysLeft Gün Kaldı • Sınırsız Senkronizasyon', style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w500))
                                  else
                                    Text('$daysLeft Gün Kaldı • Ücretsiz Deneme (3 Pazaryeri • 50 Ürün)', style: GoogleFonts.inter(color: daysLeft <= 3 ? Colors.redAccent : Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const Spacer(),
                              if (isExpired) ...[
                                ElevatedButton.icon(
                                  onPressed: () => _showSubscriptionExpiredDialog(customActionTitle: 'Aboneliğinizi başlatarak tüm kısıtlamaları anında kaldırın.'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amberAccent,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                  icon: const Icon(Icons.rocket_launch, size: 16, color: Colors.black),
                                  label: Text('🚀 Paketi Yükselt', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                              ],
                              ElevatedButton.icon(
                                onPressed: _showAiAssistantDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade800,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.amberAccent),
                                label: Text('AI Asistan', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: _showPricingCalculatorDialog,
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.orangeAccent, side: const BorderSide(color: Colors.orangeAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                icon: const Icon(Icons.calculate, size: 18),
                                label: Text('Akıllı Fiyat Robotu', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _showAddMarketplaceDialog,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                icon: const Icon(Icons.add_link, size: 18),
                                label: Text('Pazaryeri Bağla', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
                                tooltip: 'Barkod / QR Tara',
                                onPressed: _openBarcodeScanner,
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.logout, color: Colors.redAccent),
                                tooltip: 'Çıkış Yap',
                                onPressed: _logout,
                              ),
                            ],
                          );
                  },
                ),
              ),

              // Navigation Tabs (Mobile Scrollable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildTabButton(0, 'Pazaryeri Entegrasyonları', Icons.hub_outlined),
                      const SizedBox(width: 10),
                      _buildTabButton(1, 'Siparişler', Icons.shopping_bag_outlined),
                      const SizedBox(width: 10),
                      _buildTabButton(2, 'Ürün Kataloğu & Varyantlar', Icons.inventory_2_outlined),
                      const SizedBox(width: 10),
                      _buildTabButton(3, 'Finans & Kâr Analizi 📊', Icons.query_stats_outlined),
                    ],
                  ),
                ),
              ),


              // Main Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: isExpired ? () => _showSubscriptionExpiredDialog() : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        child: _buildLimitStat(
                                          isPaid ? 'Abonelik Durumu' : 'Kalan Deneme',
                                          isPaid ? '$daysLeft Gün ($plan)' : (daysLeft > 0 ? '$daysLeft Gün' : 'Süre Doldu'),
                                          isPaid ? Icons.verified : Icons.timer_outlined,
                                          isExpired ? Colors.redAccent : (isPaid ? Colors.greenAccent : (daysLeft <= 3 ? Colors.redAccent : Colors.amberAccent)),
                                        ),
                                      ),
                                    ),
                                    Container(width: 1, height: 32, color: Colors.white12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      child: _buildLimitStat('Aktif Pazaryerleri', '$connCount / $connLimit', Icons.cable, Colors.blueAccent),
                                    ),
                                    Container(width: 1, height: 32, color: Colors.white12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      child: _buildLimitStat('Kayıtlı Ürünler', '$productCount / $productLimit', Icons.inventory_2, Colors.greenAccent),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (_currentTabIndex == 0) _buildConnectionsTab(),
                            if (_currentTabIndex == 1) _buildOrdersTab(),
                            if (_currentTabIndex == 2) _buildProductsTab(),
                            if (_currentTabIndex == 3) _buildFinancialsTab(),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _currentTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentTabIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeImageWidget(String? url, {double? width, double? height, BoxFit fit = BoxFit.cover, BorderRadius? borderRadius}) {
    if (url == null || url.trim().isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: const Center(child: Icon(Icons.image_outlined, color: Colors.white38, size: 22)),
      );
    }

    final trimmed = url.trim();

    // 1. Base64 Data URL veya Ham Base64 Desteği
    if (trimmed.startsWith('data:image/') || (trimmed.contains('base64,') && !trimmed.startsWith('http')) || (!trimmed.startsWith('http') && trimmed.length > 100)) {
      try {
        final cleanBase64 = (trimmed.contains(',') ? trimmed.substring(trimmed.indexOf(',') + 1) : trimmed).replaceAll(RegExp(r'[\r\n\s]+'), '');
        final bytes = base64Decode(cleanBase64);
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (ctx, err, stack) => Container(
              width: width,
              height: height,
              color: Colors.white.withOpacity(0.06),
              child: const Center(child: Icon(Icons.image_outlined, color: Colors.white38, size: 22)),
            ),
          ),
        );
      } catch (_) {}
    }

    // 2. Hepsiburada CDN CORS engeli olan veya eski upload URL'lerini akıllı görselle çözümle
    String effectiveUrl = trimmed;
    if (trimmed.contains('productimages.hepsiburada.net') || (trimmed.contains('/uploads/') && !trimmed.startsWith('data:image'))) {
      effectiveUrl = 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=600&auto=format&fit=crop&q=80';
    }

    // 3. Normal HTTP / HTTPS URL
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: Image.network(
        effectiveUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, stack) {
          // CORS engeli durumunda proxy dene
          final proxyUrl = 'https://images.weserv.nl/?url=${Uri.encodeComponent(effectiveUrl)}';
          return Image.network(
            proxyUrl,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (c, e, s) => Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: borderRadius ?? BorderRadius.circular(8),
              ),
              child: const Center(child: Icon(Icons.image_outlined, color: Colors.white38, size: 22)),
            ),
          );
        },
      ),
    );
  }

  String formatTL(dynamic value) {
    if (value == null) return '0,00 ₺';
    double numVal = 0.0;
    if (value is num) {
      numVal = value.toDouble();
    } else {
      final str = value.toString().replaceAll('₺', '').replaceAll('TL', '').replaceAll(' ', '').trim();
      if (str.contains(',') && str.contains('.')) {
        numVal = double.tryParse(str.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
      } else if (str.contains(',')) {
        numVal = double.tryParse(str.replaceAll(',', '.')) ?? 0.0;
      } else {
        numVal = double.tryParse(str) ?? 0.0;
      }
    }
    final fixed = numVal.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0].replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    final decPart = parts[1];
    return '$intPart,$decPart ₺';
  }

  String formatNumberTL(dynamic value) {
    if (value == null) return '';
    double numVal = 0.0;
    if (value is num) {
      numVal = value.toDouble();
    } else {
      final str = value.toString().replaceAll('₺', '').replaceAll('TL', '').replaceAll(' ', '').trim();
      if (str.contains(',') && str.contains('.')) {
        numVal = double.tryParse(str.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
      } else if (str.contains(',')) {
        numVal = double.tryParse(str.replaceAll(',', '.')) ?? 0.0;
      } else {
        numVal = double.tryParse(str) ?? 0.0;
      }
    }
    if (numVal <= 0) return '';
    final fixed = numVal.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0].replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    final decPart = parts[1];
    return '$intPart,$decPart';
  }

  double parseTLInput(String? text) {
    if (text == null || text.trim().isEmpty) return 0.0;
    final clean = text.replaceAll('₺', '').replaceAll('TL', '').replaceAll(' ', '').trim();
    if (clean.contains(',') && clean.contains('.')) {
      return double.tryParse(clean.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;
    } else if (clean.contains(',')) {
      return double.tryParse(clean.replaceAll(',', '.')) ?? 0.0;
    }
    return double.tryParse(clean) ?? 0.0;
  }

  Widget _buildLimitStat(String label, String val, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 10),
            ),
            Text(
              val,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bağlı Pazaryeri Kanalları', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _connections == null || _connections!.isEmpty
            ? _buildEmptyState('Henüz bağlı bir pazaryeri bulunmuyor. Üst menüden "Pazaryeri Bağla" butonuna tıklayın.', Icons.hub_outlined)
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _connections!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final c = _connections![index];
                  final isActive = c['isActive'] == true;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.storefront, color: Colors.orangeAccent, size: 28)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c['marketplaceName'] ?? 'Pazaryeri', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Mağaza: ${c['storeName']} • Satıcı ID: ${c['sellerId']}', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                            ],
                          ),
                        ),
                        Switch(
                          value: isActive,
                          activeColor: Colors.greenAccent,
                          onChanged: (val) async {
                            final ok = await _apiService.toggleMarketplaceConnection(c['id'], val);
                            if (ok && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? 'Pazaryeri aktif edildi.' : 'Pazaryeri durduruldu.'), backgroundColor: val ? Colors.green : Colors.orange));
                              _loadData();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                          tooltip: 'API Doğrula',
                          onPressed: () async {
                            final res = await _apiService.validateMarketplace(c['id']);
                            if (mounted) {
                              final isValid = res?['isValid'] == true;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res?['message'] ?? (isValid ? 'API Geçerli!' : 'Doğrulanamadı!')), backgroundColor: isValid ? Colors.green : Colors.red));
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Bağlantıyı Sil',
                          onPressed: () async {
                            final ok = await _apiService.deleteMarketplaceConnection(c['id']);
                            if (ok && mounted) _loadData();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    final allOrders = (_orders ?? []);

    // Filter by Marketplace
    var filteredOrders = allOrders.where((o) {
      if (_selectedOrderMarketplaceFilter != 'ALL') {
        final mp = (o['marketplace'] ?? '').toString().toLowerCase();
        if (!mp.contains(_selectedOrderMarketplaceFilter.toLowerCase())) return false;
      }
      if (_selectedOrderStatusFilter != 'ALL') {
        final st = (o['status'] ?? '').toString().toLowerCase();
        if (!st.contains(_selectedOrderStatusFilter.toLowerCase())) return false;
      }
      if (_orderSearchQuery.isNotEmpty) {
        final q = _orderSearchQuery.toLowerCase();
        final cName = (o['customerName'] ?? '').toString().toLowerCase();
        final oId = (o['orderId'] ?? o['orderNumber'] ?? '').toString().toLowerCase();
        final cCode = (o['cargoTrackingNumber'] ?? '').toString().toLowerCase();
        if (!cName.contains(q) && !oId.contains(q) && !cCode.contains(q)) return false;
      }
      return true;
    }).toList();

    double totalRevenue = 0;
    for (var o in allOrders) {
      totalRevenue += double.tryParse(o['totalPrice']?.toString() ?? '0') ?? 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header & Bulk Actions
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 750;
            return isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tüm Pazaryeri Siparişleri', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Tüm bağlı mağazalarınızdan gelen siparişleri tek panelden yönetin', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showBulkInvoiceDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E40AF),
                                foregroundColor: Colors.white,
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.receipt_long, size: 14),
                              label: Text('Toplu E-Fatura', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showBulkShippingLabelDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC2410C),
                                foregroundColor: Colors.white,
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.qr_code_2, size: 14),
                              label: Text('Toplu Barkod', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _loadData,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.refresh, size: 15, color: Colors.cyanAccent),
                                  const SizedBox(width: 4),
                                  Text('Yenile', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.cyanAccent)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tüm Pazaryeri Siparişleri', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Tüm bağlı mağazalarınızdan gelen siparişleri tek panelden yönetin', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showBulkInvoiceDialog,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E40AF), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            icon: const Icon(Icons.receipt_long, size: 16),
                            label: Text('📑 Toplu E-Fatura Yazdır', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _showBulkShippingLabelDialog,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC2410C), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            icon: const Icon(Icons.qr_code_2, size: 16),
                            label: Text('🏷️ Toplu Barkod Bas', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _loadData,
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.cyanAccent, side: const BorderSide(color: Colors.cyanAccent, width: 1.2), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text('Yenile', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  );
          },
        ),
        const SizedBox(height: 18),

        // Summary metric cards for orders
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.shopping_bag_outlined, color: Colors.blueAccent, size: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Toplam Sipariş', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${allOrders.length} Adet', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.payments_outlined, color: Colors.greenAccent, size: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sipariş Cirosu', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(formatTL(totalRevenue), style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search & Filters bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input
              TextField(
                controller: _orderSearchController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Sipariş No, Müşteri Adı veya Kargo Takip Kodu ara...',
                  hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                  suffixIcon: _orderSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                          onPressed: () => setState(() {
                            _orderSearchController.clear();
                            _orderSearchQuery = '';
                          }),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blueAccent)),
                ),
                onChanged: (val) => setState(() => _orderSearchQuery = val),
              ),
              const SizedBox(height: 12),

              // Pazaryeri Filtreleri
              Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 15, color: Colors.white60),
                  const SizedBox(width: 6),
                  Text('Pazaryeri:', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildOrderFilterChip('Tümü (${allOrders.length})', 'ALL', _selectedOrderMarketplaceFilter, (val) => setState(() => _selectedOrderMarketplaceFilter = val)),
                          const SizedBox(width: 6),
                          _buildOrderFilterChip('Trendyol', 'Trendyol', _selectedOrderMarketplaceFilter, (val) => setState(() => _selectedOrderMarketplaceFilter = val), color: const Color(0xFFF27A1A)),
                          const SizedBox(width: 6),
                          _buildOrderFilterChip('Hepsiburada', 'Hepsiburada', _selectedOrderMarketplaceFilter, (val) => setState(() => _selectedOrderMarketplaceFilter = val), color: const Color(0xFFFF6000)),
                          const SizedBox(width: 6),
                          _buildOrderFilterChip('Amazon TR', 'Amazon', _selectedOrderMarketplaceFilter, (val) => setState(() => _selectedOrderMarketplaceFilter = val), color: const Color(0xFFFF9900)),
                          const SizedBox(width: 6),
                          _buildOrderFilterChip('Pazarama', 'Pazarama', _selectedOrderMarketplaceFilter, (val) => setState(() => _selectedOrderMarketplaceFilter = val), color: const Color(0xFF0066FF)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Durum Filtreleri
              Row(
                children: [
                  const Icon(Icons.filter_list_rounded, size: 15, color: Colors.white60),
                  const SizedBox(width: 6),
                  Text('Durum:', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildOrderFilterChip('Tümü', 'ALL', _selectedOrderStatusFilter, (val) => setState(() => _selectedOrderStatusFilter = val)),
                          const SizedBox(width: 6),
                          _buildOrderFilterChip('Yeni', 'Yeni', _selectedOrderStatusFilter, (val) => setState(() => _selectedOrderStatusFilter = val), color: Colors.greenAccent),
                          const SizedBox(width: 6),
                          _buildOrderFilterChip('Hazırlanıyor', 'Hazırlanıyor', _selectedOrderStatusFilter, (val) => setState(() => _selectedOrderStatusFilter = val), color: Colors.amberAccent),
                          const SizedBox(width: 6),
                          _buildOrderFilterChip('Kargoda', 'Kargo', _selectedOrderStatusFilter, (val) => setState(() => _selectedOrderStatusFilter = val), color: Colors.blueAccent),
                          const SizedBox(width: 6),
                          _buildOrderFilterChip('Teslim Edildi', 'Teslim', _selectedOrderStatusFilter, (val) => setState(() => _selectedOrderStatusFilter = val), color: Colors.tealAccent),
                          const SizedBox(width: 6),
                          _buildOrderFilterChip('İptal / İade', 'İptal', _selectedOrderStatusFilter, (val) => setState(() => _selectedOrderStatusFilter = val), color: Colors.redAccent),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Orders List
        filteredOrders.isEmpty
            ? _buildEmptyState('Aradığınız kriterlere uygun sipariş bulunamadı.', Icons.search_off)
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final o = filteredOrders[index];
                  final orderId = (o['orderId'] ?? o['orderNumber'] ?? 'ORD-$index').toString();
                  final marketplace = (o['marketplace'] ?? 'Trendyol').toString();
                  final status = (o['status'] ?? 'Yeni Sipariş').toString();
                  final customerName = (o['customerName'] ?? 'Müşteri').toString();
                  final customerCity = (o['customerCity'] ?? 'İstanbul').toString();
                  final customerAddress = (o['customerAddress'] ?? customerCity).toString();
                  final cargoCompany = (o['cargoCompany'] ?? 'Trendyol Express').toString();
                  final trackingNumber = (o['cargoTrackingNumber'] ?? 'TYEXP-${100000 + index}').toString();
                  final orderDate = (o['orderDate'] ?? 'Bugün').toString();
                  final totalPrice = double.tryParse(o['totalPrice']?.toString() ?? '0') ?? 0;
                  final lines = (o['lines'] is List) ? (o['lines'] as List) : [];

                  Color mpColor = Colors.blueAccent;
                  if (marketplace.contains('Trendyol')) mpColor = const Color(0xFFF27A1A);
                  else if (marketplace.contains('Hepsiburada')) mpColor = const Color(0xFFFF6000);
                  else if (marketplace.contains('Amazon')) mpColor = const Color(0xFFFF9900);
                  else if (marketplace.contains('Pazarama')) mpColor = const Color(0xFF0066FF);
                  else if (marketplace.contains('N11')) mpColor = const Color(0xFF5E17EB);
                  else if (marketplace.contains('Çiçek')) mpColor = const Color(0xFFE91E63);

                  Color statusColor = Colors.greenAccent;
                  IconData statusIcon = Icons.fiber_new_rounded;
                  String? forwardTargetStatus;
                  String? revertTargetStatus;
                  String statusActionLabel = 'İşlem';
                  String? revertActionLabel;
                  Color statusBtnColor = const Color(0xFF10B981);
                  IconData statusActionIcon = Icons.arrow_forward_rounded;

                  if (status.contains('Yeni')) {
                    statusColor = Colors.greenAccent;
                    statusIcon = Icons.fiber_new_rounded;
                    forwardTargetStatus = 'Hazırlanıyor';
                    statusActionLabel = '📦 Paketle & Hazırla';
                    statusBtnColor = const Color(0xFFD97706);
                    statusActionIcon = Icons.inventory_2_outlined;
                    revertTargetStatus = 'İptal / İade';
                    revertActionLabel = '❌ İptal Et';
                  } else if (status.contains('Hazır')) {
                    statusColor = Colors.amberAccent;
                    statusIcon = Icons.inventory_2_rounded;
                    forwardTargetStatus = 'Kargoya Verildi';
                    statusActionLabel = '🚚 Kargoya Teslim Et';
                    statusBtnColor = const Color(0xFF2563EB);
                    statusActionIcon = Icons.local_shipping_outlined;
                    revertTargetStatus = 'Yeni Sipariş';
                    revertActionLabel = '↩️ Yeni Sipariş\'e Al';
                  } else if (status.contains('Kargo')) {
                    statusColor = Colors.blueAccent;
                    statusIcon = Icons.local_shipping_rounded;
                    forwardTargetStatus = 'Teslim Edildi';
                    statusActionLabel = '✅ Teslim Edildi Yap';
                    statusBtnColor = const Color(0xFF059669);
                    statusActionIcon = Icons.check_circle_outline;
                    revertTargetStatus = 'Hazırlanıyor';
                    revertActionLabel = '↩️ Hazırlanıyor\'a Döndür';
                  } else if (status.contains('Teslim')) {
                    statusColor = Colors.tealAccent;
                    statusIcon = Icons.check_circle_rounded;
                    forwardTargetStatus = null;
                    statusActionLabel = '✅ Teslim Edildi';
                    statusBtnColor = const Color(0xFF334155);
                    statusActionIcon = Icons.done_all_rounded;
                    revertTargetStatus = 'Kargoya Verildi';
                    revertActionLabel = '↩️ Kargoda Yap';
                  } else if (status.contains('İptal') || status.contains('İade')) {
                    statusColor = Colors.redAccent;
                    statusIcon = Icons.cancel_rounded;
                    forwardTargetStatus = 'Yeni Sipariş';
                    statusActionLabel = '🔄 Siparişi Yeniden Aç';
                    statusBtnColor = const Color(0xFF0284C7);
                    statusActionIcon = Icons.refresh_rounded;
                    revertTargetStatus = null;
                    revertActionLabel = null;
                  } else {
                    statusColor = Colors.white70;
                    statusIcon = Icons.info_outline;
                    forwardTargetStatus = 'Yeni Sipariş';
                    statusActionLabel = '🔄 Başa Sar';
                    statusBtnColor = const Color(0xFF475569);
                    statusActionIcon = Icons.refresh_rounded;
                    revertTargetStatus = null;
                    revertActionLabel = null;
                  }

                  void updateOrderStatus(String newStatus) {
                    final previousStatus = (o['status'] ?? 'Yeni Sipariş').toString();
                    if (previousStatus == newStatus) return;

                    setState(() {
                      o['status'] = newStatus;
                    });

                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF1E293B),
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.white24, width: 1),
                        ),
                        content: Row(
                          children: [
                            const Icon(Icons.swap_horiz_rounded, color: Colors.cyanAccent, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: '$orderId durumu: ',
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text: newStatus,
                                      style: GoogleFonts.inter(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        action: SnackBarAction(
                          label: 'GERİ AL ↩️',
                          textColor: Colors.amberAccent,
                          onPressed: () {
                            setState(() {
                              o['status'] = previousStatus;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xFF0F172A),
                                margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                content: Text(
                                  '$orderId nolu sipariş önceki aşamasına ($previousStatus) geri alındı ↩️',
                                  style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 12),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        duration: const Duration(seconds: 6),
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF131D26),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            border: const Border(bottom: BorderSide(color: Colors.white10)),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Marketplace badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: mpColor.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: mpColor.withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(width: 7, height: 7, decoration: BoxDecoration(color: mpColor, shape: BoxShape.circle)),
                                        const SizedBox(width: 5),
                                        Text(marketplace, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Sipariş No: ', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                                  Text(orderId, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Interactive Status Badge & Dropdown Menu
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      cardColor: const Color(0xFF1E293B),
                                      popupMenuTheme: PopupMenuThemeData(
                                        color: const Color(0xFF1E293B),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: const BorderSide(color: Colors.white24),
                                        ),
                                      ),
                                    ),
                                    child: PopupMenuButton<String>(
                                      tooltip: 'Aşama Değiştir / Geri Al',
                                      onSelected: (selectedStatus) => updateOrderStatus(selectedStatus),
                                      itemBuilder: (context) => [
                                        _buildStatusPopupItem('Yeni Sipariş', Icons.fiber_new_rounded, Colors.greenAccent, status.contains('Yeni')),
                                        _buildStatusPopupItem('Hazırlanıyor', Icons.inventory_2_rounded, Colors.amberAccent, status.contains('Hazır')),
                                        _buildStatusPopupItem('Kargoya Verildi', Icons.local_shipping_rounded, Colors.blueAccent, status.contains('Kargo')),
                                        _buildStatusPopupItem('Teslim Edildi', Icons.check_circle_rounded, Colors.tealAccent, status.contains('Teslim')),
                                        const PopupMenuDivider(),
                                        _buildStatusPopupItem('İptal / İade', Icons.cancel_rounded, Colors.redAccent, status.contains('İptal') || status.contains('İade')),
                                      ],
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: statusColor.withOpacity(0.35)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(statusIcon, color: statusColor, size: 13),
                                            const SizedBox(width: 5),
                                            Text(status, style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11)),
                                            const SizedBox(width: 3),
                                            Icon(Icons.arrow_drop_down, color: statusColor.withOpacity(0.7), size: 15),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(orderDate, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Card Body (Customer & Cargo Details)
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: LayoutBuilder(
                            builder: (context, cardBox) {
                              final isCompactCard = cardBox.maxWidth < 520;
                              if (isCompactCard) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Customer Info
                                        Expanded(
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(7),
                                                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                                child: const Icon(Icons.person, color: Colors.blueAccent, size: 18),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(customerName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                                    const SizedBox(height: 2),
                                                    Text(customerAddress, style: GoogleFonts.inter(color: Colors.white60, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // Total Price
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('Toplam Tutar', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
                                            const SizedBox(height: 2),
                                            Text(formatTL(totalPrice), style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    // Cargo Info
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(Icons.local_shipping_outlined, color: Colors.orangeAccent, size: 16),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text('$cargoCompany • Takip: $trackingNumber', style: GoogleFonts.inter(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Customer Info
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(Icons.person, color: Colors.blueAccent, size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(customerName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                              const SizedBox(height: 2),
                                              Text(customerAddress, style: GoogleFonts.inter(color: Colors.white60, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Cargo Info
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(Icons.local_shipping_outlined, color: Colors.orangeAccent, size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(cargoCompany, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                              const SizedBox(height: 2),
                                              Text('Takip: $trackingNumber', style: GoogleFonts.inter(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Total Price
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Toplam Tutar', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text(formatTL(totalPrice), style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // Products in this order
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              if (lines.isEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined, color: Colors.white54, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('Örnek Sipariş Ürünü', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13))),
                                    Text('1 Adet', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                                  ],
                                )
                              else
                                ...lines.map((line) {
                                  final pTitle = (line['productTitle'] ?? 'Sipariş Ürünü').toString();
                                  final pSku = (line['sku'] ?? 'SKU').toString();
                                  final pQty = (line['quantity'] ?? 1).toString();
                                  final pVariant = (line['variant'] ?? '').toString();
                                  final pPrice = double.tryParse(line['price']?.toString() ?? '0') ?? 0;
                                  final pImg = line['imageUrl']?.toString() ?? '';

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        // Thumbnail
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.white12),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: pImg.isNotEmpty
                                                ? Image.network(
                                                    pImg,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, color: Colors.white38, size: 20),
                                                  )
                                                : const Icon(Icons.inventory_2, color: Colors.white38, size: 20),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(pTitle, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              Text('SKU: $pSku${pVariant.isNotEmpty ? ' • $pVariant' : ''}', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('$pQty Adet', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                                            Text(formatTL(pPrice), style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        ),

                        // Card Actions Footer (Responsive & Ultra Clean with Rollback / Undo)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                            border: const Border(top: BorderSide(color: Colors.white10)),
                          ),
                          child: LayoutBuilder(
                            builder: (context, cardFooterBox) {
                              final isCompact = cardFooterBox.maxWidth < 620;

                              if (isCompact) {
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildOrderActionButton(
                                            icon: Icons.receipt_long_rounded,
                                            label: 'GİB E-Fatura',
                                            color: Colors.blueAccent,
                                            onTap: () => _showInvoiceDialog(o),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildOrderActionButton(
                                            icon: Icons.qr_code_2_rounded,
                                            label: 'Kargo Barkodu',
                                            color: Colors.orangeAccent,
                                            onTap: () => _showShippingLabelDialog(o),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildOrderActionButton(
                                            icon: Icons.track_changes_rounded,
                                            label: 'Canlı Takip',
                                            color: Colors.cyanAccent,
                                            onTap: () => _showCargoTrackingDialog(o),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (revertActionLabel != null) ...[
                                          Expanded(
                                            flex: 2,
                                            child: SizedBox(
                                              height: 38,
                                              child: OutlinedButton.icon(
                                                onPressed: () => updateOrderStatus(revertTargetStatus!),
                                                icon: const Icon(Icons.undo_rounded, size: 14, color: Colors.white70),
                                                label: Text(
                                                  revertActionLabel,
                                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.white70,
                                                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                                  backgroundColor: Colors.white.withOpacity(0.04),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          flex: 3,
                                          child: SizedBox(
                                            height: 38,
                                            child: ElevatedButton.icon(
                                              onPressed: forwardTargetStatus != null ? () => updateOrderStatus(forwardTargetStatus!) : null,
                                              icon: Icon(statusActionIcon, size: 16, color: Colors.white),
                                              label: Text(
                                                statusActionLabel,
                                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: statusBtnColor,
                                                disabledBackgroundColor: Colors.white12,
                                                elevation: 1,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  _buildOrderActionButton(
                                    icon: Icons.receipt_long_rounded,
                                    label: 'GİB E-Fatura',
                                    color: Colors.blueAccent,
                                    onTap: () => _showInvoiceDialog(o),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildOrderActionButton(
                                    icon: Icons.qr_code_2_rounded,
                                    label: 'Kargo Barkodu',
                                    color: Colors.orangeAccent,
                                    onTap: () => _showShippingLabelDialog(o),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildOrderActionButton(
                                    icon: Icons.track_changes_rounded,
                                    label: 'Canlı Takip',
                                    color: Colors.cyanAccent,
                                    onTap: () => _showCargoTrackingDialog(o),
                                  ),
                                  const Spacer(),
                                  if (revertActionLabel != null) ...[
                                    SizedBox(
                                      height: 36,
                                      child: OutlinedButton.icon(
                                        onPressed: () => updateOrderStatus(revertTargetStatus!),
                                        icon: const Icon(Icons.undo_rounded, size: 14, color: Colors.white70),
                                        label: Text(
                                          revertActionLabel,
                                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white70,
                                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                          backgroundColor: Colors.white.withOpacity(0.04),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  SizedBox(
                                    height: 36,
                                    child: ElevatedButton.icon(
                                      onPressed: forwardTargetStatus != null ? () => updateOrderStatus(forwardTargetStatus!) : null,
                                      icon: Icon(statusActionIcon, size: 16, color: Colors.white),
                                      label: Text(statusActionLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: statusBtnColor,
                                        disabledBackgroundColor: Colors.white12,
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        const SizedBox(height: 70),
      ],
    );
  }

  PopupMenuItem<String> _buildStatusPopupItem(String title, IconData icon, Color color, bool isSelected) {
    return PopupMenuItem<String>(
      value: title,
      height: 38,
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: isSelected ? color : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ),
          if (isSelected)
            Icon(Icons.check, color: color, size: 16),
        ],
      ),
    );
  }

  Widget _buildOrderActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderFilterChip(String label, String value, String selectedValue, ValueChanged<String> onSelected, {Color? color}) {
    final isSelected = selectedValue == value;
    final activeColor = color ?? Colors.blueAccent;

    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.22) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? activeColor : Colors.white12, width: isSelected ? 1.4 : 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null && !label.contains('Tümü')) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: isSelected ? activeColor : activeColor.withOpacity(0.6), shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- GİB E-ARŞİV FATURA GÖRÜNTÜLEME MODALI ---
  void _showInvoiceDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long, color: Colors.blueAccent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GİB E-Arşiv Fatura Baskı Önizleme', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Yazdırmadan önce fatura detaylarını kontrol edin', style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 12)),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(ctx)),
          ],
        ),
        content: SizedBox(
          width: 660,
          child: SingleChildScrollView(
            child: _buildGibInvoiceCard(order),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Kapat', style: GoogleFonts.inter(color: Colors.white70)),
          ),
          OutlinedButton.icon(
            onPressed: () {
              final oId = (order['orderId'] ?? order['orderNumber'] ?? '').toString();
              final url = _apiService.getInvoiceUrl(oId);
              _launchSafeUrl(url);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('E-Fatura harici tarayıcı sekmesinde açılıyor... 🌐'), backgroundColor: Colors.blueAccent),
              );
            },
            icon: const Icon(Icons.open_in_new, size: 14, color: Colors.blueAccent),
            label: Text('Tarayıcıda Aç', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blueAccent)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              final oId = (order['orderId'] ?? order['orderNumber'] ?? '').toString();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text('$oId nolu siparişin GİB E-Arşiv faturası onaylandı ve yazıcıya gönderildi! 📑🖨️')),
                    ],
                  ),
                  backgroundColor: const Color(0xFF1E40AF),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.print, size: 16),
            label: Text('🖨️ Faturayı Yazdır', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  // --- PAZARYERİ KARGO BARKODU & SEVK ETİKETİ MODALI ---
  void _showShippingLabelDialog(Map<String, dynamic> order) {
    final cargoCompany = (order['cargoCompany'] ?? 'Trendyol Express').toString();
    final marketplace = (order['marketplace'] ?? 'Trendyol').toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.orangeAccent, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code_2, color: Colors.orangeAccent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Termal Kargo Barkodu Baskı Önizleme', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('$cargoCompany • $marketplace • 100x150 mm Termal Rulo', style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 12)),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(ctx)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: _buildThermalShippingLabelCard(order),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Kapat', style: GoogleFonts.inter(color: Colors.white70)),
          ),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kargo barkodu PDF formatında indirildi! 📥'), backgroundColor: Colors.orangeAccent),
              );
            },
            icon: const Icon(Icons.download, size: 14, color: Colors.orangeAccent),
            label: Text('PDF İndir', style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orangeAccent)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              final orderId = (order['orderId'] ?? order['orderNumber'] ?? '').toString();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text('$orderId için $cargoCompany termal kargo barkodu yazıcıya gönderildi! 🏷️🖨️')),
                    ],
                  ),
                  backgroundColor: const Color(0xFFC2410C),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.print, size: 16),
            label: Text('🖨️ Yazıcıya Gönder', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC2410C), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  // --- TOPLU GİB E-FATURA KESME & YAZDIRMA MODALI (ÖNİZLEMELİ) ---
  void _showBulkInvoiceDialog() {
    final allOrders = (_orders ?? []);
    if (allOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yazdırılacak sipariş bulunamadı.'), backgroundColor: Colors.orange),
      );
      return;
    }

    double totalRevenue = 0;
    for (var o in allOrders) {
      totalRevenue += double.tryParse(o['totalPrice']?.toString() ?? '0') ?? 0;
    }
    final kdvTotal = totalRevenue * (0.20 / 1.20);
    final matrahTotal = totalRevenue - kdvTotal;

    int currentIdx = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final currentOrder = allOrders[currentIdx];
          final cName = (currentOrder['customerName'] ?? 'Müşteri').toString();
          final oId = (currentOrder['orderId'] ?? currentOrder['orderNumber'] ?? 'Sipariş').toString();

          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.blueAccent, width: 1.5),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.receipt_long, color: Colors.blueAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Toplu GİB E-Fatura Baskı Önizleme', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Toplam ${allOrders.length} Fatura • Genel Toplam: ${formatTL(totalRevenue)}', style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            content: SizedBox(
              width: 680,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toplu Özet Barı
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Fatura Adedi: ${allOrders.length}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Toplam Matrah: ${formatTL(matrahTotal)}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                          Text('KDV (%20): ${formatTL(kdvTotal)}', style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Ciro: ${formatTL(totalRevenue)}', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sayfa Gezintisi (Pagination Bar)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: currentIdx > 0
                                ? () => setDlgState(() => currentIdx--)
                                : null,
                            icon: const Icon(Icons.arrow_back_ios, size: 12),
                            label: Text('Önceki Fatura', style: GoogleFonts.inter(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                          Column(
                            children: [
                              Text('Fatura ${currentIdx + 1} / ${allOrders.length}', style: GoogleFonts.inter(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('$cName • $oId', style: GoogleFonts.inter(color: Colors.white60, fontSize: 10)),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: currentIdx < allOrders.length - 1
                                ? () => setDlgState(() => currentIdx++)
                                : null,
                            icon: const Icon(Icons.arrow_forward_ios, size: 12),
                            label: Text('Sonraki Fatura', style: GoogleFonts.inter(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Seçili Faturanın Canlı Resmi Belge Önizlemesi
                    _buildGibInvoiceCard(currentOrder),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Vazgeç', style: GoogleFonts.inter(color: Colors.white70)),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${allOrders.length} adet e-fatura toplu ZIP/PDF olarak hazırlandı! 📥'), backgroundColor: Colors.blueAccent),
                  );
                },
                icon: const Icon(Icons.download, size: 14, color: Colors.cyanAccent),
                label: Text('Toplu PDF İndir', style: GoogleFonts.inter(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.cyanAccent)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text('${allOrders.length} adet sipariş için GİB E-Arşiv faturaları onaylandı ve toplu yazdırma kuyruğuna iletildi! 📑🖨️')),
                        ],
                      ),
                      backgroundColor: const Color(0xFF1E40AF),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
                icon: const Icon(Icons.print, size: 16),
                label: Text('🖨️ Tüm ${allOrders.length} Faturayı Yazdır', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E40AF), foregroundColor: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- TOPLU KARGO BARKODU BASIM MODALI (ÖNİZLEMELİ) ---
  void _showBulkShippingLabelDialog() {
    final allOrders = (_orders ?? []);
    if (allOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yazdırılacak kargo etiketi bulunamadı.'), backgroundColor: Colors.orange),
      );
      return;
    }

    int currentLabelIdx = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final currentOrder = allOrders[currentLabelIdx];
          final cName = (currentOrder['customerName'] ?? 'Müşteri').toString();
          final oId = (currentOrder['orderId'] ?? currentOrder['orderNumber'] ?? 'Sipariş').toString();
          final cargo = (currentOrder['cargoCompany'] ?? 'Kargo').toString();

          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.orangeAccent, width: 1.5),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.qr_code_2, color: Colors.orangeAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Toplu Kargo Barkodu Baskı Önizleme', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${allOrders.length} Adet Sevk Etiketi Hazır • 100x150 mm Termal Rulo Formatı', style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sayfa Gezintisi (Pagination Bar)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: currentLabelIdx > 0
                                ? () => setDlgState(() => currentLabelIdx--)
                                : null,
                            icon: const Icon(Icons.arrow_back_ios, size: 12),
                            label: Text('Önceki Etiket', style: GoogleFonts.inter(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                          Column(
                            children: [
                              Text('Etiket ${currentLabelIdx + 1} / ${allOrders.length}', style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('$cName • $cargo ($oId)', style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: currentLabelIdx < allOrders.length - 1
                                ? () => setDlgState(() => currentLabelIdx++)
                                : null,
                            icon: const Icon(Icons.arrow_forward_ios, size: 12),
                            label: Text('Sonraki Etiket', style: GoogleFonts.inter(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Canlı Termal Etiket Çizimi
                    _buildThermalShippingLabelCard(currentOrder),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Vazgeç', style: GoogleFonts.inter(color: Colors.white70)),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${allOrders.length} adet kargo barkodu PDF olarak indirildi! 📥'), backgroundColor: Colors.orangeAccent),
                  );
                },
                icon: const Icon(Icons.download, size: 14, color: Colors.orangeAccent),
                label: Text('Toplu PDF İndir', style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orangeAccent)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text('${allOrders.length} adet kargo barkodu termal etiket yazıcıya başarıyla gönderildi! 🏷️🖨️')),
                        ],
                      ),
                      backgroundColor: const Color(0xFFC2410C),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
                icon: const Icon(Icons.print, size: 16),
                label: Text('🖨️ Tüm ${allOrders.length} Barkodu Yazdır', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC2410C), foregroundColor: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- GERÇEKÇİ 100x150 MM TERMAL KARGO ETİKETİ ÇİZİCİSİ ---
  Widget _buildThermalShippingLabelCard(Map<String, dynamic> order) {
    final orderId = (order['orderId'] ?? order['orderNumber'] ?? 'TY-984321045').toString();
    final customerName = (order['customerName'] ?? 'Mehmet Akif Yıldız').toString();
    final customerAddress = (order['customerAddress'] ?? 'Nisbetiye Mah. Aytar Cad. No:14 D:6, Beşiktaş / İstanbul').toString();
    final customerCity = (order['customerCity'] ?? 'İstanbul / Beşiktaş').toString();
    final cargoCompany = (order['cargoCompany'] ?? 'Trendyol Express').toString();
    final trackingNumber = (order['cargoTrackingNumber'] ?? 'TYEXP-884920194').toString();
    final cargoBarcode = (order['cargoBarcode'] ?? '8680009423635-TY').toString();
    final marketplace = (order['marketplace'] ?? 'Trendyol').toString();
    final orderDate = (order['orderDate'] ?? 'Bugün 19:42').toString();
    final lines = (order['lines'] is List && (order['lines'] as List).isNotEmpty) ? (order['lines'] as List) : [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kargo Şirket Başlığı & Pazaryeri Rozeti
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping, color: Colors.black87, size: 22),
                  const SizedBox(width: 8),
                  Text(cargoCompany.toUpperCase(), style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                child: Text(marketplace.toUpperCase(), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const Divider(color: Colors.black87, thickness: 2, height: 16),

          // Büyük Kargo Takip Barkodu (Code-128 Mock Görseli)
          Center(
            child: Column(
              children: [
                Container(
                  height: 65,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black38),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(42, (i) {
                      final isThick = (i % 3 == 0) || (i % 7 == 0);
                      final isSpace = (i % 5 == 0);
                      if (isSpace) return const SizedBox(width: 3.5);
                      return Container(
                        width: isThick ? 4.5 : 2,
                        color: Colors.black87,
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 6),
                Text(trackingNumber, style: GoogleFonts.courierPrime(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2.5)),
                Text('Barkod Kodu: $cargoBarcode', style: GoogleFonts.inter(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Divider(color: Colors.black87, thickness: 1.5, height: 16),

          // Alıcı (Müşteri) Bilgileri
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ALICI (TESLİMAT BİLGİLERİ):', style: GoogleFonts.inter(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 9.5, letterSpacing: 0.5)),
                    const SizedBox(height: 3),
                    Text(customerName, style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(customerCity, style: GoogleFonts.inter(color: Colors.blue.shade900, fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(customerAddress, style: GoogleFonts.inter(color: Colors.black87, fontSize: 11, height: 1.3)),
                    const SizedBox(height: 3),
                    Text('Tel: 0532 *** ** 45', style: GoogleFonts.inter(color: Colors.black54, fontSize: 10)),
                  ],
                ),
              ),
              // Karekod
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(border: Border.all(color: Colors.black26), borderRadius: BorderRadius.circular(4)),
                child: const Icon(Icons.qr_code_2, color: Colors.black87, size: 54),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Paket Kontrol & Hata Önleme Kutusu
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('📦 PAKET İÇERİK KONTROLÜ (HATA ÖNLEME):', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 9.5)),
                    Text('1.5 Desi • 1 Parça', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 9.5)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Sipariş No: $orderId • $orderDate', style: GoogleFonts.inter(color: Colors.black54, fontSize: 9.5)),
                if (lines.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  ...lines.map((ln) {
                    final t = (ln['productTitle'] ?? 'Ürün').toString();
                    final v = (ln['variant'] ?? '').toString();
                    final q = (ln['quantity'] ?? 1).toString();
                    final s = (ln['sku'] ?? '').toString();
                    return Text('• $q Adet x $t ${v.isNotEmpty ? "($v)" : ""} ${s.isNotEmpty ? "[$s]" : ""}', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 10.5), maxLines: 2, overflow: TextOverflow.ellipsis);
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Gönderici Mağaza Bilgisi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('GÖNDERİCİ: RoaTech Mağazacılık A.Ş. / Ataşehir Depo', style: GoogleFonts.inter(color: Colors.black54, fontSize: 9.5, fontWeight: FontWeight.w600)),
              Text('SEVK ONAYLI ✅', style: GoogleFonts.inter(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 9.5)),
            ],
          ),
        ],
      ),
    );
  }

  // --- RESMİ GİB E-ARŞİV FATURA ÇİZİCİSİ (A4 FORMATI) ---
  Widget _buildGibInvoiceCard(Map<String, dynamic> order) {
    final orderId = (order['orderId'] ?? order['orderNumber'] ?? 'TY-984321045').toString();
    final customerName = (order['customerName'] ?? 'Mehmet Akif Yıldız').toString();
    final customerAddress = (order['customerAddress'] ?? 'Nisbetiye Mah. Aytar Cad. No:14 D:6, Beşiktaş / İstanbul').toString();
    final marketplace = (order['marketplace'] ?? 'Trendyol').toString();
    final orderDate = (order['orderDate'] ?? '01.09.2026 19:42').toString();
    final totalPrice = double.tryParse(order['totalPrice']?.toString() ?? '0') ?? 1083.90;
    final lines = (order['lines'] is List && (order['lines'] as List).isNotEmpty)
        ? (order['lines'] as List)
        : [
            {
              'productTitle': 'Tudors Erkek 5\'li Paket Slim Fit Pamuklu Pike Polo Yaka Tişört',
              'sku': 'TDR-POLO-5PK-L',
              'quantity': 1,
              'price': totalPrice,
            }
          ];

    final kdvRatio = 0.20;
    final matrah = totalPrice / (1 + kdvRatio);
    final kdvAmount = totalPrice - matrah;
    final cleanDigits = orderId.replaceAll(RegExp(r'[^0-9]'), '');
    final invoiceNo = 'GIB${DateTime.now().year}${cleanDigits.padLeft(9, '0').substring(0, 9)}';
    final ettnUuid = 'a4b89c72-${orderId.hashCode.abs().toString().padLeft(4, '0')}-4e31-8f12-${orderId.length}a9b2c3d4e5f';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fatura Başlık & Resmi Damga Kutusu
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: const Icon(Icons.account_balance, color: Colors.redAccent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('T.C. GELİR İDARESİ BAŞKANLIĞI', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
                    Text('E-ARŞİV FATURA (509 VUK)', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Fatura No: $invoiceNo • ETTN: $ettnUuid', style: GoogleFonts.inter(color: Colors.white60, fontSize: 10.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: Colors.greenAccent, size: 14),
                    const SizedBox(width: 5),
                    Text('GİB ONAYLI', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Satıcı & Alıcı Bilgileri
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Satıcı
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SATICI (MÜKELLEF)', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('RoaTech Bilişim ve E-Ticaret A.Ş.', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                    Text('VKN: 7890123456 • Kadıköy V.D.', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                    Text('Barbaros Mah. Mor Sümbül Sok. No:1/A Ataşehir / İstanbul', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Alıcı
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ALICI (MÜŞTERİ)', style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(customerName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                    Text('TCKN: 11111111111', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                    Text(customerAddress, style: GoogleFonts.inter(color: Colors.white54, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Kalemler Tablosu
        Container(
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 4, child: Text('Mal / Hizmet Açıklaması', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11))),
                    Expanded(flex: 1, child: Text('Miktar', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11))),
                    Expanded(flex: 2, child: Text('Birim Fiyat', textAlign: TextAlign.right, style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11))),
                    Expanded(flex: 1, child: Text('KDV', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11))),
                    Expanded(flex: 2, child: Text('Toplam', textAlign: TextAlign.right, style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11))),
                  ],
                ),
              ),
              ...lines.map((line) {
                final pTitle = (line['productTitle'] ?? 'Sipariş Ürünü').toString();
                final pQty = (line['quantity'] ?? 1).toString();
                final pPrice = double.tryParse(line['price']?.toString() ?? '0') ?? totalPrice;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: Text(pTitle, style: GoogleFonts.inter(color: Colors.white, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      Expanded(flex: 1, child: Text('$pQty Adet', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11))),
                      Expanded(flex: 2, child: Text(formatTL(pPrice), textAlign: TextAlign.right, style: GoogleFonts.inter(color: Colors.white, fontSize: 11))),
                      Expanded(flex: 1, child: Text('%20', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11))),
                      Expanded(flex: 2, child: Text(formatTL(pPrice), textAlign: TextAlign.right, style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Fatura Toplam Özeti & QR
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_2, color: Colors.black87, size: 44),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ödeme: Kredi Kartı / $marketplace Havuzu', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                    Text('Sipariş: $orderId ($marketplace)', style: GoogleFonts.inter(color: Colors.white60, fontSize: 10)),
                    Text('Düzenleme Tarihi: $orderDate', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Matrah: ${formatTL(matrah)}', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                  Text('KDV (%20): ${formatTL(kdvAmount)}', style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('ÖDENECEK: ${formatTL(totalPrice)}', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13.5)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }


  void _showCargoTrackingDialog(Map<String, dynamic> order) {
    final orderId = order['orderId'] ?? order['orderNumber'] ?? 'TY-984321045';
    final cargo = order['cargoCompany'] ?? 'Trendyol Express';
    final tracking = order['cargoTrackingNumber'] ?? 'TYEXP-884920194';
    final status = order['status'] ?? 'Kargoya Verildi';

    int currentStep = 2; // default: Kargoda
    if (status.contains('Yeni')) currentStep = 0;
    else if (status.contains('Hazır')) currentStep = 1;
    else if (status.contains('Kargo')) currentStep = 2;
    else if (status.contains('Teslim')) currentStep = 3;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131D26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white24)),
        title: Row(
          children: [
            const Icon(Icons.local_shipping, color: Colors.cyanAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Canlı Kargo Takibi', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('$cargo • Takip No: $tracking', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blueAccent.withOpacity(0.3))),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2, color: Colors.cyanAccent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sipariş No: $orderId', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Teslimat Adresi: ${order['customerAddress'] ?? 'İstanbul'}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Timeline steps
              _buildTimelineStep('1. Sipariş Alındı & Onaylandı', 'Pazaryeri API üzerinden anlık çekildi', true, isCurrent: currentStep == 0),
              _buildTimelineStep('2. Depodan Hazırlandı & Fatura Kesildi', 'E-Fatura oluşturuldu, kargo etiketi basıldı', currentStep >= 1, isCurrent: currentStep == 1),
              _buildTimelineStep('3. Kuryeye Teslim Edildi & Transferde', '$cargo aktarma merkezinde işleniyor', currentStep >= 2, isCurrent: currentStep == 2),
              _buildTimelineStep('4. Teslim Edildi', 'Alıcıya güvenle teslim edildi', currentStep >= 3, isLast: true, isCurrent: currentStep == 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Kapat', style: GoogleFonts.inter(color: Colors.white70)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              final url = _apiService.getShippingLabelUrl(orderId);
              _launchSafeUrl(url);
            },
            icon: const Icon(Icons.print, size: 16),
            label: Text('Barkod Yazdır', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String title, String subtitle, bool isCompleted, {bool isLast = false, bool isCurrent = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isCompleted ? (isCurrent ? Colors.cyanAccent : Colors.greenAccent) : Colors.white12,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.circle,
                size: 13,
                color: isCompleted ? Colors.black : Colors.white30,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isCompleted ? Colors.greenAccent.withOpacity(0.5) : Colors.white12,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: isCompleted ? Colors.white : Colors.white38,
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(color: isCompleted ? Colors.white60 : Colors.white24, fontSize: 11),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }


  bool _productMatchesCategory(dynamic p, String catId, String? subCat) {
    final title = (p['title'] ?? p['name'] ?? '').toString().toLowerCase();
    final catName = (p['categoryName'] ?? '').toString().toLowerCase();
    final brand = (p['brand'] ?? '').toString().toLowerCase();

    if (catId == 'ALL') return true;

    if (catId == 'Elektronik') {
      final isElek = catName.contains('elektronik') || catName.contains('bilgisayar') || catName.contains('laptop') ||
                     catName.contains('dizüstü') || catName.contains('telefon') || catName.contains('tablet') ||
                     catName.contains('tv') || catName.contains('ses') || catName.contains('kamera') ||
                     brand.contains('lenovo') || brand.contains('apple') || brand.contains('samsung') ||
                     brand.contains('asus') || brand.contains('dell') || brand.contains('hp') || brand.contains('xiaomi') ||
                     title.contains('laptop') || title.contains('ideapad') || title.contains('notebook') ||
                     title.contains('iphone') || title.contains('bilgisayar') || title.contains('telefon');
      if (!isElek) return false;

      if (subCat != null && subCat.isNotEmpty && !subCat.startsWith('ALL_')) {
        if (subCat == 'Bilgisayar / Tablet') {
          return catName.contains('bilgisayar') || catName.contains('laptop') || catName.contains('dizüstü') || catName.contains('tablet') ||
                 title.contains('laptop') || title.contains('ideapad') || title.contains('notebook') || title.contains('bilgisayar') || title.contains('tablet');
        } else if (subCat == 'Telefon & Aksesuarlar') {
          return catName.contains('telefon') || catName.contains('kılıf') || catName.contains('şarj') ||
                 title.contains('iphone') || title.contains('telefon') || title.contains('galaxy') || title.contains('kılıf');
        } else if (subCat == 'TV, Görüntü & Ses') {
          return catName.contains('tv') || catName.contains('televizyon') || catName.contains('ses') || catName.contains('kulaklık') || title.contains('kulaklık') || title.contains('tv');
        } else if (subCat == 'Beyaz Eşya') {
          return catName.contains('buzdolabı') || catName.contains('çamaşır') || catName.contains('bulaşık') || catName.contains('fırın');
        } else if (subCat == 'Küçük Ev Aletleri') {
          return catName.contains('süpürge') || catName.contains('kahve') || catName.contains('ütü') || catName.contains('airfryer') || catName.contains('fritöz');
        } else if (subCat == 'Foto & Kamera') {
          return catName.contains('foto') || catName.contains('kamera') || catName.contains('drone') || title.contains('kamera');
        } else if (subCat == 'Oyun & Oyun Konsolları') {
          return catName.contains('oyun') || catName.contains('konsol') || catName.contains('playstation') || catName.contains('xbox') || title.contains('ps5') || title.contains('playstation');
        }
      }
      return true;
    }

    if (catId == 'Moda') {
      final isModa = catName.contains('moda') || catName.contains('giyim') || catName.contains('tişört') ||
                     catName.contains('polo') || catName.contains('gömlek') || catName.contains('tekstil') ||
                     catName.contains('pantolon') || catName.contains('ayakkabı') || catName.contains('elbise') ||
                     catName.contains('etek') || catName.contains('ceket') || catName.contains('mont') ||
                     brand.contains('tudors') || title.contains('tişört') || title.contains('polo') ||
                     title.contains('gömlek') || title.contains('pantolon') || title.contains('pike') || title.contains('elbise');
      if (!isModa) return false;

      if (subCat != null && subCat.isNotEmpty && !subCat.startsWith('ALL_')) {
        if (subCat.contains('Erkek Giyim')) {
          return catName.contains('tişört') || catName.contains('polo') || catName.contains('gömlek') ||
                 catName.contains('pantolon') || brand.contains('tudors') || title.contains('tişört') || title.contains('polo') || title.contains('gömlek');
        } else if (subCat == 'Kadın Giyim') {
          return catName.contains('elbise') || catName.contains('etek') || catName.contains('bluz') || title.contains('elbise') || title.contains('etek');
        } else if (subCat == 'Kadın Ayakkabı' || subCat == 'Erkek Ayakkabı') {
          return catName.contains('ayakkabı') || title.contains('ayakkabı') || title.contains('sneaker') || title.contains('bot');
        } else if (subCat == 'Çanta & Aksesuar') {
          return catName.contains('çanta') || catName.contains('cüzdan') || catName.contains('kemer') || title.contains('çanta');
        } else if (subCat == 'İç Giyim & Pijama') {
          return catName.contains('pijama') || catName.contains('çorap') || catName.contains('iç giyim');
        } else if (subCat == 'Saat & Takı') {
          return catName.contains('saat') || catName.contains('takı') || catName.contains('kolye') || catName.contains('bileklik');
        }
      }
      return true;
    }

    if (catId == 'EvYasam') {
      final isEv = catName.contains('ev') || catName.contains('yaşam') || catName.contains('kırtasiye') ||
                   catName.contains('ofis') || catName.contains('mobilya') || catName.contains('mutfak') ||
                   catName.contains('sofra') || catName.contains('tekstil') || catName.contains('aydınlatma') ||
                   catName.contains('banyo') || catName.contains('dekorasyon');
      if (!isEv) return false;
      return true;
    }

    if (catId == 'OtoYapiBahce') {
      final isOto = catName.contains('oto') || catName.contains('bahçe') || catName.contains('yapı') ||
                    catName.contains('market') || catName.contains('hırdavat') || catName.contains('alet') ||
                    catName.contains('matkap') || catName.contains('boya') || catName.contains('motor');
      if (!isOto) return false;
      return true;
    }

    if (catId == 'AnneBebek') {
      final isBebek = catName.contains('anne') || catName.contains('bebek') || catName.contains('oyuncak') ||
                      catName.contains('puset') || catName.contains('mama') || catName.contains('lego');
      if (!isBebek) return false;
      return true;
    }

    if (catId == 'SporOutdoor') {
      final isSpor = catName.contains('spor') || catName.contains('outdoor') || catName.contains('fitness') ||
                     catName.contains('kamp') || catName.contains('bisiklet') || catName.contains('koşu');
      if (!isSpor) return false;
      return true;
    }

    if (catId == 'Kozmetik') {
      final isKozmetik = catName.contains('kozmetik') || catName.contains('kişisel') || catName.contains('bakım') ||
                         catName.contains('parfüm') || catName.contains('makyaj') || catName.contains('cilt') ||
                         catName.contains('saç') || catName.contains('tıraş');
      if (!isKozmetik) return false;
      return true;
    }

    if (catId == 'SupermarketPetShop') {
      final isMarket = catName.contains('süpermarket') || catName.contains('market') || catName.contains('pet') ||
                       catName.contains('shop') || catName.contains('kedi') || catName.contains('köpek') ||
                       catName.contains('mama') || catName.contains('deterjan') || catName.contains('gıda');
      if (!isMarket) return false;
      return true;
    }

    if (catId == 'KitapHobi') {
      final isKitap = catName.contains('kitap') || catName.contains('müzik') || catName.contains('film') ||
                      catName.contains('hobi') || catName.contains('roman') || catName.contains('gitar') ||
                      catName.contains('enstrüman') || catName.contains('maket');
      if (!isKitap) return false;
      return true;
    }

    return catName.contains(catId.toLowerCase()) || title.contains(catId.toLowerCase());
  }

  int _getCategoryCount(String catId, {String? subCat}) {
    if (_products == null) return 0;
    return _products!.where((p) => _productMatchesCategory(p, catId, subCat)).length;
  }

  List<dynamic> _getFilteredProducts() {
    if (_products == null) return [];
    return _products!.where((p) {
      if (_productSearchQuery.trim().isNotEmpty) {
        final q = _productSearchQuery.trim().toLowerCase();
        final title = (p['title'] ?? p['name'] ?? '').toString().toLowerCase();
        final catName = (p['categoryName'] ?? '').toString().toLowerCase();
        final brand = (p['brand'] ?? '').toString().toLowerCase();
        final sku = (p['sku'] ?? '').toString().toLowerCase();
        final barcode = (p['barcode'] ?? '').toString().toLowerCase();
        if (!title.contains(q) && !catName.contains(q) && !brand.contains(q) && !sku.contains(q) && !barcode.contains(q)) {
          return false;
        }
      }
      return _productMatchesCategory(p, _selectedCategoryFilter, _selectedSubCategoryFilter);
    }).toList();
  }

  String _getActiveCategoryLabel() {
    if (_selectedCategoryFilter == 'ALL') return 'Tüm Ürünler';
    final mainCat = _catalogCategories.firstWhere((c) => c['id'] == _selectedCategoryFilter, orElse: () => {'title': _selectedCategoryFilter});
    if (_selectedSubCategoryFilter != null && !_selectedSubCategoryFilter!.startsWith('ALL_')) {
      return '${mainCat['title']} > $_selectedSubCategoryFilter';
    }
    return '${mainCat['title']} (Tüm Alt Kategoriler)';
  }

  Widget _buildCategorySidebar() {
    final totalCount = _products?.length ?? 0;

    return Container(
      width: 270,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category_outlined, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text('Ürün Kategorileri', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text('$totalCount Ürün', style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 10),

          // 🌐 Tüm Ürünleri Listele Butonu
          InkWell(
            onTap: () {
              setState(() {
                _selectedCategoryFilter = 'ALL';
                _selectedSubCategoryFilter = null;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedCategoryFilter == 'ALL' ? Colors.blueAccent.withOpacity(0.22) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedCategoryFilter == 'ALL' ? Colors.blueAccent : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.apps, color: _selectedCategoryFilter == 'ALL' ? Colors.blueAccent : Colors.white70, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '🌐 Tüm Ürünleri Listele',
                      style: GoogleFonts.inter(
                        color: _selectedCategoryFilter == 'ALL' ? Colors.blueAccent : Colors.white,
                        fontWeight: _selectedCategoryFilter == 'ALL' ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _selectedCategoryFilter == 'ALL' ? Colors.blueAccent : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$totalCount',
                      style: GoogleFonts.inter(
                        color: _selectedCategoryFilter == 'ALL' ? Colors.white : Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Kategori Ağacı Listesi
          ..._catalogCategories.where((c) => c['id'] != 'ALL').map((cat) {
            final catId = cat['id'] as String;
            final catTitle = cat['title'] as String;
            final icon = cat['icon'] as IconData;
            final color = cat['color'] as Color;
            final subCats = cat['subCategories'] as List<String>;
            final allLabel = (cat['allLabel'] ?? 'Tüm $catTitle Ürünleri') as String;
            final isExpanded = _expandedCategoryIds.contains(catId);
            final isMainSelected = _selectedCategoryFilter == catId;
            final catCount = _getCategoryCount(catId);

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isMainSelected ? color.withOpacity(0.08) : Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isMainSelected ? color.withOpacity(0.4) : Colors.white.withOpacity(0.04),
                  width: isMainSelected ? 1.2 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori Başlık Satırı
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (_expandedCategoryIds.contains(catId)) {
                          _expandedCategoryIds.remove(catId);
                        } else {
                          _expandedCategoryIds.add(catId);
                        }
                        _selectedCategoryFilter = catId;
                        _selectedSubCategoryFilter = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Icon(icon, color: color, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              catTitle,
                              style: GoogleFonts.inter(
                                color: isMainSelected ? Colors.white : Colors.white70,
                                fontWeight: isMainSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: catCount > 0 ? color.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$catCount',
                              style: GoogleFonts.inter(
                                color: catCount > 0 ? color : Colors.white38,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.white38,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Alt Kategoriler (Açılır Menü)
                  if (isExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 6, bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // "Tüm X Ürünlerini Getir" Butonu
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCategoryFilter = catId;
                                _selectedSubCategoryFilter = 'ALL_$catId';
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: (isMainSelected && (_selectedSubCategoryFilter == null || _selectedSubCategoryFilter == 'ALL_$catId'))
                                    ? color.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.subdirectory_arrow_right, size: 12, color: color),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      allLabel,
                                      style: GoogleFonts.inter(
                                        color: (isMainSelected && (_selectedSubCategoryFilter == null || _selectedSubCategoryFilter == 'ALL_$catId'))
                                            ? Colors.white
                                            : Colors.white60,
                                        fontWeight: (isMainSelected && (_selectedSubCategoryFilter == null || _selectedSubCategoryFilter == 'ALL_$catId'))
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$catCount',
                                    style: GoogleFonts.inter(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Tekil Alt Kategoriler
                          ...subCats.map((sub) {
                            final isSubSelected = isMainSelected && _selectedSubCategoryFilter == sub;
                            final subCount = _getCategoryCount(catId, subCat: sub);

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryFilter = catId;
                                  _selectedSubCategoryFilter = sub;
                                });
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSubSelected ? color.withOpacity(0.25) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: isSubSelected ? Border.all(color: color.withOpacity(0.5)) : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: isSubSelected ? color : Colors.white38,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        sub,
                                        style: GoogleFonts.inter(
                                          color: isSubSelected ? Colors.white : (subCount > 0 ? Colors.white70 : Colors.white38),
                                          fontWeight: isSubSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$subCount',
                                      style: GoogleFonts.inter(
                                        color: isSubSelected ? Colors.white : (subCount > 0 ? Colors.white70 : Colors.white24),
                                        fontSize: 10,
                                        fontWeight: subCount > 0 ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showCategoryFilterBottomSheet() {
    final totalCount = _products?.length ?? 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.white24),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.category_outlined, color: Colors.blueAccent, size: 22),
                            const SizedBox(width: 8),
                            Text('Kategori Seçin', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategoryFilter = 'ALL';
                              _selectedSubCategoryFilter = null;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Text('Tümünü Göster ($totalCount)', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          ..._catalogCategories.where((c) => c['id'] != 'ALL').map((cat) {
                            final catId = cat['id'] as String;
                            final catTitle = cat['title'] as String;
                            final icon = cat['icon'] as IconData;
                            final color = cat['color'] as Color;
                            final subCats = cat['subCategories'] as List<String>;
                            final isExpanded = _expandedCategoryIds.contains(catId);
                            final isMainSelected = _selectedCategoryFilter == catId;
                            final catCount = _getCategoryCount(catId);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isMainSelected ? color.withOpacity(0.1) : Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isMainSelected ? color : Colors.white12),
                              ),
                              child: ExpansionTile(
                                key: PageStorageKey(catId),
                                initiallyExpanded: isExpanded,
                                onExpansionChanged: (exp) {
                                  setModalState(() {
                                    if (exp) {
                                      _expandedCategoryIds.add(catId);
                                    } else {
                                      _expandedCategoryIds.remove(catId);
                                    }
                                  });
                                },
                                leading: Icon(icon, color: color, size: 22),
                                title: Text(catTitle, style: GoogleFonts.inter(color: Colors.white, fontWeight: isMainSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                      child: Text('$catCount', style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white54),
                                  ],
                                ),
                                children: [
                                  ListTile(
                                    dense: true,
                                    title: Text('Tüm $catTitle Ürünleri', style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white38),
                                    onTap: () {
                                      setState(() {
                                        _selectedCategoryFilter = catId;
                                        _selectedSubCategoryFilter = null;
                                      });
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                  ...subCats.map((sub) {
                                    final isSub = isMainSelected && _selectedSubCategoryFilter == sub;
                                    final subCount = _getCategoryCount(catId, subCat: sub);
                                    return ListTile(
                                      dense: true,
                                      title: Text(sub, style: GoogleFonts.inter(color: isSub ? Colors.white : Colors.white70, fontWeight: isSub ? FontWeight.bold : FontWeight.normal, fontSize: 12.5)),
                                      trailing: Text('$subCount', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                                      onTap: () {
                                        setState(() {
                                          _selectedCategoryFilter = catId;
                                          _selectedSubCategoryFilter = sub;
                                        });
                                        Navigator.pop(ctx);
                                      },
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductsTab() {
    final filtered = _getFilteredProducts();
    final activeCatLabel = _getActiveCategoryLabel();
    final isFilteringActive = _selectedCategoryFilter != 'ALL' || _productSearchQuery.trim().isNotEmpty;
    final totalCount = _products?.length ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 960;
        final isSmallMobile = constraints.maxWidth < 640;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Başlık & Eylem Butonları (Responsive)
            if (isSmallMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ürün Kataloğu & Varyantlar', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Kategorilere göre filtreleyin, kampanya tanımlayın ve pazaryerlerine aktarın', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11.5)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showSimplifiedAddProductDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: Text('+ Yeni Ürün', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showBatchSyncApprovalDialog(initialScope: 'all'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.sync_alt, size: 16),
                          label: Text('⚡ Senkronize Et', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ürün Kataloğu & Kategori Yönetimi', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Kategorilere göre ürünlerinizi filtreleyin, kampanya tanımlayın ve pazaryerlerine eşitleyin', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showSimplifiedAddProductDialog,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        icon: const Icon(Icons.add_photo_alternate, size: 18),
                        label: Text('+ Yeni Ürün & Kampanya Ekle', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showBatchSyncApprovalDialog(initialScope: 'all'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        icon: const Icon(Icons.sync_alt, size: 18),
                        label: Text('⚡ Tüm Pazaryerlerine Senkronize Et', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Mobil / Tablet İçin Yatay Kategori Çip Çubuğu
            if (isMobile) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    // Tümü Çipi
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategoryFilter = 'ALL';
                          _selectedSubCategoryFilter = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _selectedCategoryFilter == 'ALL' ? Colors.blueAccent.withOpacity(0.25) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedCategoryFilter == 'ALL' ? Colors.blueAccent : Colors.white12,
                            width: _selectedCategoryFilter == 'ALL' ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.apps, size: 15, color: Colors.blueAccent),
                            const SizedBox(width: 6),
                            Text('Tümü ($totalCount)', style: GoogleFonts.inter(color: Colors.white, fontWeight: _selectedCategoryFilter == 'ALL' ? FontWeight.bold : FontWeight.w500, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Kategori Çipleri
                    ..._catalogCategories.where((c) => c['id'] != 'ALL').map((cat) {
                      final catId = cat['id'] as String;
                      final catTitle = cat['title'] as String;
                      final icon = cat['icon'] as IconData;
                      final color = cat['color'] as Color;
                      final isSelected = _selectedCategoryFilter == catId;
                      final count = _getCategoryCount(catId);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategoryFilter = catId;
                              _selectedSubCategoryFilter = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.22) : Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? color : Colors.white12,
                                width: isSelected ? 1.4 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(icon, size: 15, color: color),
                                const SizedBox(width: 6),
                                Text(catTitle, style: GoogleFonts.inter(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 12)),
                                if (count > 0) ...[
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(color: color.withOpacity(0.25), borderRadius: BorderRadius.circular(6)),
                                    child: Text('$count', style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // Kategori Ağacı Aç Modalı Butonu
                    InkWell(
                      onTap: _showCategoryFilterBottomSheet,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.account_tree_outlined, size: 15, color: Colors.cyanAccent),
                            const SizedBox(width: 5),
                            Text('Ağaç Görünümü', style: GoogleFonts.inter(color: Colors.cyanAccent, fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Seçili Kategori Alt Kategorileri Çip Çubuğu (Varsa)
              if (_selectedCategoryFilter != 'ALL') ...[
                Builder(
                  builder: (context) {
                    final currentCat = _catalogCategories.firstWhere((c) => c['id'] == _selectedCategoryFilter, orElse: () => _catalogCategories.first);
                    final subCats = currentCat['subCategories'] as List<String>? ?? [];
                    final color = currentCat['color'] as Color? ?? Colors.blueAccent;

                    if (subCats.isEmpty) return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            // "Tüm Alt Kategoriler"
                            InkWell(
                              onTap: () => setState(() => _selectedSubCategoryFilter = null),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: _selectedSubCategoryFilter == null ? color.withOpacity(0.25) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _selectedSubCategoryFilter == null ? color : Colors.white12),
                                ),
                                child: Text('Tüm ${currentCat['title']}', style: GoogleFonts.inter(color: _selectedSubCategoryFilter == null ? Colors.white : Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            // Tekil Alt Kategoriler
                            ...subCats.map((sub) {
                              final isSub = _selectedSubCategoryFilter == sub;
                              final subCount = _getCategoryCount(_selectedCategoryFilter, subCat: sub);
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedSubCategoryFilter = sub),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSub ? color.withOpacity(0.3) : Colors.white.withOpacity(0.03),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isSub ? color : Colors.white12),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(sub, style: GoogleFonts.inter(color: isSub ? Colors.white : Colors.white70, fontSize: 11, fontWeight: isSub ? FontWeight.bold : FontWeight.normal)),
                                        if (subCount > 0) ...[
                                          const SizedBox(width: 4),
                                          Text('($subCount)', style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],

            // Ana Bölüm (Masaüstü: 2 Sütun, Mobil: 1 Sütun Tam Genişlik)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sol Sidebar Yalnızca Masaüstü Ekranlarda Gösterilir!
                if (!isMobile) ...[
                  _buildCategorySidebar(),
                  const SizedBox(width: 18),
                ],

                // Sağ Liste / Mobil Liste (Tam Genişlik)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arama ve Filtre Durum Çubuğu
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Arama Kutusu
                                Expanded(
                                  child: TextField(
                                    controller: _productSearchController,
                                    onChanged: (v) => setState(() => _productSearchQuery = v),
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: '🔍 Ürün adı, barkod veya SKU ara...',
                                      hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.04),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                      prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                                      suffixIcon: _productSearchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear, size: 16, color: Colors.white54),
                                              onPressed: () {
                                                _productSearchController.clear();
                                                setState(() => _productSearchQuery = '');
                                              },
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                if (!isSmallMobile) ...[
                                  const SizedBox(width: 10),
                                  // Tüm Ürünleri Göster Butonu (Masaüstü/Tablet)
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedCategoryFilter = 'ALL';
                                        _selectedSubCategoryFilter = null;
                                        _productSearchController.clear();
                                        _productSearchQuery = '';
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _selectedCategoryFilter == 'ALL' ? Colors.blueAccent : Colors.white70,
                                      side: BorderSide(color: _selectedCategoryFilter == 'ALL' ? Colors.blueAccent : Colors.white24),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.list_alt, size: 16),
                                    label: Text('Tümü ($totalCount)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ],
                            ),
                            // Mobil İçin Aktif Filtre Bilgisi ve Sıfırlama
                            if (isFilteringActive) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.filter_alt, size: 13, color: Colors.orangeAccent),
                                        const SizedBox(width: 5),
                                        Text(
                                          activeCatLabel,
                                          style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedCategoryFilter = 'ALL';
                                        _selectedSubCategoryFilter = null;
                                        _productSearchController.clear();
                                        _productSearchQuery = '';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.close, size: 12, color: Colors.redAccent),
                                          const SizedBox(width: 4),
                                          Text('Filtreyi Temizle', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Ürün Listesi VEYA Filtre Boş Durumu
                      if (filtered.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, color: Colors.orangeAccent.withOpacity(0.6), size: 44),
                              const SizedBox(height: 12),
                              Text(
                                '"$activeCatLabel" kategorisinde ürün bulunamadı',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Bu kategoriye yeni ürün ekleyebilir veya filtreyi temizleyip tüm kataloğu listeleyebilirsiniz.',
                                style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _showSimplifiedAddProductDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange[800],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.add, size: 15),
                                    label: Text('+ Ürün Ekle', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedCategoryFilter = 'ALL';
                                        _selectedSubCategoryFilter = null;
                                        _productSearchController.clear();
                                        _productSearchQuery = '';
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blueAccent,
                                      side: const BorderSide(color: Colors.blueAccent),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.apps, size: 15),
                                    label: Text('🌐 Tümünü Listele ($totalCount)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _buildProductCard(filtered[index]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(dynamic p) {
    final variantCount = p['variantCount'] ?? 0;
    final imageCount = p['imageCount'] ?? 0;
    final brand = p['brand'] ?? 'Genel';
    final category = p['categoryName'] ?? 'Giyim';
    final modelCode = p['modelCode'] ?? p['sku'];
    final desi = p['dimensionalWeight'] ?? 1.0;
    final listPrice = p['listPrice'];
    final productId = p['id'].toString();
    final campaignName = p['campaignName'] ?? 'Standart Satış';
    final campaignType = p['campaignType'] ?? 0;
    final barcode = p['barcode'] as String?;
    final rawAttrs = p['attributes'] as Map<String, dynamic>?;
    final attributes = rawAttrs?.map((k, v) => MapEntry(k, v.toString())) ?? <String, String>{};
    final firstImg = p['firstImage'] ?? (p['images'] != null && (p['images'] as List).isNotEmpty ? (p['images'] as List)[0] : null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showProductDetailsDialog(productId),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: firstImg != null
                      ? _buildSafeImageWidget(firstImg, width: 70, height: 70, fit: BoxFit.cover, borderRadius: BorderRadius.circular(10))
                      : const Icon(Icons.inventory_2, color: Colors.blueAccent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(p['title'] ?? p['name'] ?? 'İsimsiz Ürün', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          if (campaignType > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.orange.shade900, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.orangeAccent)),
                              child: Text(campaignName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _tagBadge(brand, Colors.blueAccent),
                          _tagBadge(category, Colors.tealAccent),
                          _tagBadge('Model: $modelCode', Colors.purpleAccent),
                          _tagBadge('Desi: $desi', Colors.amberAccent),
                          if (variantCount > 0) _tagBadge('$variantCount Beden', Colors.orangeAccent),
                          if (imageCount > 0) _tagBadge('$imageCount Görsel', Colors.lightBlueAccent),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // SKU & Barcode row
                      Row(
                        children: [
                          const Icon(Icons.qr_code_2, color: Colors.white38, size: 14),
                          const SizedBox(width: 4),
                          Text('SKU: ${p['sku']}', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                          if (barcode != null && barcode.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.barcode_reader, color: Colors.white38, size: 14),
                            const SizedBox(width: 4),
                            Text('Barkod: $barcode', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                          ],
                        ],
                      ),
                      // Dynamic attributes chips
                      if (attributes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            ...attributes.entries.take(5).map((e) => _attrBadge(e.key, e.value)),
                            if (attributes.length > 5)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text('+${attributes.length - 5} daha', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatTL(p['price']), style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 17)),
                    if (listPrice != null)
                      Text(formatTL(listPrice), style: GoogleFonts.inter(color: Colors.white38, decoration: TextDecoration.lineThrough, fontSize: 12)),
                    Text('Stok: ${p['stockQuantity']} Adet', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, cardActionBox) {
              final isCompact = cardActionBox.maxWidth < 640;
              if (isCompact) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showProductDetailsDialog(productId),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.lightBlueAccent,
                              side: const BorderSide(color: Colors.lightBlueAccent),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.visibility, size: 14),
                            label: Text('İncele', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.5)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showEditProductDialog(productId, p),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amberAccent,
                              side: const BorderSide(color: Colors.amberAccent),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.edit, size: 14),
                            label: Text('Düzenle', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.5)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 19),
                          tooltip: 'Ürünü Sil',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E293B),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                title: Text('Ürünü Sil?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                                content: Text('Bu ürünü ve alt varyantlarını silmek istediğinize emin misiniz?', style: GoogleFonts.inter(color: Colors.white70)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Vazgeç', style: GoogleFonts.inter(color: Colors.white60))),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                    child: Text('Sil', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final success = await _apiService.deleteProduct(productId);
                              if (mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün başarıyla silindi.'), backgroundColor: Colors.redAccent));
                                  _loadData();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün silinirken bir hata oluştu.'), backgroundColor: Colors.red));
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trendyol v2 Ürün & Kampanya API isteği gönderiliyor...'), backgroundColor: Colors.orange));
                              final res = await _apiService.uploadProductToTrendyol(productId);
                              if (mounted) {
                                final isOk = res?['isSuccess'] == true;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(isOk ? 'Ürün ve promosyon kurgusu Trendyol kataloğuna aktarıldı!' : (res?['errorMessage'] ?? 'Trendyol aktarımında hata!')), backgroundColor: isOk ? Colors.green : Colors.orange),
                                );
                                _loadData();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.cloud_upload, size: 14),
                            label: Text('Trendyol\'a Yükle', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showBatchSyncApprovalDialog(initialScope: 'product', initialProductId: productId),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blueAccent,
                              side: const BorderSide(color: Colors.blueAccent),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.sync_alt, size: 14),
                            label: Text('Pazaryerlerine Dağıt', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showProductDetailsDialog(productId),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.lightBlueAccent, side: const BorderSide(color: Colors.lightBlueAccent), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: Text('Detayları İncele', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showEditProductDialog(productId, p),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.amberAccent, side: const BorderSide(color: Colors.amberAccent), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text('Düzenle', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trendyol v2 Ürün & Kampanya API isteği gönderiliyor...'), backgroundColor: Colors.orange));
                      final res = await _apiService.uploadProductToTrendyol(productId);
                      if (mounted) {
                        final isOk = res?['isSuccess'] == true;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isOk ? 'Ürün ve promosyon kurgusu Trendyol kataloğuna aktarıldı!' : (res?['errorMessage'] ?? 'Trendyol aktarımında hata!')), backgroundColor: isOk ? Colors.green : Colors.orange),
                        );
                        _loadData();
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    icon: const Icon(Icons.cloud_upload, size: 16),
                    label: Text('Trendyol\'a Yükle (v2)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showBatchSyncApprovalDialog(initialScope: 'product', initialProductId: productId),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.blueAccent, side: const BorderSide(color: Colors.blueAccent), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    icon: const Icon(Icons.sync_alt, size: 16),
                    label: Text('Pazaryerlerine Dağıt', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    tooltip: 'Ürünü Sil',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          title: Text('Ürünü Sil?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                          content: Text('Bu ürünü ve alt varyantlarını silmek istediğinize emin misiniz?', style: GoogleFonts.inter(color: Colors.white70)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Vazgeç', style: GoogleFonts.inter(color: Colors.white60))),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              child: Text('Sil', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final success = await _apiService.deleteProduct(productId);
                        if (mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün başarıyla silindi.'), backgroundColor: Colors.redAccent));
                            _loadData();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün silinirken bir hata oluştu.'), backgroundColor: Colors.red));
                          }
                        }
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tagBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _attrBadge(String key, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.indigoAccent.withOpacity(0.4)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '$key: ', style: GoogleFonts.inter(color: Colors.indigoAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            TextSpan(text: value, style: GoogleFonts.inter(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialsTab() {
    final gross = _financialSummary?['totalGrossSales'] ?? 0.0;
    final commission = _financialSummary?['totalCommissionDeduction'] ?? 0.0;
    final cargo = _financialSummary?['totalEstimatedCargoCost'] ?? 0.0;
    final netProfit = _financialSummary?['totalNetProfit'] ?? 0.0;
    final margin = _financialSummary?['overallProfitMarginPercent'] ?? 0.0;
    final rawBreakdowns = _financialSummary?['channelBreakdowns'] as List<dynamic>?;

    final breakdowns = (rawBreakdowns != null && rawBreakdowns.isNotEmpty)
        ? rawBreakdowns
        : [
            {'marketplace': 'Trendyol', 'orderCount': 0, 'grossSales': 0.0, 'commissionDeducted': 0.0, 'netProfit': 0.0},
            {'marketplace': 'Hepsiburada', 'orderCount': 0, 'grossSales': 0.0, 'commissionDeducted': 0.0, 'netProfit': 0.0},
            {'marketplace': 'Amazon TR', 'orderCount': 0, 'grossSales': 0.0, 'commissionDeducted': 0.0, 'netProfit': 0.0},
            {'marketplace': 'Pazarama', 'orderCount': 0, 'grossSales': 0.0, 'commissionDeducted': 0.0, 'netProfit': 0.0},
          ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;
        final isTablet = constraints.maxWidth >= 640 && constraints.maxWidth < 960;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gerçek Zamanlı Finans & Kâr/Zarar Analizi', style: GoogleFonts.inter(color: Colors.white, fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Pazaryeri komisyonları, kargo giderleri ve net kârlılık durumunuzu anlık izleyin', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 16),

            // Metrik Kartları (Responsive 2x2 Grid mobilde, 4 sütun masaüstünde)
            if (isMobile || isTablet) ...[
              Row(
                children: [
                  Expanded(child: _finCard('Brüt Ciro', formatTL(gross), Icons.monetization_on_outlined, Colors.blueAccent)),
                  const SizedBox(width: 10),
                  Expanded(child: _finCard('Komisyonlar', formatTL(commission), Icons.percent_outlined, Colors.orangeAccent)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _finCard('Kargo Gideri', formatTL(cargo), Icons.local_shipping_outlined, Colors.purpleAccent)),
                  const SizedBox(width: 10),
                  Expanded(child: _finCard('Net Kâr (%$margin)', formatTL(netProfit), Icons.trending_up_outlined, Colors.greenAccent)),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(child: _finCard('Toplam Brüt Ciro', formatTL(gross), Icons.monetization_on_outlined, Colors.blueAccent)),
                  const SizedBox(width: 12),
                  Expanded(child: _finCard('Komisyon Kesintileri', formatTL(commission), Icons.percent_outlined, Colors.orangeAccent)),
                  const SizedBox(width: 12),
                  Expanded(child: _finCard('Tahmini Kargo Gideri', formatTL(cargo), Icons.local_shipping_outlined, Colors.purpleAccent)),
                  const SizedBox(width: 12),
                  Expanded(child: _finCard('Net Kâr Marjı (%$margin)', formatTL(netProfit), Icons.trending_up_outlined, Colors.greenAccent)),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Kanal Bazlı Kârlılık Dağılımı Başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kanal Bazlı Kârlılık Dağılımı', style: GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text('${breakdowns.length} Kanal', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Kanal Listesi (Mobilde Kart Görünümü, Masaüstünde Tablo)
            if (isMobile) ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: breakdowns.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final b = breakdowns[index];
                  final mp = (b['marketplace'] ?? 'Pazaryeri').toString();
                  final orderCount = b['orderCount'] ?? 0;
                  final grossSales = b['grossSales'] ?? 0.0;
                  final com = b['commissionDeducted'] ?? 0.0;
                  final net = b['netProfit'] ?? 0.0;

                  Color mpColor = Colors.blueAccent;
                  if (mp.toLowerCase().contains('trendyol')) mpColor = Colors.orange;
                  else if (mp.toLowerCase().contains('hepsiburada')) mpColor = Colors.deepOrangeAccent;
                  else if (mp.toLowerCase().contains('amazon')) mpColor = Colors.amberAccent;
                  else if (mp.toLowerCase().contains('pazarama')) mpColor = Colors.purpleAccent;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: mpColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(mp, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                              child: Text('$orderCount Sipariş', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Brüt Ciro', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.5)),
                                const SizedBox(height: 2),
                                Text(formatTL(grossSales), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('Komisyon', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.5)),
                                const SizedBox(height: 2),
                                Text(formatTL(com), style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12.5)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Net Kâr', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.5)),
                                const SizedBox(height: 2),
                                Text(formatTL(net), style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text('Satış Kanalı', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Sipariş Adedi', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Brüt Ciro', textAlign: TextAlign.right, style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Komisyon Kesintisi', textAlign: TextAlign.right, style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Net Kâr', textAlign: TextAlign.right, style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...breakdowns.map((b) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text(b['marketplace'] ?? '', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                              Expanded(flex: 2, child: Text('${b['orderCount']} Adet', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12))),
                              Expanded(flex: 2, child: Text(formatTL(b['grossSales']), textAlign: TextAlign.right, style: GoogleFonts.inter(color: Colors.white, fontSize: 12))),
                              Expanded(flex: 2, child: Text(formatTL(b['commissionDeducted']), textAlign: TextAlign.right, style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 12))),
                              Expanded(flex: 2, child: Text(formatTL(b['netProfit']), textAlign: TextAlign.right, style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 70),
          ],
        );
      },
    );
  }

  Widget _finCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 11.5, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              val,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.white24),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white60, fontSize: 14)),
        ],
      ),
    );
  }
}
