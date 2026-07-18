import 'building.dart';

class BoardCell {
  final int index;
  String? ownerTeamId;
  BuildingType buildingType;
  int? customValueOverride;

  BoardCell({
    required this.index,
    this.ownerTeamId,
    this.buildingType = BuildingType.house,
    this.customValueOverride,
  });

  BoardCell copyWith({
    int? index,
    String? ownerTeamId,
    BuildingType? buildingType,
    int? customValueOverride,
    bool clearOwner = false,
    bool clearCustomValueOverride = false,
  }) {
    return BoardCell(
      index: index ?? this.index,
      ownerTeamId: clearOwner ? null : (ownerTeamId ?? this.ownerTeamId),
      buildingType: buildingType ?? this.buildingType,
      customValueOverride: clearCustomValueOverride
          ? null
          : (customValueOverride ?? this.customValueOverride),
    );
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'ownerTeamId': ownerTeamId,
    'buildingType': buildingType.name,
    'customValueOverride': customValueOverride,
  };

  factory BoardCell.fromJson(Map<String, dynamic> json) => BoardCell(
    index: json['index'] as int,
    ownerTeamId: json['ownerTeamId'] as String?,
    buildingType: BuildingType.values.byName(json['buildingType'] as String),
    customValueOverride: json['customValueOverride'] as int?,
  );
}
