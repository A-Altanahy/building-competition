import 'dart:ui';

class Team {
  final String id;
  String name;
  Color color;
  int score;
  List<int> scoreHistory;

  Team({
    required this.id,
    required this.name,
    required this.color,
    this.score = 0,
    List<int>? scoreHistory,
  }) : scoreHistory = scoreHistory ?? [0];

  Team copyWith({
    String? id,
    String? name,
    Color? color,
    int? score,
    List<int>? scoreHistory,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      score: score ?? this.score,
      scoreHistory: scoreHistory ?? List.from(this.scoreHistory),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.toARGB32(),
    'score': score,
    'scoreHistory': scoreHistory,
  };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'] as String,
    name: json['name'] as String,
    color: Color(json['color'] as int),
    score: json['score'] as int,
    scoreHistory: List<int>.from(json['scoreHistory'] as List),
  );
}
