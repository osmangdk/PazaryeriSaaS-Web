import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class MarketplaceLogoWidget extends StatelessWidget {
  final String marketplaceName;
  final double size;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final bool showBadgeBackground;
  final Color? backgroundColor;

  const MarketplaceLogoWidget({
    super.key,
    required this.marketplaceName,
    this.size = 36,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius = 8,
    this.showBadgeBackground = false,
    this.backgroundColor,
  });

  static String? getAssetPath(String name) {
    final clean = name.trim().toLowerCase();
    if (clean.contains('trendyol')) return 'assets/logos/trendyol.svg';
    if (clean.contains('hepsiburada')) return 'assets/logos/hepsiburada.svg';
    if (clean.contains('n11')) return 'assets/logos/n11.svg';
    if (clean.contains('amazon')) return 'assets/logos/amazon.svg';
    if (clean.contains('cicek') || clean.contains('çiçek')) return 'assets/logos/ciceksepeti.svg';
    if (clean.contains('pazarama')) return 'assets/logos/pazarama.svg';
    if (clean.contains('ptt')) return 'assets/logos/pttavm.svg';
    if (clean.contains('idefix') || clean.contains('İdefix')) return 'assets/logos/idefix.svg';
    if (clean.contains('teknosa')) return 'assets/logos/teknosa.svg';
    if (clean.contains('mediamarkt') || clean.contains('media markt')) return 'assets/logos/mediamarkt.svg';
    if (clean.contains('koctas') || clean.contains('koçtaş')) return 'assets/logos/koctas.svg';
    if (clean.contains('boyner')) return 'assets/logos/boyner.svg';
    if (clean.contains('beymen')) return 'assets/logos/beymen.svg';
    if (clean.contains('lcw') || clean.contains('waikiki')) return 'assets/logos/lcwaikiki.svg';
    if (clean.contains('flo')) return 'assets/logos/flo.svg';
    if (clean.contains('a101') || clean.contains('a 101') || clean.contains('a·101')) return 'assets/logos/a101.svg';
    if (clean.contains('pasaj') || clean.contains('turkcell')) return 'assets/logos/turkcell-pasaj.svg';
    if (clean.contains('modanisa')) return 'assets/logos/modanisa.svg';
    if (clean.contains('temu')) return 'assets/logos/temu.svg';
    if (clean.contains('etsy')) return 'assets/logos/etsy.svg';
    if (clean.contains('ozon')) return 'assets/logos/ozon.svg';
    if (clean.contains('getir')) return 'assets/logos/getir.svg';
    if (clean.contains('yemeksepeti') || clean.contains('yemek sepeti')) return 'assets/logos/yemeksepeti.svg';
    if (clean.contains('akakce') || clean.contains('akakçe')) return 'assets/logos/akakce.svg';
    if (clean.contains('ideasoft')) return 'assets/logos/ideasoft.svg';
    if (clean.contains('sahibinden')) return 'assets/logos/sahibinden.svg';
    if (clean.contains('cimri')) return 'assets/logos/cimri.svg';
    return null;
  }

  static Color getBrandColor(String name) {
    final clean = name.trim().toLowerCase();
    if (clean.contains('trendyol')) return const Color(0xFFF27A1A);
    if (clean.contains('hepsiburada')) return const Color(0xFFFF6000);
    if (clean.contains('n11')) return const Color(0xFFE31E24);
    if (clean.contains('amazon')) return const Color(0xFFFF9900);
    if (clean.contains('cicek') || clean.contains('çiçek')) return const Color(0xFF0072C6);
    if (clean.contains('pazarama')) return const Color(0xFF6D28D9);
    if (clean.contains('ptt')) return const Color(0xFFFFCC00);
    if (clean.contains('idefix')) return const Color(0xFF0284C7);
    if (clean.contains('teknosa')) return const Color(0xFFF37021);
    if (clean.contains('mediamarkt')) return const Color(0xFFDF0000);
    if (clean.contains('koctas')) return const Color(0xFF003087);
    if (clean.contains('boyner')) return const Color(0xFF0F172A);
    if (clean.contains('beymen')) return const Color(0xFF1E293B);
    if (clean.contains('lcw')) return const Color(0xFF0084CA);
    if (clean.contains('flo')) return const Color(0xFFFF671B);
    if (clean.contains('a101')) return const Color(0xFF00A3AD);
    if (clean.contains('pasaj')) return const Color(0xFF002855);
    if (clean.contains('modanisa')) return const Color(0xFFD82374);
    if (clean.contains('temu')) return const Color(0xFFFB7701);
    if (clean.contains('etsy')) return const Color(0xFFF1641E);
    if (clean.contains('ozon')) return const Color(0xFF005BFF);
    if (clean.contains('getir')) return const Color(0xFF5D3EBC);
    if (clean.contains('yemeksepeti')) return const Color(0xFFEA004B);
    if (clean.contains('akakce')) return const Color(0xFF00A3E0);
    if (clean.contains('ideasoft')) return const Color(0xFF10B981);
    if (clean.contains('sahibinden')) return const Color(0xFFFFD200);
    if (clean.contains('cimri')) return const Color(0xFF059669);
    return Colors.blueGrey;
  }

  static String getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'MP';
    final parts = clean.split(RegExp(r's+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return clean.substring(0, clean.length >= 3 ? 3 : clean.length).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;
    final assetPath = getAssetPath(marketplaceName);
    final brandColor = getBrandColor(marketplaceName);

    Widget logoContent;

    if (assetPath != null) {
      logoContent = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SvgPicture.asset(
          assetPath,
          width: w,
          height: h,
          fit: fit,
          placeholderBuilder: (context) => _buildFallback(w, h, brandColor),
        ),
      );
    } else {
      logoContent = _buildFallback(w, h, brandColor);
    }

    if (showBadgeBackground) {
      return Container(
        width: w + 8,
        height: h + 8,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(borderRadius + 2),
          border: Border.all(color: Colors.white12),
        ),
        child: Center(child: logoContent),
      );
    }

    return logoContent;
  }

  Widget _buildFallback(double w, double h, Color brandColor) {
    final initials = getInitials(marketplaceName);
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: brandColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: (w * 0.38).clamp(10.0, 24.0),
          ),
        ),
      ),
    );
  }
}
