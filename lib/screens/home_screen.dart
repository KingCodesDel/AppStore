import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/app_model.dart';
import '../services/supabase_service.dart';
import 'app_detail_screen.dart';
import 'upload_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<AppModel>> _appsFuture;
  String _selectedCategory = 'all';

  final _categories = ['all', 'games', 'productivity', 'social', 'tools', 'other'];

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  void _loadApps() {
    _appsFuture = SupabaseService.fetchApps(
      category: _selectedCategory == 'all' ? null : _selectedCategory,
    );
  }

  Future<void> _refresh() async {
    setState(_loadApps);
    await _appsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = SupabaseService.currentUser != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My App Store'),
        actions: [
          IconButton(
            icon: Icon(signedIn ? Icons.logout : Icons.login),
            tooltip: signedIn ? 'Sign out' : 'Sign in',
            onPressed: () async {
              if (signedIn) {
                await SupabaseService.signOut();
                setState(() {});
              } else {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()));
                setState(() {});
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.upload_file),
        label: const Text('Publish app'),
        onPressed: () async {
          if (!signedIn) {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AuthScreen()));
            if (SupabaseService.currentUser == null) return;
          }
          if (!context.mounted) return;
          await Navigator.push(
              context, MaterialPageRoute(builder: (_) => const UploadScreen()));
          _refresh();
        },
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat[0].toUpperCase() + cat.substring(1)),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = cat;
                      _loadApps();
                    });
                  },
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<AppModel>>(
                future: _appsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                      message: snapshot.error.toString(),
                      onRetry: _refresh,
                    );
                  }
                  final apps = snapshot.data ?? [];
                  if (apps.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No apps yet — be the first to publish one!')),
                      ],
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: apps.length,
                    itemBuilder: (context, i) => _AppCard(app: apps[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final AppModel app;
  const _AppCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AppDetailScreen(appId: app.id)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: app.iconUrl != null
                  ? CachedNetworkImage(
                      imageUrl: app.iconUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) => const Icon(Icons.apps, size: 48),
                    )
                  : const Icon(Icons.apps, size: 48),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    app.latestVersion != null ? 'v${app.latestVersion}' : 'No version',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 8),
            Text('Something went wrong:\n$message', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
