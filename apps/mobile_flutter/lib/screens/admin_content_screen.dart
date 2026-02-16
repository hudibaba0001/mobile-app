// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../design/app_theme.dart';
import '../widgets/standard_app_bar.dart';

/// Admin screen for managing legal documents and app messages.
class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        title: 'Content Management',
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.description), text: 'Legal Documents'),
            Tab(icon: Icon(Icons.campaign), text: 'App Messages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LegalDocumentsTab(),
          _AppMessagesTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legal Documents Tab
// ---------------------------------------------------------------------------
class _LegalDocumentsTab extends StatefulWidget {
  const _LegalDocumentsTab();

  @override
  State<_LegalDocumentsTab> createState() => _LegalDocumentsTabState();
}

class _LegalDocumentsTabState extends State<_LegalDocumentsTab> {
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseConfig.client
          .from('legal_documents')
          .select()
          .order('type')
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _documents = (response as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          final doc = _documents[index];
          final isCurrent = doc['is_current'] == true;
          return Card(
            child: ListTile(
              leading: Icon(
                doc['type'] == 'terms' ? Icons.description : Icons.privacy_tip,
                color: isCurrent ? theme.colorScheme.primary : Colors.grey,
              ),
              title: Text(doc['title'] ?? ''),
              subtitle: Text(
                'Version: ${doc['version']} ${isCurrent ? '(Current)' : '(Old)'}',
              ),
              trailing: isCurrent
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () => _editDocument(doc),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editDocument(Map<String, dynamic> doc) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _LegalDocumentEditor(document: doc),
      ),
    );
    if (result == true) _load();
  }
}

// ---------------------------------------------------------------------------
// Legal Document Editor
// ---------------------------------------------------------------------------
class _LegalDocumentEditor extends StatefulWidget {
  final Map<String, dynamic> document;

  const _LegalDocumentEditor({required this.document});

  @override
  State<_LegalDocumentEditor> createState() => _LegalDocumentEditorState();
}

class _LegalDocumentEditorState extends State<_LegalDocumentEditor> {
  late TextEditingController _titleController;
  late TextEditingController _versionController;
  late TextEditingController _contentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document['title']);
    _versionController = TextEditingController(text: widget.document['version']);
    _contentController = TextEditingController(text: widget.document['content']);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _versionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await SupabaseConfig.client
          .from('legal_documents')
          .update({
            'title': _titleController.text.trim(),
            'version': _versionController.text.trim(),
            'content': _contentController.text,
          })
          .eq('id', widget.document['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.document['type']}'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _versionController,
              decoration: const InputDecoration(
                labelText: 'Version (e.g., v1, v2)',
                border: OutlineInputBorder(),
                helperText:
                    'Changing version will require users to re-accept terms',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content (Markdown)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App Messages Tab
// ---------------------------------------------------------------------------
class _AppMessagesTab extends StatefulWidget {
  const _AppMessagesTab();

  @override
  State<_AppMessagesTab> createState() => _AppMessagesTabState();
}

class _AppMessagesTabState extends State<_AppMessagesTab> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseConfig.client
          .from('app_messages')
          .select()
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _messages = (response as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load: $e')),
      );
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> msg) async {
    final newActive = !(msg['is_active'] as bool? ?? true);
    try {
      await SupabaseConfig.client
          .from('app_messages')
          .update({'is_active': newActive}).eq('id', msg['id']);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  Future<void> _deleteMessage(Map<String, dynamic> msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: Text('Delete "${msg['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await SupabaseConfig.client
          .from('app_messages')
          .delete()
          .eq('id', msg['id']);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: _messages.isEmpty
            ? const Center(child: Text('No messages yet'))
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isActive = msg['is_active'] == true;
                  final type = msg['type'] as String? ?? 'info';
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        _iconForType(type),
                        color: isActive ? theme.colorScheme.primary : Colors.grey,
                      ),
                      title: Text(
                        msg['title'] ?? '',
                        style: TextStyle(
                          decoration:
                              isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Text(
                        '${msg['type']} • ${isActive ? 'Active' : 'Inactive'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: isActive,
                            onChanged: (_) => _toggleActive(msg),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editMessage(msg),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20,
                                color: Colors.red),
                            onPressed: () => _deleteMessage(msg),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createMessage,
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'update':
        return Icons.system_update;
      case 'maintenance':
        return Icons.construction;
      default:
        return Icons.info_outline;
    }
  }

  Future<void> _createMessage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _AppMessageEditor()),
    );
    if (result == true) _load();
  }

  Future<void> _editMessage(Map<String, dynamic> msg) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _AppMessageEditor(message: msg)),
    );
    if (result == true) _load();
  }
}

