import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/responsive_auth_layout.dart';

/// RESPONSIVE:
///   • Mobile  (< 600)     : chữ dồn xuống dưới, nút full chiều ngang
///   • Tablet  (600–1023)  : nội dung căn giữa, rộng tối đa 520
///   • Desktop (≥ 1024)    : 2 cột – chữ bên trái, hình minh họa bên phải
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, .08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _continue() => Navigator.pushReplacementNamed(context, '/login');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), AppColors.primary, Color(0xFF1E3A8A)],
            stops: [0, .55, 1],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Breakpoints.of(constraints.maxWidth);

            final Widget content = switch (size) {
              // ---------- MOBILE ----------
              ScreenSize.mobile => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: NoiLogo(color: Colors.white, fontSize: 24),
                      ),
                      // FittedBox: máy thấp thì hình tự thu nhỏ, không bị tràn
                      const Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _Illustration(size: 220),
                          ),
                        ),
                      ),
                      _texts(size),
                      const SizedBox(height: 32),
                      _button(),
                    ],
                  ),
                ),
              ),

              // ---------- TABLET ----------
              ScreenSize.tablet => Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: _Illustration(size: 260)),
                        const SizedBox(height: 40),
                        const NoiLogo(color: Colors.white, fontSize: 28),
                        const SizedBox(height: 20),
                        _texts(size),
                        const SizedBox(height: 36),
                        _button(),
                      ],
                    ),
                  ),
                ),
              ),

              // ---------- DESKTOP ----------
              ScreenSize.desktop => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 72,
                  vertical: 56,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NoiLogo(color: Colors.white, fontSize: 28),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _texts(size),
                                  const SizedBox(height: 40),
                                  SizedBox(width: 260, child: _button()),
                                ],
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Center(child: _Illustration(size: 380)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            };

            return Stack(
              children: [
                // Vòng tròn
                Positioned(
                  right: -140,
                  bottom: -140,
                  child: Container(
                    width: 420,
                    height: 420,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0x12FFFFFF),
                        width: 64,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(position: _slide, child: content),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: BreakpointBadge(size: size),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Slogan
  Widget _texts(ScreenSize size) {
    final titleSize = switch (size) {
      ScreenSize.mobile => 34.0,
      ScreenSize.tablet => 42.0,
      ScreenSize.desktop => 56.0,
    };
    final center = size == ScreenSize.tablet;
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'Đi đúng nơi.\nGiao đúng lúc.',
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Đồ ăn, hàng hóa và dịch vụ vận chuyển chuyên biệt trong một ứng dụng.',
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            color: Color(0xD9FFFFFF),
            fontSize: 17,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// button : tiếp tục
  Widget _button() {
    return ElevatedButton(
      onPressed: _continue,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Tiếp tục'),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, size: 20),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final small = size * .26;
    Widget bubble(IconData icon) => Container(
      width: small,
      height: small,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary, size: small * .5),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0x1FFFFFFF),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: size * .62,
            height: size * .62,
            decoration: const BoxDecoration(
              color: Color(0x29FFFFFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.route_rounded,
              color: Colors.white,
              size: size * .3,
            ),
          ),
          Positioned(
            top: 0,
            left: size * .1,
            child: bubble(Icons.two_wheeler_rounded),
          ),
          Positioned(
            top: size * .18,
            right: 0,
            child: bubble(Icons.inventory_2_outlined),
          ),
          Positioned(
            bottom: 0,
            left: size * .3,
            child: bubble(Icons.directions_car_outlined),
          ),
        ],
      ),
    );
  }
}
