import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../config/supabase_config.dart';
import '../design/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final response = await SupabaseConfig.client
          .from('legal_documents')
          .select('title, content')
          .eq('type', widget.type)
          .eq('is_current', true)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _error = 'Document not found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _title = response['title'] as String?;
        _content = response['content'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load document';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title ?? ''),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: AppIconSize.xl,
                            color: theme.colorScheme.error),
                        const SizedBox(height: AppSpacing.md),
                        Text(_error!, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _loadDocument();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Markdown(
                    data: _content ?? '',
                    padding: const EdgeInsets.all(AppSpacing.lg),
                  ),
      ),
    );
  }
}
