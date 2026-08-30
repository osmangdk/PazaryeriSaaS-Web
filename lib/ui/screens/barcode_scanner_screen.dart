import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Tam ekran kamera barkod / QR kod tarayıcı ekranı.
/// Kullanım: await Navigator.push(context, MaterialPageRoute(
///   builder: (_) => BarcodeScannerScreen(onDetected: (code) { ... })));
class BarcodeScannerScreen extends StatefulWidget {
  final void Function(String barcode) onDetected;
  final String title;

  const BarcodeScannerScreen({
    super.key,
    required this.onDetected,
    this.title = 'Barkod / QR Tara',
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController? _controller;
  bool _detected = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        _detected = true;
        _controller?.stop();
        widget.onDetected(value);
        if (mounted) Navigator.of(context).pop();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Kamera ──────────────────────────────────────────────────────
          MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
          ),

          // ── Tarama Çerçevesi Overlay ────────────────────────────────────
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Köşe efekti
                  Positioned(top: 0, left: 0, child: _corner()),
                  Positioned(top: 0, right: 0, child: _corner(flipX: true)),
                  Positioned(bottom: 0, left: 0, child: _corner(flipY: true)),
                  Positioned(bottom: 0, right: 0, child: _corner(flipX: true, flipY: true)),

                  // Tarama animasyonu çizgisi
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blueAccent.withOpacity(0),
                              Colors.blueAccent,
                              Colors.blueAccent.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Üst Bar ────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Geri Butonu
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  // Fener Butonu
                  GestureDetector(
                    onTap: () async {
                      await _controller?.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _torchOn ? Colors.amberAccent.withOpacity(0.3) : Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _torchOn ? Colors.amberAccent : Colors.white24,
                        ),
                      ),
                      child: Icon(
                        _torchOn ? Icons.flashlight_off : Icons.flashlight_on,
                        color: _torchOn ? Colors.amberAccent : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Alt Açıklama ────────────────────────────────────────────────
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Barkod veya QR kodu çerçeve içine alın',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ürün barkodunu tarayarak hızlıca arama yapabilirsiniz',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({bool flipX = false, bool flipY = false}) {
    return Transform.scale(
      scaleX: flipX ? -1 : 1,
      scaleY: flipY ? -1 : 1,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: const Border(
            top: BorderSide(color: Colors.blueAccent, width: 4),
            left: BorderSide(color: Colors.blueAccent, width: 4),
          ),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(8)),
        ),
      ),
    );
  }
}
