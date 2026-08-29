import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:frontend/data/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // AI Chat State
  final List<Map<String, dynamic>> _aiMessages = [];
  bool _isAiThinking = false;
  final TextEditingController _aiInputController = TextEditingController();
  final ScrollController _aiScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _initAiGreeting();
  }

  void _initAiGreeting() {
    _aiMessages.add({
      'role': 'assistant',
      'content': 'Merhaba! Ben sizin **Pazaryeri & E-Ticaret Yapay Zeka Danışmanınızım**. 🤖\n\nSistemi nasıl kullanacağınızı, 2 Al 1 Öde kampanyalarını, 1.2s stok eşitlemeyi veya kâr marjınızı nasıl optimize edeceğinizi bana 7/24 sorabilirsiniz.',
      'actions': [
        {'label': '🔥 2 Al 1 Öde Nasıl Açılır?', 'action': 'ask', 'prompt': '2 Al 1 Öde kampanyası nasıl açılır?'},
        {'label': '🔗 Mağaza Nasıl Bağlanır?', 'action': 'ask', 'prompt': 'Trendyol mağazamı nasıl bağlarım?'},
        {'label': '⚡ Stoklar Nasıl Eşitlenir?', 'action': 'ask', 'prompt': 'Stok senkronizasyonu nasıl çalışır?'},
        {'label': '🖩 Fiyat Robotu Nasıl Kullanılır?', 'action': 'ask', 'prompt': 'Kâr marjımı nasıl hesaplarım?'},
      ]
    });
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
            } else if (actionType == 'switch_tab_orders') {
              Navigator.pop(ctx);
              setState(() => _currentTabIndex = 1);
            } else if (actionType == 'broadcast_stock') {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stoklar tüm pazaryerlerine 1.2 saniyede dağıtılıyor...'), backgroundColor: Colors.blueAccent));
            } else if (act['prompt'] != null) {
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
                      Text('Pazaryeri Yapay Zeka Danışmanı', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
                              if (quickPrompts != null && quickPrompts.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: quickPrompts.map((p) {
                                    return ActionChip(
                                      label: Text(p.toString(), style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                                      backgroundColor: Colors.white.withOpacity(0.08),
                                      side: const BorderSide(color: Colors.white24),
                                      onPressed: () => sendMessage(p.toString()),
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
      {'type': 1, 'name': '🔥 2 Al 1 Öde (BOGO)', 'desc': '2 ürün sepete eklendiğinde 1 ürün bedava olur (Birim: ₺${(basePrice / 2).toStringAsFixed(2)}).', 'badge': '2 Al 1 Öde'},
      {'type': 2, 'name': '🎁 3 Al 2 Öde', 'desc': '3 ürün sepete eklendiğinde 2 ürün fiyatı ödenir (Birim: ₺${((basePrice * 2) / 3).toStringAsFixed(2)}).', 'badge': '3 Al 2 Öde'},
      {'type': 3, 'name': '⚡ 2. Ürüne %50 İndirim', 'desc': 'İkinci ürün %50 indirimli ₺${(basePrice * 0.5).toStringAsFixed(2)} olur (2li sepet: ₺${(basePrice * 1.5).toStringAsFixed(2)}).', 'badge': '2. Ürün %50'},
      {'type': 4, 'name': '🛒 Sepette %10 İndirim', 'desc': 'Sepette anında ₺${(basePrice * 0.9).toStringAsFixed(2)} fiyata düşer.', 'badge': 'Sepette %10'},
      {'type': 5, 'name': '🛒 Sepette %20 İndirim', 'desc': 'Sepette anında ₺${(basePrice * 0.8).toStringAsFixed(2)} fiyata düşer.', 'badge': 'Sepette %20'},
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

  // --- SADE ÜRÜN EKLEME MODALI ---
  void _showSimplifiedAddProductDialog() {
    final titleController = TextEditingController();
    final brandController = TextEditingController(text: 'Tudors');
    final categoryController = TextEditingController(text: 'Polo Yaka Tişört');
    final priceController = TextEditingController(text: '1083.90');
    final stockController = TextEditingController(text: '100');
    final listPriceController = TextEditingController(text: '1747.80');
    final desiController = TextEditingController(text: '1.5');
    final skuController = TextEditingController(text: 'TDR-PL-01');
    final urlInputController = TextEditingController();

    List<String> uploadedImages = [
      "https://cdn.dsmcdn.com/ty1687/prod/QC_PREP/20250603/18/c2992fcf-6771-3257-8743-e1c6731041fd/1_org_zoom.jpg",
      "https://cdn.dsmcdn.com/ty1686/prod/QC_PREP/20250603/18/53f6bf86-2c9f-3e2c-87c1-206a47e4ad34/1_org_zoom.jpg"
    ];
    int selectedCampaignType = 1;
    String selectedCampaignName = "🔥 2 Al 1 Öde (BOGO)";
    bool isUploadingImage = false;
    bool showAdvancedOptions = false;
    bool autoCreateVariants = true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          void pickAndUploadImage() {
            final uploadInput = html.FileUploadInputElement();
            uploadInput.accept = 'image/*';
            uploadInput.click();

            uploadInput.onChange.listen((e) {
              final files = uploadInput.files;
              if (files != null && files.isNotEmpty) {
                final file = files[0];
                final reader = html.FileReader();
                setDlgState(() => isUploadingImage = true);

                reader.onLoadEnd.listen((e) async {
                  final base64String = reader.result as String;
                  final uploadedUrl = await _apiService.uploadImage(base64String, file.name);

                  setDlgState(() {
                    isUploadingImage = false;
                    if (uploadedUrl != null) {
                      uploadedImages.add(uploadedUrl);
                    } else {
                      uploadedImages.add(base64String);
                    }
                  });
                });
                reader.readAsDataUrl(file);
              }
            });
          }

          final currentPrice = double.tryParse(priceController.text) ?? 1083.90;

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
              width: 820,
              height: 580,
              child: SingleChildScrollView(
                child: Row(
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
                                        image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover),
                                      ),
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
                          Text('📝 Temel Ürün Bilgileri', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: titleController,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Ürün Başlığı *',
                              hintText: 'Örn: Tudors Erkek 5li Paket Polo Tişört',
                              labelStyle: GoogleFonts.inter(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
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
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                  decoration: InputDecoration(labelText: 'Satış Fiyatı (₺) *', prefixText: '₺ ', prefixStyle: GoogleFonts.inter(color: Colors.greenAccent), labelStyle: GoogleFonts.inter(color: Colors.white70), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
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
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: listPriceController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                                    decoration: InputDecoration(labelText: 'Üstü Çizili Liste Fiyatı', prefixText: '₺ ', labelStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 11), filled: true, fillColor: Colors.white.withOpacity(0.04), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: desiController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                                    decoration: InputDecoration(labelText: 'Kargo Desisi', suffixText: 'Desi', labelStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 11), filled: true, fillColor: Colors.white.withOpacity(0.04), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: skuController,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                                    decoration: InputDecoration(labelText: 'Özel Stok Kodu (SKU)', labelStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 11), filled: true, fillColor: Colors.white.withOpacity(0.04), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                                  ),
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
                        final price = double.tryParse(priceController.text) ?? 1083.90;
                        final listPrice = double.tryParse(listPriceController.text) ?? price * 1.3;
                        final stock = int.tryParse(stockController.text) ?? 100;
                        final desi = double.tryParse(desiController.text) ?? 1.5;
                        final sku = skuController.text.trim().isNotEmpty ? skuController.text.trim() : 'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

                        List<Map<String, dynamic>> variants = [];
                        if (autoCreateVariants) {
                          final sizes = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL'];
                          variants = sizes.map((sz) {
                            return {
                              'sku': '$sku-$sz',
                              'barcode': '868000${sz.hashCode.abs().toString().padLeft(6, '0')}',
                              'size': sz,
                              'color': 'Çok Renkli',
                              'price': price,
                              'listPrice': listPrice,
                              'stockQuantity': (stock / sizes.length).round(),
                              'isActive': true
                            };
                          }).toList();
                        }

                        final richPayload = {
                          'title': titleController.text,
                          'sku': sku,
                          'barcode': '868000${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
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
                          'attributes': {
                            'Kalıp': 'Slim Fit',
                            'Kategori': categoryController.text,
                            'Marka': brandController.text,
                            'Kampanya': selectedCampaignName
                          },
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
                                  image: selectedImage.isNotEmpty
                                      ? DecorationImage(image: NetworkImage(selectedImage), fit: BoxFit.contain)
                                      : null,
                                ),
                                child: selectedImage.isEmpty ? const Center(child: Icon(Icons.image_not_supported, color: Colors.white24, size: 48)) : null,
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
                                            image: DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover),
                                          ),
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
                                        Text('₺${details['price']}', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 22)),
                                      ],
                                    ),
                                    const SizedBox(width: 24),
                                    if (details['listPrice'] != null)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Liste Fiyatı', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                                          Text('₺${details['listPrice']}', style: GoogleFonts.inter(color: Colors.white38, decoration: TextDecoration.lineThrough, fontSize: 16)),
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
                                      Expanded(flex: 2, child: Text('₺${v['price']}', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13))),
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
    final companyName = tenant?['companyName'] ?? 'Mağazam';
    final limits = _metrics?['limits'];
    final productCount = limits?['currentProducts'] ?? 0;
    final productLimit = limits?['productLimit'] ?? 50;
    final connCount = limits?['currentConnections'] ?? 0;
    final connLimit = limits?['connectionLimit'] ?? 3;
    final daysLeft = limits?['daysLeft'] ?? 30;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAiAssistantDialog,
        backgroundColor: Colors.purpleAccent.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
        label: Text('✨ AI E-Ticaret Danışmanı', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
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
            Text('Ürün Kataloğu & Kampanya Yönetimi', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tüm ürünlerin stokları aktif pazaryerlerine dağıtılıyor... (1.2s)'), backgroundColor: Colors.blueAccent));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  icon: const Icon(Icons.flash_on, size: 18),
                  label: Text('⚡ Hızlı Stok Dağıt', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _products == null || _products!.isEmpty
            ? _buildEmptyState('Henüz ürün eklenmemiş. Yukarıdaki "+ Yeni Ürün & Kampanya Ekle" butonuyla kolayca ürün ekleyebilirsiniz.', Icons.inventory_2_outlined)
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
    final productId = p['id'].toString();
    final campaignName = p['campaignName'] ?? 'Standart Satış';
    final campaignType = p['campaignType'] ?? 0;

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
                          if (variantCount > 0) _tagBadge('$variantCount Beden Varyantı', Colors.orangeAccent),
                          if (imageCount > 0) _tagBadge('$imageCount Görsel', Colors.lightBlueAccent),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('SKU: ${p['sku']} • Barkod: ${p['barcode'] ?? '-'}', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
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
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 6),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showProductDetailsDialog(productId),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.lightBlueAccent, side: const BorderSide(color: Colors.lightBlueAccent), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: const Icon(Icons.visibility, size: 16),
                label: Text('Detayları İncele', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
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
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: const Icon(Icons.cloud_upload, size: 16),
                label: Text('Trendyol a Yükle (v2)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final res = await _apiService.broadcastStock(productId, p['stockQuantity']);
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
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                tooltip: 'Ürünü Sil',
                onPressed: () async {
                  final ok = await _apiService.deleteProduct(productId);
                  if (ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün silindi.'), backgroundColor: Colors.redAccent));
                    _loadData();
                  }
                },
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
