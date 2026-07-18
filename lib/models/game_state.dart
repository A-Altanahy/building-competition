import 'board_cell.dart';
import 'team.dart';
import 'building.dart';

class GameState {
  final List<BoardCell> board;
  final List<Team> teams;
  final int roundNumber;
  final DateTime timestamp;
  final Map<int, String?> previousRoundOwners;
  final Map<int, BuildingType> previousRoundBuildings;

  GameState({
    required this.board,
    required this.teams,
    required this.roundNumber,
    required this.timestamp,
    required this.previousRoundOwners,
    required this.previousRoundBuildings,
  });

  GameState copyWith({
    List<BoardCell>? board,
    List<Team>? teams,
    int? roundNumber,
    DateTime? timestamp,
    Map<int, String?>? previousRoundOwners,
    Map<int, BuildingType>? previousRoundBuildings,
  }) {
    return GameState(
      board: board ?? this.board.map((c) => c.copyWith()).toList(),
      teams: teams ?? this.teams.map((t) => t.copyWith()).toList(),
      roundNumber: roundNumber ?? this.roundNumber,
      timestamp: timestamp ?? this.timestamp,
      previousRoundOwners:
          previousRoundOwners ?? Map.from(this.previousRoundOwners),
      previousRoundBuildings:
          previousRoundBuildings ?? Map.from(this.previousRoundBuildings),
    );
  }

  Map<String, dynamic> toJson() => {
    'board': board.map((c) => c.toJson()).toList(),
    'teams': teams.map((t) => t.toJson()).toList(),
    'roundNumber': roundNumber,
    'timestamp': timestamp.toIso8601String(),
    'previousRoundOwners': previousRoundOwners.map(
      (k, v) => MapEntry(k.toString(), v),
    ),
    'previousRoundBuildings': previousRoundBuildings.map(
      (k, v) => MapEntry(k.toString(), v.name),
    ),
  };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    board: (json['board'] as List)
        .map((c) => BoardCell.fromJson(c as Map<String, dynamic>))
        .toList(),
    teams: (json['teams'] as List)
        .map((t) => Team.fromJson(t as Map<String, dynamic>))
        .toList(),
    roundNumber: json['roundNumber'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
    previousRoundOwners: (json['previousRoundOwners'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(int.parse(k), v as String?)),
    previousRoundBuildings:
        (json['previousRoundBuildings'] as Map<String, dynamic>).map(
          (k, v) =>
              MapEntry(int.parse(k), BuildingType.values.byName(v as String)),
        ),
  );
}
