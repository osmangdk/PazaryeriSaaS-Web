import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _marketplacesKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  bool _isAnnualPricing = true;

  void _scrollTo(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1118),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 80),
                _buildHeroSection(),
                const SizedBox(height: 60),
                _buildMarketplacesSection(key: _marketplacesKey),
                const SizedBox(height: 80),
                _buildFeaturesSection(key: _featuresKey),
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
          Positioned(top: 0, left: 0, right: 0, child: _buildNavbar()),
        ],
      ),
    );
  }

  Widget _buildNavbar() {
    final isDesktop = MediaQuery.of(context).size.width > 850;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1118).withOpacity(0.92),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.rocket_launch, color: Colors.blueAccent, size: 22),
                ),
                const SizedBox(width: 10),
                Text('PazaryeriSaaS', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              ],
            ),
          ),
          const Spacer(),
          if (isDesktop) ...[
            _navButton('Ozellikler', () => _scrollTo(_featuresKey)),
            _navButton('Pazaryerleri', () => _scrollTo(_marketplacesKey)),
            _navButton('Nasil Calisir?', () => _scrollTo(_howItWorksKey)),
            _navButton('Fiyatlandirma', () => _scrollTo(_pricingKey)),
            _navButton('SSS', () => _scrollTo(_faqKey)),
            const SizedBox(width: 20),
          ],
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text('Giris Yap', style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('14 Gun Ucretsiz Basla', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flash_on, color: Colors.blueAccent, size: 16),
                  const SizedBox(width: 8),
                  Text('2026 Nesil Entegrasyon Motoru - 1.2sn Senkronizasyon', style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pazaryeri Kaosuna Son:\nTum Satislari, Stoklari ve Kargolari Tek Panelden Yonetin.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white, fontSize: isMobile ? 28 : 46, fontWeight: FontWeight.w900, height: 1.15, letterSpacing: -1),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Text(
                'Trendyol, Hepsiburada, Amazon, N11, CicekSepeti, PttAVM, Boyner ve Pazarama siparislerinizi tek merkezde toplayin. Cift satis riskini sifirlayin, satislarinizi hizla buyutun.',
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
                  label: Text('14 Gun Ucretsiz Basla', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login, size: 18),
                  label: Text('Magazama Giris Yap', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
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
                _microTrustItem('90 Saniyede Kurulum'),
                _microTrustItem('Kredi Karti Gerekmez'),
                _microTrustItem('%100 Cift Satis Korumasi'),
                _microTrustItem('7/24 Kesintisiz Destek'),
              ],
            ),
          ],
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
      {'name': 'Trendyol', 'color': const Color(0xFFF27A1A), 'desc': 'V2 Urun, Stok & Siparis'},
      {'name': 'Hepsiburada', 'color': const Color(0xFFFF6000), 'desc': 'MPOP, Listing & OMS'},
      {'name': 'Amazon', 'color': const Color(0xFFFF9900), 'desc': 'SP-API Global & TR'},
      {'name': 'N11', 'color': const Color(0xFF5E2E91), 'desc': 'SOAP & REST Entegrasyon'},
      {'name': 'Pazarama', 'color': const Color(0xFF0066FF), 'desc': 'OAuth2 & Anlik Stok'},
      {'name': 'CicekSepeti', 'color': const Color(0xFFE91E63), 'desc': 'Bayi & Marketplace API'},
      {'name': 'PttAVM', 'color': const Color(0xFFFFB300), 'desc': 'REST & PTT Kargo'},
      {'name': 'Boyner', 'color': const Color(0xFF00897B), 'desc': 'Mirakl Seller API'},
    ];

    final isWide = MediaQuery.of(context).size.width > 800;

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            Text('DESTEKLENEN KANALLAR', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Text('Turkiye\'nin En Buyuk Pazaryerleri ile Tam Entegre', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 36),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
              ),
              itemCount: marketplaces.length,
              itemBuilder: (context, index) {
                final m = marketplaces[index];
                final color = m['color'] as Color;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.store, color: color, size: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(m['name'] as String, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(m['desc'] as String, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection({required GlobalKey key}) {
    final features = [
      {'icon': Icons.flash_on, 'color': Colors.blueAccent, 'title': 'Isik Hizinda Stok Senkronizasyonu', 'desc': 'Bir pazaryerinde satis gerceklestigi an, kalan tum magazalarinizdaki stok 1.2 saniye icinde otomatik esitlenir. Cift satis ve ceza puanina son.'},
      {'icon': Icons.calculate_outlined, 'color': Colors.orangeAccent, 'title': 'Akilli Komisyon & Fiyatlandirma', 'desc': 'Her pazaryerinin komisyon oranini ve kargo baremlerini otomatik hesaplayin. Maliyetinizi girin, sistem en karlý satis fiyatini belirlesin.'},
      {'icon': Icons.receipt_long_outlined, 'color': Colors.greenAccent, 'title': 'Tek Tikla Toplu E-Fatura & Barkod', 'desc': 'Yuzlerce farkli siparis icin tek tek fatura kesmeyin. Pazaryeri kargo barkodlarini ve e-faturalarinizi tek tusla yazdirin.'},
      {'icon': Icons.analytics_outlined, 'color': Colors.purpleAccent, 'title': 'Gercek Zamanli Finans Analitigi', 'desc': 'Hangi urun ne kadar net kar birakti? Detayli finans paneli ile isletmenizin gercek net karliligini anlik izleyin.'},
    ];

    final isDesktop = MediaQuery.of(context).size.width > 750;

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            Text('NEDEN BIZ?', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Text('Satislarinizi Buyutecek 4 Cekirdek Guc Modulu', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 36),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 2 : 1,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: isDesktop ? 1.8 : 2.0,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final f = features[index];
                final color = f['color'] as Color;
                return Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(f['icon'] as IconData, color: color, size: 28)),
                      const SizedBox(height: 20),
                      Text(f['title'] as String, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 10),
                      Text(f['desc'] as String, style: GoogleFonts.inter(color: Colors.white60, fontSize: 14, height: 1.5)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksSection({required GlobalKey key}) {
    final steps = [
      {'step': '01', 'title': 'Magazalarini Bagla', 'desc': 'API anahtarlarinizi girerek Trendyol, Hepsiburada ve diger magazalarinizi 90 saniyede ekleyin.'},
      {'step': '02', 'title': 'Urunlerini Eslestir', 'desc': 'Stok ve fiyatlarinizi tek tikla merkezi katalogunuzla eslestirin veya ice aktarin.'},
      {'step': '03', 'title': 'Arkaniza Yaslanin', 'desc': 'Siparisler geldikce stoklar tum kanallarda otomatik esitlensin, kargolar hazir olsun.'},
    ];

    final isWide = MediaQuery.of(context).size.width > 750;

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            Text('KOLAY KURULUM', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Text('3 Adimda Pazaryeri Satislarinizi Otomatize Edin', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 36),
            isWide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: steps.map((s) => Expanded(child: _stepCard(s))).toList())
                : Column(children: steps.map((s) => _stepCard(s)).toList()),
          ],
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
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            Text('SEFFAF FIYATLANDIRMA', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Text('Isletmenizin Olcegine Uygun Plani Secin', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Aylik', style: GoogleFonts.inter(color: !_isAnnualPricing ? Colors.white : Colors.white60)),
                Switch(value: _isAnnualPricing, activeColor: Colors.blueAccent, onChanged: (val) => setState(() => _isAnnualPricing = val)),
                Text('Yillik (%30 Indirim)', style: GoogleFonts.inter(color: _isAnnualPricing ? Colors.greenAccent : Colors.white60, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 36),
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _pricingCard(title: 'Starter', price: _isAnnualPricing ? '499 TL' : '699 TL', desc: 'Yeni baslayan e-ticaret saticilari icin', features: ['3 Pazaryeri Baglantisi', 'Aylik 500 Siparis', 'Anlik Stok Senkronu', 'E-Posta Destegi'], isPopular: false)),
                      const SizedBox(width: 16),
                      Expanded(child: _pricingCard(title: 'Scale PRO', price: _isAnnualPricing ? '1.199 TL' : '1.599 TL', desc: 'Hizli buyuyen ve cok kanalli magazalar icin', features: ['Tum Pazaryerleri (Sinirsiz)', 'Sinirsiz Siparis & Urun', 'Otomatik E-Fatura & Barkod', 'Akilli Fiyatlandirma Robotu', 'Oncelikli WhatsApp Destegi'], isPopular: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _pricingCard(title: 'Enterprise', price: _isAnnualPricing ? '2.799 TL' : '3.699 TL', desc: 'Yuksek hacimli markalar ve depolar', features: ['Sinirsiz Kanal & Coklu Depo', 'Logo / Mikro / SAP Entegrasyonu', 'Ozel Musteri Temsilcisi', '7/24 Telefon Hatti'], isPopular: false)),
                    ],
                  )
                : Column(
                    children: [
                      _pricingCard(title: 'Starter', price: _isAnnualPricing ? '499 TL' : '699 TL', desc: 'Yeni baslayan e-ticaret saticilari icin', features: ['3 Pazaryeri Baglantisi', 'Aylik 500 Siparis', 'Anlik Stok Senkronu', 'E-Posta Destegi'], isPopular: false),
                      const SizedBox(height: 16),
                      _pricingCard(title: 'Scale PRO', price: _isAnnualPricing ? '1.199 TL' : '1.599 TL', desc: 'Hizli buyuyen ve cok kanalli magazalar icin', features: ['Tum Pazaryerleri (Sinirsiz)', 'Sinirsiz Siparis & Urun', 'Otomatik E-Fatura & Barkod', 'Akilli Fiyatlandirma Robotu', 'Oncelikli WhatsApp Destegi'], isPopular: true),
                      const SizedBox(height: 16),
                      _pricingCard(title: 'Enterprise', price: _isAnnualPricing ? '2.799 TL' : '3.699 TL', desc: 'Yuksek hacimli markalar ve depolar', features: ['Sinirsiz Kanal & Coklu Depo', 'Logo / Mikro / SAP Entegrasyonu', 'Ozel Musteri Temsilcisi', '7/24 Telefon Hatti'], isPopular: false),
                    ],
                  ),
          ],
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
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(8)), child: Text('EN COK TERCIH EDILEN', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          const SizedBox(height: 6),
          Text(desc, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 20),
          Text(price, style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
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
              child: Text('14 Gun Ucretsiz Basla', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection({required GlobalKey key}) {
    final faqs = [
      {'q': 'Kurulum ne kadar surer? Teknik bilgiye ihtiyacim var mi?', 'a': 'Hayir, hicbir kodlama veya teknik bilgi gerekmez. Pazaryerlerinizden aldiginiz API anahtarlarini panelimize girerek magazalarinizi 90 saniye icinde baglayabilirsiniz.'},
      {'q': 'Gercekten cift satis (overselling) riskini engelliyor musunuz?', 'a': 'Evet. Gelismis Sync-Engine altyapimiz, bir kanaldan siparis dustugu anda milisaniyeler seviyesinde diger tum platformlardaki stok miktarini gunceller ve ceza puanini engeller.'},
      {'q': '14 gunluk ucretsiz deneme suresinde kredi karti girmem gerekir mi?', 'a': 'Kesinlikle hayir. Kredi karti bilginizi almadan tum Pro ozellikleri 14 gun boyunca sinirsiz deneyebilirsiniz.'},
      {'q': 'Kullandigim muhasebe ve ERP programlari ile entegre olabilir mi?', 'a': 'Platformumuz Parasut, Bizmu, Logo, Mikro, Zirve gibi tum populer on muhasebe ve ERP yazilimlariyla tam entegre calismaktadir.'},
    ];

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: Column(
          children: [
            Text('SIKCA SORULAN SORULAR', style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Text('Akliniza Takilan Tum Sorularin Cevaplari', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 36),
            ...faqs.map((faq) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
                  child: ExpansionTile(
                    iconColor: Colors.blueAccent,
                    collapsedIconColor: Colors.white60,
                    title: Text(faq['q']!, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    children: [
                      Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text(faq['a']!, style: GoogleFonts.inter(color: Colors.white60, fontSize: 14, height: 1.5))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1100),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Text('Bugun Baslayin, Ilk Satisinizi 10 Dakika Icinde Otomatize Edin.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Text('14 gun boyunca kredi kartsiz ucretsiz deneyin. E-ticaret operasyonunuzu sifir hata ile buyutun.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Hemen 14 Gun Ucretsiz Basla', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white10))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rocket_launch, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text('PazaryeriSaaS (c) 2026 Tum Haklari Saklidir.', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text('256-Bit SSL Guvenli Altyapi - KVKK Uyumlu', style: GoogleFonts.inter(color: Colors.white30, fontSize: 11)),
        ],
      ),
    );
  }
}
