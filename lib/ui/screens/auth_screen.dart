import 'package:flutter/material.dart';
import 'package:frontend/core/biometric_service.dart';
import 'package:frontend/data/api_service.dart';
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
  final _companyController = TextEditingController(); // Sadece kayıt
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isBiometricLoading = false;
  bool _biometricAvailable = false;
  BiometricType? _preferredBiometric;
  final _apiService = ApiService();

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
        reason: 'RoaTech hesabınıza giriş yapmak için doğrulayın',
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

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    
    String? token;
    if (_isLogin) {
      token = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      token = await _apiService.register(
        _emailController.text,
        _passwordController.text,
        _companyController.text,
      );
    }
    
    setState(() => _isLoading = false);

    if (token != null) {
      // Token'ı kaydet (biyometrik giriş için)
      await BiometricService.saveToken(token);
      if (mounted) context.go('/dashboard');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLogin ? 'Giriş başarısız!' : 'Kayıt başarısız! (Aynı e-posta kayıtlı olabilir)'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // Top Left Home Link
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
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    elevation: 12,
                    shadowColor: Colors.black45,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo veya İkon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket_launch, size: 48, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 24),
                      
                      // Başlık
                      Text(
                        _isLogin ? 'Hoşgeldiniz' : 'Yeni Kayıt Ol',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Hesabınıza giriş yapın' : '30 gün ücretsiz deneyin',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form Alanları
                      if (!_isLogin) ...[
                        _buildTextField(
                          controller: _companyController,
                          label: 'Firma / Mağaza Adı',
                          icon: Icons.storefront,
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      _buildTextField(
                        controller: _emailController,
                        label: 'E-posta Adresi',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Şifre',
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Buton
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading 
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                _isLogin ? 'Giriş Yap' : 'Kayıt Ol (Ücretsiz)',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Alt geçiş metni
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin ? 'Hesabınız yok mu? Ücretsiz Kayıt Olun' : 'Zaten hesabınız var mı? Giriş Yapın',
                          style: GoogleFonts.inter(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // ── Biyometrik Giriş Butonu ──────────────────────────
                      if (_biometricAvailable && _isLogin) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Colors.black12)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'ya da',
                                style: GoogleFonts.inter(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _isBiometricLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.blueAccent,
                                    ),
                                  )
                                : Icon(
                                    _preferredBiometric == BiometricType.face
                                        ? Icons.face
                                        : Icons.fingerprint,
                                    color: Colors.blueAccent,
                                    size: 24,
                                  ),
                            label: Text(
                              _preferredBiometric == BiometricType.face
                                  ? 'Face ID ile Giriş Yap'
                                  : 'Parmak İzi ile Giriş Yap',
                              style: GoogleFonts.inter(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(color: Colors.black12),
                      const SizedBox(height: 8),

                      // Ana Sayfaya Dön Butonu
                      TextButton.icon(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF64748B)),
                        label: Text(
                          'Ana Sayfaya Dön',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
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
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
