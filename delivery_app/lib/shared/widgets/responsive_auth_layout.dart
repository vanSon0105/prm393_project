import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'common.dart';

///  RESPONSIVE UI (mobile-first) – dùng chung cho Đăng nhập & Đăng ký
///    • Mobile  : width < 600       → form full màn hình như app
///    • Tablet  : 600 ≤ width < 1024 → form trong thẻ trắng giữa màn hình
///    • Desktop : width ≥ 1024      → 2 cột: banner thương hiệu | form

enum ScreenSize { mobile, tablet, desktop }

//xep loai man hinh
class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  static ScreenSize of(double width) {
    if (width >= desktop) return ScreenSize.desktop;
    if (width >= tablet) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }
}

class ResponsiveAuthLayout extends StatelessWidget {
  const ResponsiveAuthLayout({
    super.key,
    required this.form,
    required this.brandTitle,
    required this.brandSubtitle,
    required this.brandChips,
    this.cardMaxWidth = 480,
  });

  /// Nội dung form – nhận ScreenSize để tự đổi bố cục bên trong
  final Widget Function(ScreenSize size) form;
  final String brandTitle;
  final String brandSubtitle;
  final List<Widget> brandChips;
  final double cardMaxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //đo độ rộng
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Breakpoints.of(constraints.maxWidth);
          //xếp loại bố cục theo màn
          final Widget content = switch (size) {
            // MOBILE 
            ScreenSize.mobile => SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: form(size),
                ),
              ),

            // TABLET 
            ScreenSize.tablet => Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardMaxWidth),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x140F172A),
                            blurRadius: 30,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: form(size),
                    ),
                  ),
                ),
              ),

            // DESKTOP
            ScreenSize.desktop => Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 55,
                    child: _BrandPanel(
                      title: brandTitle,
                      subtitle: brandSubtitle,
                      chips: brandChips,
                      large: constraints.maxWidth >= 1440,
                    ),
                  ),
                  Expanded(
                    flex: 45,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(48),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: form(size),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          };

          return Stack(
            children: [
              Positioned.fill(child: content),
              // Huy hiệu hiển thị breakpoint – để demo responsive
              Positioned(right: 12, bottom: 12, child: BreakpointBadge(size: size)),
            ],
          );
        },
      ),
    );
  }
}

/// Banner xanh bên trái – chỉ có ở Desktop
class _BrandPanel extends StatelessWidget {
  const _BrandPanel({
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.large,
  });

  final String title;
  final String subtitle;
  final List<Widget> chips;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), AppColors.primary, Color(0xFF1E3A8A)],
          stops: [0, .55, 1],
        ),
      ),
      child: Stack(
        children: [
          // Vòng tròn 
          Positioned(
            right: -120,
            bottom: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x12FFFFFF), width: 60),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: large ? 96 : 56,
              vertical: large ? 64 : 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const NoiLogo(color: Colors.white, fontSize: 28),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: large ? 52 : 44,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xD9FFFFFF),
                          fontSize: 17,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(spacing: 12, runSpacing: 12, children: chips),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nhãn nhỏ góc phải dưới cho biết đang ở breakpoint nào
class BreakpointBadge extends StatelessWidget {
  const BreakpointBadge({super.key, required this.size});
  final ScreenSize size;

  @override
  Widget build(BuildContext context) {
    final label = switch (size) {
      ScreenSize.mobile => '📱 Mobile < 600',
      ScreenSize.tablet => '📲 Tablet 600–1023',
      ScreenSize.desktop => '🖥️ Desktop ≥ 1024',
    };
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xD90F172A),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
