import 'package:delivery_app/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
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
          title: Text(LocaleKeys.driver_terms_title.tr()),
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
                        children: [
                          const Icon(
                            Icons.two_wheeler_rounded,
                            size: 44,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            LocaleKeys.driver_terms_heading.tr(),
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            LocaleKeys.driver_terms_intro.tr(),
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _TermsSection(
                            number: '01',
                            title: LocaleKeys.driver_terms_eligibility_title
                                .tr(),
                            items: [
                              LocaleKeys.driver_terms_eligibility_age.tr(),
                              LocaleKeys.driver_terms_eligibility_id.tr(),
                              LocaleKeys.driver_terms_eligibility_license.tr(),
                              LocaleKeys.driver_terms_eligibility_vehicle.tr(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _TermsSection(
                            number: '02',
                            title: LocaleKeys.driver_terms_information_title
                                .tr(),
                            items: [
                              LocaleKeys.driver_terms_information_accurate.tr(),
                              LocaleKeys.driver_terms_information_valid.tr(),
                              LocaleKeys.driver_terms_information_update.tr(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _TermsSection(
                            number: '03',
                            title: LocaleKeys.driver_terms_review_title.tr(),
                            items: [
                              LocaleKeys.driver_terms_review_pending.tr(),
                              LocaleKeys.driver_terms_review_required.tr(),
                              LocaleKeys.driver_terms_review_correction.tr(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _TermsSection(
                            number: '04',
                            title: LocaleKeys.driver_terms_trips_title.tr(),
                            items: [
                              LocaleKeys.driver_terms_trips_ready.tr(),
                              LocaleKeys.driver_terms_trips_progress.tr(),
                              LocaleKeys.driver_terms_trips_cancel.tr(),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            LocaleKeys.driver_terms_confirmation.tr(),
                            style: const TextStyle(
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
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                LocaleKeys.driver_terms_scroll_hint.tr(),
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            ),
                          CheckboxListTile(
                            value: _agreed,
                            onChanged: _readToEnd
                                ? (value) =>
                                      setState(() => _agreed = value ?? false)
                                : null,
                            title: Text(
                              LocaleKeys.driver_terms_agree.tr(),
                              style: const TextStyle(fontSize: 14),
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
                            child: Text(LocaleKeys.driver_terms_continue.tr()),
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
