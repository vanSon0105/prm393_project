import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../domain/entities/admin_driver_request.dart';

class AdminDriverRequestCard extends StatelessWidget {
  const AdminDriverRequestCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onViewDocuments,
    super.key,
  });

  final AdminDriverRequest request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewDocuments;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InitialsAvatar(label: request.initials, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (request.phone.isNotEmpty)
                        Text(
                          request.phone,
                          style: const TextStyle(color: AppColors.textSoft),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.address.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                request.address,
                style: const TextStyle(color: AppColors.textSoft),
              ),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onViewDocuments,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Xem giấy tờ'),
            ),
            const SizedBox(height: 8),
            if (busy)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      child: const Text('Từ chối'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      child: const Text('Duyệt'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class AdminDriverDocumentsSheet extends StatelessWidget {
  const AdminDriverDocumentsSheet({required this.request, super.key});

  final AdminDriverRequest request;

  @override
  Widget build(BuildContext context) {
    final documents = <(String, String)>[
      ('Bằng lái mặt trước', request.licenseFrontUrl),
      ('Bằng lái mặt sau', request.licenseBackUrl),
      ('Căn cước mặt trước', request.identityFrontUrl),
      ('Căn cước mặt sau', request.identityBackUrl),
    ];

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Giấy tờ của ${request.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            for (final (title, url) in documents) ...[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (url.isEmpty)
                const Text('Chưa có ảnh')
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 80,
                      child: Center(child: Text('Không tải được ảnh')),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
