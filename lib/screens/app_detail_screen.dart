import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_model.dart';
import '../services/supabase_service.dart';
import '../services/download_service.dart';

class AppDetailScreen extends StatefulWidget {
  final String appId;
  const AppDetailScreen({super.key, required this.appId});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  late Future<AppModel> _appFuture;
  final _downloadService = DownloadService();

  double? _downloadProgress; // null = not downloading
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _appFuture = SupabaseService.fetchAppById(widget.appId);
  }

  Future<void> _handleDownload(AppModel app) async {
    if (app.latestFileUrl == null) return;

    setState(() {
      _downloadProgress = 0;
      _errorMessage = null;
    });

    try {
      await _downloadService.downloadAndInstall(
        url: app.latestFileUrl!,
        fileName: '${app.name.replaceAll(' ', '_')}_${app.latestVersion}.apk',
        onProgress: (p) => setState(() => _downloadProgress = p),
      );
      await SupabaseService.incrementDownloadCount(app.id, app.downloadCount);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _downloadProgress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App details')),
      body: FutureBuilder<AppModel>(
        future: _appFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final app = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: app.iconUrl != null
                          ? CachedNetworkImage(
                              imageUrl: app.iconUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.apps, size: 48),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.name,
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(app.category,
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                          'v${app.latestVersion ?? "-"} · ${app.downloadCount} downloads',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDownloadButton(app),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              Text('About this app', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(app.description ?? 'No description provided.'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDownloadButton(AppModel app) {
    if (_downloadProgress != null) {
      return Column(
        children: [
          LinearProgressIndicator(value: _downloadProgress),
          const SizedBox(height: 8),
          Text('${(_downloadProgress! * 100).toStringAsFixed(0)}%'),
        ],
      );
    }

    return FilledButton.icon(
      icon: const Icon(Icons.download),
      label: const Text('Install'),
      onPressed: app.latestFileUrl != null ? () => _handleDownload(app) : null,
    );
  }
}
