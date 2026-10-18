import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/responsive_auth_layout.dart';

enum AccountType { customer, driver }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  AccountType _type = AccountType.customer;
  String _vehicle = 'Xe máy';
  bool _obscure = true;
  bool _agree = true;

  static const _vehicles = ['Xe máy', 'Ô tô 4 chỗ', 'Xe tải nhỏ'];

  bool get _isDriver => _type == AccountType.driver;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _phoneCtrl,
      _addressCtrl,
      _plateCtrl,
      _passCtrl,
      _confirmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      _toast('Vui lòng đồng ý với điều khoản sử dụng.');
      return;
    }
    if (_isDriver) {
      _toast('Đã gửi yêu cầu mở tài khoản tài xế. Vui lòng chờ admin duyệt.');
    } else {
      _toast('Đăng ký thành công! Mời bạn đăng nhập.');
      Navigator.maybePop(context);
    }
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /// RESPONSIVE: mobile xếp dọc 1 cột, tablet/desktop xếp 2 cột cạnh nhau
  Widget _pair(ScreenSize size, Widget a, Widget b) {
    if (size == ScreenSize.mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [a, const SizedBox(height: 16), b],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 16),
        Expanded(child: b),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveAuthLayout(
      cardMaxWidth: 560,
      brandTitle: 'Tham gia Nối\nchỉ trong 1 phút.',
      brandSubtitle: 'Khách hàng dùng ngay sau khi đăng ký. Tài khoản tài xế sẽ được admin duyệt trước khi nhận chuyến.',
      brandChips: const [
        BrandChip(label: 'Miễn phí đăng ký'),
        BrandChip(label: 'Thanh toán tiền mặt / QR'),
      ],
      form: (size) => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTopBar(size: size, eyebrow: 'Tạo tài khoản'),
            AuthHeading(
              title: 'Thông tin đăng ký',
              subtitle: 'Chọn loại tài khoản và điền thông tin cơ bản.',
              size: size,
            ),

            // Tab Khách hàng / Tài xế
            _Segment(value: _type, onChanged: (t) => setState(() => _type = t)),
            const SizedBox(height: 22),

            LabeledField(
              label: 'Họ và tên',
              child: TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Nguyễn Văn A',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) =>
                    Validators.notEmpty(v, 'Vui lòng nhập họ và tên.'),
              ),
            ),
            const SizedBox(height: 16),

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
              label: 'Địa chỉ thường dùng',
              child: TextFormField(
                controller: _addressCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: '12 Nguyễn Huệ, Quận 1',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
            ),

            // Chỉ hiện khi chọn Tài xế
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _isDriver
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _pair(
                        size,
                        LabeledField(
                          label: 'Loại xe',
                          child: _VehiclePicker(
                            value: _vehicle,
                            options: _vehicles,
                            onChanged: (v) => setState(() => _vehicle = v),
                          ),
                        ),
                        LabeledField(
                          label: 'Biển số xe',
                          child: TextFormField(
                            controller: _plateCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: '59A1 234.56',
                              prefixIcon: Icon(Icons.credit_card_outlined),
                            ),
                            validator: (v) => _isDriver
                                ? Validators.notEmpty(
                                    v,
                                    'Vui lòng nhập biển số xe.',
                                  )
                                : null,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 16),

            _pair(
              size,
              LabeledField(
                label: 'Mật khẩu',
                child: TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Tối thiểu 6 ký tự',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: Validators.password,
                ),
              ),
              LabeledField(
                label: 'Nhập lại mật khẩu',
                child: TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    hintText: 'Nhập lại',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (v) => (v ?? '').isEmpty || v != _passCtrl.text
                      ? 'Mật khẩu nhập lại không khớp.'
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Checkbox(
                  value: _agree,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                ),
                const Expanded(
                  child: Text(
                    'Tôi đồng ý với điều khoản sử dụng',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _submit,
              child: const Text('Gửi đăng ký'),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Đã có tài khoản?',
                  style: TextStyle(color: AppColors.muted),
                ),
                TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab bo tròn Khách hàng / Tài xế
class _Segment extends StatelessWidget {
  const _Segment({required this.value, required this.onChanged});
  final AccountType value;
  final ValueChanged<AccountType> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(AccountType t, String label) {
      final selected = t == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x140F172A),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.ink : AppColors.muted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          tab(AccountType.customer, 'Khách hàng'),
          tab(AccountType.driver, 'Tài xế'),
        ],
      ),
    );
  }
}

/// Chọn loại xe (bấm để mở danh sách)
class _VehiclePicker extends StatelessWidget {
  const _VehiclePicker({
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final o in options) PopupMenuItem(value: o, child: Text(o)),
      ],
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.two_wheeler_rounded),
          suffixIcon: Icon(Icons.expand_more_rounded),
        ),
        child: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
