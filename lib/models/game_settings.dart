import 'dart:ui';

class GameSettings {
  final Map<String, String> teamNames;
  final Map<String, Color> teamColors;
  final int gridRows;
  final int gridCols;

  GameSettings({
    required this.teamNames,
    required this.teamColors,
    this.gridRows = 10,
    this.gridCols = 10,
  });

  factory GameSettings.defaultSettings() {
    return GameSettings(
      teamNames: {
        'team1': 'علي بن أبي طالب',
        'team2': 'مصعب بن عمير',
        'team3': 'عبدالله بن عمر',
        'team4': 'عبدالله بن عباس',
        'team5': 'أنس بن مالك',
      },
      teamColors: {
        'team1': const Color(0xFFEF5350), // Red
        'team2': const Color(0xFF37474F), // Dark Gray
        'team3': const Color(0xFF29B6F6), // Light Blue
        'team4': const Color(0xFF66BB6A), // Green
        'team5': const Color(0xFF26C6DA), // Cyan
      },
      gridRows: 10,
      gridCols: 10,
    );
  }

  Map<String, dynamic> toJson() => {
    'teamNames': teamNames,
    'teamColors': teamColors.map((k, v) => MapEntry(k, v.toARGB32())),
    'gridRows': gridRows,
    'gridCols': gridCols,
  };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    final colorsJson = json['teamColors'] as Map<String, dynamic>;
    final namesJson = json['teamNames'] as Map<String, dynamic>;
    return GameSettings(
      teamNames: namesJson.map((k, v) => MapEntry(k, v as String)),
      teamColors: colorsJson.map((k, v) => MapEntry(k, Color(v as int))),
      gridRows: json['gridRows'] as int? ?? 10,
      gridCols: json['gridCols'] as int? ?? 10,
    );
  }
}
