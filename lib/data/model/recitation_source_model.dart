import 'package:hafiz_app/domain/entities/recitation_source.dart';

/// Data model for Recitation Source, maps between local storage and domain entities
class RecitationSourceModel {
  final int reciterId;
  final String reciterName;
  final String type; // 'online', 'offline', 'none'
  final String? localFilePath;
  final String? downloadUrl;

  const RecitationSourceModel({
    required this.reciterId,
    required this.reciterName,
    required this.type,
    this.localFilePath,
    this.downloadUrl,
  });

  factory RecitationSourceModel.fromJson(Map<String, dynamic> json) {
    return RecitationSourceModel(
      reciterId: json['reciter_id'] as int,
      reciterName: json['reciter_name'] as String,
      type: json['type'] as String,
      localFilePath: json['local_file_path'] as String?,
      downloadUrl: json['download_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reciter_id': reciterId,
      'reciter_name': reciterName,
      'type': type,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (downloadUrl != null) 'download_url': downloadUrl,
    };
  }

  RecitationSourceEntity toEntity() {
    return RecitationSourceEntity(
      reciterId: reciterId,
      reciterName: reciterName,
      type: RecitationSourceModel.parseType(type),
      localFilePath: localFilePath,
      downloadUrl: downloadUrl,
    );
  }

  static RecitationSource parseType(String type) {
    switch (type) {
      case 'offline':
        return RecitationSource.offline;
      case 'online':
        return RecitationSource.online;
      default:
        return RecitationSource.none;
    }
  }

  factory RecitationSourceModel.fromEntity(RecitationSourceEntity entity) {
    return RecitationSourceModel(
      reciterId: entity.reciterId,
      reciterName: entity.reciterName,
      type: RecitationSourceModel.typeToString(entity.type),
      localFilePath: entity.localFilePath,
      downloadUrl: entity.downloadUrl,
    );
  }

  static String typeToString(RecitationSource type) {
    switch (type) {
      case RecitationSource.offline:
        return 'offline';
      case RecitationSource.online:
        return 'online';
      case RecitationSource.none:
        return 'none';
    }
  }
}
