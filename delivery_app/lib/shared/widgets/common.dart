import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'responsive_auth_layout.dart';

/// Logo "nối"
class NoiLogo extends StatelessWidget {
  const NoiLogo({super.key, this.color = AppColors.ink, this.fontSize = 22});
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.route_rounded,
            size: fontSize + 4,
            color: color == AppColors.ink ? AppColors.primary : color),
        const SizedBox(width: 6),
        Text('nối',
            style: TextStyle(
                fontSize: fontSize, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

/// Thanh trên cùng: nút back + (tiêu đề nhỏ) + logo
/// Desktop đã có logo ở banner nên ẩn logo ở đây.
class AuthTopBar extends StatelessWidget {
  const AuthTopBar({super.key, required this.size, this.eyebrow, this.onBack});
  final ScreenSize size;
  final String? eyebrow;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        children: [
          Material(
            color: AppColors.surface,
            shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack ?? () => Navigator.maybePop(context),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.chevron_left_rounded, color: AppColors.ink),
              ),
            ),
          ),
          if (eyebrow != null) ...[
            const SizedBox(width: 12),
            Text(eyebrow!,
                style: const TextStyle(
                    color: AppColors.muted, fontWeight: FontWeight.w600)),
          ],
          const Spacer(),
          if (size != ScreenSize.desktop) const NoiLogo(),
        ],
      ),
    );
  }
}

/// Tiêu đề + mô tả
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.subtitle, required this.size});
  final String title;
  final String subtitle;
  final ScreenSize size;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
              fontSize: size == ScreenSize.mobile ? 28 : 30,
              fontWeight: FontWeight.w800,
              height: 1.2,
            )),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 15)),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Nhãn + ô nhập
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Chip trên banner desktop
class BrandChip extends StatelessWidget {
  const BrandChip({super.key, required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x24FFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.check_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Kiểm tra dữ liệu
class Validators {
  static String? phone(String? v) {
    final s = (v ?? '').replaceAll(' ', '');
    if (!RegExp(r'^0\d{9}$').hasMatch(s)) {
      return 'Số điện thoại gồm 10 chữ số, bắt đầu bằng 0.';
    }
    return null;
  }

  static String? password(String? v) =>
      (v ?? '').length < 6 ? 'Mật khẩu tối thiểu 6 ký tự.' : null;

  static String? notEmpty(String? v, String message) =>
      (v ?? '').trim().isEmpty ? message : null;
}
