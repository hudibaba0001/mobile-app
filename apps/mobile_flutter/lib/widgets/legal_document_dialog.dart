import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../config/supabase_config.dart';
import '../design/design.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../widgets/onboarding/onboarding_scaffold.dart';

/// Fetches and displays a legal document (terms or privacy) from the database
/// in a full-screen dialog so the user never leaves the app.
class LegalDocumentDialog extends StatefulWidget {
  /// 'terms' or 'privacy'
  final String type;

  const LegalDocumentDialog({super.key, required this.type});

  /// Show the terms dialog
  static Future<void> showTerms(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const LegalDocumentDialog(type: 'terms'),
    );
  }

  /// Show the privacy policy dialog
  static Future<void> showPrivacy(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const LegalDocumentDialog(type: 'privacy'),
    );
  }

  @override
  State<LegalDocumentDialog> createState() => _LegalDocumentDialogState();
}

class _LegalDocumentDialogState extends State<LegalDocumentDialog> {
  String? _title;
  String? _content;
  bool _isLoading = true;
  String? _error;
  String? _localeCode;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settingsProvider = context.watch<SettingsProvider>();
    final deviceLocale = Localizations.localeOf(context).languageCode;
    final nextLocale = settingsProvider.locale?.languageCode ?? deviceLocale;
    if (_localeCode != nextLocale) {
      _localeCode = nextLocale;
      _loadDocument();
    }
  }

  Future<Map<String, dynamic>?> _queryDocument({String? localeCode}) {
    var query = SupabaseConfig.client
        .from('legal_documents')
        .select('title, content')
        .eq('type', widget.type)
        .eq('is_current', true);
    if (localeCode != null) {
      query = query.eq('locale', localeCode);
    }
    return query.maybeSingle();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic>? response;
      if (_localeCode != null) {
        try {
          response = await _queryDocument(localeCode: _localeCode);
        } catch (_) {
          response = null;
        }
      }
      response ??= await _queryDocument();

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _error = AppLocalizations.of(context).legal_documentNotFound;
          _isLoading = false;
        });
        return;
      }

      final doc = response;
      setState(() {
        _title = doc['title'] as String?;
        _content = doc['content'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).legal_documentLoadFailed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final t = AppLocalizations.of(context);
    final fallbackTitle =
        widget.type == 'terms' ? t.settings_terms : t.settings_privacy;
    final resolvedTitle = (_title == null || _title!.trim().isEmpty)
        ? fallbackTitle
        : _title!;

    return Dialog.fullscreen(
      child: OnboardingScaffold(
        title: resolvedTitle,
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: AppIconSize.xl,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _error = null;
                              });
                              _loadDocument();
                            },
                            child: Text(t.common_retry),
                          ),
                        ],
                      ),
                    ),
                  )
                : MarkdownBody(
                    data: _content ?? '',
                    styleSheet: MarkdownStyleSheet.fromTheme(theme),
                  ),
      ),
    );
  }
}
