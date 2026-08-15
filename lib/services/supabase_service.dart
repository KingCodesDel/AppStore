import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_model.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ---------------- AUTH ----------------

  static Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  static Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static User? get currentUser => _client.auth.currentUser;

  // ---------------- FETCH APPS ----------------

  /// Fetch all published apps, with their latest version joined in.
  static Future<List<AppModel>> fetchApps({String? category}) async {
    var query = _client
        .from('apps')
        .select('*, app_versions(version_number, file_url, file_size_bytes, created_at)')
        .eq('status', 'published');

    if (category != null && category != 'all') {
      query = query.eq('category', category);
    }

    final data = await query.order('created_at', ascending: false);

    return (data as List).map((row) {
      // Sort versions so the most recent is first before parsing
      final versions = (row['app_versions'] as List?) ?? [];
      versions.sort((a, b) =>
          (b['created_at'] as String).compareTo(a['created_at'] as String));
      row['app_versions'] = versions;
      return AppModel.fromJson(row);
    }).toList();
  }

  static Future<AppModel> fetchAppById(String id) async {
    final row = await _client
        .from('apps')
        .select('*, app_versions(version_number, file_url, file_size_bytes, created_at)')
        .eq('id', id)
        .single();

    final versions = (row['app_versions'] as List?) ?? [];
    versions.sort((a, b) =>
        (b['created_at'] as String).compareTo(a['created_at'] as String));
    row['app_versions'] = versions;
    return AppModel.fromJson(row);
  }

  // ---------------- UPLOAD APP ----------------

  /// Uploads an icon file to the `app-icons` bucket and returns its public URL.
  static Future<String> uploadIcon(File iconFile, String fileName) async {
    final path = 'icons/$fileName';
    await _client.storage.from('app-icons').upload(
          path,
          iconFile,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('app-icons').getPublicUrl(path);
  }

  /// Uploads an APK file to the `app-binaries` bucket and returns its public URL.
  static Future<String> uploadApk(File apkFile, String fileName) async {
    final path = 'apks/$fileName';
    await _client.storage.from('app-binaries').upload(
          path,
          apkFile,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'application/vnd.android.package-archive',
          ),
        );
    return _client.storage.from('app-binaries').getPublicUrl(path);
  }

  /// Creates the `apps` row, then the first `app_versions` row.
  static Future<void> publishApp({
    required String name,
    required String description,
    required String category,
    required String packageName,
    required String iconUrl,
    required String apkUrl,
    required int apkSizeBytes,
    required String versionNumber,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) {
      throw Exception('You must be signed in to publish an app.');
    }

    final appRow = await _client
        .from('apps')
        .insert({
          'name': name,
          'description': description,
          'category': category,
          'package_name': packageName,
          'icon_url': iconUrl,
          'developer_id': userId,
          'status': 'published',
        })
        .select()
        .single();

    await _client.from('app_versions').insert({
      'app_id': appRow['id'],
      'version_number': versionNumber,
      'version_code': 1,
      'file_url': apkUrl,
      'file_size_bytes': apkSizeBytes,
    });
  }

  // ---------------- DOWNLOAD COUNT ----------------

  static Future<void> incrementDownloadCount(String appId, int currentCount) async {
    await _client
        .from('apps')
        .update({'download_count': currentCount + 1}).eq('id', appId);
  }
}
