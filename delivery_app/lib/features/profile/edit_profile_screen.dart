import 'dart:typed_data';

import 'package:delivery_app/core/theme/app_theme.dart';
import 'package:delivery_app/features/app_view_model.dart';
import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/gen/assets.gen.dart';
import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_provider.dart';
import 'profile_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const blue = AppColors.blue;
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  UserProfile? _loadedProfile;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _editing = false;
  bool _saving = false;
  int _avatarVersion = 0;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _fill(UserProfile profile) {
    if (!mounted || _loadedProfile?.id == profile.id) return;
    setState(() {
      _loadedProfile = profile;
      _name.text = profile.fullName;
      _phone.text = profile.phoneNumber;
      _address.text = profile.address;
      _imageBytes = null;
      _imageName = null;
    });
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickImage() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        _notice(LocaleKeys.profile_image_size_error.tr());
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
    } catch (_) {
      if (mounted) _notice(LocaleKeys.register_file_read_error.tr());
    }
  }

  Future<void> _save() async {
    final original = _loadedProfile;
    if (original == null || _saving || !_formKey.currentState!.validate()) {
      return;
    }
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final address = _address.text.trim();
    if (address.isEmpty && original.address.isNotEmpty) {
      _notice(LocaleKeys.profile_address_cannot_clear.tr());
      return;
    }
    final changes = ProfileChanges(
      fullName: name == original.fullName ? null : name,
      phoneNumber: phone == original.phoneNumber ? null : phone,
      address: address == original.address || address.isEmpty ? null : address,
      imageBytes: _imageBytes,
      imageName: _imageName,
    );
    if (changes.isEmpty) {
      setState(() => _editing = false);
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(profileRepositoryProvider)
          .updateProfile(original.id, changes);
      if (!mounted) return;
      setState(() {
        _loadedProfile = saved;
        _name.text = saved.fullName;
        _phone.text = saved.phoneNumber;
        _address.text = saved.address;
        _imageBytes = null;
        _imageName = null;
        _editing = false;
        if (changes.imageBytes != null) _avatarVersion++;
      });
      ref.invalidate(userProfileProvider(original.id));
      _notice(LocaleKeys.profile_saved.tr());
    } catch (_) {
      if (mounted) _notice(LocaleKeys.profile_save_error.tr());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field({
    required String label,
    required SvgGenImage icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      controller: controller,
      readOnly: !_editing || _saving,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: icon.svg(
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(blue, BlendMode.srcIn),
          ),
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _avatar(UserProfile profile) => Center(
    child: InkWell(
      onTap: _editing && !_saving ? _pickImage : null,
      borderRadius: BorderRadius.circular(60),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.blueSoft,
            child: ClipOval(
              child: _imageBytes != null
                  ? Image.memory(
                      _imageBytes!,
                      width: 104,
                      height: 104,
                      fit: BoxFit.cover,
                    )
                  : profile.imageUrl.isNotEmpty
                  ? Image.network(
                      _avatarVersion == 0
                          ? profile.imageUrl
                          : Uri.parse(profile.imageUrl)
                                .replace(
                                  queryParameters: {'v': '$_avatarVersion'},
                                )
                                .toString(),
                      width: 104,
                      height: 104,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _defaultAvatar(),
                    )
                  : _defaultAvatar(),
            ),
          ),
          if (_editing)
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 17,
                backgroundColor: blue,
                child: Assets.images.icCamera.svg(
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    AppColors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _defaultAvatar() => Assets.images.icUser.svg(
    width: 65,
    height: 65,
    colorFilter: const ColorFilter.mode(blue, BlendMode.srcIn),
  );

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appViewModelProvider);
    final roleLabel = switch (app.role) {
      Role.admin => LocaleKeys.users_role_admin.tr(),
      Role.driver => LocaleKeys.profile_driver.tr(),
      Role.customer => LocaleKeys.profile_customer.tr(),
      null => '',
    };
    final profileId = app.profileId;
    final profile = profileId == null || profileId <= 0
        ? null
        : ref.watch(userProfileProvider(profileId));

    return Theme(
      data: AppTheme.light(),
      child: Scaffold(
        appBar: AppBar(title: Text(LocaleKeys.profile_title.tr())),
        body: SafeArea(
          child: profile == null
              ? Center(child: Text(LocaleKeys.profile_sign_in_again.tr()))
              : profile.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(LocaleKeys.profile_load_error.tr()),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(userProfileProvider(profileId!)),
                          child: Text(LocaleKeys.admin_try_again.tr()),
                        ),
                      ],
                    ),
                  ),
                  data: (value) {
                    if (_loadedProfile?.id != value.id) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _fill(value),
                      );
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _content(value, roleLabel);
                  },
                ),
        ),
      ),
    );
  }

  Widget _content(UserProfile profile, String roleLabel) => Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        _avatar(profile),
        const SizedBox(height: 14),
        Center(
          child: Text(
            _name.text.isEmpty ? LocaleKeys.profile_user.tr() : _name.text,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Center(child: Chip(label: Text(roleLabel))),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceStrong,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.profile_personal_info.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _field(
                label: LocaleKeys.profile_full_name.tr(),
                icon: Assets.images.icUser,
                controller: _name,
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ||
                        (v?.trim().runes.length ?? 0) > 45
                    ? LocaleKeys.profile_name_invalid.tr()
                    : null,
              ),
              _field(
                label: LocaleKeys.profile_phone.tr(),
                icon: Assets.images.icPhone,
                controller: _phone,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    RegExp(r'^\+?\d{9,15}$').hasMatch(v?.trim() ?? '')
                    ? null
                    : LocaleKeys.profile_phone_invalid.tr(),
              ),
              _field(
                label: LocaleKeys.profile_address.tr(),
                icon: Assets.images.icLocation,
                controller: _address,
                validator: (v) => (v?.trim().runes.length ?? 0) > 45
                    ? LocaleKeys.profile_address_invalid.tr()
                    : null,
              ),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: LocaleKeys.profile_role.tr(),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                child: Text(roleLabel),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _saving
                ? null
                : (_editing ? _save : () => setState(() => _editing = true)),
            icon: (_editing ? Assets.images.icSave : Assets.images.icUserEdit)
                .svg(
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    AppColors.white,
                    BlendMode.srcIn,
                  ),
                ),
            label: Text(
              _saving
                  ? LocaleKeys.admin_saving.tr()
                  : _editing
                  ? LocaleKeys.profile_save.tr()
                  : LocaleKeys.profile_edit.tr(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
