import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../design/app_theme.dart';
import '../l10n/generated/app_localizations.dart';

Future<void> showExportShareDialog(
  BuildContext context, {
  required String filePath,
  required String fileName,
  required String format,
}) async {
  final theme = Theme.of(context);
  final t = AppLocalizations.of(context);

  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(t.export_complete)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.export_savedSuccess(format.toUpperCase()),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            t.export_sharePrompt,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(t.common_done),
        ),
        FilledButton.icon(
          onPressed: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            Navigator.of(dialogContext).pop();
            try {
              await SharePlus.instance.share(
                ShareParams(
                  files: [XFile(filePath)],
                  subject: t.export_shareSubject(fileName),
                  text: t.export_shareText,
                ),
              );
            } catch (e) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(t.error_shareFile(e.toString())),
                  backgroundColor: AppColors.accent,
                ),
              );
            }
          },
          icon: const Icon(Icons.share),
          label: Text(t.common_share),
        ),
      ],
    ),
  );
}
