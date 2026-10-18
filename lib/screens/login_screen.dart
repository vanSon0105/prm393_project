import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/responsive_auth_layout.dart';

/// STT 2 – Màn hình đăng nhập (Khách hàng / Tài xế / Admin) – NgLinh
enum UserRole { customer, driver, admin }

extension on UserRole {
  String get label => switch (this) {
        UserRole.customer => 'Khách hàng',
        UserRole.driver => 'Tài xế',
        UserRole.admin => 'Admin',
      };
  IconData get icon => switch (this) {
        UserRole.customer => Icons.person_outline_rounded,
        UserRole.driver => Icons.two_wheeler_rounded,
        UserRole.admin => Icons.verified_user_outlined,
      };
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  UserRole _role = UserRole.customer;
  bool _obscure = true;
  bool _remember = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đăng nhập thành công với vai trò: ${_role.label}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveAuthLayout(
      brandTitle: 'Đi đúng nơi.\nGiao đúng lúc.',
      brandSubtitle:
          'Đồ ăn, hàng hóa và dịch vụ vận chuyển chuyên biệt trong một ứng dụng.',
      brandChips: const [
        BrandChip(label: 'Đồ ăn', icon: Icons.two_wheeler_rounded),
        BrandChip(label: 'Hàng hóa', icon: Icons.inventory_2_outlined),
        BrandChip(label: 'Đưa đón', icon: Icons.directions_car_outlined),
      ],
      form: (size) => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTopBar(size: size),
            AuthHeading(
                title: 'Chào bạn',
                subtitle: 'Chọn vai trò để tiếp tục.',
                size: size),

            // Chọn vai trò
            Row(
              children: [
                for (final r in UserRole.values) ...[
                  Expanded(
                    child: _RoleTile(
                      role: r,
                      selected: r == _role,
                      onTap: () => setState(() => _role = r),
                    ),
                  ),
                  if (r != UserRole.values.last) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 22),

            LabeledField(
              label: 'Số điện thoại',
              child: TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: '090 123 4567',
                  prefixIcon: Icon(Icons.phone_iphone_rounded),
                ),
                validator: Validators.phone,
              ),
            ),
            const SizedBox(height: 16),

            LabeledField(
              label: 'Mật khẩu',
              child: TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Nhập mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: Validators.password,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Checkbox(
                  value: _remember,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _remember = v ?? false),
                ),
                const Text('Ghi nhớ tôi', style: TextStyle(color: AppColors.muted)),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('Quên mật khẩu?',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ElevatedButton(onPressed: _submit, child: const Text('Đăng nhập')),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Chưa có tài khoản?',
                    style: TextStyle(color: AppColors.muted)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Đăng ký',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({required this.role, required this.selected, required this.onTap});
  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.line,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Column(
            children: [
              Icon(role.icon,
                  color: selected ? AppColors.primary : AppColors.muted, size: 24),
              const SizedBox(height: 6),
              Text(
                role.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primaryDark : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
