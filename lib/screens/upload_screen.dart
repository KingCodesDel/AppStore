import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/supabase_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _packageController = TextEditingController();
  final _versionController = TextEditingController(text: '1.0.0');
  String _category = 'tools';

  File? _iconFile;
  File? _apkFile;
  int? _apkSizeBytes;

  bool _submitting = false;
  String? _error;

  final _categories = ['games', 'productivity', 'social', 'tools', 'other'];

  Future<void> _pickIcon() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _iconFile = File(result.files.single.path!));
    }
  }

  Future<void> _pickApk() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['apk'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _apkFile = File(result.files.single.path!);
        _apkSizeBytes = result.files.single.size;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_apkFile == null) {
      setState(() => _error = 'Please select an APK file.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final safeName = _nameController.text.trim().replaceAll(' ', '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      String iconUrl = '';
      if (_iconFile != null) {
        iconUrl = await SupabaseService.uploadIcon(
            _iconFile!, '${safeName}_icon_$timestamp.png');
      }

      final apkUrl = await SupabaseService.uploadApk(
          _apkFile!, '${safeName}_$timestamp.apk');

      await SupabaseService.publishApp(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        packageName: _packageController.text.trim(),
        iconUrl: iconUrl,
        apkUrl: apkUrl,
        apkSizeBytes: _apkSizeBytes ?? 0,
        versionNumber: _versionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App published!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publish an app')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'App name'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _packageController,
              decoration: const InputDecoration(
                  labelText: 'Package name (e.g. com.you.app)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _versionController,
              decoration: const InputDecoration(labelText: 'Version (e.g. 1.0.0)'),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.image),
              label: Text(_iconFile == null ? 'Pick icon (optional)' : 'Icon selected ✓'),
              onPressed: _pickIcon,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.android),
              label: Text(_apkFile == null ? 'Pick APK file' : 'APK selected ✓'),
              onPressed: _pickApk,
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }
}
