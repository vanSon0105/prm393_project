import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/features/auth/register/register_state.dart';
import 'package:delivery_app/features/auth/register/register_view_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/responsive_auth_layout.dart';
import 'driver_documents_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, required this.role});

  final Role role;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final documentsFieldKey =
      GlobalKey<FormFieldState<Map<DriverDocumentType, PlatformFile>>>();

  bool _obscure = true;
  bool _agree = true;

  RegisterViewModel get viewModel => ref.read(
    registerViewModelProvider(RegisterState(currentRole: widget.role)).notifier,
  );
  @override
  void initState() {
    super.initState();
    viewModel.getVehicleType();
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _phoneCtrl,
      _plateCtrl,
      _passCtrl,
      _confirmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /// RESPONSIVE
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
    final registerState = ref.watch(
      registerViewModelProvider(RegisterState(currentRole: widget.role)),
    );

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
            _Segment(value: registerState.currentRole, onChanged: (role) {}),
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
            // Chỉ hiện khi chọn Tài xế
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: registerState.isDriver
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _pair(
                        size,
                        LabeledField(
                          label: 'Loại xe',
                          child: const InputDecorator(
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.two_wheeler_rounded),
                            ),
                            child: Text(
                              'Xe máy',
                              style: TextStyle(fontSize: 16),
                            ),
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
                            validator: (v) => registerState.isDriver
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

            if (registerState.isDriver) ...[
              const Divider(height: 32),
              const Text(
                'Hồ sơ và giấy tờ tài xế',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Điền thông tin trên giấy tờ và chọn ảnh rõ nét để hoàn thiện hồ sơ.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              DriverDocumentsField(),
              const SizedBox(height: 16),
            ],

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

            if (registerState.isDriver)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Đã đồng ý với điều khoản dành cho tài xế'),
                    ),
                  ],
                ),
              )
            else
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
              onPressed: () {
                final isValid =
                    documentsFieldKey.currentState?.validate() ?? false;
                if (isValid) {
                  final Map<DriverDocumentType, PlatformFile>? selectedFiles =
                      documentsFieldKey.currentState?.value;
                  if (selectedFiles != null) {
                    final cccdFrontFile =
                        selectedFiles[DriverDocumentType.cccdFront];
                    final cccdBackFile =
                        selectedFiles[DriverDocumentType.cccdBack];
                    final licenseFront =
                        selectedFiles[DriverDocumentType.drivingLicenseFront];
                    final licenseBack =
                        selectedFiles[DriverDocumentType.drivingLicenseBack];
                  }
                }
              },
              child: Text(
                registerState.isDriver ? 'Kiểm tra thông tin' : 'Gửi đăng ký',
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
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

/// Tab Khách hàng / Tài xế
class _Segment extends StatelessWidget {
  const _Segment({required this.value, required this.onChanged});

  final Role value;
  final ValueChanged<Role> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(Role t, String label) {
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
          tab(Role.customer, Role.customer.title),
          tab(Role.driver, Role.driver.title),
        ],
      ),
    );
  }
}
