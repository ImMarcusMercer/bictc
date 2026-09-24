import 'dart:typed_data';

enum ReportStatus {
  accessible('Accessible'),
  partial('Partial Access'),
  barrier('Significant Barrier');

  const ReportStatus(this.label);
  final String label;
}

class CommunityReport {
  const CommunityReport({
    required this.id,
    required this.author,
    required this.place,
    required this.city,
    required this.description,
    required this.status,
    required this.observedAt,
    required this.createdAt,
    this.photoPath,
    this.helpfulCount = 0,
    this.isHelpful = false,
    this.verification = 'unverified',
  });
  final String id, author, place, city, description, verification;
  final ReportStatus status;
  final DateTime observedAt, createdAt;
  final String? photoPath;
  final int helpfulCount;
  final bool isHelpful;

  factory CommunityReport.fromJson(Map<String, dynamic> row) => CommunityReport(
    id: row['id'] as String,
    author: row['author_name'] as String,
    place: row['place_name'] as String,
    city: row['city'] as String,
    description: row['description'] as String,
    status: ReportStatus.values.byName(row['status'] as String),
    observedAt: DateTime.parse(row['observed_at'] as String),
    createdAt: DateTime.parse(row['created_at'] as String),
    photoPath: row['photo_path'] as String?,
    helpfulCount: (row['helpful_count'] as num).toInt(),
    isHelpful: row['is_helpful'] as bool,
    verification: row['verification_state'] as String,
  );
}

class ReportPhoto {
  ReportPhoto(this.bytes) {
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Choose a photo smaller than 5 MB.');
    }
    if (contentType == null) {
      throw const FormatException('Choose a JPEG, PNG, or WebP photo.');
    }
  }
  final Uint8List bytes;
  String? get contentType {
    if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes.take(8).join(',') == '137,80,78,71,13,10,26,10') {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
        String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }
}

class ReportDraft {
  const ReportDraft({
    required this.author,
    required this.place,
    required this.city,
    required this.description,
    required this.status,
    required this.observedAt,
    this.photo,
  });
  final String author, place, city, description;
  final ReportStatus status;
  final DateTime observedAt;
  final ReportPhoto? photo;
}
