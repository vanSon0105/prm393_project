import 'package:delivery_app/gen/assets.gen.dart';
import 'package:delivery_app/routes/app_navigate.dart';
import 'package:flutter/material.dart';

import '../../../gen/colors.gen.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    this.title = '',
    this.message = '',
    this.positive = '',
    this.negative = '',
    this.onPositive,
    this.onNegative,
  });

  final String title;
  final String message;
  final String positive;
  final String negative;
  final void Function()? onPositive;
  final void Function()? onNegative;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              constraints: const BoxConstraints(maxWidth: 342),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Assets.images.icInfo.svg(
                        colorFilter: ColorFilter.mode(
                          ColorName.danger,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 5),
                      if (title.isNotEmpty) ...[
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            color: ColorName.danger,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (message.isNotEmpty) ...[
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 25),
                  ],
                  Row(
                    children: [
                      if (positive.isNotEmpty) ...[
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: () {
                              AppNavigate.instance.back();
                              onPositive?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorName.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              positive,
                              style: const TextStyle(
                                fontSize: 12,
                                color: ColorName.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 20),
                      if (negative.isNotEmpty) ...[
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorName.surfaceMuted,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              AppNavigate.instance.back();
                              onNegative?.call();
                            },
                            child: Text(
                              negative,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
