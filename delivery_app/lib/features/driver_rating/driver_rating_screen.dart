import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../generated/locale_keys.g.dart';

import '../../core/theme/app_theme.dart';
import '../../gen/assets.gen.dart';

class DriverRatingScreen extends StatefulWidget {
  const DriverRatingScreen({super.key});

  @override
  State<DriverRatingScreen> createState() => _DriverRatingScreenState();
}

class _DriverRatingScreenState extends State<DriverRatingScreen> {
  static const blue = AppColors.blue;
  final commentController = TextEditingController();

  int rating = 5;
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
              const Center(
                child: Text(
                  'Nguyễn Văn Minh',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Center(
                child: Text(
                  LocaleKeys.rating_driver_vehicle.tr(),
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
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          LocaleKeys.rating_saved_demo.tr(
                            namedArgs: {'rating': '$rating'},
                          ),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    LocaleKeys.rating_submit.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
