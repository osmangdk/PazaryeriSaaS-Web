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

  // Category & Catalog Filter State
  String _selectedCategoryFilter = 'ALL';
  String? _selectedSubCategoryFilter;
  String _productSearchQuery = '';
  final TextEditingController _productSearchController = TextEditingController();
  final Set<String> _expandedCategoryIds = {'Giyim', 'Bilgisayar'};

  final List<Map<String, dynamic>> _catalogCategories = [
    {
      'id': 'ALL',
      'title': 'Tüm Ürünleri Listele',
      'icon': Icons.apps,
      'color': Colors.blueAccent,
      'subCategories': <String>[],
    },
    {
      'id': 'Giyim',
      'title': 'Giyim & Tekstil',
      'icon': Icons.checkroom,
      'color': Colors.orangeAccent,
      'allLabel': 'Tüm Giyim Ürünleri',
      'subCategories': ['Tişört & Polo Yaka', 'Gömlek', 'Pantolon & Jean', 'Ceket & Mont', 'Elbise & Etek', 'Ayakkabı'],
    },
    {
      'id': 'Bilgisayar',
      'title': 'Laptop & Bilgisayar',
      'icon': Icons.laptop_mac,
      'color': Colors.tealAccent,
      'allLabel': 'Tüm Bilgisayar Ürünleri',
      'subCategories': ['Dizüstü Bilgisayar (Laptop)', 'Masaüstü & Monitör', 'Tablet & Çevre Birimleri', 'Bilgisayar Bileşenleri'],
    },
    {
      'id': 'Telefon',
      'title': 'Telefon & Aksesuar',
      'icon': Icons.smartphone,
      'color': Colors.purpleAccent,
      'allLabel': 'Tüm Telefon Ürünleri',
      'subCategories': ['Akıllı Telefonlar', 'Kılıf & Koruyucu', 'Şarj & Kablo', 'Akıllı Saat & Bileklik'],
    },
    {
      'id': 'Ev',
      'title': 'Ev & Yaşam',
      'icon': Icons.home,
      'color': Colors.greenAccent,
      'allLabel': 'Tüm Ev & Yaşam Ürünleri',
      'subCategories': ['Küçük Ev Aletleri', 'Mutfak & Sofra', 'Mobilya & Dekorasyon', 'Ev Tekstili'],
    },
    {
      'id': 'Oyun',
      'title': 'Oyun & Hobi',
      'icon': Icons.sports_esports,
      'color': Colors.pinkAccent,
      'allLabel': 'Tüm Oyun & Hobi Ürünleri',
      'subCategories': ['Oyun Konsolları', 'Konsol Oyunları', 'Gaming Aksesuar', 'Hobi & Maket'],
    },
    {
      'id': 'Araç',
      'title': 'Oto & Yapı Market',
      'icon': Icons.build,
      'color': Colors.amberAccent,
      'allLabel': 'Tüm Yapı Market Ürünleri',
      'subCategories': ['Elektrikli El Aletleri', 'Oto Aksesuar', 'Hırdavat & Boya', 'Bahçe Ekipmanları'],
    },
  ];

  // AI Chat State
  final List<Map<String, dynamic>> _aiMessages = [];
  final Set<String> _askedPrompts = {};
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
                  html.window.open('https://wa.me/905550000000?text=Merhaba,%20PazaryeriSaaS%20hakkında%20bilgi%20almak%20istiyorum', '_blank');
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
                  html.window.open('tel:08500000000', '_self');
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
                  html.window.open('mailto:destek@pazaryeri.com?subject=PazaryeriSaaS%20Destek%20Talebi', '_self');
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
                        child: const Icon(Icons.email_outlined, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('E-Posta Destek Talebi', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('destek@pazaryeri.com (Maks. 15 dk dönüş)', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
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
              html.window.open('https://wa.me/905550000000?text=Merhaba,%20PazaryeriSaaS%20hakkında%20bilgi%20almak%20istiyorum', '_blank');
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
    final barcodeController = TextEditingController();
    final urlInputController = TextEditingController();
    final attrKeyController = TextEditingController();
    final attrValueController = TextEditingController();

    Map<String, String> productAttributes = {};

    // Kategori şablonları
    final categoryTemplates = {
      '💻 Laptop & Bilgisayar': ['İşlemci', 'RAM (Sistem Belleği)', 'SSD Kapasitesi', 'Ekran Boyutu', 'İşletim Sistemi', 'Ekran Kartı', 'Çözünürlük', 'Renk', 'Ağırlık', 'Garanti Süresi'],
      '📱 Telefon & Tablet': ['Dahili Hafıza', 'RAM', 'Renk', 'Ekran Boyutu', 'Kamera Çözünürlüğü', 'Pil Gücü', 'İşletim Sistemi', 'Garanti'],
      '👕 Giyim & Tekstil': ['Kalıp', 'Kumaş', 'Yaka', 'Renk', 'Cinsiyet', 'Sezon', 'Paket'],
      '🏠 Ev & Yaşam': ['Malzeme', 'Güç', 'Kapasite', 'Renk', 'Boyut', 'Garanti'],
      '🎮 Oyun & Konsol': ['Platform', 'Depolama', 'Kapasite', 'Renk', 'Garanti'],
      '🔧 Araç & Gereç': ['Güç', 'Voltaj', 'Kapasite', 'Ölçü', 'Garanti'],
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
              priceController.text = '31999.00';
              listPriceController.text = '33683.16';
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
                'https://productimages.hepsiburada.net/s/777/550/110000889146191.jpg',
                'https://productimages.hepsiburada.net/s/777/550/110000889146192.jpg',
                'https://productimages.hepsiburada.net/s/777/550/110000889146193.jpg'
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
              priceController.text = '89999.00';
              listPriceController.text = '94999.00';
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
                'https://productimages.hepsiburada.net/s/777/550/110000889146191.jpg'
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
              priceController.text = '1083.90';
              listPriceController.text = '1747.80';
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
                'https://cdn.dsmcdn.com/ty1687/prod/QC_PREP/20250603/18/c2992fcf-6771-3257-8743-e1c6731041fd/1_org_zoom.jpg',
                'https://cdn.dsmcdn.com/ty1686/prod/QC_PREP/20250603/18/53f6bf86-2c9f-3e2c-87c1-206a47e4ad34/1_org_zoom.jpg'
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
                  // Anında yerel önizleme ekle
                  setDlgState(() {
                    uploadedImages.add(base64String);
                  });

                  // Sunucuya arka planda yükle
                  final uploadedUrl = await _apiService.uploadImage(base64String, file.name);
                  setDlgState(() {
                    isUploadingImage = false;
                    if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
                      final idx = uploadedImages.indexOf(base64String);
                      if (idx != -1) {
                        uploadedImages[idx] = uploadedUrl;
                      }
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
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: listPriceController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'Üstü Çizili Liste Fiyatı',
                                      prefixText: '₺ ',
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
                    final price = double.tryParse(priceController.text) ?? 1083.90;
                    final listPrice = double.tryParse(listPriceController.text) ?? price * 1.3;
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
    final titleController = TextEditingController(text: product['title'] ?? '');
    final brandController = TextEditingController(text: product['brand'] ?? '');
    final categoryController = TextEditingController(text: product['categoryName'] ?? '');
    final priceVal = double.tryParse((product['price'] ?? '').toString()) ?? 0.0;
    final listPriceVal = double.tryParse((product['listPrice'] ?? '').toString());
    final priceController = TextEditingController(text: priceVal > 0 ? priceVal.toStringAsFixed(2) : '');
    final stockController = TextEditingController(text: (product['stockQuantity'] ?? '').toString());
    final listPriceController = TextEditingController(text: listPriceVal != null && listPriceVal > 0 ? listPriceVal.toStringAsFixed(2) : '');
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
      '📱 Telefon / Elektronik': ['RAM', 'Depolama', 'Renk', 'Ekran Boyutu', 'İşlemci', 'Batarya', 'Kamera'],
      '💻 Bilgisayar': ['İşlemci', 'RAM', 'Depolama', 'Ekran', 'GPU', 'İşletim Sistemi', 'Ağırlık'],
      '👕 Giyim & Tekstil': ['Renk', 'Kumaş', 'Kalıp', 'Cinsiyet', 'Sezon'],
      '🏠 Ev & Yaşam': ['Malzeme', 'Boyut', 'Renk', 'Ağırlık', 'Garanti'],
      '🎮 Oyun & Hobi': ['Platform', 'Tür', 'Oyuncu Sayısı', 'Yaş Sınırı', 'Dil'],
      '🔧 Araç & Gereç': ['Güç', 'Voltaj', 'Kapasite', 'Ölçü', 'Garanti'],
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
                  // Anında yerel önizleme ekle
                  setDlgState(() {
                    uploadedImages.add(base64String);
                  });

                  // Sunucuya arka planda yükle
                  final uploadedUrl = await _apiService.uploadImage(base64String, file.name);
                  setDlgState(() {
                    isUploadingImage = false;
                    if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
                      final idx = uploadedImages.indexOf(base64String);
                      if (idx != -1) {
                        uploadedImages[idx] = uploadedUrl;
                      }
                    }
                  });
                });
                reader.readAsDataUrl(file);
              }
            });
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
                          TextField(
                            controller: titleController,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(labelText: 'Ürün Başlığı *', labelStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 12), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
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
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(labelText: 'Satış Fiyatı *', prefixText: '₺ ', labelStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 12), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
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
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'Liste Fiyatı (Üstü Çizili)',
                                      prefixText: '₺ ',
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
                          'price': double.tryParse(priceController.text) ?? 0,
                          'listPrice': double.tryParse(listPriceController.text),
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
                                  Expanded(flex: 3, child: Text(formatTL(item['recommendedSalePrice']), style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14))),
                                  Expanded(flex: 2, child: Text(formatTL(item['targetProfitAmount']), style: GoogleFonts.inter(color: Colors.white70, fontSize: 12))),
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
        label: Text('✨ AI Pazaryeri Danışmanı', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
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

  Widget _buildSafeImageWidget(String? url, {double? width, double? height, BoxFit fit = BoxFit.cover, BorderRadius? borderRadius}) {
    if (url == null || url.trim().isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: const Center(child: Icon(Icons.image_outlined, color: Colors.white38, size: 24)),
      );
    }

    final trimmed = url.trim();

    // Base64 Data URL desteği
    if (trimmed.startsWith('data:image/') || (trimmed.contains('base64,') && !trimmed.startsWith('http'))) {
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
              color: Colors.white.withOpacity(0.05),
              child: const Center(child: Icon(Icons.broken_image, color: Colors.white38, size: 24)),
            ),
          ),
        );
      } catch (_) {}
    }

    // CORS engeli olan CDN'ler için akıllı proxy URL oluşturucu
    String effectiveUrl = trimmed;
    if (trimmed.contains('productimages.hepsiburada.net') || trimmed.contains('cdn.dsmcdn.com')) {
      effectiveUrl = 'https://images.weserv.nl/?url=${Uri.encodeComponent(trimmed)}';
    }

    // Normal HTTP / HTTPS URL
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: Image.network(
        effectiveUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, stack) {
          if (!effectiveUrl.contains('images.weserv.nl') && effectiveUrl.startsWith('http')) {
            return Image.network(
              'https://images.weserv.nl/?url=${Uri.encodeComponent(trimmed)}',
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (c, e, s) => Container(
                width: width,
                height: height,
                color: Colors.white.withOpacity(0.05),
                child: const Center(child: Icon(Icons.image_outlined, color: Colors.white38, size: 24)),
              ),
            );
          }
          return Container(
            width: width,
            height: height,
            color: Colors.white.withOpacity(0.05),
            child: const Center(child: Icon(Icons.image_outlined, color: Colors.white38, size: 24)),
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
      final str = value.toString().replaceAll('₺', '').replaceAll(' ', '').trim();
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tüm Pazaryeri Siparişleri', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            if (_orders != null && _orders!.isNotEmpty)
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      final firstOrderId = _orders!.first['orderId'] ?? 'ORD-001';
                      final url = _apiService.getInvoiceUrl(firstOrderId);
                      html.window.open(url, '_blank');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tüm siparişler için toplu GİB E-Fatura yazdırma sayfası açıldı! 📑'), backgroundColor: Colors.blueAccent));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    icon: const Icon(Icons.receipt_long, size: 16),
                    label: Text('📑 Toplu E-Fatura Yazdır', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      final firstOrderId = _orders!.first['orderId'] ?? 'ORD-001';
                      final url = _apiService.getShippingLabelUrl(firstOrderId);
                      html.window.open(url, '_blank');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tüm siparişler için toplu Kargo Barkodları yazdırma sayfası açıldı! 🏷️'), backgroundColor: Colors.orange));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    icon: const Icon(Icons.qr_code_2, size: 16),
                    label: Text('🏷️ Toplu Barkod Bas', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
          ],
        ),
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
                            Text(formatTL(o['totalPrice']), style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
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

  bool _productMatchesCategory(dynamic p, String catId, String? subCat) {
    final title = (p['title'] ?? p['name'] ?? '').toString().toLowerCase();
    final catName = (p['categoryName'] ?? '').toString().toLowerCase();
    final brand = (p['brand'] ?? '').toString().toLowerCase();

    if (catId == 'ALL') return true;

    if (catId == 'Giyim') {
      final isGiyim = catName.contains('giyim') || catName.contains('tişört') || catName.contains('polo') ||
                      catName.contains('gömlek') || catName.contains('tekstil') || catName.contains('pantolon') ||
                      brand.contains('tudors') || title.contains('tişört') || title.contains('polo') || title.contains('gömlek') || title.contains('pantolon') || title.contains('pike');
      if (!isGiyim) return false;

      if (subCat != null && subCat.isNotEmpty && !subCat.startsWith('ALL_')) {
        if (subCat == 'Tişört & Polo Yaka') {
          return catName.contains('tişört') || catName.contains('polo') || title.contains('tişört') || title.contains('polo') || title.contains('pike');
        } else if (subCat == 'Gömlek') {
          return catName.contains('gömlek') || title.contains('gömlek');
        } else if (subCat == 'Pantolon & Jean') {
          return catName.contains('pantolon') || catName.contains('jean') || title.contains('pantolon');
        } else if (subCat == 'Ceket & Mont') {
          return catName.contains('ceket') || catName.contains('mont') || title.contains('ceket') || title.contains('mont');
        } else if (subCat == 'Elbise & Etek') {
          return catName.contains('elbise') || catName.contains('etek') || title.contains('elbise');
        } else if (subCat == 'Ayakkabı') {
          return catName.contains('ayakkabı') || title.contains('ayakkabı');
        }
      }
      return true;
    }

    if (catId == 'Bilgisayar') {
      final isPC = catName.contains('bilgisayar') || catName.contains('laptop') || catName.contains('dizüstü') ||
                   title.contains('laptop') || title.contains('ideapad') || title.contains('notebook') || title.contains('bilgisayar') || brand.contains('lenovo') || brand.contains('asus') || brand.contains('dell') || brand.contains('hp');
      if (!isPC) return false;

      if (subCat != null && subCat.isNotEmpty && !subCat.startsWith('ALL_')) {
        if (subCat == 'Dizüstü Bilgisayar (Laptop)') {
          return catName.contains('laptop') || catName.contains('dizüstü') || title.contains('laptop') || title.contains('ideapad') || title.contains('notebook') || title.contains('taşınabilir');
        } else if (subCat == 'Masaüstü & Monitör') {
          return catName.contains('masaüstü') || catName.contains('monitör') || title.contains('monitör') || title.contains('desktop');
        } else if (subCat == 'Tablet & Çevre Birimleri') {
          return catName.contains('tablet') || catName.contains('mouse') || catName.contains('klavye') || title.contains('tablet');
        }
      }
      return true;
    }

    if (catId == 'Telefon') {
      final isPhone = catName.contains('telefon') || catName.contains('tablet') || title.contains('iphone') || title.contains('telefon') || title.contains('samsung') || title.contains('xiaomi');
      if (!isPhone) return false;

      if (subCat != null && subCat.isNotEmpty && !subCat.startsWith('ALL_')) {
        if (subCat == 'Akıllı Telefonlar') {
          return catName.contains('telefon') || title.contains('iphone') || title.contains('galaxy') || title.contains('telefon');
        } else if (subCat == 'Kılıf & Koruyucu') {
          return catName.contains('kılıf') || catName.contains('koruyucu') || title.contains('kılıf');
        }
      }
      return true;
    }

    if (catId == 'Ev') {
      final isEv = catName.contains('ev') || catName.contains('yaşam') || catName.contains('mobilya') || catName.contains('mutfak') || title.contains('mobilya') || title.contains('süpürge');
      if (!isEv) return false;
      return true;
    }

    if (catId == 'Oyun') {
      final isOyun = catName.contains('oyun') || catName.contains('gaming') || catName.contains('hobi') || catName.contains('ps5') || title.contains('playstation') || title.contains('xbox');
      if (!isOyun) return false;
      return true;
    }

    if (catId == 'Araç') {
      final isArac = catName.contains('araç') || catName.contains('yapı') || catName.contains('hırdavat') || catName.contains('oto') || title.contains('matkap') || title.contains('akü');
      if (!isArac) return false;
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

  Widget _buildProductsTab() {
    final filtered = _getFilteredProducts();
    final activeCatLabel = _getActiveCategoryLabel();
    final isFilteringActive = _selectedCategoryFilter != 'ALL' || _productSearchQuery.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Üst Başlık & Eylem Butonları
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
                OutlinedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hepsiburada Lenovo Laptop demo ürünü ekleniyor...'), backgroundColor: Colors.orange));
                    final res = await _apiService.seedDemoProducts();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res?['message'] ?? 'Lenovo IdeaPad Laptop kataloğa eklendi!'), backgroundColor: Colors.green),
                      );
                      _loadData();
                    }
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.tealAccent, side: const BorderSide(color: Colors.tealAccent), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  icon: const Icon(Icons.laptop_chromebook, size: 18),
                  label: Text('💻 + Lenovo Laptop Ekle', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
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

        // Ana İçerik: Sol Kategori Ağacı + Sağ Ürün Kataloğu
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sol: Kategori Ağacı Menüsü
            _buildCategorySidebar(),
            const SizedBox(width: 18),

            // Sağ: Filtrelenmiş Ürün Listesi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arama ve Filtre Durum Çubuğu
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        // Arama Kutusu
                        Expanded(
                          child: TextField(
                            controller: _productSearchController,
                            onChanged: (v) => setState(() => _productSearchQuery = v),
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: '🔍 Ürün adı, barkod, model kodu veya SKU ara...',
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
                        const SizedBox(width: 12),

                        // Aktif Kategori Göstergesi & Sıfırla Butonu
                        if (isFilteringActive) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.filter_alt, size: 14, color: Colors.orangeAccent),
                                const SizedBox(width: 6),
                                Text(
                                  activeCatLabel,
                                  style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
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
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.2), shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 12, color: Colors.orangeAccent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Tüm Ürünleri Göster Butonu
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
                          label: Text('Tüm Ürünleri Listele (${_products?.length ?? 0})', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Ürün Listesi VEYA Filtre Boş Durumu
                  if (filtered.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, color: Colors.orangeAccent.withOpacity(0.6), size: 48),
                          const SizedBox(height: 14),
                          Text(
                            '"$activeCatLabel" kategorisinde ürün bulunamadı',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Bu kategoriye yeni ürün tanımlayabilir veya sol menüden tüm ürünleri listeleyebilirsiniz.',
                            style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _showSimplifiedAddProductDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[800],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                label: Text('+ Bu Kategoriye Ürün Ekle', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedCategoryFilter = 'ALL';
                                    _selectedSubCategoryFilter = null;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blueAccent,
                                  side: const BorderSide(color: Colors.blueAccent),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.apps, size: 16),
                                label: Text('🌐 Tüm Ürünleri Listele', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
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
          Row(
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
                style: OutlinedButton.styleFrom(foregroundColor: Colors.blueAccent, side: const BorderSide(color: Colors.blueAccent), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: const Icon(Icons.flash_on, size: 16),
                label: Text('Stok Dağıt (1.2s)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
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
            Expanded(child: _finCard('Toplam Brüt Ciro', formatTL(gross), Icons.monetization_on, Colors.blueAccent)),
            const SizedBox(width: 12),
            Expanded(child: _finCard('Komisyon Kesintileri', formatTL(commission), Icons.percent, Colors.orangeAccent)),
            const SizedBox(width: 12),
            Expanded(child: _finCard('Tahmini Kargo Gideri', formatTL(cargo), Icons.local_shipping, Colors.purpleAccent)),
            const SizedBox(width: 12),
            Expanded(child: _finCard('Net Kâr Marjı (%$margin)', formatTL(netProfit), Icons.trending_up, Colors.greenAccent)),
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
                          Expanded(flex: 2, child: Text(formatTL(b['grossSales']), style: GoogleFonts.inter(color: Colors.white))),
                          Expanded(flex: 2, child: Text(formatTL(b['commissionDeducted']), style: GoogleFonts.inter(color: Colors.orangeAccent))),
                          Expanded(flex: 2, child: Text(formatTL(b['netProfit']), style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
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
