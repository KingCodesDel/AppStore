class AppModel {
  final String id;
  final String name;
  final String? description;
  final String category;
  final String? iconUrl;
  final String developerId;
  final String? packageName;
  final String status;
  final int downloadCount;
  final DateTime createdAt;

  // Latest version info, joined in from app_versions
  final String? latestVersion;
  final String? latestFileUrl;
  final int? latestFileSizeBytes;

  AppModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.iconUrl,
    required this.developerId,
    this.packageName,
    required this.status,
    required this.downloadCount,
    required this.createdAt,
    this.latestVersion,
    this.latestFileUrl,
    this.latestFileSizeBytes,
  });

  factory AppModel.fromJson(Map<String, dynamic> json) {
    // app_versions may come back as a list (from a Supabase join)
    Map<String, dynamic>? latest;
    final versions = json['app_versions'];
    if (versions is List && versions.isNotEmpty) {
      // Assume versions are ordered by created_at desc in the query
      latest = versions.first as Map<String, dynamic>;
    }

    return AppModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'other',
      iconUrl: json['icon_url'] as String?,
      developerId: json['developer_id'] as String,
      packageName: json['package_name'] as String?,
      status: json['status'] as String? ?? 'published',
      downloadCount: json['download_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      latestVersion: latest?['version_number'] as String?,
      latestFileUrl: latest?['file_url'] as String?,
      latestFileSizeBytes: latest?['file_size_bytes'] as int?,
    );
  }
}
