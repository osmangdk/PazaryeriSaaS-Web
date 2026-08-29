import 'package:flutter/material.dart';
import 'package:frontend/data/api_service.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String companyName = _metrics?['companyName'] ?? 'Firma';
    final int productCount = _metrics?['productCount'] ?? 0;
    final int productLimit = _metrics?['productLimit'] ?? 10;
    final int connCount = _metrics?['connectionCount'] ?? 0;
    final int connLimit = _metrics?['connectionLimit'] ?? 3;
    final int daysLeft = _metrics?['daysLeft'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hoşgeldiniz, $companyName!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Kalan Deneme Süresi: $daysLeft Gün', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatCard('Ürün Kotası', '$productCount / $productLimit', Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard('Pazaryeri', '$connCount / $connLimit', Colors.orange),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ürünler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Yeni Ürün Ekle Modal
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ürün Ekle'),
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _products == null || _products!.isEmpty
                  ? const Center(child: Text('Henüz ürün eklenmemiş.'))
                  : ListView.builder(
                      itemCount: _products!.length,
                      itemBuilder: (context, index) {
                        final p = _products![index];
                        return Card(
                          child: ListTile(
                            title: Text(p['title'] ?? ''),
                            subtitle: Text('SKU: ${p['sku']} | Stok: ${p['stockQuantity']} | Fiyat: ${p['price']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatusDot(Colors.grey, 'Durum Bilinmiyor'),
                              ],
                            ),
                            onTap: () {
                              // Ürün detayı ve sync işlemi
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDot(Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
