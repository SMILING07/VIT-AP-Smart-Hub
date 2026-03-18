class VersionModel {
  final String latestVersion;
  final String minSupportedVersion;
  final String updateType;
  final String apkUrl;

  VersionModel({
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.updateType,
    required this.apkUrl,
  });

  factory VersionModel.fromJson(Map<String, dynamic> json) {
    return VersionModel(
      latestVersion: json['latest_version'] ?? '1.0.0',
      minSupportedVersion: json['min_supported_version'] ?? '1.0.0',
      updateType: json['update_type'] ?? 'ota',
      apkUrl: json['apk_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_version': latestVersion,
      'min_supported_version': minSupportedVersion,
      'update_type': updateType,
      'apk_url': apkUrl,
    };
  }
}
