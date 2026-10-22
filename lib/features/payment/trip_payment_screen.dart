
import 'package:flutter/material.dart';

class TripPaymentScreen extends StatefulWidget {
  const TripPaymentScreen({super.key});

  @override
  State<TripPaymentScreen> createState() =>
      _TripPaymentScreenState();
}

class _TripPaymentScreenState
    extends State<TripPaymentScreen> {
  final blue = const Color(0xFF2F6BDB);
  String paymentMethod = 'cash';

  Widget paymentOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = paymentMethod == value;

    return InkWell(
      onTap: () => setState(() => paymentMethod = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEAF1FF)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? blue : const Color(0xFFE1E6EF),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: blue, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: paymentMethod,
              onChanged: (v) {
                if (v != null) {
                  setState(() => paymentMethod = v);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thanh toán chuyến đi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Text(
                    'Tổng tiền chuyến đi',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '42.000đ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mã chuyến: TRIP-2026-001',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle,
                          color: Color(0xFF2F6BDB),
                          size: 14),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('12 Nguyễn Huệ'),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 24,
                        child: VerticalDivider(
                          thickness: 2,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.stop,
                          color: Color(0xFF182230),
                          size: 16),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('86 Võ Văn Tần'),
                      ),
                    ],
                  ),
                  Divider(height: 30),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cước chuyến đi'),
                      Text('40.000đ'),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Phí dịch vụ'),
                      Text('2.000đ'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            paymentOption(
              value: 'cash',
              icon: Icons.payments_outlined,
              title: 'Tiền mặt',
              subtitle: 'Thanh toán trực tiếp cho tài xế',
            ),
            paymentOption(
              value: 'qr',
              icon: Icons.qr_code_2,
              title: 'QR ngân hàng',
              subtitle: 'Chuyển khoản bằng mã QR',
            ),
            if (paymentMethod == 'qr')
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 140,
                      color: Color(0xFF182230),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Minh họa QR - chưa dùng để thanh toán',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Đã chọn phương thức thanh toán (demo)',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Xác nhận thanh toán',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
