import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../generated/locale_keys.g.dart';

import '../../core/theme/app_theme.dart';
import '../../gen/assets.gen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const blue = AppColors.blue;

  final nameController = TextEditingController(text: 'Nguyễn Văn An');
  final phoneController = TextEditingController(text: '0912345678');
  final emailController = TextEditingController(text: 'an@example.com');
  final addressController = TextEditingController(text: 'Hà Nội, Việt Nam');

  bool isEditing = false;
  String role = 'Khách hàng';

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Widget inputField({
    required String label,
    required SvgGenImage icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        readOnly: !isEditing,
        keyboardType: keyboardType,
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
          suffixIcon: isEditing
              ? Padding(
                  padding: const EdgeInsets.all(15),
                  child: Assets.images.icUserEdit.svg(
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textSoft,
                      BlendMode.srcIn,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            LocaleKeys.profile_title.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 10),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.blueSoft,
                      child: Assets.images.icUser.svg(
                        width: 65,
                        height: 65,
                        colorFilter: const ColorFilter.mode(
                          blue,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    if (isEditing)
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
              const SizedBox(height: 14),
              Center(
                child: Text(
                  nameController.text.isEmpty
                      ? LocaleKeys.profile_user.tr()
                      : nameController.text,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role == 'Khách hàng'
                        ? LocaleKeys.profile_customer.tr()
                        : LocaleKeys.profile_driver.tr(),
                    style: const TextStyle(
                      color: blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
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
                    inputField(
                      label: LocaleKeys.profile_full_name.tr(),
                      icon: Assets.images.icUser,
                      controller: nameController,
                    ),
                    inputField(
                      label: LocaleKeys.profile_phone.tr(),
                      icon: Assets.images.icPhone,
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    inputField(
                      label: LocaleKeys.profile_email.tr(),
                      icon: Assets.images.icEmail,
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    inputField(
                      label: LocaleKeys.profile_address.tr(),
                      icon: Assets.images.icLocation,
                      controller: addressController,
                    ),
                    Text(
                      LocaleKeys.profile_role.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'Khách hàng',
                          child: Text(LocaleKeys.profile_customer.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'Tài xế',
                          child: Text(LocaleKeys.profile_driver.tr()),
                        ),
                      ],
                      onChanged: isEditing
                          ? (value) {
                              if (value != null) {
                                setState(() => role = value);
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isEditing = !isEditing;
                    });

                    if (!isEditing) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(LocaleKeys.profile_saved_demo.tr()),
                        ),
                      );
                    }
                  },
                  icon: (isEditing
                          ? Assets.images.icSave
                          : Assets.images.icUserEdit)
                      .svg(
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(
                          AppColors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                  label: Text(
                    isEditing
                        ? LocaleKeys.profile_save.tr()
                        : LocaleKeys.profile_edit.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
        ),
      ),
    );
  }
}
