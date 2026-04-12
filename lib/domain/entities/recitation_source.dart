import 'package:equatable/equatable.dart';

/// Audio source type for recitation
enum RecitationSource { online, offline, none }

/// Represents available audio sources (online or offline)
class RecitationSourceEntity extends Equatable {
  final int reciterId;
  final String reciterName;
  final RecitationSource type;
  final String? localFilePath;
  final String? downloadUrl;

  const RecitationSourceEntity({
    required this.reciterId,
    required this.reciterName,
    required this.type,
    this.localFilePath,
    this.downloadUrl,
  });

  @override
  List<Object?> get props => [
    reciterId,
    reciterName,
    type,
    localFilePath,
    downloadUrl,
  ];

  RecitationSourceEntity copyWith({
    int? reciterId,
    String? reciterName,
    RecitationSource? type,
    String? localFilePath,
    String? downloadUrl,
  }) {
    return RecitationSourceEntity(
      reciterId: reciterId ?? this.reciterId,
      reciterName: reciterName ?? this.reciterName,
      type: type ?? this.type,
      localFilePath: localFilePath ?? this.localFilePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }
}
