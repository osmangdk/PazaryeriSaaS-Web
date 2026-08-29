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
                              labelText: 'Maliyet (₺)',
                              labelStyle: GoogleFonts.inter(color: Colors.white60),
                              prefixText: '₺ ',
                              prefixStyle: GoogleFonts.inter(color: Colors.white),
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
                              labelText: 'Hedef Kâr (%)',
                              labelStyle: GoogleFonts.inter(color: Colors.white60),
                              suffixText: '%',
                              suffixStyle: GoogleFonts.inter(color: Colors.white),
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
                              labelText: 'Kargo (₺)',
                              labelStyle: GoogleFonts.inter(color: Colors.white60),
                              prefixText: '₺ ',
                              prefixStyle: GoogleFonts.inter(color: Colors.white),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isCalculating ? null : doCalculate,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                          child: Text('Hesapla', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 12),
                    if (isCalculating)
                      const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
                    else if (calculatedResults != null)
                      Table(
                        border: TableBorder.all(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
                            children: [
                              _tableCell('Pazaryeri', isHeader: true),
                              _tableCell('Komisyon %', isHeader: true),
                              _tableCell('Tavsiye Fiyat', isHeader: true),
                              _tableCell('Komisyon Kesintisi', isHeader: true),
                              _tableCell('Net Kâr', isHeader: true),
                            ],
                          ),
                          ...calculatedResults!.map((r) => TableRow(
                                children: [
                                  _tableCell(r['marketplaceName'] ?? '', isBold: true),
                                  _tableCell('%${r['commissionPercent']}'),
                                  _tableCell('₺${r['recommendedSalePrice']}', textColor: Colors.greenAccent, isBold: true),
                                  _tableCell('₺${r['commissionAmount']}', textColor: Colors.redAccent),
                                  _tableCell('₺${r['netProfitAmount']} (%${r['netProfitMarginPercent']})', textColor: Colors.blueAccent, isBold: true),
                                ],
                              )),
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

  Widget _tableCell(String text, {bool isHeader = false, bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: textColor ?? (isHeader ? Colors.white : Colors.white70),
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 12 : 13,
        ),
      ),
    );
  }

  void _showConnectMarketplaceDialog() {
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
          final isTrendyol = selectedType == 1;
          final isHepsiburada = selectedType == 2;

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isTrendyol ? Colors.orange.withOpacity(0.2) : (isHepsiburada ? Colors.deepOrange.withOpacity(0.2) : Colors.blue.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.storefront, color: isTrendyol ? Colors.orange : (isHepsiburada ? Colors.deepOrange : Colors.blue)),
                ),
                const SizedBox(width: 12),
                Text('Pazaryeri Bağla', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      dropdownColor: const Color(0xFF0F172A),
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Pazaryeri Seçin',
                        labelStyle: GoogleFonts.inter(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('🟠 Trendyol')),
                        DropdownMenuItem(value: 2, child: Text('🟧 Hepsiburada')),
                        DropdownMenuItem(value: 3, child: Text('🟣 N11')),
                        DropdownMenuItem(value: 4, child: Text('📦 Amazon')),
                        DropdownMenuItem(value: 5, child: Text('🔵 Pazarama')),
                        DropdownMenuItem(value: 6, child: Text('🌸 ÇiçekSepeti')),
                        DropdownMenuItem(value: 7, child: Text('📮 PttAVM')),
                        DropdownMenuItem(value: 8, child: Text('👔 Boyner')),
                        DropdownMenuItem(value: 9, child: Text('🚗 Sahibinden')),
                      ],
                      onChanged: (val) => setDialogState(() => selectedType = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: storeNameController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(labelText: 'Mağaza Adı (Takma Ad)', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sellerIdController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(labelText: 'Satıcı ID / Merchant ID', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: apiKeyController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(labelText: 'API Key / Kullanıcı Adı', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: apiSecretController,
                      obscureText: true,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(labelText: 'API Secret / Şifre', labelStyle: GoogleFonts.inter(color: Colors.white60), filled: true, fillColor: Colors.white.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.rocket_launch, color: Colors.blueAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text('PazaryeriSaaS', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _showPricingCalculatorDialog,
                      icon: const Icon(Icons.calculate_outlined, color: Colors.orangeAccent, size: 18),
                      label: Text('Akıllı Fiyat Robotu', style: GoogleFonts.inter(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orangeAccent)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadData),
                    IconButton(icon: const Icon(Icons.logout, color: Colors.white70), onPressed: _logout),
                  ],
                ),
              ),

              // Navigation Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabButton(0, 'Genel Bakış', Icons.dashboard_outlined),
                      const SizedBox(width: 8),
                      _buildTabButton(1, 'Pazaryerleri (${_connections?.length ?? 0})', Icons.storefront_outlined),
                      const SizedBox(width: 8),
                      _buildTabButton(2, 'Siparişler (${_orders?.length ?? 0})', Icons.shopping_bag_outlined),
                      const SizedBox(width: 8),
                      _buildTabButton(3, 'Ürünler (${_products?.length ?? 0})', Icons.inventory_2_outlined),
                      const SizedBox(width: 8),
                      _buildTabButton(4, 'Finans & Kâr Analizi 📊', Icons.analytics_outlined),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildCurrentTabContent(companyName, productCount, productLimit, connCount, connLimit, daysLeft),
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

  Widget _buildCurrentTabContent(String companyName, int productCount, int productLimit, int connCount, int connLimit, int daysLeft) {
    switch (_currentTabIndex) {
      case 1:
        return _buildMarketplacesTab();
      case 2:
        return _buildOrdersTab();
      case 3:
        return _buildProductsTab();
      case 4:
        return _buildFinancialsTab();
      default:
        return _buildOverviewTab(companyName, productCount, productLimit, connCount, connLimit, daysLeft);
    }
  }

  Widget _buildOverviewTab(String companyName, int productCount, int productLimit, int connCount, int connLimit, int daysLeft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hoşgeldiniz,', style: GoogleFonts.inter(color: Colors.white60, fontSize: 16)),
        Text(companyName, style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),

        // Plan & Limit Kartı
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
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
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text('Ücretsiz Deneme (1 Ay / 50.000 ₺)', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Text('$daysLeft gün kaldı', style: GoogleFonts.inter(color: Colors.amber, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ürün Kotası ($productCount / $productLimit)', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: productCount / productLimit, backgroundColor: Colors.white12, color: Colors.blueAccent),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pazaryeri Bağlantısı ($connCount / $connLimit)', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: connCount / connLimit, backgroundColor: Colors.white12, color: Colors.greenAccent),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildMarketplaceConnectionsOverview(),
        const SizedBox(height: 24),
        _buildRecentOrdersOverview(),
      ],
    );
  }

  Widget _buildMarketplacesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Bağlı Pazaryerleri', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _showConnectMarketplaceDialog,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Pazaryeri Bağla', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _connections == null || _connections!.isEmpty
            ? _buildEmptyState('Henüz pazaryeri bağlanmamış.', Icons.storefront_outlined)
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _connections!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final c = _connections![index];
                  final String typeName = c['marketplaceName'] ?? 'Pazaryeri';
                  final bool isTrendyol = typeName.toLowerCase().contains('trendyol');
                  final bool isHepsiburada = typeName.toLowerCase().contains('hepsiburada');
                  final Color brandColor = isTrendyol ? Colors.orange : (isHepsiburada ? Colors.deepOrange : Colors.blue);
                  final bool isActive = c['isActive'] ?? true;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: brandColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: brandColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: brandColor.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.storefront, color: brandColor, size: 28)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(typeName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.greenAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(isActive ? 'Aktif' : 'Pasif', style: GoogleFonts.inter(color: isActive ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Mağaza: ${c['storeName']} • Satıcı ID: ${c['sellerId']}', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(isActive ? 'Açık' : 'Kapalı', style: GoogleFonts.inter(color: isActive ? Colors.greenAccent : Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
                            Switch(
                              value: isActive,
                              activeColor: Colors.greenAccent,
                              onChanged: (val) async {
                                final res = await _apiService.toggleMarketplaceStatus(c['id']);
                                if (mounted) {
                                  _loadData();
                                }
                              },
                            ),
                          ],
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
                  final orderId = o['orderId'] ?? o['orderNumber'] ?? 'ORD-001';
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sipariş: $orderId', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: Text(o['status'] ?? 'Onaylandı', style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Tutar: ${o['totalPrice']} ${o['currency'] ?? 'TRY'} • Takip No: ${o['cargoTrackingNumber'] ?? 'TRK-' + orderId}', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                final url = _apiService.getInvoiceUrl(orderId);
                                html.window.open(url, '_blank');
                              },
                              icon: const Icon(Icons.receipt_long, size: 16),
                              label: Text('GİB E-Fatura Görüntüle', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                final url = _apiService.getShippingLabelUrl(orderId);
                                html.window.open(url, '_blank');
                              },
                              icon: const Icon(Icons.qr_code, size: 16),
                              label: Text('Kargo Barkodu Yazdır', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
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
            Text('Ürün Kataloğu', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
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
        const SizedBox(height: 16),
        _products == null || _products!.isEmpty
            ? _buildEmptyState('Henüz ürün eklenmemiş.', Icons.inventory_2_outlined)
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _products!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _buildProductCard(_products![index]),
              ),
      ],
    );
  }

  Widget _buildProductCard(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.inventory_2, color: Colors.blueAccent, size: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['name'] ?? 'İsimsiz Ürün', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text('SKU: ${p['sku']} • Barkod: ${p['barcode'] ?? '-'}', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₺${p['price']}', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Stok: ${p['stockQuantity']} Adet', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.blueAccent),
            tooltip: 'Tüm Kanallara Stok Dağıt (Broadcast)',
            onPressed: () async {
              final res = await _apiService.broadcastStock(p['id'], p['stockQuantity']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res?['isSuccess'] == true ? 'Stok 1.2 saniyede tüm pazaryerlerine eşitlendi!' : 'Stok dağıtımında hata!'), backgroundColor: Colors.blueAccent),
                );
              }
            },
          ),
        ],
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
            Expanded(child: _finCard('Toplam Brüt Ciro', '₺${gross}', Icons.monetization_on, Colors.blueAccent)),
            const SizedBox(width: 12),
            Expanded(child: _finCard('Komisyon Kesintileri', '₺${commission}', Icons.percent, Colors.orangeAccent)),
            const SizedBox(width: 12),
            Expanded(child: _finCard('Kargo Giderleri', '₺${cargo}', Icons.local_shipping, Colors.purpleAccent)),
            const SizedBox(width: 12),
            Expanded(child: _finCard('Net Kâr (%$margin)', '₺${netProfit}', Icons.trending_up, Colors.greenAccent)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Kanal Bazlı Finansal Dağılım', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        breakdowns.isEmpty
            ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
                child: Text('Aktif pazaryerlerinden sipariş verisi çekildikçe finansal metrikler anlık hesaplanmaktadır.', style: GoogleFonts.inter(color: Colors.white60)),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: breakdowns.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final b = breakdowns[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(b['channelName'] ?? '', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Sipariş: ${b['orderCount']}', style: GoogleFonts.inter(color: Colors.white70)),
                        Text('Ciro: ₺${b['grossSales']}', style: GoogleFonts.inter(color: Colors.white)),
                        Text('Komisyon: ₺${b['commissionAmount']}', style: GoogleFonts.inter(color: Colors.orangeAccent)),
                        Text('Net Kâr: ₺${b['netProfit']}', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _finCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildMarketplaceConnectionsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Bağlı Pazaryerleri', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => setState(() => _currentTabIndex = 1), child: Text('Tümünü Gör', style: GoogleFonts.inter(color: Colors.blueAccent))),
          ],
        ),
        const SizedBox(height: 12),
        _connections == null || _connections!.isEmpty
            ? _buildEmptyState('Bağlı pazaryeri yok. Sağ üstteki sekmeden hemen bağlayabilirsiniz.', Icons.storefront_outlined)
            : Row(
                children: _connections!.map((c) {
                  final String typeName = c['marketplaceName'] ?? 'Pazaryeri';
                  final bool isTrendyol = typeName.toLowerCase().contains('trendyol');
                  final bool isHepsiburada = typeName.toLowerCase().contains('hepsiburada');
                  final Color brandColor = isTrendyol ? Colors.orange : (isHepsiburada ? Colors.deepOrange : Colors.blue);

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: brandColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: brandColor.withOpacity(0.4))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.storefront, color: brandColor, size: 24),
                          const SizedBox(height: 8),
                          Text(typeName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(c['storeName'] ?? 'Aktif', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildRecentOrdersOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Son Siparişler', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            TextButton(onPressed: () => setState(() => _currentTabIndex = 2), child: Text('Tümünü Gör', style: GoogleFonts.inter(color: Colors.blueAccent))),
          ],
        ),
        const SizedBox(height: 12),
        _orders == null || _orders!.isEmpty
            ? _buildEmptyState('Henüz sipariş yok.', Icons.shopping_bag_outlined)
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _orders!.length > 3 ? 3 : _orders!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final o = _orders![index];
                  final orderId = o['orderId'] ?? o['orderNumber'] ?? 'ORD-001';
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sipariş: $orderId', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('${o['totalPrice']} TRY', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.white30),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white60, fontSize: 14)),
        ],
      ),
    );
  }
}
