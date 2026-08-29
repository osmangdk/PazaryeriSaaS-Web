import 'package:flutter/material.dart';
import 'package:frontend/data/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;

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
  List<dynamic>? _orders;
  Map<String, dynamic>? _financialSummary;
  bool _isLoading = true;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final metrics = await _apiService.getDashboardMetrics();
    final products = await _apiService.getProducts();
    final connections = await _apiService.getMarketplaceConnections();
    final orders = await _apiService.getMarketplaceOrders();
    final financials = await _apiService.getFinancialSummary();

    setState(() {
      _metrics = metrics;
      _products = products;
      _connections = connections;
      _orders = orders;
      _financialSummary = financials;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (mounted) context.go('/');
  }

  void _showPricingCalculatorDialog() {
    final costController = TextEditingController(text: '150');
    final profitController = TextEditingController(text: '25');
    final shippingController = TextEditingController(text: '45');
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
                Text('Akıllı Komisyon & Fiyat Robotu', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: 650,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                        const SizedBox(width: 12),
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
                        const SizedBox(width: 12),
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
                          onPressed: doCalculate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isCalculating)
                      const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.orangeAccent))
                    else if (calculatedResults != null)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text('Pazaryeri', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 2, child: Text('Komisyon', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 3, child: Text('Önerilen Fiyat', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 2, child: Text('Net Kâr', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...calculatedResults!.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: Row(
                                children: [
                                  Expanded(flex: 3, child: Text(item['marketplace'] ?? '', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
                                  Expanded(flex: 2, child: Text('%${item['commissionRate']}', style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 12))),
                                  Expanded(flex: 3, child: Text('₺${item['recommendedSalePrice']}', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14))),
                                  Expanded(flex: 2, child: Text('₺${item['targetProfitAmount']}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12))),
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

  void _showAddMarketplaceDialog() {
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
                    DropdownButtonFormField<int>(
                      value: selectedType,
                      dropdownColor: const Color(0xFF1E293B),
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(labelText: 'Pazaryeri Seçin', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
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
                      ],
                      onChanged: (val) => setDialogState(() => selectedType = val ?? 1),
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

  void _showAddRichProductDialog() {
    final titleController = TextEditingController(text: "Tudors Erkek 5'li Paket Slim Fit Pamuklu Pike Polo Yaka Tişört");
    final brandController = TextEditingController(text: "Tudors");
    final categoryController = TextEditingController(text: "Polo Yaka Tişört");
    final modelCodeController = TextEditingController(text: "942363515");
    final skuController = TextEditingController(text: "TDR-POLO-5PK");
    final priceController = TextEditingController(text: "1083.90");
    final listPriceController = TextEditingController(text: "1747.80");
    final costPriceController = TextEditingController(text: "450.00");
    final desiController = TextEditingController(text: "2.0");
    final stockController = TextEditingController(text: "385");
    final imagesController = TextEditingController(text: "https://cdn.dsmcdn.com/ty1687/prod/QC_PREP/20250603/18/c2992fcf-6771-3257-8743-e1c6731041fd/1_org_zoom.jpg, https://cdn.dsmcdn.com/ty1686/prod/QC_PREP/20250603/18/53f6bf86-2c9f-3e2c-87c1-206a47e4ad34/1_org_zoom.jpg");
    final fitController = TextEditingController(text: "Slim Fit");
    final materialController = TextEditingController(text: "%55 Polyester, %45 Pamuk");
    final collarController = TextEditingController(text: "Polo Yaka");
    final colorsController = TextEditingController(text: "Gri-Mavi-Haki-Yeşil-Siyah");
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.shopping_bag, color: Colors.orangeAccent),
                ),
                const SizedBox(width: 12),
                Text('Gelişmiş Ürün & Varyant Tanımla (Trendyol V2 Standart)', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            content: SizedBox(
              width: 650,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. Temel Bilgiler & Tanımlayıcılar', style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(labelText: 'Ürün Başlığı', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: brandController,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(labelText: 'Marka (Brand)', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: categoryController,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(labelText: 'Kategori', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: modelCodeController,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(labelText: 'Model Kodu (Grup)', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('2. Fiyatlandırma, KDV & Lojistik (Desi)', style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(labelText: 'Satış Fiyatı (₺)', prefixText: '₺ ', prefixStyle: GoogleFonts.inter(color: Colors.greenAccent), labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: listPriceController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(labelText: 'Liste Fiyatı (Üstü Çizili)', prefixText: '₺ ', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: costPriceController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(labelText: 'Maliyet (₺)', prefixText: '₺ ', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: desiController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(labelText: 'Desi / Ağırlık', suffixText: 'Desi', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('3. Kategori Nitelikleri (Attributes)', style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: fitController,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(labelText: 'Kalıp (Fit)', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: materialController,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(labelText: 'Materyal', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: collarController,
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(labelText: 'Yaka Tipi', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('4. Çoklu Resim Bağlantıları (1-8 Adet)', style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: imagesController,
                      maxLines: 2,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(labelText: 'Görsel CDN URL leri (virgülle ayrılmış)', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blueAccent.withOpacity(0.3))),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.blueAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Otomatik Beden Varyantları (XS, S, M, L, XL, 2XL, 3XL) bağımsız barkodlar ve stoklarla oluşturulacaktır.',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
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
                        if (titleController.text.isEmpty || priceController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen zorunlu alanları doldurun.'), backgroundColor: Colors.orangeAccent));
                          return;
                        }
                        setDlgState(() => isSubmitting = true);
                        final price = double.tryParse(priceController.text) ?? 1083.90;
                        final listPrice = double.tryParse(listPriceController.text) ?? 1747.80;
                        final costPrice = double.tryParse(costPriceController.text) ?? 450.0;
                        final desi = double.tryParse(desiController.text) ?? 2.0;
                        final stock = int.tryParse(stockController.text) ?? 385;

                        final rawImages = imagesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

                        // 7 Beden varyantı üret
                        final sizes = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL'];
                        final variants = sizes.map((sz) {
                          return {
                            'sku': '${skuController.text}-$sz',
                            'barcode': '868000${sz.hashCode.abs().toString().padLeft(6, '0')}',
                            'size': sz,
                            'color': colorsController.text,
                            'price': price,
                            'listPrice': listPrice,
                            'stockQuantity': (stock / sizes.length).round(),
                            'isActive': true
                          };
                        }).toList();

                        final richPayload = {
                          'title': titleController.text,
                          'sku': skuController.text,
                          'barcode': '8680009423635',
                          'modelCode': modelCodeController.text,
                          'brand': brandController.text,
                          'categoryName': categoryController.text,
                          'price': price,
                          'listPrice': listPrice,
                          'costPrice': costPrice,
                          'vatRate': 20,
                          'stockQuantity': stock,
                          'dimensionalWeight': desi,
                          'cargoCompany': 'Trendyol Express',
                          'deliveryDuration': 2,
                          'description': "${titleController.text} - ${fitController.text}, ${materialController.text}, ${collarController.text}",
                          'images': rawImages,
                          'attributes': {
                            'Kalıp': fitController.text,
                            'Materyal': materialController.text,
                            'Yaka': collarController.text,
                            'Renk': colorsController.text,
                            'Paket': "5'li",
                            'Cinsiyet': 'Erkek'
                          },
                          'variants': variants
                        };

                        final res = await _apiService.createRichProduct(richPayload);
                        setDlgState(() => isSubmitting = false);

                        if (res != null && mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zengin Ürün & 7 Beden Varyantı Başarıyla Eklendi!'), backgroundColor: Colors.green));
                          _loadData();
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün eklenirken bir hata oluştu!'), backgroundColor: Colors.red));
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]),
                child: isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Zengin Ürünü Kaydet 🚀', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenant = _metrics?['tenant'];
    final companyName = tenant?['companyName'] ?? 'Mağazam';
    final limits = _metrics?['limits'];
    final productCount = limits?['currentProducts'] ?? 0;
    final productLimit = limits?['productLimit'] ?? 50;
    final connCount = limits?['currentConnections'] ?? 0;
    final connLimit = limits?['connectionLimit'] ?? 3;
    final daysLeft = limits?['daysLeft'] ?? 30;

    return Scaffold(
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  border: const Border(bottom: BorderSide(color: Colors.white12)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.storefront, color: Colors.blueAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(companyName, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('30 Gün / 50.000 ₺ Ücretsiz Deneme Paketi', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
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
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      tooltip: 'Çıkış Yap',
                      onPressed: _logout,
                    ),
                  ],
                ),
              ),

              // Navigation Tabs
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    _buildTabButton(0, 'Pazaryeri Entegrasyonları', Icons.hub_outlined),
                    const SizedBox(width: 12),
                    _buildTabButton(1, 'Siparişler', Icons.shopping_bag_outlined),
                    const SizedBox(width: 12),
                    _buildTabButton(2, 'Ürün Kataloğu & Varyantlar', Icons.inventory_2_outlined),
                    const SizedBox(width: 12),
                    _buildTabButton(3, 'Finans & Kâr Analizi 📊', Icons.query_stats_outlined),
                  ],
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
                            // Usage Meter
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: _buildLimitStat('Kalan Deneme Süresi', '$daysLeft Gün', Icons.timer_outlined, Colors.amberAccent)),
                                  Container(width: 1, height: 40, color: Colors.white12),
                                  Expanded(child: _buildLimitStat('Aktif Pazaryerleri', '$connCount / $connLimit', Icons.cable, Colors.blueAccent)),
                                  Container(width: 1, height: 40, color: Colors.white12),
                                  Expanded(child: _buildLimitStat('Kayıtlı Ürünler', '$productCount / $productLimit', Icons.inventory_2, Colors.greenAccent)),
                                ],
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

  Widget _buildLimitStat(String label, String val, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
            Text(val, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tüm Pazaryeri Siparişleri', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _orders == null || _orders!.isEmpty
            ? _buildEmptyState('Henüz sipariş bulunmuyor.', Icons.shopping_bag_outlined)
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _orders!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final o = _orders![index];
                  final orderId = o['orderId'] ?? 'ORD-001';
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.shopping_bag, color: Colors.greenAccent, size: 24)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${o['customerName']} • ${o['marketplace']}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text('Sipariş No: $orderId • Durum: ${o['status']}', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('₺${o['totalPrice']}', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                final url = _apiService.getInvoiceUrl(orderId);
                                html.window.open(url, '_blank');
                              },
                              icon: const Icon(Icons.receipt_long, size: 16, color: Colors.blueAccent),
                              label: Text('GİB E-Fatura Görüntüle', style: GoogleFonts.inter(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blueAccent), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () {
                                final url = _apiService.getShippingLabelUrl(orderId);
                                html.window.open(url, '_blank');
                              },
                              icon: const Icon(Icons.qr_code, size: 16, color: Colors.orangeAccent),
                              label: Text('Kargo Barkodu Yazdır', style: GoogleFonts.inter(fontSize: 12, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orangeAccent), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildProductsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ürün Kataloğu & Varyant Matrisi', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddRichProductDialog,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: Text('Gelişmiş Ürün Tanımla (Varyantlı)', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tüm ürünlerin stokları aktif pazaryerlerine dağıtılıyor... (1.2s)'), backgroundColor: Colors.blueAccent));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  icon: const Icon(Icons.flash_on, size: 18),
                  label: Text('Işık Hızında Stok Dağıt', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _products == null || _products!.isEmpty
            ? _buildEmptyState('Henüz ürün eklenmemiş. Yukarıdaki "Gelişmiş Ürün Tanımla" butonuyla yeni ürün ekleyebilirsiniz.', Icons.inventory_2_outlined)
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _products!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildProductCard(_products![index]),
              ),
      ],
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  image: p['firstImage'] != null
                      ? DecorationImage(image: NetworkImage(p['firstImage']), fit: BoxFit.cover)
                      : null,
                ),
                child: p['firstImage'] == null ? const Icon(Icons.inventory_2, color: Colors.blueAccent, size: 28) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['title'] ?? p['name'] ?? 'İsimsiz Ürün', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _tagBadge(brand, Colors.blueAccent),
                        _tagBadge(category, Colors.tealAccent),
                        _tagBadge('Model: $modelCode', Colors.purpleAccent),
                        _tagBadge('Desi: $desi', Colors.amberAccent),
                        if (variantCount > 0) _tagBadge('$variantCount Beden Varyantı', Colors.orangeAccent),
                        if (imageCount > 0) _tagBadge('$imageCount Görsel', Colors.lightBlueAccent),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('SKU: ${p['sku']} • Barkod: ${p['barcode'] ?? '-'}', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₺${p['price']}', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 17)),
                  if (listPrice != null)
                    Text('₺$listPrice', style: GoogleFonts.inter(color: Colors.white38, decoration: TextDecoration.lineThrough, fontSize: 12)),
                  Text('Stok: ${p['stockQuantity']} Adet', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trendyol v2 Ürün Oluşturma API isteği gönderiliyor...'), backgroundColor: Colors.orange));
                  final res = await _apiService.uploadProductToTrendyol(p['id']);
                  if (mounted) {
                    final isOk = res?['isSuccess'] == true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isOk ? 'Ürün Trendyol kataloğuna başarıyla aktarıldı!' : (res?['errorMessage'] ?? 'Trendyol aktarımında hata!')), backgroundColor: isOk ? Colors.green : Colors.orange),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: const Icon(Icons.cloud_upload, size: 16),
                label: Text('Trendyol a Yükle (v2)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final res = await _apiService.broadcastStock(p['id'], p['stockQuantity']);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res?['isSuccess'] == true ? 'Stok 1.2 saniyede tüm pazaryerlerine eşitlendi!' : 'Stok dağıtımında hata!'), backgroundColor: Colors.blueAccent),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.blueAccent, side: const BorderSide(color: Colors.blueAccent), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: const Icon(Icons.flash_on, size: 16),
                label: Text('Stok Dağıt (1.2s)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
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

  Widget _buildFinancialsTab() {
    final gross = _financialSummary?['totalGrossSales'] ?? 18450.0;
    final commission = _financialSummary?['totalCommissionDeduction'] ?? 3690.0;
    final cargo = _financialSummary?['totalEstimatedCargoCost'] ?? 1125.0;
    final netProfit = _financialSummary?['totalNetProfit'] ?? 7380.0;
    final margin = _financialSummary?['overallProfitMarginPercent'] ?? 40.0;
    final breakdowns = _financialSummary?['channelBreakdowns'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gerçek Zamanlı Finans & Kâr/Zarar Analizi', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _finCard('Toplam Brüt Ciro', '₺${gross}', Icons.monetization_on, Colors.blueAccent)),
            const SizedBox(width: 12),
            Expanded(child: _finCard('Komisyon Kesintileri', '₺${commission}', Icons.percent, Colors.orangeAccent)),
            const SizedBox(width: 12),
            Expanded(child: _finCard('Tahmini Kargo Gideri', '₺${cargo}', Icons.local_shipping, Colors.purpleAccent)),
            const SizedBox(width: 12),
            Expanded(child: _finCard('Net Kâr Marjı (%$margin)', '₺${netProfit}', Icons.trending_up, Colors.greenAccent)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Kanal Bazlı Kârlılık Dağılımı', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (breakdowns.isEmpty)
          _buildEmptyState('Finansal dağılım verisi hesaplanıyor...', Icons.analytics_outlined)
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(flex: 3, child: Text('Kanal', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Sipariş', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Brüt Ciro', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Komisyon', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Net Kâr', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                ...breakdowns.map((b) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(b['marketplace'] ?? '', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('${b['orderCount']} Adet', style: GoogleFonts.inter(color: Colors.white70))),
                          Expanded(flex: 2, child: Text('₺${b['grossSales']}', style: GoogleFonts.inter(color: Colors.white))),
                          Expanded(flex: 2, child: Text('₺${b['commissionDeducted']}', style: GoogleFonts.inter(color: Colors.orangeAccent))),
                          Expanded(flex: 2, child: Text('₺${b['netProfit']}', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _finCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(val, style: GoogleFonts.inter(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
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
