import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes/app_navigate.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/responsive_auth_layout.dart';
import 'driver_documents_field.dart';
import 'driver_terms_provider.dart';

enum AccountType { customer, driver }

enum _DriverDateField { birth, cccdExpiry, insuranceExpiry }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.initialType = AccountType.customer});

  final AccountType initialType;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _cccdCtrl = TextEditingController();
  final _cccdExpiryCtrl = TextEditingController();
  final _licenseNumberCtrl = TextEditingController();
  final _insuranceExpiryCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  AccountType _type = AccountType.customer;
  DateTime? _birthDate;
  DateTime? _cccdExpiry;
  DateTime? _insuranceExpiry;
  String? _licenseClass;
  bool _obscure = true;
  bool _agree = true;

  bool get _isDriver => _type == AccountType.driver;

  @override
  void initState() {
    super.initState();
    if (widget.initialType == AccountType.driver &&
        ref.read(driverTermsConsentProvider)) {
      _type = AccountType.driver;
    }
  }

  Future<void> _selectType(AccountType type) async {
    if (type == AccountType.driver && !ref.read(driverTermsConsentProvider)) {
      final accepted = await AppNavigate.instance.gotoDriverTerms();
      if (!mounted || accepted != true) return;
    }
    setState(() => _type = type);
  }

  Future<void> _selectDate(_DriverDateField field) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final isBirth = field == _DriverDateField.birth;
    final picked = await showDatePicker(
      context: context,
      initialDate: isBirth
          ? DateTime(today.year - 25, today.month, today.day)
          : DateTime(today.year + 1, today.month, today.day),
      firstDate: isBirth ? DateTime(1900) : today.add(const Duration(days: 1)),
      lastDate: isBirth ? today : DateTime(today.year + 20),
      helpText: isBirth ? 'Chọn ngày sinh' : 'Chọn ngày hết hạn',
    );
    if (!mounted || picked == null) return;

    final formatted =
        '${picked.day.toString().padLeft(2, '0')}/'
        '${picked.month.toString().padLeft(2, '0')}/'
        '${picked.year}';
    setState(() {
      switch (field) {
        case _DriverDateField.birth:
          _birthDate = picked;
          _birthDateCtrl.text = formatted;
        case _DriverDateField.cccdExpiry:
          _cccdExpiry = picked;
          _cccdExpiryCtrl.text = formatted;
        case _DriverDateField.insuranceExpiry:
          _insuranceExpiry = picked;
          _insuranceExpiryCtrl.text = formatted;
      }
    });
  }

  String? _validateDriverDate(_DriverDateField field) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (field == _DriverDateField.birth) {
      final birth = _birthDate;
      if (birth == null) return 'Vui lòng chọn ngày sinh.';
      var age = today.year - birth.year;
      if (today.month < birth.month ||
          (today.month == birth.month && today.day < birth.day)) {
        age--;
      }
      return age < 18 || age > 60 ? 'Tài xế cần từ 18 đến 60 tuổi.' : null;
    }
    final expiry = field == _DriverDateField.cccdExpiry
        ? _cccdExpiry
        : _insuranceExpiry;
    if (expiry == null) return 'Vui lòng chọn ngày hết hạn.';
    return expiry.isAfter(today) ? null : 'Giấy tờ cần còn hiệu lực.';
  }

  Widget _dateInput({
    required String label,
    required TextEditingController controller,
    required _DriverDateField field,
  }) {
    return LabeledField(
      label: label,
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _selectDate(field),
        decoration: const InputDecoration(
          hintText: 'dd/MM/yyyy',
          prefixIcon: Icon(Icons.calendar_today_outlined),
          suffixIcon: Icon(Icons.arrow_drop_down_rounded),
        ),
        validator: (_) => _validateDriverDate(field),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _phoneCtrl,
      _addressCtrl,
      _plateCtrl,
      _birthDateCtrl,
      _cccdCtrl,
      _cccdExpiryCtrl,
      _licenseNumberCtrl,
      _insuranceExpiryCtrl,
      _passCtrl,
      _confirmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_isDriver && !ref.read(driverTermsConsentProvider)) {
      _toast('Vui lòng đọc và đồng ý với điều khoản tài xế trước.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (!_isDriver && !_agree) {
      _toast('Vui lòng đồng ý với điều khoản sử dụng.');
      return;
    }
    if (_isDriver) {
      _toast('Thông tin hợp lệ. Chức năng gửi hồ sơ tài xế chưa khả dụng.');
    } else {
      _toast('Đăng ký thành công! Mời bạn đăng nhập.');
      Navigator.maybePop(context);
    }
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
            _Segment(value: _type, onChanged: _selectType),
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

            if (_isDriver) ...[
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
              _pair(
                size,
                _dateInput(
                  label: 'Ngày sinh *',
                  controller: _birthDateCtrl,
                  field: _DriverDateField.birth,
                ),
                LabeledField(
                  label: 'Số CCCD *',
                  child: TextFormField(
                    controller: _cccdCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    decoration: const InputDecoration(
                      hintText: '12 chữ số',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) =>
                        RegExp(r'^\d{12}$').hasMatch(value?.trim() ?? '')
                        ? null
                        : 'CCCD cần có đúng 12 chữ số.',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _pair(
                size,
                _dateInput(
                  label: 'Ngày hết hạn CCCD *',
                  controller: _cccdExpiryCtrl,
                  field: _DriverDateField.cccdExpiry,
                ),
                LabeledField(
                  label: 'Số giấy phép lái xe *',
                  child: TextFormField(
                    controller: _licenseNumberCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nhập số giấy phép',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                    ),
                    validator: (value) => Validators.notEmpty(
                      value,
                      'Vui lòng nhập số giấy phép lái xe.',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _pair(
                size,
                LabeledField(
                  label: 'Hạng giấy phép lái xe *',
                  child: DropdownButtonFormField<String>(
                    initialValue: _licenseClass,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.two_wheeler_outlined),
                    ),
                    hint: const Text('Chọn hạng'),
                    items: const [
                      DropdownMenuItem(value: 'A1', child: Text('A1')),
                      DropdownMenuItem(value: 'A2', child: Text('A2')),
                    ],
                    onChanged: (value) => setState(() => _licenseClass = value),
                    validator: (value) =>
                        value == null ? 'Vui lòng chọn hạng giấy phép.' : null,
                  ),
                ),
                _dateInput(
                  label: 'Ngày hết hạn bảo hiểm xe *',
                  controller: _insuranceExpiryCtrl,
                  field: _DriverDateField.insuranceExpiry,
                ),
              ),
              const SizedBox(height: 22),
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

            if (_isDriver)
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
              onPressed: _submit,
              child: Text(_isDriver ? 'Kiểm tra thông tin' : 'Gửi đăng ký'),
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
