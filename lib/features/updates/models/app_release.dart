/// Parsed application version following the project's `X.Y.Z[-pre-release-N]`
/// scheme. Used to compare the installed version against GitHub releases.
///
/// Comparison rules (semver-ish):
///   * Numeric `major.minor.patch` are compared first.
///   * A stable version (no pre-release suffix) is newer than any pre-release
///     of the same `major.minor.patch`.
///   * Two pre-releases of the same base are ordered by their trailing number.
class AppVersion implements Comparable<AppVersion> {
  final int major;
  final int minor;
  final int patch;

  /// `null` means a stable release (no pre-release suffix).
  final int? preRelease;

  const AppVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease,
  });

  factory AppVersion.parse(String raw) {
    var s = raw.trim();
    if (s.isNotEmpty && (s[0] == 'v' || s[0] == 'V')) {
      s = s.substring(1);
    }
    // Strip any build metadata (e.g. "+8").
    final plus = s.indexOf('+');
    if (plus != -1) s = s.substring(0, plus);

    int? pre;
    String base = s;
    final dash = s.indexOf('-');
    if (dash != -1) {
      base = s.substring(0, dash);
      final suffix = s.substring(dash + 1);
      final match = RegExp(r'(\d+)\s*$').firstMatch(suffix);
      // A pre-release with no trailing number ranks as 0.
      pre = match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
    }

    final parts = base.split('.');
    int partAt(int i) {
      if (i >= parts.length) return 0;
      final digits = parts[i].replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(digits) ?? 0;
    }

    return AppVersion(
      major: partAt(0),
      minor: partAt(1),
      patch: partAt(2),
      preRelease: pre,
    );
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    if (preRelease == null && other.preRelease == null) return 0;
    if (preRelease == null) return 1; // stable > pre-release
    if (other.preRelease == null) return -1;
    return preRelease!.compareTo(other.preRelease!);
  }

  bool isNewerThan(AppVersion other) => compareTo(other) > 0;

  @override
  String toString() {
    final base = '$major.$minor.$patch';
    return preRelease == null ? base : '$base-pre-release-$preRelease';
  }
}

/// A downloadable file attached to a GitHub release.
class ReleaseAsset {
  final String name;
  final String downloadUrl;
  final int size;

  /// Lower-case hex SHA-256 of the file, from GitHub's `digest` field
  /// (`sha256:<hex>`). Null for assets uploaded before GitHub started
  /// publishing digests, or when the field is in another algorithm.
  final String? sha256;

  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
    this.sha256,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: (json['name'] ?? '') as String,
      downloadUrl: (json['browser_download_url'] ?? '') as String,
      size: (json['size'] ?? 0) as int,
      sha256: _parseSha256(json['digest']),
    );
  }

  static String? _parseSha256(Object? digest) {
    if (digest is! String) return null;
    const prefix = 'sha256:';
    if (!digest.toLowerCase().startsWith(prefix)) return null;
    final hex = digest.substring(prefix.length).trim().toLowerCase();
    return RegExp(r'^[0-9a-f]{64}$').hasMatch(hex) ? hex : null;
  }
}

/// A single GitHub release entry.
class AppRelease {
  final String tagName;
  final String name;
  final String body;
  final String htmlUrl;
  final bool draft;
  final bool prerelease;
  final List<ReleaseAsset> assets;

  const AppRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    required this.draft,
    required this.prerelease,
    required this.assets,
  });

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    final rawAssets = (json['assets'] as List?) ?? const [];
    return AppRelease(
      tagName: (json['tag_name'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      htmlUrl: (json['html_url'] ?? '') as String,
      draft: (json['draft'] ?? false) as bool,
      prerelease: (json['prerelease'] ?? false) as bool,
      assets: rawAssets
          .whereType<Map<String, dynamic>>()
          .map(ReleaseAsset.fromJson)
          .toList(),
    );
  }

  AppVersion get version => AppVersion.parse(tagName);

  /// Human-friendly title for the dialog; falls back to the tag.
  String get displayName => name.trim().isNotEmpty ? name.trim() : tagName;
}
