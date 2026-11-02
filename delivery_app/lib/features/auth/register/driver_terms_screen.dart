import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/common.dart';
import 'driver_terms_provider.dart';

class DriverTermsScreen extends ConsumerStatefulWidget {
  const DriverTermsScreen({super.key});

  @override
  ConsumerState<DriverTermsScreen> createState() => _DriverTermsScreenState();
}

class _DriverTermsScreenState extends ConsumerState<DriverTermsScreen> {
  final _scrollController = ScrollController();
  bool _readToEnd = false;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollEnd);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollEnd());
  }

  void _checkScrollEnd() {
    if (!mounted || !_scrollController.hasClients || _readToEnd) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0 ||
        position.pixels >= position.maxScrollExtent - 24) {
      setState(() => _readToEnd = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          title: const Text('Điều khoản tài xế'),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: Center(child: NoiLogo(fontSize: 18)),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            Icons.two_wheeler_rounded,
                            size: 44,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Điều kiện đăng ký tài xế',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Vui lòng đọc các điều kiện dưới đây trước khi điền thông tin đăng ký.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: AppColors.muted,
                            ),
                          ),
                          SizedBox(height: 28),
                          _TermsSection(
                            number: '01',
                            title: 'Điều kiện đăng ký',
                            items: [
                              'Bạn từ 18 đến 60 tuổi tại ngày đăng ký.',
                              'Có CCCD gồm 12 chữ số và còn hiệu lực.',
                              'Có giấy phép lái xe hạng A1 hoặc A2 và bảo hiểm xe còn hạn.',
                              'Sử dụng xe máy có biển số hợp lệ để nhận chuyến.',
                            ],
                          ),
                          SizedBox(height: 16),
                          _TermsSection(
                            number: '02',
                            title: 'Thông tin đăng ký',
                            items: [
                              'Cung cấp thông tin cá nhân và phương tiện chính xác, sử dụng giấy tờ của chính bạn.',
                              'Đảm bảo CCCD, giấy phép lái xe và bảo hiểm xe còn hiệu lực trong thời gian hoạt động.',
                              'Cập nhật thông tin khi giấy tờ hoặc phương tiện thay đổi.',
                            ],
                          ),
                          SizedBox(height: 16),
                          _TermsSection(
                            number: '03',
                            title: 'Xét duyệt tài khoản',
                            items: [
                              'Đăng ký tài khoản không đồng nghĩa với việc được nhận chuyến ngay.',
                              'Tài khoản tài xế cần được xét duyệt trước khi có thể bật nhận chuyến.',
                              'Nếu thông tin không chính xác hoặc giấy tờ hết hiệu lực, bạn cần bổ sung hoặc cập nhật trước khi hoạt động.',
                            ],
                          ),
                          SizedBox(height: 16),
                          _TermsSection(
                            number: '04',
                            title: 'Khi nhận chuyến',
                            items: [
                              'Chỉ bật nhận chuyến khi bạn sẵn sàng và đủ điều kiện hoạt động.',
                              'Sau khi nhận chuyến, cập nhật đúng các bước đến điểm đón, đón khách và hoàn thành chuyến trong ứng dụng.',
                              'Nếu không thể tiếp tục chuyến, hãy dùng chức năng hủy và ghi rõ lý do.',
                            ],
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Bằng việc đồng ý, bạn xác nhận đã đọc và hiểu các điều kiện đăng ký tài xế ở trên. Sau đó, bạn có thể tiếp tục điền hồ sơ.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Material(
                    color: AppColors.surface,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.line)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_readToEnd)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Cuộn xuống cuối để đọc toàn bộ điều khoản.',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ),
                          CheckboxListTile(
                            value: _agreed,
                            onChanged: _readToEnd
                                ? (value) =>
                                      setState(() => _agreed = value ?? false)
                                : null,
                            title: const Text(
                              'Tôi đã đọc và đồng ý với điều khoản dành cho tài xế',
                              style: TextStyle(fontSize: 14),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _readToEnd && _agreed
                                ? () {
                                    ref
                                        .read(
                                          driverTermsConsentProvider.notifier,
                                        )
                                        .accept();
                                    context.pop(true);
                                  }
                                : null,
                            child: const Text('Tiếp tục đăng ký tài xế'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.number,
    required this.title,
    required this.items,
  });

  final String number;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number  $title',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(color: AppColors.primary)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        height: 1.45,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
