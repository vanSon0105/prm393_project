
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final blue = const Color(0xFF2F6BDB);

  final nameController =
      TextEditingController(text: 'Nguyễn Văn An');
  final phoneController =
      TextEditingController(text: '0912345678');
  final emailController =
      TextEditingController(text: 'an@example.com');
  final addressController =
      TextEditingController(text: 'Hà Nội, Việt Nam');

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
    required IconData icon,
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
          prefixIcon: Icon(icon, color: blue),
          filled: true,
          fillColor: const Color(0xFFF6F8FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          suffixIcon: isEditing
              ? const Icon(Icons.edit_outlined, size: 18)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông tin tài khoản',
          style: TextStyle(fontWeight: FontWeight.bold),
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
                    backgroundColor:
                        const Color(0xFFE4EDFF),
                    child: Icon(
                      Icons.person,
                      size: 65,
                      color: blue,
                    ),
                  ),
                  if (isEditing)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: blue,
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
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
                    ? 'Người dùng'
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
                  color: const Color(0xFFE4EDFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role,
                  style: TextStyle(
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin cá nhân',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  inputField(
                    label: 'Họ và tên',
                    icon: Icons.person_outline,
                    controller: nameController,
                  ),
                  inputField(
                    label: 'Số điện thoại',
                    icon: Icons.phone_outlined,
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  inputField(
                    label: 'Email',
                    icon: Icons.email_outlined,
                    controller: emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                  ),
                  inputField(
                    label: 'Địa chỉ',
                    icon: Icons.location_on_outlined,
                    controller: addressController,
                  ),
                  const Text(
                    'Vai trò tài khoản',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF6F8FC),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Khách hàng',
                        child: Text('Khách hàng'),
                      ),
                      DropdownMenuItem(
                        value: 'Tài xế',
                        child: Text('Tài xế'),
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
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Đã lưu thông tin tạm thời (demo)',
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(
                  isEditing
                      ? Icons.save_outlined
                      : Icons.edit_outlined,
                ),
                label: Text(
                  isEditing
                      ? 'Lưu thông tin'
                      : 'Chỉnh sửa thông tin',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