// ---------------------------------------------------------------------------
// App Message Editor
// ---------------------------------------------------------------------------
class _AppMessageEditor extends StatefulWidget {
  final Map<String, dynamic>? message;

  const _AppMessageEditor({this.message});

  @override
  State<_AppMessageEditor> createState() => _AppMessageEditorState();
}

class _AppMessageEditorState extends State<_AppMessageEditor> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _actionUrlController;
  late TextEditingController _actionLabelController;
  late TextEditingController _minVersionController;
  late TextEditingController _maxVersionController;
  String _type = 'info';
  bool _isDismissible = true;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEditing => widget.message != null;

  @override
  void initState() {
    super.initState();
    final msg = widget.message;
    _titleController = TextEditingController(text: msg?['title'] ?? '');
    _bodyController = TextEditingController(text: msg?['body'] ?? '');
    _actionUrlController =
        TextEditingController(text: msg?['action_url'] ?? '');
    _actionLabelController =
        TextEditingController(text: msg?['action_label'] ?? '');
    _minVersionController =
        TextEditingController(text: msg?['min_app_version'] ?? '');
    _maxVersionController =
        TextEditingController(text: msg?['max_app_version'] ?? '');
    _type = msg?['type'] as String? ?? 'info';
    _isDismissible = msg?['is_dismissible'] as bool? ?? true;
    _isActive = msg?['is_active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _actionUrlController.dispose();
    _actionLabelController.dispose();
    _minVersionController.dispose();
    _maxVersionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and body are required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final data = {
      'title': _titleController.text.trim(),
      'body': _bodyController.text.trim(),
      'type': _type,
      'action_url': _actionUrlController.text.trim().isEmpty
          ? null
          : _actionUrlController.text.trim(),
      'action_label': _actionLabelController.text.trim().isEmpty
          ? null
          : _actionLabelController.text.trim(),
      'min_app_version': _minVersionController.text.trim().isEmpty
          ? null
          : _minVersionController.text.trim(),
      'max_app_version': _maxVersionController.text.trim().isEmpty
          ? null
          : _maxVersionController.text.trim(),
      'is_dismissible': _isDismissible,
      'is_active': _isActive,
    };

    try {
      if (_isEditing) {
        await SupabaseConfig.client
            .from('app_messages')
            .update(data)
            .eq('id', widget.message!['id']);
      } else {
        await SupabaseConfig.client.from('app_messages').insert(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Updated' : 'Created')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Message' : 'New Message'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'info', child: Text('Info')),
                DropdownMenuItem(value: 'warning', child: Text('Warning')),
                DropdownMenuItem(value: 'update', child: Text('Update')),
                DropdownMenuItem(
                    value: 'maintenance', child: Text('Maintenance')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'info'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _actionUrlController,
              decoration: const InputDecoration(
                labelText: 'Action URL (optional)',
                hintText: 'https://play.google.com/store/apps/...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _actionLabelController,
              decoration: const InputDecoration(
                labelText: 'Action Label (optional)',
                hintText: 'Update Now',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minVersionController,
                    decoration: const InputDecoration(
                      labelText: 'Min App Version',
                      hintText: 'e.g., 1.0.0',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _maxVersionController,
                    decoration: const InputDecoration(
                      labelText: 'Max App Version',
                      hintText: 'e.g., 1.0.1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              title: const Text('Dismissible'),
              subtitle: const Text('Can users close this message?'),
              value: _isDismissible,
              onChanged: (v) => setState(() => _isDismissible = v),
            ),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Show this message to users'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
        ),
      ),
    );
  }
}
