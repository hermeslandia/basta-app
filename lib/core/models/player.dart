import 'dart:convert';

class Player {
  final String id;
  final String name;
  final bool isHost;
  final int score;
  final Map<String, String>? currentAnswers;
  final int avatarIndex;
  final String gender;

  Player({
    required this.id,
    required this.name,
    this.isHost = false,
    this.score = 0,
    this.currentAnswers,
    this.avatarIndex = 0,
    this.gender = 'M',
  });

  Player copyWith({
    String? id,
    String? name,
    bool? isHost,
    int? score,
    Map<String, String>? currentAnswers,
    int? avatarIndex,
    String? gender,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      isHost: isHost ?? this.isHost,
      score: score ?? this.score,
      currentAnswers: currentAnswers ?? this.currentAnswers,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      gender: gender ?? this.gender,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isHost': isHost,
      'score': score,
      'currentAnswers': currentAnswers,
      'avatarIndex': avatarIndex,
      'gender': gender,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      isHost: map['isHost'] ?? false,
      score: map['score']?.toInt() ?? 0,
      currentAnswers: map['currentAnswers'] != null 
          ? Map<String, String>.from(map['currentAnswers']) 
          : null,
      avatarIndex: map['avatarIndex']?.toInt() ?? 0,
      gender: map['gender'] ?? 'M',
    );
  }

  String toJson() => json.encode(toMap());

  factory Player.fromJson(String source) => Player.fromMap(json.decode(source));
}
