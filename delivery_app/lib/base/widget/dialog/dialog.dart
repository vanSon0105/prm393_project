import 'package:flutter/material.dart';

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
                children: [
                  if (title.isNotEmpty) ...[
                    Text(title, textAlign: TextAlign.center),
                    const SizedBox(height: 25),
                  ],
                  if (message.isNotEmpty) ...[
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 25),
                  ],
                  if (positive.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: onPositive,
                      child: Text(positive),
                    ),
                  ],
                  if (negative.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: onNegative,
                      child: Text(negative),
                    ),
                  ],
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
