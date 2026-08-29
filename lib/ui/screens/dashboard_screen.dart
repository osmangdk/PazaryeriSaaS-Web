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

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _metrics;
  List<dynamic>? _products;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final metrics = await _apiService.getDashboardMetrics();
    final products = await _apiService.getProducts();
    setState(() {
      _metrics = metrics;
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final String companyName = _metrics?['companyName'] ?? 'Firma';
    final int productCount = _metrics?['productCount'] ?? 0;
    final int productLimit = _metrics?['productLimit'] ?? 10;
    final int connCount = _metrics?['connectionCount'] ?? 0;
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
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
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
                                'Kalan Deneme Suresi: $daysLeft Gun',
                                style: GoogleFonts.inter(color: daysLeft <= 7 ? Colors.redAccent : Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(child: _buildStatCard(icon: Icons.inventory_2_outlined, title: 'Urun Kotasi', value: '$productCount / $productLimit', color: Colors.blueAccent)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildStatCard(icon: Icons.storefront_outlined, title: 'Pazaryeri', value: '$connCount / $connLimit', color: const Color(0xFFFF9500))),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Urunlerim', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: Text('Urun Ekle', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _products == null || _products!.isEmpty
                                ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 48),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.inventory_2_outlined, color: Colors.white30, size: 48),
                                        const SizedBox(height: 12),
                                        Text('Henuz urun eklenmemis.', style: GoogleFonts.inter(color: Colors.white38, fontSize: 15)),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _products!.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (context, index) => _buildProductCard(_products![index]),
                                  ),
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
                Text(p['title'] ?? 'Urun', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
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
}