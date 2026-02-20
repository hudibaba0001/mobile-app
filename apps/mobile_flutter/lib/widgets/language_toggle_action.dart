import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class LanguageToggleAction extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const LanguageToggleAction({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final deviceLocale = Localizations.localeOf(context).languageCode;
    var effectiveCode = settingsProvider.locale?.languageCode ?? deviceLocale;
    if (effectiveCode != 'sv' && effectiveCode != 'en') {
      effectiveCode = 'en';
    }

    final isSv = effectiveCode == 'sv';
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: ToggleButtons(
        constraints: const BoxConstraints(minWidth: 36, minHeight: 28),
        borderRadius: BorderRadius.circular(16),
        borderColor: theme.colorScheme.outline.withValues(alpha: 0.4),
        selectedBorderColor: theme.colorScheme.primary,
        fillColor: theme.colorScheme.primary,
        selectedColor: theme.colorScheme.onPrimary,
        color: theme.colorScheme.onSurfaceVariant,
        isSelected: [isSv, !isSv],
        onPressed: (index) {
          settingsProvider
              .setLocale(Locale(index == 0 ? 'sv' : 'en'));
        },
        children: const [
          Text('SV', style: TextStyle(fontWeight: FontWeight.w700)),
          Text('EN', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
