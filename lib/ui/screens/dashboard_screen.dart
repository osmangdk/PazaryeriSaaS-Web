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

    setState(() {
      _metrics = metrics;
      _products = products;
      _connections = connections;
      _orders = orders;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (mounted) context.go('/login');
  }

  void _showConnectMarketplaceDialog() {
    int selectedType = 1; // 1: Trendyol, 2: Hepsiburada, 3: N11, 4: Amazon, 5: Pazarama
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
            content: SingleChildScrollView(
              child: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pazaryeri Seçin', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedType,
                          dropdownColor: const Color(0xFF1E293B),
                          isExpanded: true,
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('🟠 Trendyol')),
                            DropdownMenuItem(value: 2, child: Text('🔴 Hepsiburada')),
                            DropdownMenuItem(value: 3, child: Text('🟣 N11')),
                            DropdownMenuItem(value: 4, child: Text('🟡 Amazon')),
                            DropdownMenuItem(value: 5, child: Text('🔵 Pazarama')),
                            DropdownMenuItem(value: 6, child: Text('🌸 ÇiçekSepeti')),
                            DropdownMenuItem(value: 7, child: Text('🟡 PttAVM')),
                            DropdownMenuItem(value: 8, child: Text('👔 Boyner')),
                            DropdownMenuItem(value: 9, child: Text('🚗 Sahibinden')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedType = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: storeNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Mağaza Adı (Opsiyonel)',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sellerIdController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: isTrendyol ? 'Satıcı / Supplier ID (örn: 12345)' : (isHepsiburada ? 'Merchant ID / UUID' : 'Satıcı ID'),
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: apiKeyController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: isHepsiburada ? 'API Kullanıcı Adı (Username)' : 'API Key',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: apiSecretController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: isHepsiburada ? 'API Şifresi (Password)' : 'API Secret Key',
                        labelStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: Text('İptal', style: GoogleFonts.inter(color: Colors.white60)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        final res = await _apiService.connectMarketplace(
                          marketplaceType: selectedType,
                          storeName: storeNameController.text.trim().isEmpty ? null : storeNameController.text.trim(),
                          sellerId: sellerIdController.text.trim(),
                          apiKey: apiKeyController.text.trim(),
                          apiSecret: apiSecretController.text.trim(),
                        );
                        setDialogState(() => isSubmitting = false);

                        if (res != null && !res.containsKey('error')) {
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pazaryeri başarıyla bağlandı!'), backgroundColor: Colors.green),
                            );
                            _loadData();
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res?['error'] ?? 'Bağlantı hatası!'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Bağla', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String companyName = _metrics?['companyName'] ?? 'Firma';
    final int productCount = _metrics?['productCount'] ?? 0;
    final int productLimit = _metrics?['productLimit'] ?? 10;
    final int connCount = _connections?.length ?? (_metrics?['connectionCount'] ?? 0);
    final int connLimit = _metrics?['connectionLimit'] ?? 3;
    final int daysLeft = _metrics?['daysLeft'] ?? 0;

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
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.rocket_launch, color: Colors.blueAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text('PazaryeriSaaS', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadData),
                    IconButton(icon: const Icon(Icons.logout, color: Colors.white70), onPressed: _logout),
                  ],
                ),
              ),

              // Navigation Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _buildTabButton(0, 'Genel Bakış', Icons.dashboard_outlined),
                    const SizedBox(width: 8),
                    _buildTabButton(1, 'Pazaryerleri (${_connections?.length ?? 0})', Icons.storefront_outlined),
                    const SizedBox(width: 8),
                    _buildTabButton(2, 'Siparişler (${_orders?.length ?? 0})', Icons.shopping_bag_outlined),
                    const SizedBox(width: 8),
                    _buildTabButton(3, 'Ürünler (${_products?.length ?? 0})', Icons.inventory_2_outlined),
                  ],
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
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: daysLeft <= 7 ? Colors.redAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: daysLeft <= 7 ? Colors.redAccent : Colors.greenAccent, width: 1),
          ),
          child: Text(
            'Kalan Deneme Süresi: $daysLeft Gün',
            style: GoogleFonts.inter(color: daysLeft <= 7 ? Colors.redAccent : Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _buildStatCard(icon: Icons.inventory_2_outlined, title: 'Ürün Kotası', value: '$productCount / $productLimit', color: Colors.blueAccent)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(icon: Icons.storefront_outlined, title: 'Pazaryeri', value: '$connCount / $connLimit', color: const Color(0xFFFF9500))),
          ],
        ),
        const SizedBox(height: 32),
        _buildMarketplaceConnectionsOverview(),
        const SizedBox(height: 32),
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
            ? _buildEmptyState('Henüz bir pazaryeri bağlanmamış.', Icons.storefront_outlined)
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _connections!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final c = _connections![index];
                  final String typeName = c['marketplaceName'] ?? 'Pazaryeri';
                  final bool isActive = c['isActive'] == true;
                  final bool isTrendyol = typeName.toLowerCase().contains('trendyol');
                  final bool isHepsiburada = typeName.toLowerCase().contains('hepsiburada');
                  final Color brandColor = isTrendyol ? Colors.orange : (isHepsiburada ? Colors.deepOrange : Colors.blue);

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isActive ? brandColor.withOpacity(0.4) : Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive ? brandColor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.store, color: isActive ? brandColor : Colors.white38, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    typeName,
                                    style: GoogleFonts.inter(
                                      color: isActive ? Colors.white : Colors.white54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.greenAccent.withOpacity(0.15) : Colors.redAccent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isActive ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      isActive ? 'Aktif' : 'Pasif',
                                      style: GoogleFonts.inter(
                                        color: isActive ? Colors.greenAccent : Colors.redAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Mağaza: ${c['storeName'] ?? 'Varsayılan'} • Satıcı ID: ${c['sellerId'] ?? '-'}', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
                            ],
                          ),
                        ),
                        // Aktif / Pasif Toggle Switch
                        Row(
                          children: [
                            Text(
                              isActive ? 'Açık' : 'Kapalı',
                              style: GoogleFonts.inter(color: isActive ? Colors.greenAccent : Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Switch(
                              value: isActive,
                              activeColor: Colors.greenAccent,
                              onChanged: (val) async {
                                final res = await _apiService.toggleMarketplaceStatus(c['id']);
                                if (mounted) {
                                  if (res?['error'] != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(res!['error']), backgroundColor: Colors.red),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(res?['message'] ?? 'Durum güncellendi.'), backgroundColor: Colors.blueAccent),
                                    );
                                    _loadData();
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                          tooltip: 'API Doğrula',
                          onPressed: () async {
                            final res = await _apiService.validateMarketplace(c['id']);
                            if (mounted) {
                              final isValid = res?['isValid'] == true;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res?['message'] ?? (isValid ? 'API Geçerli!' : 'Doğrulanamadı!')),
                                  backgroundColor: isValid ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Bağlantıyı Sil',
                          onPressed: () async {
                            final ok = await _apiService.deleteMarketplaceConnection(c['id']);
                            if (ok && mounted) {
                              _loadData();
                            }
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
                            Text('Sipariş: ${o['orderNumber'] ?? o['orderId']}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: Text(o['status'] ?? 'Unknown', style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Tutar: ${o['totalPrice']} ${o['currency'] ?? 'TRY'} • Takip No: ${o['cargoTrackingNumber'] ?? 'Henüz yok'}', style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
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
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Ürün Ekle', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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

  Widget _buildMarketplaceConnectionsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Bağlı Pazaryerleri', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => setState(() => _currentTabIndex = 1),
              child: Text('Tümünü Gör', style: GoogleFonts.inter(color: Colors.blueAccent)),
            ),
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
                      decoration: BoxDecoration(
                        color: brandColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: brandColor.withOpacity(0.4)),
                      ),
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
            TextButton(
              onPressed: () => setState(() => _currentTabIndex = 2),
              child: Text('Tümünü Gör', style: GoogleFonts.inter(color: Colors.blueAccent)),
            ),
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
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sipariş #${o['orderNumber'] ?? o['orderId']}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                        Text('${o['totalPrice']} TL', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.inventory_2, color: Colors.blueAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['title'] ?? 'Ürün', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text('SKU: ${p['sku'] ?? '-'}  |  Stok: ${p['stockQuantity'] ?? 0}  |  ${p['price'] ?? 0} TL', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white30),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white30, size: 40),
          const SizedBox(height: 12),
          Text(text, style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}