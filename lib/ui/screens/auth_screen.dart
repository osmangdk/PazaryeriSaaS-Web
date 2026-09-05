import 'package:flutter/material.dart';
import 'package:frontend/core/biometric_service.dart';
import 'package:frontend/data/api_service.dart';
import 'package:frontend/ui/widgets/marketplace_logo.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // 1. Adım: Yetkili & İletişim Bilgileri
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // 2. Adım: Firma, Yasal & Sektör Bilgileri
  final _companyController = TextEditingController();
  String _companyType = 'Company'; // 'SoleProprietorship' (Şahıs) or 'Company' (LTD/AŞ)
  final _taxNumberController = TextEditingController();
  final _taxOfficeController = TextEditingController();
  final _cityController = TextEditingController();
  
  final Set<String> _selectedIndustries = {'👗 Moda & Tekstil'};
  final Set<String> _selectedMarketplaces = {'Trendyol', 'Hepsiburada'};

  int _registerStep = 1; // 1: Hesap, 2: Firma & Sektör
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isBiometricLoading = false;
  bool _biometricAvailable = false;
  BiometricType? _preferredBiometric;
  final _apiService = ApiService();

  final List<Map<String, dynamic>> _availableIndustries = [
    {'id': 'Moda', 'title': '👗 Moda & Tekstil'},
    {'id': 'Elektronik', 'title': '📱 Elektronik & Teknoloji'},
    {'id': 'Kozmetik', 'title': '💄 Kozmetik & Bakım'},
    {'id': 'EvYasam', 'title': '🛋️ Ev, Yaşam & Mobilya'},
    {'id': 'AnneBebek', 'title': '🍼 Anne, Bebek & Oyuncak'},
    {'id': 'Otomotiv', 'title': '🚗 Otomotiv & Yapı Market'},
    {'id': 'Spor', 'title': '⚽ Spor & Outdoor'},
    {'id': 'Kitap', 'title': '📚 Kitap, Kırtasiye & Ofis'},
    {'id': 'Gida', 'title': '🍎 Gıda & Süpermarket'},
    {'id': 'Taki', 'title': '💎 Takı, Saat & Aksesuar'},
    {'id': 'Saglik', 'title': '🌿 Sağlık & Medikal'},
    {'id': 'Diger', 'title': '🛍️ Diğer / Genel Ticaret'},
  ];

  final List<String> _availableMarketplaces = [
    'Trendyol',
    'Hepsiburada',
    'Amazon',
    'N11',
    'ÇiçekSepeti',
    'Pazarama',
    'PttAVM',
    'Teknosa',
    'MediaMarkt',
    'Koçtaş',
    'Boyner',
    'Beymen',
    'LC Waikiki',
    'FLO',
    'A101',
    'Turkcell Pasaj',
    'Modanisa',
    'İdefix',
    'Etsy',
    'Ozon',
    'Getir',
    'Yemeksepeti',
    'Sahibinden',
    'IdeaSoft',
  ];

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricService.isAvailable();
    final hasSaved = await BiometricService.hasSavedSession();
    if (mounted) {
      setState(() => _biometricAvailable = available && hasSaved);
      if (available && hasSaved) {
        _preferredBiometric = await BiometricService.getPreferredBiometric();
      }
    }
  }

  Future<void> _biometricLogin() async {
    setState(() => _isBiometricLoading = true);
    try {
      final authenticated = await BiometricService.authenticate(
        reason: 'PazarYerleri hesabınıza giriş yapmak için doğrulayın',
      );
      if (authenticated && mounted) {
        context.go('/dashboard');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biyometrik doğrulama başarısız.'),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBiometricLoading = false);
    }
  }

  void _nextRegisterStep() {
    // 1. Adım Validasyonları
    if (_fullNameController.text.trim().length < 3) {
      _showError('Lütfen ad ve soyadınızı eksiksiz giriniz.');
      return;
    }
    if (!_emailController.text.contains('@') || !_emailController.text.contains('.')) {
      _showError('Lütfen geçerli bir e-posta adresi giriniz.');
      return;
    }
    if (_phoneController.text.trim().length < 10) {
      _showError('Lütfen geçerli bir cep telefonu numarası (örn: 05XX XXX XX XX) giriniz.');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError('Şifreniz en az 6 karakter olmalıdır.');
      return;
    }

    setState(() => _registerStep = 2);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isLogin) {
      if (!_emailController.text.contains('@')) {
        _showError('Lütfen geçerli bir e-posta adresi giriniz.');
        return;
      }
      if (_passwordController.text.isEmpty) {
        _showError('Lütfen şifrenizi giriniz.');
        return;
      }

      setState(() => _isLoading = true);
      final token = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      setState(() => _isLoading = false);

      if (token != null) {
        await BiometricService.saveToken(token);
        if (mounted) context.go('/dashboard');
      } else {
        if (mounted) _showError('Giriş başarısız! Lütfen e-posta ve şifrenizi kontrol ediniz.');
      }
    } else {
      // 2. Adım Kayıt Gönderimi
      if (_companyController.text.trim().isEmpty) {
        _showError('Lütfen firma veya mağaza adınızı giriniz.');
        return;
      }

      final taxNo = _taxNumberController.text.trim().replaceAll(' ', '');
      if (taxNo.isNotEmpty) {
        if (_companyType == 'SoleProprietorship' && taxNo.length != 11) {
          _showError('Şahıs şirketi için T.C. Kimlik Numarası 11 haneli olmalıdır.');
          return;
        } else if (_companyType == 'Company' && taxNo.length != 10) {
          _showError('Limited / A.Ş. için Vergi Kimlik Numarası 10 haneli olmalıdır.');
          return;
        }
      }

      if (_selectedIndustries.isEmpty) {
        _showError('Lütfen en az bir faaliyet sektörü seçiniz.');
        return;
      }

      setState(() => _isLoading = true);
      final result = await _apiService.registerAdvanced(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        companyName: _companyController.text.trim(),
        companyType: _companyType,
        taxNumber: taxNo.isNotEmpty ? taxNo : null,
        taxOffice: _taxOfficeController.text.trim().isNotEmpty ? _taxOfficeController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        selectedIndustries: _selectedIndustries.toList(),
        selectedMarketplaces: _selectedMarketplaces.toList(),
      );
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        final token = result['token'] as String?;
        if (token != null) await BiometricService.saveToken(token);
        if (mounted) context.go('/dashboard');
      } else {
        if (mounted) _showError(result['message'] ?? 'Kayıt işlemi gerçekleştirilemedi.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Sol Üst Ana Sayfaya Dön Butonu
            Positioned(
              top: 24,
              left: 24,
              child: InkWell(
                onTap: () => context.go('/'),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Ana Sayfaya Dön',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                child: Center(
                  child: Card(
                    elevation: 16,
                    shadowColor: Colors.black54,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: _isLogin ? 420 : 540),
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 36.0 : 20.0, vertical: 36.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // PazarYerleri Logo & Başlık
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.cyanAccent]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: const Icon(Icons.hub, size: 36, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'PazarYerleri',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0A2540),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pazaryeri Entegrasyon & API',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0284C7),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Başlık & Açıklama
                          Text(
                            _isLogin
                                ? 'Hoş Geldiniz'
                                : (_registerStep == 1 ? 'Hesap Oluşturun (1/2)' : 'Firma & Sektör Bilgileri (2/2)'),
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isLogin
                                ? 'Hesabınıza güvenle giriş yapın'
                                : '30 gün boyunca kredi kartsız ücretsiz deneyin',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                          ),

                          // Kayıt Ol Adım Göstergesi (Step Indicator)
                          if (!_isLogin) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _registerStep == 2 ? Colors.blueAccent : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 24),

                          // ── FORM ALANLARI ──
                          if (_isLogin) ...[
                            // GİRİŞ FORMU
                            _buildTextField(
                              controller: _emailController,
                              label: 'E-posta Adresi',
                              hint: 'ornek@sirket.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Şifre',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ] else if (_registerStep == 1) ...[
                            // KAYIT ADIM 1: Yetkili & İletişim Bilgileri
                            _buildTextField(
                              controller: _fullNameController,
                              label: 'Yetkili Adı Soyadı',
                              hint: 'Örn: Ahmet Yılmaz',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _emailController,
                              label: 'E-posta Adresi',
                              hint: 'ahmet@firma.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Cep Telefonu',
                              hint: '0 (5XX) XXX XX XX',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Şifre Belirleyin',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ] else ...[
                            // KAYIT ADIM 2: Firma, Yasal & Sektör Bilgileri
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => setState(() => _registerStep = 1),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.arrow_back, size: 14, color: Colors.blueAccent),
                                        const SizedBox(width: 4),
                                        Text('Hesap Bilgilerini Düzenle', style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            _buildTextField(
                              controller: _companyController,
                              label: 'Firma / Mağaza Adı',
                              hint: 'Örn: Yılmaz Tekstil Sanayi',
                              icon: Icons.storefront_outlined,
                            ),
                            const SizedBox(height: 14),

                            // Şirket Türü Seçimi (Şahıs vs LTD/AŞ)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setState(() => _companyType = 'SoleProprietorship'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _companyType == 'SoleProprietorship' ? Colors.blueAccent : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Şahıs Şirketi (TCKN)',
                                            style: GoogleFonts.inter(
                                              color: _companyType == 'SoleProprietorship' ? Colors.white : Colors.black87,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setState(() => _companyType = 'Company'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _companyType == 'Company' ? Colors.blueAccent : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Limited / A.Ş. (VKN)',
                                            style: GoogleFonts.inter(
                                              color: _companyType == 'Company' ? Colors.white : Colors.black87,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            _buildTextField(
                              controller: _taxNumberController,
                              label: _companyType == 'SoleProprietorship' ? 'T.C. Kimlik No (11 Hane)' : 'Vergi Kimlik No (VKN - 10 Hane)',
                              hint: _companyType == 'SoleProprietorship' ? '12345678901' : '1234567890',
                              icon: Icons.badge_outlined,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _taxOfficeController,
                                    label: 'Vergi Dairesi',
                                    hint: 'Örn: Beşiktaş',
                                    icon: Icons.account_balance_outlined,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _cityController,
                                    label: 'İl / Şehir',
                                    hint: 'Örn: İstanbul',
                                    icon: Icons.location_on_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Faaliyet Sektörleri (Çoklu Seçim)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  const Icon(Icons.category_outlined, size: 16, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Faaliyet Gösterdiğiniz Sektörler *',
                                    style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Kataloğunuz ve kategorileriniz bu seçimlerinize göre özelleştirilecektir.',
                                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _availableIndustries.map((ind) {
                                final title = ind['title'] as String;
                                final isSelected = _selectedIndustries.contains(title);
                                return FilterChip(
                                  label: Text(title, style: GoogleFonts.inter(fontSize: 11.5, color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                  selected: isSelected,
                                  selectedColor: Colors.blueAccent,
                                  backgroundColor: Colors.grey[100],
                                  checkmarkColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.grey[300]!),
                                  ),
                                  onSelected: (val) {
                                    setState(() {
                                      if (val) {
                                        _selectedIndustries.add(title);
                                      } else if (_selectedIndustries.length > 1) {
                                        _selectedIndustries.remove(title);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),

                            // Satış Yapılan Pazaryerleri
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Satış Yaptığınız Pazaryerleri',
                                style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _availableMarketplaces.map((mp) {
                                final isSelected = _selectedMarketplaces.contains(mp);
                                return FilterChip(
                                  avatar: MarketplaceLogoWidget(
                                    marketplaceName: mp,
                                    size: 18,
                                    borderRadius: 4,
                                  ),
                                  label: Text(mp, style: GoogleFonts.inter(fontSize: 11.5, color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF0EA5E9),
                                  backgroundColor: Colors.grey[100],
                                  checkmarkColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: isSelected ? const Color(0xFF0EA5E9) : Colors.grey[300]!),
                                  ),
                                  onSelected: (val) {
                                    setState(() {
                                      if (val) _selectedMarketplaces.add(mp);
                                      else _selectedMarketplaces.remove(mp);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],

                          const SizedBox(height: 28),

                          // Buton
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : (_isLogin || _registerStep == 2 ? _submit : _nextRegisterStep),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      _isLogin
                                          ? 'Giriş Yap'
                                          : (_registerStep == 1 ? 'Devam Et: Firma Bilgileri ➔' : '🚀 30 Gün Ücretsiz Başla'),
                                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Alt Geçiş Metni (Login <-> Register)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _registerStep = 1;
                              });
                            },
                            child: Text(
                              _isLogin ? 'Hesabınız yok mu? 30 Gün Ücretsiz Kayıt Olun' : 'Zaten hesabınız var mı? Giriş Yapın',
                              style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),

                          // Biyometrik Giriş Butonu
                          if (_biometricAvailable && _isLogin) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Expanded(child: Divider(color: Colors.black12)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('ya da', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12)),
                                ),
                                const Expanded(child: Divider(color: Colors.black12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _isBiometricLoading ? null : _biometricLogin,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.blueAccent, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: _isBiometricLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent))
                                    : Icon(_preferredBiometric == BiometricType.face ? Icons.face : Icons.fingerprint, color: Colors.blueAccent, size: 24),
                                label: Text(
                                  _preferredBiometric == BiometricType.face ? 'Face ID ile Giriş Yap' : 'Parmak İzi ile Giriş Yap',
                                  style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),
                          const Divider(color: Colors.black12),
                          const SizedBox(height: 6),

                          // Ana Sayfaya Dön Butonu
                          TextButton.icon(
                            onPressed: () => context.go('/'),
                            icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF64748B)),
                            label: Text('Ana Sayfaya Dön', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
        labelStyle: GoogleFonts.inter(color: Colors.grey[700], fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
