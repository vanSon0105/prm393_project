import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../generated/locale_keys.g.dart';

import '../../core/theme/app_theme.dart';
import '../../gen/assets.gen.dart';
import 'data/trip_rating_repository.dart';

enum TripRatingResult { submitted, alreadyRated, later }

class DriverRatingScreen extends ConsumerStatefulWidget {
  const DriverRatingScreen({super.key, this.tripId, this.driverName});

  final int? tripId;
  final String? driverName;

  @override
  ConsumerState<DriverRatingScreen> createState() => _DriverRatingScreenState();
}

class _DriverRatingScreenState extends ConsumerState<DriverRatingScreen> {
  static const blue = AppColors.blue;
  final commentController = TextEditingController();

  int rating = 5;
  bool submitting = false;
  final Set<String> selectedTags = {};

  static const tags = [
    LocaleKeys.rating_safe_driving,
    LocaleKeys.rating_friendly,
    LocaleKeys.rating_punctual,
    LocaleKeys.rating_clean_vehicle,
    LocaleKeys.rating_professional,
    LocaleKeys.rating_polite,
  ];

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final tripId = widget.tripId;
    if (submitting || tripId == null || tripId <= 0) return;
    setState(() => submitting = true);
    final comments = [
      ...selectedTags.map((tag) => tag.tr()),
      if (commentController.text.trim().isNotEmpty)
        commentController.text.trim(),
    ];
    try {
      await ref
          .read(tripRatingRepositoryProvider)
          .submit(tripId: tripId, vote: rating, comment: comments.join('\n'));
      if (mounted) Navigator.of(context).pop(TripRatingResult.submitted);
    } on TripAlreadyRatedException {
      if (mounted) Navigator.of(context).pop(TripRatingResult.alreadyRated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocaleKeys.rating_submit_failed.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            LocaleKeys.rating_title.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 12),
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.blueSoft,
                  child: Assets.images.icDriver.svg(
                    width: 48,
                    height: 48,
                    colorFilter: const ColorFilter.mode(
                      AppColors.blue,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  widget.driverName?.trim().isNotEmpty == true
                      ? widget.driverName!
                      : LocaleKeys.trip_driver.tr(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Center(
                child: Text(
                  widget.tripId == null || widget.tripId! <= 0
                      ? LocaleKeys.trip_history_unavailable.tr()
                      : LocaleKeys.trip_code.tr(
                          namedArgs: {'code': '${widget.tripId}'},
                        ),
                  style: const TextStyle(color: AppColors.textSoft),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceStrong,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      LocaleKeys.rating_question.tr(),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LocaleKeys.rating_prompt.tr(),
                      style: const TextStyle(color: AppColors.textSoft),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setState(() => rating = index + 1);
                          },
                          icon: Assets.images.icStar.svg(
                            width: 40,
                            height: 40,
                            colorFilter: ColorFilter.mode(
                              index < rating
                                  ? AppColors.ratingStar
                                  : AppColors.textFaint,
                              BlendMode.srcIn,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rating >= 4
                          ? LocaleKeys.rating_excellent.tr()
                          : rating == 3
                          ? LocaleKeys.rating_average.tr()
                          : LocaleKeys.rating_improve.tr(),
                      style: const TextStyle(
                        color: blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                LocaleKeys.rating_positive_prompt.tr(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) {
                  return FilterChip(
                    label: Text(tag.tr()),
                    selected: selectedTags.contains(tag),
                    selectedColor: AppColors.blueSoft,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedTags.add(tag);
                        } else {
                          selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                LocaleKeys.rating_comment.tr(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 4,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: LocaleKeys.rating_comment_hint.tr(),
                  filled: true,
                  fillColor: AppColors.surfaceStrong,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        submitting ||
                            widget.tripId == null ||
                            widget.tripId! <= 0
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(LocaleKeys.rating_submit.tr()),
                  ),
                ),
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(context).pop(TripRatingResult.later),
                  child: Text(LocaleKeys.rating_later.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
