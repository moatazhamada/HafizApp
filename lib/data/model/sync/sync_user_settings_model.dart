import 'package:equatable/equatable.dart';

class SyncUserSettingsModel extends Equatable {
  final String? themeMode;
  final String? localeCode;
  final String? recitationProvider;
  final String? qiraatEdition;
  final int? reciterId;
  final String? customAsrEndpoint;
  final String? whisperModel;
  final int? qrcHafzLevel;
  final int? qrcTajweedLevel;
  final bool? isSingleLine;
  final int? lastReadSurahId;
  final int? lastReadVerseIndex;
  final double? lastReadOffset;
  final DateTime? lastUpdated;

  const SyncUserSettingsModel({
    this.themeMode,
    this.localeCode,
    this.recitationProvider,
    this.qiraatEdition,
    this.reciterId,
    this.customAsrEndpoint,
    this.whisperModel,
    this.qrcHafzLevel,
    this.qrcTajweedLevel,
    this.isSingleLine,
    this.lastReadSurahId,
    this.lastReadVerseIndex,
    this.lastReadOffset,
    this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'localeCode': localeCode,
      'recitationProvider': recitationProvider,
      'qiraatEdition': qiraatEdition,
      'reciterId': reciterId,
      'customAsrEndpoint': customAsrEndpoint,
      'whisperModel': whisperModel,
      'qrcHafzLevel': qrcHafzLevel,
      'qrcTajweedLevel': qrcTajweedLevel,
      'isSingleLine': isSingleLine,
      'lastReadSurahId': lastReadSurahId,
      'lastReadVerseIndex': lastReadVerseIndex,
      'lastReadOffset': lastReadOffset,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory SyncUserSettingsModel.fromJson(Map<String, dynamic> json) {
    return SyncUserSettingsModel(
      themeMode: json['themeMode'] as String?,
      localeCode: json['localeCode'] as String?,
      recitationProvider: json['recitationProvider'] as String?,
      qiraatEdition: json['qiraatEdition'] as String?,
      reciterId: json['reciterId'] as int?,
      customAsrEndpoint: json['customAsrEndpoint'] as String?,
      whisperModel: json['whisperModel'] as String?,
      qrcHafzLevel: json['qrcHafzLevel'] as int?,
      qrcTajweedLevel: json['qrcTajweedLevel'] as int?,
      isSingleLine: json['isSingleLine'] as bool?,
      lastReadSurahId: json['lastReadSurahId'] as int?,
      lastReadVerseIndex: json['lastReadVerseIndex'] as int?,
      lastReadOffset: (json['lastReadOffset'] as num?)?.toDouble(),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  factory SyncUserSettingsModel.fromPrefUtils(
    String themeMode,
    String localeCode,
    String recitationProvider,
    String qiraatEdition,
    int reciterId,
    String customAsrEndpoint,
    String whisperModel,
    int qrcHafzLevel,
    int qrcTajweedLevel,
    bool isSingleLine,
    int? lastReadSurahId,
    int? lastReadVerseIndex,
    double? lastReadOffset,
  ) {
    return SyncUserSettingsModel(
      themeMode: themeMode,
      localeCode: localeCode,
      recitationProvider: recitationProvider,
      qiraatEdition: qiraatEdition,
      reciterId: reciterId,
      customAsrEndpoint: customAsrEndpoint,
      whisperModel: whisperModel,
      qrcHafzLevel: qrcHafzLevel,
      qrcTajweedLevel: qrcTajweedLevel,
      isSingleLine: isSingleLine,
      lastReadSurahId: lastReadSurahId,
      lastReadVerseIndex: lastReadVerseIndex,
      lastReadOffset: lastReadOffset,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    localeCode,
    recitationProvider,
    qiraatEdition,
    reciterId,
    customAsrEndpoint,
    whisperModel,
    qrcHafzLevel,
    qrcTajweedLevel,
    isSingleLine,
    lastReadSurahId,
    lastReadVerseIndex,
    lastReadOffset,
    lastUpdated,
  ];
}
