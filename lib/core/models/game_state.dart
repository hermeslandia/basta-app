import 'dart:convert';
import 'player.dart';

enum GamePhase { lobby, categorySelection, roulette, letterCountdown, playing, frozen, scoring, leaderboard, review }

class GameState {
  final GamePhase phase;
  final bool isInGame; // Bandera: true cuando la sala está en juego, false cuando está en espera
  final String? currentLetter;
  final List<String> usedLetters; // Letras ya sorteadas en la partida actual para no repetirlas
  final List<Player> players;
  final String? frozenById;
  final String? roomCode;
  final String? roomName;
  final bool isPrivateRoom;
  final int timerDurationSeconds;
  final List<String> selectedCategories;
  final String winCondition; // 'rounds' o 'points'
  final int currentRound;
  final int totalRounds;
  final int targetScore; // Puntos para ganar cuando winCondition == 'points'
  final String? activePlayerId;
  final int spinTargetIndex; // -1 cuando aún no se ha girado en la ronda actual
  final int spinId; // 0 cuando aún no se ha girado en la ronda actual
  final Map<String, Map<String, Map<String, bool>>> wordVotes; // ownerId -> category -> voterId -> isValid
  final Map<String, int> roundScores; // playerId -> score this round
  final List<String> confirmedVoters; // playerIds who confirmed their ratings this round

  GameState({
    this.phase = GamePhase.lobby,
    this.isInGame = false,
    this.currentLetter,
    this.usedLetters = const [],
    this.players = const [],
    this.frozenById,
    this.roomCode,
    this.roomName,
    this.isPrivateRoom = false,
    this.timerDurationSeconds = 60,
    this.selectedCategories = const ['Nombre', 'Apellido', 'Ciudad/País', 'Animal', 'Flor/Fruto', 'Cosa'],
    this.winCondition = 'rounds',
    this.currentRound = 1,
    this.totalRounds = 3,
    this.targetScore = 25000,
    this.activePlayerId,
    this.spinTargetIndex = -1,
    this.spinId = 0,
    this.wordVotes = const {},
    this.roundScores = const {},
    this.confirmedVoters = const [],
  });

  GameState copyWith({
    GamePhase? phase,
    bool? isInGame,
    String? currentLetter,
    List<String>? usedLetters,
    List<Player>? players,
    String? frozenById,
    String? roomCode,
    String? roomName,
    bool? isPrivateRoom,
    int? timerDurationSeconds,
    List<String>? selectedCategories,
    String? winCondition,
    int? currentRound,
    int? totalRounds,
    int? targetScore,
    String? activePlayerId,
    int? spinTargetIndex,
    int? spinId,
    Map<String, Map<String, Map<String, bool>>>? wordVotes,
    Map<String, int>? roundScores,
    List<String>? confirmedVoters,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      isInGame: isInGame ?? this.isInGame,
      currentLetter: currentLetter ?? this.currentLetter,
      usedLetters: usedLetters ?? this.usedLetters,
      players: players ?? this.players,
      frozenById: frozenById ?? this.frozenById,
      roomCode: roomCode ?? this.roomCode,
      roomName: roomName ?? this.roomName,
      isPrivateRoom: isPrivateRoom ?? this.isPrivateRoom,
      timerDurationSeconds: timerDurationSeconds ?? this.timerDurationSeconds,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      winCondition: winCondition ?? this.winCondition,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      targetScore: targetScore ?? this.targetScore,
      activePlayerId: activePlayerId ?? this.activePlayerId,
      spinTargetIndex: spinTargetIndex ?? this.spinTargetIndex,
      spinId: spinId ?? this.spinId,
      wordVotes: wordVotes ?? this.wordVotes,
      roundScores: roundScores ?? this.roundScores,
      confirmedVoters: confirmedVoters ?? this.confirmedVoters,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phase': phase.index,
      'isInGame': isInGame,
      'currentLetter': currentLetter,
      'usedLetters': usedLetters,
      'players': players.map((x) => x.toMap()).toList(),
      'frozenById': frozenById,
      'roomCode': roomCode,
      'roomName': roomName,
      'isPrivateRoom': isPrivateRoom,
      'timerDurationSeconds': timerDurationSeconds,
      'selectedCategories': selectedCategories,
      'winCondition': winCondition,
      'currentRound': currentRound,
      'totalRounds': totalRounds,
      'targetScore': targetScore,
      'activePlayerId': activePlayerId,
      'spinTargetIndex': spinTargetIndex,
      'spinId': spinId,
      'wordVotes': wordVotes,
      'roundScores': roundScores,
      'confirmedVoters': confirmedVoters,
    };
  }

  factory GameState.fromMap(Map<String, dynamic> map) {
    final GamePhase parsedPhase = GamePhase.values[map['phase'] ?? 0];
    final bool defaultInGame = parsedPhase != GamePhase.lobby && parsedPhase != GamePhase.categorySelection;
    return GameState(
      phase: parsedPhase,
      isInGame: map['isInGame'] ?? defaultInGame,
      currentLetter: map['currentLetter'],
      usedLetters: map['usedLetters'] != null
          ? List<String>.from(map['usedLetters'])
          : const [],
      players: map['players'] != null
          ? List<Player>.from(map['players']?.map((x) => Player.fromMap(Map<String, dynamic>.from(x))))
          : [],
      frozenById: map['frozenById'],
      roomCode: map['roomCode'],
      roomName: map['roomName'],
      isPrivateRoom: map['isPrivateRoom'] == true,
      timerDurationSeconds: map['timerDurationSeconds']?.toInt() ?? 60,
      selectedCategories: map['selectedCategories'] != null
          ? List<String>.from(map['selectedCategories'])
          : ['Nombre', 'Apellido', 'Ciudad/País', 'Animal', 'Flor/Fruto', 'Cosa'],
      winCondition: (map['winCondition'] ?? 'rounds').toString(),
      currentRound: (map['currentRound'] as num?)?.toInt() ?? 1,
      totalRounds: (map['totalRounds'] as num?)?.toInt() ?? 3,
      targetScore: (map['targetScore'] as num?)?.toInt() ?? 25000,
      activePlayerId: map['activePlayerId'],
      spinTargetIndex: (map['spinTargetIndex'] as num?)?.toInt() ?? -1,
      spinId: (map['spinId'] as num?)?.toInt() ?? 0,
      wordVotes: map['wordVotes'] != null
          ? Map<String, Map<String, Map<String, bool>>>.from(
              (map['wordVotes'] as Map).map((k, v) => MapEntry<String, Map<String, Map<String, bool>>>(
                  k.toString(),
                  Map<String, Map<String, bool>>.from(
                      (v as Map).map((k2, v2) => MapEntry<String, Map<String, bool>>(
                          k2.toString(),
                          Map<String, bool>.from((v2 as Map).map((k3, v3) => MapEntry(k3.toString(), v3 == true)))))))))
          : const {},
      roundScores: map['roundScores'] != null
          ? Map<String, int>.from((map['roundScores'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt())))
          : const {},
      confirmedVoters: map['confirmedVoters'] != null
          ? List<String>.from(map['confirmedVoters'])
          : const [],
    );
  }

  String toJson() => json.encode(toMap());

  factory GameState.fromJson(String source) => GameState.fromMap(json.decode(source));
}
