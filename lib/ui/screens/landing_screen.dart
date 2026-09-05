import 'package:flutter/material.dart';
import 'package:frontend/data/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _marketplacesKey = GlobalKey();
  final GlobalKey _mobileAppKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  bool _isAnnualPricing = true;

  // AI Danışman State
  final _apiService = ApiService();
  final List<Map<String, dynamic>> _aiMessages = [];
  final Set<String> _askedPrompts = {};
  bool _isAiThinking = false;
  bool _isAiFabMinimized = false;
  final TextEditingController _aiInputController = TextEditingController();
  final ScrollController _aiScrollController = ScrollController();

  Future<void> _launchSafeUrl(String urlStr) async {
    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _initAiGreeting() {
    if (_aiMessages.isEmpty) {
      _aiMessages.add({
        'role': 'assistant',
        'content': 'Merhaba! Ben sizin **RoaTech AI Danışmanınızım**. 🤖\n\nRoaTech\'in 30 gün ücretsiz deneme imkanı (3 pazaryeri ve 50 ürün kotası), 1.2s anlık stok eşitleme, 2 Al 1 Öde kampanya kurguları ve Trendyol/Hepsiburada entegrasyonu hakkında merak ettiğiniz her şeyi bana sorabilirsiniz.',
        'actions': [
          {'label': '🎁 1 Ay Ücretsiz Deneme Nedir?', 'action': 'ask', 'prompt': '1 Ay ücretsiz deneme paketi neleri kapsıyor?'},
          {'label': '🔥 2 Al 1 Öde Nasıl Çalışır?', 'action': 'ask', 'prompt': '2 Al 1 Öde kampanyaları nasıl çalışıyor?'},
          {'label': '⚡ 1.2s Stok Eşitleme Nedir?', 'action': 'ask', 'prompt': 'Stok senkronizasyonu nasıl çalışır?'},
          {'label': '🚀 Hemen Ücretsiz Başla', 'action': 'go_register', 'prompt': ''},
          {'label': '📞 Müşteri Temsilcisine Bağlan', 'action': 'open_support_channels', 'prompt': ''},
        ]
      });
    }
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
                        child: const Icon(Icons.email_outlined, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('E-Posta Destek Talebi', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('destek@roatech.com (Maks. 15 dk dönüş)', style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
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

  void _showAiConsultantDialog() {
    _initAiGreeting();
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
            if (actionType == 'go_register') {
              Navigator.pop(ctx);
              context.go('/register');
            } else if (actionType == 'go_login') {
              Navigator.pop(ctx);
              context.go('/login');
            } else if (actionType == 'open_support_channels') {
              _showCustomerSupportDialog();
            } else if (actionType == 'open_whatsapp_support') {
              _launchSafeUrl('https://wa.me/905550000000?text=Merhaba,%20RoaTech%20hakkında%20bilgi%20almak%20istiyorum');
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
                          Text('Online & Size Rehberlik Etmeye Hazır', style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 11)),
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
                                    Text('Yapay Zeka düşünüyor ve yanıt hazırlıyor...', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _aiInputController,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Bir soru sorun... (Örn: 1 Ay ücretsiz deneme nedir?)',
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

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        alignment: 0.08,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      floatingActionButton: (_isAiFabMinimized || isMobile)
          ? FloatingActionButton(
              heroTag: 'ai_landing_fab_minimized',
              onPressed: () {
                _showAiConsultantDialog();
              },
              backgroundColor: Colors.purple.shade800,
              tooltip: '✨ RoaTech AI Danışmanı (Açmak için tıklayın)',
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
                    onTap: _showAiConsultantDialog,
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
                          const SizedBox(width: 8),
                          Text('✨ RoaTech AI Danışmanı', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
      backgroundColor: const Color(0xFF0A1118),
      body: Stack(
        children: [
          Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            interactive: true,
            thickness: 8,
            radius: const Radius.circular(8),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    _buildHeroSection(),
                    const SizedBox(height: 60),
                    _buildMarketplacesSection(key: _marketplacesKey),
                    const SizedBox(height: 80),
                    _buildFeaturesSection(key: _featuresKey),
                    const SizedBox(height: 80),
                    _buildMobileAppSection(key: _mobileAppKey),
                    const SizedBox(height: 80),
                    _buildHowItWorksSection(key: _howItWorksKey),
                    const SizedBox(height: 80),
                    _buildPricingSection(key: _pricingKey),
                    const SizedBox(height: 80),
                    _buildFaqSection(key: _faqKey),
                    const SizedBox(height: 80),
                    _buildCtaBanner(),
                    const SizedBox(height: 60),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildNavbar()),
        ],
      ),
    );
  }

  Widget _buildNavbar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1050;
    final isTablet = screenWidth > 700 && screenWidth <= 1050;
    final isSmallMobile = screenWidth < 420;
    final isUltraSmallMobile = screenWidth < 360;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop || isTablet ? 24 : (isUltraSmallMobile ? 8 : 14),
        vertical: isUltraSmallMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1118).withOpacity(0.96),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Row(
            children: [
              // Logo & Marka Adı
              InkWell(
                onTap: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/roatech_emblem.png',
                      width: isUltraSmallMobile ? 26 : 32,
                      height: isUltraSmallMobile ? 26 : 32,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.hub, color: Colors.cyanAccent, size: 18),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Roatech',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: isUltraSmallMobile ? 15 : 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.0,
                          ),
                        ),
                        if (!isUltraSmallMobile) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Pazaryeri Entegrasyon',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF38BDF8),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Menü Linkleri & Butonlar
              if (isDesktop) ...[
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _navButton('Özellikler', () => _scrollTo(_featuresKey)),
                        _navButton('Pazaryerleri', () => _scrollTo(_marketplacesKey)),
                        _navButton('Mobil Uygulama', () => _scrollTo(_mobileAppKey)),
                        _navButton('Nasıl Çalışır?', () => _scrollTo(_howItWorksKey)),
                        _navButton('Fiyatlandırma', () => _scrollTo(_pricingKey)),
                        _navButton('SSS', () => _scrollTo(_faqKey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text('Giriş Yap', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('1 Ay Ücretsiz Başla', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ] else if (isTablet) ...[
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text('Giriş Yap', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('1 Ay Ücretsiz Başla', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 6),
                _buildMobileMenuButton(),
              ] else ...[
                // Mobil Cihazlar (< 700px)
                if (isUltraSmallMobile) ...[
                  // 344px vb. çok dar ekranlar
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Giriş Yap', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.5)),
                  ),
                ] else if (isSmallMobile) ...[
                  // 360px - 420px
                  TextButton(
                    onPressed: () => context.go('/login'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Giriş', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Ücretsiz Başla', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.5)),
                  ),
                ] else ...[
                  // 420px - 700px
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text('Giriş Yap', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12.5)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                    child: Text('1 Ay Ücretsiz Başla', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.5)),
                  ),
                ],
                const SizedBox(width: 4),
                _buildMobileMenuButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMenuButton() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: const Icon(Icons.menu, color: Colors.white70, size: 18),
      ),
      color: const Color(0xFF0F172A),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white12),
      ),
      offset: const Offset(0, 45),
      onSelected: (val) {
        if (val == 'features') _scrollTo(_featuresKey);
        else if (val == 'marketplaces') _scrollTo(_marketplacesKey);
        else if (val == 'mobile') _scrollTo(_mobileAppKey);
        else if (val == 'how_it_works') _scrollTo(_howItWorksKey);
        else if (val == 'pricing') _scrollTo(_pricingKey);
        else if (val == 'faq') _scrollTo(_faqKey);
        else if (val == 'login') context.go('/login');
      },
      itemBuilder: (context) => [
        _buildPopupMenuItem('features', 'Özellikler', Icons.star_border),
        _buildPopupMenuItem('marketplaces', 'Pazaryerleri (22+)', Icons.storefront),
        _buildPopupMenuItem('mobile', 'Mobil Uygulama', Icons.phone_iphone),
        _buildPopupMenuItem('how_it_works', 'Nasıl Çalışır?', Icons.help_outline),
        _buildPopupMenuItem('pricing', 'Fiyatlandırma', Icons.sell_outlined),
        _buildPopupMenuItem('faq', 'SSS', Icons.question_answer_outlined),
        const PopupMenuDivider(height: 1),
        _buildPopupMenuItem('login', 'Giriş Yap & Kayıt Ol', Icons.login, isHighlight: true),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, String title, IconData icon, {bool isHighlight = false}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: isHighlight ? Colors.blueAccent : Colors.white60),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              color: isHighlight ? Colors.blueAccent : Colors.white,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextButton(onPressed: onTap, child: Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14))),
    );
  }

  Widget _buildHeroSection() {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on, color: Colors.blueAccent, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      isMobile ? '⚡ 1.2sn Anlık Senkronizasyon' : '2026 Nesil Entegrasyon Motoru — 1.2sn Senkronizasyon',
                      style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: isMobile ? 11.5 : 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pazaryeri Kaosuna Son:\nTüm Satışları, Stokları ve Kargoları Tek Panelden Yönetin.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white, fontSize: isMobile ? 28 : 46, fontWeight: FontWeight.w900, height: 1.15, letterSpacing: -1),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Text(
                  'Trendyol, Hepsiburada, Amazon, N11, Teknosa, Koçtaş, MediaMarkt, FLO, Pasaj ve 22+ büyük pazaryeri siparişlerinizi tek merkezde toplayın. 30 gün boyunca kredi kartsız tamamen ücretsiz deneyin.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 16, height: 1.6),
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.rocket_launch, size: 18),
                    label: Text('1 Ay (30 Gün) Ücretsiz Başla', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.login, size: 18),
                    label: Text('Mağazama Giriş Yap', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 24,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _microTrustItem('30 Gün Kredi Kartsız Deneme'),
                  _microTrustItem('3 Pazaryeri & 50 Ürün Kotası'),
                  _microTrustItem('%100 Çift Satış Koruması'),
                  _microTrustItem('90 Saniyede Kurulum'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _microTrustItem(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
      ],
    );
  }

  Widget _buildMarketplacesSection({required GlobalKey key}) {
    final marketplaces = [
      {'name': 'Trendyol', 'color': const Color(0xFFF27A1A), 'logoUrl': 'https://logo.clearbit.com/trendyol.com', 'initials': 'TY'},
      {'name': 'Hepsiburada', 'color': const Color(0xFFFF6000), 'logoUrl': 'https://logo.clearbit.com/hepsiburada.com', 'initials': 'HB'},
      {'name': 'N11', 'color': const Color(0xFF5E17EB), 'logoUrl': 'https://logo.clearbit.com/n11.com', 'initials': 'N11'},
      {'name': 'Amazon', 'color': const Color(0xFFFF9900), 'logoUrl': 'https://logo.clearbit.com/amazon.com.tr', 'initials': 'AMZ'},
      {'name': 'ÇiçekSepeti', 'color': const Color(0xFFE91E63), 'logoUrl': 'https://logo.clearbit.com/ciceksepeti.com', 'initials': 'ÇS'},
      {'name': 'Pazarama', 'color': const Color(0xFF0066FF), 'logoUrl': 'https://logo.clearbit.com/pazarama.com', 'initials': 'PZ'},
      {'name': 'PttAVM', 'color': const Color(0xFFFFCC00), 'logoUrl': 'https://logo.clearbit.com/pttavm.com', 'initials': 'PTT'},
      {'name': 'Akakçe', 'color': const Color(0xFF00A3E0), 'logoUrl': 'https://logo.clearbit.com/akakce.com', 'initials': 'AKK'},
      {'name': 'IdeaSoft', 'color': const Color(0xFF00A859), 'logoUrl': 'https://logo.clearbit.com/ideasoft.com.tr', 'initials': 'IDS'},
      {'name': 'T-Soft', 'color': const Color(0xFFE53935), 'logoUrl': 'https://logo.clearbit.com/tsoft.com.tr', 'initials': 'TSF'},
      {'name': 'Etsy', 'color': const Color(0xFFF56400), 'logoUrl': 'https://logo.clearbit.com/etsy.com', 'initials': 'ETSY'},
      {'name': 'Ozon', 'color': const Color(0xFF005BFF), 'logoUrl': 'https://logo.clearbit.com/ozon.ru', 'initials': 'OZN'},
      {'name': 'Teknosa', 'color': const Color(0xFF0055A5), 'logoUrl': 'https://logo.clearbit.com/teknosa.com', 'initials': 'TKN'},
      {'name': 'Koçtaş', 'color': const Color(0xFFFF6600), 'logoUrl': 'https://logo.clearbit.com/koctas.com.tr', 'initials': 'KÇT'},
      {'name': 'MediaMarkt', 'color': const Color(0xFFDF0000), 'logoUrl': 'https://logo.clearbit.com/mediamarkt.com.tr', 'initials': 'MM'},
      {'name': 'Turkcell Pasaj', 'color': const Color(0xFFFFC72C), 'logoUrl': 'https://logo.clearbit.com/turkcell.com.tr', 'initials': 'PSJ'},
      {'name': 'FLO', 'color': const Color(0xFFFF5000), 'logoUrl': 'https://logo.clearbit.com/flo.com.tr', 'initials': 'FLO'},
      {'name': 'Modanisa', 'color': const Color(0xFFD81B60), 'logoUrl': 'https://logo.clearbit.com/modanisa.com', 'initials': 'MDN'},
      {'name': 'İdefix', 'color': const Color(0xFF0088CC), 'logoUrl': 'https://logo.clearbit.com/idefix.com', 'initials': 'İDF'},
      {'name': 'Vodafone', 'color': const Color(0xFFE60000), 'logoUrl': 'https://logo.clearbit.com/vodafone.com.tr', 'initials': 'VF'},
      {'name': 'Beymen', 'color': const Color(0xFF9E9E9E), 'logoUrl': 'https://logo.clearbit.com/beymen.com', 'initials': 'BYM'},
      {'name': 'LC Waikiki', 'color': const Color(0xFF003399), 'logoUrl': 'https://logo.clearbit.com/lcwaikiki.com', 'initials': 'LCW'},
      {'name': 'Boyner', 'color': const Color(0xFF00897B), 'logoUrl': 'https://logo.clearbit.com/boyner.com.tr', 'initials': 'BYN'},
      {'name': 'Sahibinden', 'color': const Color(0xFFFFD200), 'logoUrl': 'https://logo.clearbit.com/sahibinden.com', 'initials': 'SHB'},
      {'name': 'Farmazon', 'color': const Color(0xFF00B16A), 'logoUrl': 'https://logo.clearbit.com/farmazon.com.tr', 'initials': 'FRM'},
      {'name': 'Cimri', 'color': const Color(0xFF00A859), 'logoUrl': 'https://logo.clearbit.com/cimri.com', 'initials': 'CMR'},
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 1150 ? 3 : (screenWidth > 720 ? 2 : 1);

    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
              child: Text(
                'PAZARYERİ VE E-TİCARET ENTEGRASYONLARI',
                style: GoogleFonts.inter(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Tüm Satış Kanallarınızla Tam Otomatik Entegrasyon',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tek tıkla bağlanın, stoklarınızı ve siparişlerinizi ışık hızında yönetin',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 15),
            ),
            const SizedBox(height: 40),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 18,
                childAspectRatio: screenWidth > 1150 ? 2.8 : (screenWidth > 720 ? 2.6 : 2.5),
              ),
              itemCount: marketplaces.length,
              itemBuilder: (context, index) {
                final m = marketplaces[index];
                final color = m['color'] as Color;
                final name = m['name'] as String;
                final logoUrl = m['logoUrl'] as String;
                final initials = m['initials'] as String;

                return InkWell(
                  onTap: () => _showMarketplaceDetailModal(m),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Sol Taraf: Marka Adı ve ENTEGRASYONU (Referans Görsel Birebir Tasarım)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name.toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 0.8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ENTEGRASYONU',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Sağ Taraf: 3D Kıvrımlı Sticker Logo Rozeti (Peeled Sticker Badge)
                        _PeeledStickerBadge(
                          logoUrl: logoUrl,
                          initials: initials,
                          brandColor: color,
                          size: 64,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
  }

  void _showMarketplaceDetailModal(Map<String, dynamic> m) {
    final name = m['name'] as String;
    final color = m['color'] as Color;
    final logoUrl = m['logoUrl'] as String;
    final initials = m['initials'] as String;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
        ),
        title: Row(
          children: [
            _PeeledStickerBadge(
              logoUrl: logoUrl,
              initials: initials,
              brandColor: color,
              size: 52,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name Entegrasyonu',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    'Tam Otomatik Bulut Senkronizasyonu',
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailFeatureRow(Icons.bolt, '1.2 Saniye Anlık Stok & Fiyat Eşitleme'),
            const SizedBox(height: 10),
            _buildDetailFeatureRow(Icons.receipt_long, 'Tek Tıkla Kargo Barkodu & E-Fatura'),
            const SizedBox(height: 10),
            _buildDetailFeatureRow(Icons.calculate, 'Akıllı Komisyon & Kâr Robotu Desteği'),
            const SizedBox(height: 10),
            _buildDetailFeatureRow(Icons.shield_outlined, 'Fiyat Koruma Kalkanı (0 TL / Zarar Önleyici)'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'RoaTech ile $name mağazanızı 90 saniyede bağlayabilir, 30 gün boyunca tamamen ücretsiz deneyebilirsiniz.',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.4),
              ),

            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Kapat', style: GoogleFonts.inter(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/login');
            },
            icon: const Icon(Icons.rocket_launch, size: 16),
            label: Text('30 Gün Ücretsiz Başla', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.greenAccent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }




  Widget _buildFeaturesSection({required GlobalKey key}) {
    final features = [
      {'icon': Icons.flash_on, 'color': Colors.blueAccent, 'title': 'Işık Hızında Stok Senkronizasyonu', 'desc': 'Bir pazaryerinde satış gerçekleştiği an, kalan tüm mağazalarınızdaki stok 1.2 saniye içinde otomatik eşitlenir. Çift satış ve ceza puanına son.'},
      {'icon': Icons.calculate_outlined, 'color': Colors.orangeAccent, 'title': 'Akıllı Komisyon & Fiyatlandırma', 'desc': 'Her pazaryerinin komisyon oranını ve kargo baremlerini otomatik hesaplayın. Maliyetinizi girin, sistem en kârlı satış fiyatını belirlesin.'},
      {'icon': Icons.receipt_long_outlined, 'color': Colors.greenAccent, 'title': 'Tek Tıkla Toplu E-Fatura & Barkod', 'desc': 'Yüzlerce farklı sipariş için tek tek fatura kesmeyin. Pazaryeri kargo barkodlarını ve e-faturalarınızı tek tuşla yazdırın.'},
      {'icon': Icons.analytics_outlined, 'color': Colors.purpleAccent, 'title': 'Gerçek Zamanlı Finans Analitiği', 'desc': 'Hangi ürün ne kadar net kâr bıraktı? Detaylı finans paneli ile işletmenizin gerçek net kârlılığını anlık izleyin.'},
    ];

    final isDesktop = MediaQuery.of(context).size.width > 750;

    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('NEDEN BİZ?', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Text('Satışlarınızı Büyütecek 4 Çekirdek Güç Modülü', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 36),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 2 : 1,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: isDesktop ? 1.8 : 1.3,
                ),
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final f = features[index];
                  final color = f['color'] as Color;
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(f['icon'] as IconData, color: color, size: 28)),
                        const SizedBox(height: 16),
                        Text(f['title'] as String, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(f['desc'] as String, style: GoogleFonts.inter(color: Colors.white60, fontSize: 14, height: 1.5), overflow: TextOverflow.fade),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileAppSection({required GlobalKey key}) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Container(
          padding: EdgeInsets.all(isDesktop ? 48 : 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 6, child: _buildMobileAppContent()),
                    const SizedBox(width: 48),
                    Expanded(flex: 5, child: _buildMobileAppMockup()),
                  ],
                )
              : Column(
                  children: [
                    _buildMobileAppContent(),
                    const SizedBox(height: 36),
                    _buildMobileAppMockup(),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileAppContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_iphone_rounded, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                'HEM ANDROİD HEM iOS İLE %100 UYUMLU',
                style: GoogleFonts.inter(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Pazaryeri Mağazanızı Cebinizden Yönetin:\nBarkod Tara, Bildirim Al, Yüzünle Giriş Yap',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.25,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Depoda ürün ararken, yoldayken veya tatildeyken bilgisayara bağlı kalmayın. RoaTech mobil uygulaması ile 22 pazaryerindeki tüm satışlarınız, siparişleriniz ve kargolarınız parmaklarınızın ucunda.',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 15, height: 1.6),
        ),

        const SizedBox(height: 28),

        // 4 Mobil Güç Özelliği
        _buildMobileFeatureItem(
          icon: Icons.qr_code_scanner,
          color: Colors.cyanAccent,
          title: 'Kamera ile Barkod / QR Okuma',
          desc: 'Depoda veya reyonda telefonunuzun kamerasıyla ürün barkodunu tarayın, stok ve fiyatları saniyeler içinde anında güncelleyin.',
        ),
        const SizedBox(height: 16),
        _buildMobileFeatureItem(
          icon: Icons.notifications_active_rounded,
          color: Colors.amberAccent,
          title: 'Anlık Push Bildirimleri (Firebase FCM)',
          desc: '"Yeni Sipariş Geldi!" veya "Kritik Stok Uyarısı!" telefonunuza anında sesli düşsün, hiçbir satışı kaçırmayın.',
        ),
        const SizedBox(height: 16),
        _buildMobileFeatureItem(
          icon: Icons.fingerprint_rounded,
          color: Colors.greenAccent,
          title: 'Biyometrik Giriş (Face ID & Parmak İzi)',
          desc: 'Her defasında uzun şifreler yazmaya son. Tek dokunuşla veya yüz tanıma ile 0.5 saniyede panelinize güvenle bağlanın.',
        ),
        const SizedBox(height: 16),
        _buildMobileFeatureItem(
          icon: Icons.sync_rounded,
          color: Colors.purpleAccent,
          title: '22 Pazaryeri Canlı Ciro & Kargo Takibi',
          desc: 'Trendyol, Hepsiburada, Amazon ve diğer tüm mağazalarınızın günlük cirosunu ve kargo paketlerini tek ekrandan izleyin.',
        ),

        const SizedBox(height: 32),

        // İndirme Butonları (Android & iOS)
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () => _launchSafeUrl('https://pazaryerleri.vercel.app/PazaryeriSaaS.apk'),
              icon: const Icon(Icons.android, color: Colors.white, size: 20),
              label: Text(
                'Android APK İndir (v2.0)',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
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
                        const Icon(Icons.apple, color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        Text('iOS / iPhone Desteği', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'iPhone ve iPad cihazlarınızda Safari tarayıcısı üzerinden:',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('1️⃣  Safari ile pazaryerleri.vercel.app adresini açın', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text('2️⃣  Alttaki "Paylaş" (Kare + Ok) simgesine basın', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text('3️⃣  "Ana Ekrana Ekle" seçeneğine dokunun', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '⚡ Uygulama ana ekranınıza ikon olarak eklenecek ve tam ekran mobil uygulama deneyimiyle açılacaktır.',
                          style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 12),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Anladım', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.apple, color: Colors.white, size: 22),
              label: Text(
                'iOS & iPhone Desteği',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white30, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Güvenlik Standardı: En üst düzey donanımsal şifreleme ile Android 9.0+ ve iOS 14+ tam desteklenir.',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileFeatureItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileAppMockup() {
    return Center(
      child: Container(
        width: 320,
        height: 580,
        decoration: BoxDecoration(
          color: const Color(0xFF0B0F19),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0xFF334155), width: 6),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.25),
              blurRadius: 35,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Column(
            children: [
              // Dynamic Island / Notch
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 90,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle)),
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF0F172A), shape: BoxShape.circle)),
                  ],
                ),
              ),

              // Mock App Screen Content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: const Color(0xFF0F172A),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/roatech_emblem.png',
                                width: 22,
                                height: 22,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.hub, color: Colors.cyanAccent, size: 18),
                              ),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Roatech', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, height: 1.0)),
                                  Text('Pazaryeri Entegrasyon', style: GoogleFonts.inter(color: const Color(0xFF38BDF8), fontSize: 7.5, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.fingerprint, color: Colors.greenAccent, size: 12),
                                const SizedBox(width: 4),
                                Text('Giriş Yapıldı', style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Camera Viewfinder Mockup
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.qr_code_scanner, color: Colors.cyanAccent, size: 16),
                                    const SizedBox(width: 6),
                                    Text('Kamera Barkod Okuyucu', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                  child: Text('CANLI', style: GoogleFonts.inter(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 140,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: Colors.cyanAccent,
                                        boxShadow: [
                                          BoxShadow(color: Colors.cyanAccent.withOpacity(0.8), blurRadius: 6),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Barkod: 8690123456789', style: GoogleFonts.inter(color: Colors.white70, fontSize: 9)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Notification Mockup
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.amberAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.shopping_cart_checkout, color: Colors.amberAccent, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('🔔 Yeni Sipariş • Trendyol', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text('#TY-90412 • ₺1.850,00', style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Text('Şimdi', style: GoogleFonts.inter(color: Colors.white38, fontSize: 9)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Live Sync Status
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.flash_on, color: Colors.blueAccent, size: 16),
                                const SizedBox(width: 6),
                                Text('22 Pazaryeri Senkron', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text('1.2s Eşitlendi', style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Home Bar
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                width: 120,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorksSection({required GlobalKey key}) {
    final steps = [
      {'step': '01', 'title': 'Mağazalarını Bağla', 'desc': 'API anahtarlarınızı girerek Trendyol, Hepsiburada ve diğer mağazalarınızı 90 saniyede ekleyin.'},
      {'step': '02', 'title': 'Ürünlerini Eşleştir', 'desc': 'Stok ve fiyatlarınızı tek tıkla merkezi kataloğunuzla eşleştirin veya içe aktarın.'},
      {'step': '03', 'title': 'Arkanıza Yaslanın', 'desc': 'Siparişler geldikçe stoklar tüm kanallarda otomatik eşitlensin, kargolar hazır olsun.'},
    ];

    final isWide = MediaQuery.of(context).size.width > 750;

    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('KOLAY KURULUM', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Text('3 Adımda Pazaryeri Satışlarınızı Otomatize Edin', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 36),
              isWide
                  ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: steps.map((s) => Expanded(child: _stepCard(s))).toList())
                  : Column(children: steps.map((s) => _stepCard(s)).toList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepCard(Map<String, String> s) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s['step']!, style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(s['title']!, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(s['desc']!, style: GoogleFonts.inter(color: Colors.white60, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPricingSection({required GlobalKey key}) {
    final isDesktop = MediaQuery.of(context).size.width > 850;
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('ŞEFFAF FİYATLANDIRMA', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Text('İşletmenizin Ölçeğine Uygun Planı Seçin', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Aylık Ödeme', style: GoogleFonts.inter(color: !_isAnnualPricing ? Colors.white : Colors.white60)),
                  Switch(value: _isAnnualPricing, activeColor: Colors.blueAccent, onChanged: (val) => setState(() => _isAnnualPricing = val)),
                  Text('Yıllık Ödeme (%30 İndirim)', style: GoogleFonts.inter(color: _isAnnualPricing ? Colors.greenAccent : Colors.white60, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 36),
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _pricingCard(title: 'Başlangıç (Starter)', price: _isAnnualPricing ? '₺159' : '₺199', desc: 'Yeni başlayan butik satıcılar ve esnaflar için', features: ['3 Pazaryeri Bağlantısı', '250 Ürün Kotası', 'Aylık 300 Sipariş', '1.2s Anlık Stok Senkronu', 'E-Posta Desteği'], isPopular: false)),
                        const SizedBox(width: 16),
                        Expanded(child: _pricingCard(title: 'Büyüme (Growth)', price: _isAnnualPricing ? '₺319' : '₺399', desc: 'Hızlı büyüyen ve çok kanallı mağazalar için', features: ['8 Pazaryeri (Tüm Platformlar)', '2.500 Ürün Kotası', 'Sınırsız Sipariş & Senkron', 'Akıllı Fiyat & Komisyon Robotu', 'AI Pazaryeri Danışmanı', 'Öncelikli Canlı Destek'], isPopular: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _pricingCard(title: 'Profesyonel (Pro)', price: _isAnnualPricing ? '₺639' : '₺799', desc: 'Yüksek hacimli markalar, üreticiler ve depolar', features: ['Sınırsız Pazaryeri & Çoklu Mağaza', '25.000+ Ürün Kotası', 'Sınırsız Sipariş & Eşitleme', 'Otomatik E-Fatura & Barkod', 'Logo / Mikro / ERP Entegrasyonu', '7/24 Özel Destek Hattı'], isPopular: false)),
                      ],
                    )
                  : Column(
                      children: [
                        _pricingCard(title: 'Başlangıç (Starter)', price: _isAnnualPricing ? '₺159' : '₺199', desc: 'Yeni başlayan butik satıcılar ve esnaflar için', features: ['3 Pazaryeri Bağlantısı', '250 Ürün Kotası', 'Aylık 300 Sipariş', '1.2s Anlık Stok Senkronu', 'E-Posta Desteği'], isPopular: false),
                        const SizedBox(height: 16),
                        _pricingCard(title: 'Büyüme (Growth)', price: _isAnnualPricing ? '₺319' : '₺399', desc: 'Hızlı büyüyen ve çok kanallı mağazalar için', features: ['8 Pazaryeri (Tüm Platformlar)', '2.500 Ürün Kotası', 'Sınırsız Sipariş & Senkron', 'Akıllı Fiyat & Komisyon Robotu', 'AI Pazaryeri Danışmanı', 'Öncelikli Canlı Destek'], isPopular: true),
                        const SizedBox(height: 16),
                        _pricingCard(title: 'Profesyonel (Pro)', price: _isAnnualPricing ? '₺639' : '₺799', desc: 'Yüksek hacimli markalar, üreticiler ve depolar', features: ['Sınırsız Pazaryeri & Çoklu Mağaza', '25.000+ Ürün Kotası', 'Sınırsız Sipariş & Eşitleme', 'Otomatik E-Fatura & Barkod', 'Logo / Mikro / ERP Entegrasyonu', '7/24 Özel Destek Hattı'], isPopular: false),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pricingCard({required String title, required String price, required String desc, required List<String> features, required bool isPopular}) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isPopular ? Colors.blueAccent.withOpacity(0.08) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPopular ? Colors.blueAccent : Colors.white12, width: isPopular ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(8)), child: Text('EN ÇOK TERCİH EDİLEN', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 6),
          Text(desc, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(price, style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              Text(' / ay', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [const Icon(Icons.check, color: Colors.blueAccent, size: 18), const SizedBox(width: 8), Expanded(child: Text(f, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)))]),
              )),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(backgroundColor: isPopular ? Colors.blueAccent : Colors.white12, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('30 Gün Ücretsiz Başla', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection({required GlobalKey key}) {
    final faqs = [
      {'q': 'Kurulum ne kadar sürer? Teknik bilgiye ihtiyacım var mı?', 'a': 'Hayır, hiçbir kodlama veya teknik bilgi gerekmez. Pazaryerlerinizden aldığınız API anahtarlarını panelimize girerek mağazalarınızı 90 saniye içinde bağlayabilirsiniz.'},
      {'q': 'Gerçekten çift satış (overselling) riskini engelliyor musunuz?', 'a': 'Evet. Gelişmiş Sync-Engine altyapımız, bir kanaldan sipariş düştüğü anda milisaniyeler seviyesinde diğer tüm platformlardaki stok miktarını günceller ve ceza puanı almanızı engeller.'},
      {'q': '1 aylık ücretsiz deneme süresinde kredi kartı girmem gerekir mi?', 'a': 'Kesinlikle hayır. Kredi kartı bilginizi girmeden 30 gün boyunca (3 pazaryeri ve 50 ürüne kadar) tüm özellikleri ücretsiz deneyebilirsiniz.'},
      {'q': 'Kullandığım muhasebe ve ERP programları ile entegre olabilir mi?', 'a': 'Platformumuz Paraşüt, Bizmu, Logo, Mikro, Zirve gibi tüm popüler ön muhasebe ve ERP yazılımlarıyla tam entegre çalışmaktadır.'},
    ];

    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('SIKÇA SORULAN SORULAR', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Text('Aklınıza Takılan Tüm Soruların Cevapları', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 36),
              ...faqs.map((faq) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
                    child: Material(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        shape: const RoundedRectangleBorder(),
                        collapsedShape: const RoundedRectangleBorder(),
                        iconColor: Colors.blueAccent,
                        collapsedIconColor: Colors.white60,
                        title: Text(faq['q']!, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                        children: [
                          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text(faq['a']!, style: GoogleFonts.inter(color: Colors.white60, fontSize: 14, height: 1.5))),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCtaBanner() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Bugün Başlayın, İlk Satışınızı 10 Dakika İçinde Otomatize Edin.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                Text('30 gün boyunca kredi kartsız ücretsiz deneyin. E-ticaret operasyonunuzu sıfır hata ile büyütün.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Hemen 1 Ay Ücretsiz Başla', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF070C12),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kolon 1: Şirket & Tanım (Misyon Bildirimi)
                        Expanded(flex: 4, child: _buildFooterBrandCol()),
                        const SizedBox(width: 48),
                        // Kolon 2: Kurumsal
                        Expanded(flex: 3, child: _buildFooterCorporateCol()),
                        const SizedBox(width: 32),
                        // Kolon 3: Entegrasyonlar
                        Expanded(flex: 3, child: _buildFooterIntegrationsCol()),
                        const SizedBox(width: 32),
                        // Kolon 4: Özellikler & Mobil
                        Expanded(flex: 3, child: _buildFooterFeaturesCol()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFooterBrandCol(),
                        const SizedBox(height: 36),
                        _buildFooterCorporateCol(),
                        const SizedBox(height: 32),
                        _buildFooterIntegrationsCol(),
                        const SizedBox(height: 32),
                        _buildFooterFeaturesCol(),
                      ],
                    ),
              const SizedBox(height: 48),
              const Divider(color: Colors.white12),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'RoaTech © 2026 Tüm Hakları Saklıdır. Türkiye\'nin En Gelişmiş Çoklu Kanal Pazaryeri ve E-Ticaret Entegrasyon Platformu.',
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, height: 1.4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('Tüm Sunucular Aktif', style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterBrandCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/roatech_emblem.png',
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hub, color: Colors.cyanAccent, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Roatech',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pazaryeri Entegrasyon & API',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF38BDF8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),
        Text(
          'RoaTech, pazaryerlerindeki mağazalarınız, e-Ticaret siteniz ve ERP/Muhasebe yazılımınızı birbirine bağlayan, tüm e-Ticaretinizi tek ekrandan yönetmenizi sağlayan bulut tabanlı bir entegrasyon yazılımıdır.',
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildTrustPill('🛡️ 256-Bit SSL'),
            _buildTrustPill('⚖️ KVKK Uyumlu'),
            _buildTrustPill('⚡ %99.9 Uptime'),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildFooterCorporateCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kurumsal', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 16),
        _buildFooterLink('Kullanıcı Sözleşmesi', () => _showLegalDialog('Kullanıcı Sözleşmesi', _userAgreementText)),
        _buildFooterLink('Gizlilik ve Çerez Politikası', () => _showLegalDialog('Gizlilik Politikası', _privacyPolicyText)),
        _buildFooterLink('KVKK Aydınlatma Metni', () => _showLegalDialog('KVKK Aydınlatma Metni', _kvkkText)),
        _buildFooterLink('Sık Sorulan Sorular', () => _scrollTo(_faqKey)),
        _buildFooterLink('Hakkımızda & Ekibimiz', () => _showLegalDialog('Hakkımızda', 'RoaTech, Türkiye ve global e-ticaret satıcılarının operasyonel yükünü sıfırlamak amacıyla geliştirilmiş yeni nesil çoklu kanal entegrasyon platformudur.')),
        _buildFooterLink('İletişim & Canlı AI Destek', () => _showAiConsultantDialog()),
      ],
    );
  }

  Widget _buildFooterIntegrationsCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Entegrasyonlar', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 16),
        _buildFooterLink('Trendyol Entegrasyonu', () => _scrollTo(_marketplacesKey)),
        _buildFooterLink('Hepsiburada Entegrasyonu', () => _scrollTo(_marketplacesKey)),
        _buildFooterLink('N11 & Amazon TR', () => _scrollTo(_marketplacesKey)),
        _buildFooterLink('ÇiçekSepeti & Pazarama', () => _scrollTo(_marketplacesKey)),
        _buildFooterLink('PTT AVM & Akakçe', () => _scrollTo(_marketplacesKey)),
        _buildFooterLink('IdeaSoft & T-Soft Köprüsü', () => _scrollTo(_marketplacesKey)),
        _buildFooterLink('26+ Tüm Kanalları Gör →', () => _scrollTo(_marketplacesKey)),
      ],
    );
  }

  Widget _buildFooterFeaturesCol() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Özellikler & Mobil', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 16),
        _buildFooterLink('1.2s Işık Hızında Stok Eşitleme', () => _scrollTo(_featuresKey)),
        _buildFooterLink('Akıllı Fiyat & Kâr Robotu', () => _scrollTo(_featuresKey)),
        _buildFooterLink('Toplu E-Fatura & Barkod', () => _scrollTo(_featuresKey)),
        _buildFooterLink('Android Mobil Uygulama (APK)', () => _scrollTo(_mobileAppKey)),
        _buildFooterLink('iOS & Safari PWA Desteği', () => _scrollTo(_mobileAppKey)),
        _buildFooterLink('Kamera Barkod & Face ID', () => _scrollTo(_mobileAppKey)),
      ],
    );
  }

  Widget _buildFooterLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 13, height: 1.4),
        ),
      ),
    );
  }

  void _showLegalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.blueAccent, width: 1.2),
        ),
        title: Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Kapat', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static const String _userAgreementText = '''
RoaTech Kullanıcı Sözleşmesi:
1. Hizmet Kapsamı: RoaTech, kullanıcıların birden fazla e-ticaret pazaryerindeki ürün, stok, fiyat ve sipariş verilerini senkronize etmelerini sağlar.
2. Veri Güvenliği: Kullanıcının girdiği API anahtarları 256-bit AES şifreleme standardı ile korunur ve üçüncü taraflarla paylaşılmaz.
3. 30 Gün Ücretsiz Deneme: Tüm yeni kayıtlar 30 gün boyunca kredi kartsız ücretsiz deneme hakkına sahiptir.
4. Hizmet Kesintisizliği: Sistem %99.9 çalışma süresi (uptime) hedefiyle bulut mimarisinde barındırılmaktadır.
''';

  static const String _privacyPolicyText = '''
Gizlilik ve Çerez Politikası:
1. RoaTech, kullanıcılarının kişisel bilgilerini ve mağaza verilerini en üst düzey şifreleme protokolleriyle muhafaza eder.
2. Çerezler yalnızca kullanıcı oturumunu aktif tutmak ve panel performansını artırmak amacıyla kullanılır.
3. Mağaza satış ve ciro verileriniz kesinlikle üçüncü parti reklam verenlerle paylaşılmaz.
''';

  static const String _kvkkText = '''
6698 Sayılı KVKK Kapsamında Aydınlatma Metni:
Kişisel verileriniz, 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) uyarınca, veri sorumlusu sıfatıyla RoaTech tarafından; üyelik işlemlerinin yürütülmesi, faturalandırma ve teknik destek hizmetlerinin sağlanması amaçlarıyla sınırlı olarak işlenmektedir.
''';
}



class _PeeledStickerBadge extends StatelessWidget {
  final String logoUrl;
  final String initials;
  final Color brandColor;
  final double size;

  const _PeeledStickerBadge({
    required this.logoUrl,
    required this.initials,
    required this.brandColor,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ana Dairesel Etiket (Metallic 3D Gradient & Shadow)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.25, -0.3),
                radius: 0.85,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF8FAFC),
                  Color(0xFFE2E8F0),
                  Color(0xFFCBD5E1),
                ],
                stops: [0.0, 0.45, 0.8, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.38),
                  blurRadius: 10,
                  offset: const Offset(3, 5),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.9),
                  blurRadius: 4,
                  offset: const Offset(-1, -1),
                ),
              ],
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Image.network(
                  logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.inter(
                          color: brandColor,
                          fontWeight: FontWeight.w900,
                          fontSize: size * 0.26,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Sağ Üst Kıvrık Köşe Efekti (Peeled / Folded Corner)
          Positioned(
            top: 0,
            right: 0,
            child: CustomPaint(
              size: Size(size * 0.38, size * 0.38),
              painter: _StickerPeelPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerPeelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Kıvrım altındaki gölge
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    final shadowPath = Path()
      ..moveTo(size.width * 0.15, 0)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.45, size.width, size.height * 0.85)
      ..lineTo(size.width * 0.75, size.height)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.65, 0, size.height * 0.15)
      ..close();
    canvas.drawPath(shadowPath, shadowPaint);

    // Kıvrılmış Etiket Arka Yüzeyi (Gümüş/Metalik Degradeli)
    final peelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFF1F5F9),
          Color(0xFFE2E8F0),
          Color(0xFF94A3B8),
          Color(0xFF64748B),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final peelPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.2, size.width * 0.9, size.height)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.45, size.width, 0)
      ..close();

    canvas.drawPath(peelPath, peelPaint);

    // Kıvrım Işıltı Çizgisi
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(peelPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}