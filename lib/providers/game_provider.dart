import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../core/models/game_state.dart';
import '../core/models/player.dart';
import '../core/network_interface.dart';
import '../services/audio_service.dart';

class GameProvider extends ChangeNotifier {
  INetworkService _networkService;
  Player? _localPlayer;
  GameState _gameState = GameState();
  bool hostPlayAgain = false;
  bool roomClosed = false;
  String? roomClosedMessage;

  Player? get localPlayer => _localPlayer;
  GameState get gameState => _gameState;

  Timer? _pingTimer;
  Timer? _emptyRoomWatchdogTimer;
  final Map<String, DateTime> _lastPingResponses = {};

  DateTime? _bastaPressedAt;
  bool _alarmPlayedThisRound = false;
  bool _scoringTransitionScheduled = false;

  String profileName = '';
  int profileAvatarIndex = 0;
  String profileSkin = 'party';
  String profileGender = 'M';
  bool profileSfxEnabled = true;
  bool profileBgmEnabled = true;

  Future<void>? _loadProfileFuture;

  GameProvider(this._networkService) {
    _networkService.messages.listen(_handleIncomingMessage);
    _loadProfileFuture = _loadProfile();
  }

  Future<void> ensureProfileLoaded() {
    return _loadProfileFuture ??= _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    profileName = prefs.getString('profileName') ?? '';
    profileAvatarIndex = prefs.getInt('profileAvatarIndex') ?? 0;
    profileSkin = prefs.getString('profileSkin') ?? 'party';
    profileGender = prefs.getString('profileGender') ?? 'M';
    profileSfxEnabled = prefs.getBool('profileSfxEnabled') ?? true;
    profileBgmEnabled = prefs.getBool('profileBgmEnabled') ?? true;
    AudioService().updateSettings(this);
    notifyListeners();
  }

  Future<void> saveProfile(String name, int avatarIndex, String skin, String gender, bool sfx, bool bgm) async {
    profileName = name;
    profileAvatarIndex = avatarIndex;
    profileSkin = skin;
    profileGender = gender;
    profileSfxEnabled = sfx;
    profileBgmEnabled = bgm;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileName', name);
    await prefs.setInt('profileAvatarIndex', avatarIndex);
    await prefs.setString('profileSkin', skin);
    await prefs.setString('profileGender', gender);
    await prefs.setBool('profileSfxEnabled', sfx);
    await prefs.setBool('profileBgmEnabled', bgm);

    AudioService().updateSettings(this);
    AudioService().playBgm('bgm');
    notifyListeners();
  }

  Future<void> saveAudioSettings(bool sfx, bool bgm) async {
    profileSfxEnabled = sfx;
    profileBgmEnabled = bgm;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profileSfxEnabled', sfx);
    await prefs.setBool('profileBgmEnabled', bgm);
    AudioService().updateSettings(this);
    notifyListeners();
  }

  void updateNetworkService(INetworkService newService) {
    if (_networkService != newService) {
      _networkService = newService;
      _networkService.messages.listen(_handleIncomingMessage);
    }
  }

  void initializePlayer(String name, bool isHost, int avatarIndex) {
    roomClosed = false;
    roomClosedMessage = null;
    _localPlayer = Player(
      id: const Uuid().v4(),
      name: name,
      isHost: isHost,
      avatarIndex: avatarIndex,
      gender: profileGender,
    );

    if (isHost) {
      _gameState = _gameState.copyWith(isInGame: false);
      _addPlayer(_localPlayer!);
      _startPingTimer();
    } else {
      _networkService.sendMessage('player_joined', _localPlayer!.toMap());
    }
    WakelockPlus.enable();
  }

  void _syncLocalPlayerFromState() {
    if (_localPlayer == null) return;
    final idx = _gameState.players.indexWhere((p) => p.id == _localPlayer!.id);
    if (idx != -1) {
      _localPlayer = _gameState.players[idx];
    }
  }

  /// Valida las reglas de la sala:
  /// 1. Sala en espera (isInGame == false): siempre debe haber al menos 1 jugador.
  /// 2. Sala en juego (isInGame == true): siempre debe haber 2 o más jugadores.
  /// 3. Cronómetro de 15 segundos: si una sala queda vacía por más de 15 segundos se destruye.
  void _validateRoomState() {
    if (_localPlayer?.isHost != true) return;

    final int playerCount = _gameState.players.length;
    final bool inGame = _gameState.isInGame;

    _networkService.updateRoomMetadata(
      isInGame: inGame,
      playerCount: playerCount,
    );

    // Cronómetro de 15 segundos para salas vacías (0 jugadores)
    if (playerCount < 1) {
      _emptyRoomWatchdogTimer ??= Timer(const Duration(seconds: 15), () {
        if (_gameState.players.isEmpty) {
          _destroyRoomWithReason('Sala destruida por inactividad (vacía por más de 15s).');
        }
      });
    } else {
      _emptyRoomWatchdogTimer?.cancel();
      _emptyRoomWatchdogTimer = null;
    }

    // Si la sala está EN JUEGO (excepto cuando ya terminó en el podio), validar que siempre haya >= 2 jugadores
    if (inGame && _gameState.phase != GamePhase.leaderboard && playerCount < 2) {
      _destroyRoomWithReason('La partida se cerró porque quedaron menos de 2 jugadores en la sala.');
    }
  }

  void _destroyRoomWithReason(String reason) {
    _emptyRoomWatchdogTimer?.cancel();
    _emptyRoomWatchdogTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    roomClosed = true;
    roomClosedMessage = reason;
    _networkService.sendMessage('room_closed', {'reason': reason});
    _networkService.disconnect();
    notifyListeners();
  }

  void updateTimerConfig(int seconds) {
    if (_localPlayer?.isHost == true) {
      _gameState = _gameState.copyWith(timerDurationSeconds: seconds);
      _networkService.sendMessage('state_sync', _gameState.toMap());
      notifyListeners();
    }
  }

  void updateCategories(List<String> categories) {
    if (_localPlayer?.isHost == true) {
      _gameState = _gameState.copyWith(selectedCategories: categories);
      _networkService.sendMessage('state_sync', _gameState.toMap());
      notifyListeners();
    }
  }

  void updateGameModeConfig({
    required String winCondition,
    required int totalRounds,
    required int targetScore,
  }) {
    if (_localPlayer?.isHost == true) {
      _gameState = _gameState.copyWith(
        winCondition: winCondition,
        totalRounds: max(1, totalRounds),
        targetScore: max(100, targetScore),
      );
      _networkService.sendMessage('state_sync', _gameState.toMap());
      notifyListeners();
    }
  }

  void setRoomCode(String roomCode, {String? roomName, bool isPrivate = false}) {
    if (_localPlayer?.isHost == true) {
      _gameState = _gameState.copyWith(
        roomCode: roomCode,
        roomName: roomName ?? roomCode,
        isPrivateRoom: isPrivate,
        isInGame: false,
      );
      _validateRoomState();
      _networkService.sendMessage('state_sync', _gameState.toMap());
      notifyListeners();
    }
  }

  // --- Helpers de Validación y Confirmación de Calificaciones ---

  static String normalizeWord(String input) {
    String s = input.trim().toUpperCase();
    const Map<String, String> accents = {
      'Á': 'A', 'À': 'A', 'Ä': 'A', 'Â': 'A', 'Ã': 'A',
      'É': 'E', 'È': 'E', 'Ë': 'E', 'Ê': 'E',
      'Í': 'I', 'Ì': 'I', 'Ï': 'I', 'Î': 'I',
      'Ó': 'O', 'Ò': 'O', 'Ö': 'O', 'Ô': 'O', 'Õ': 'O',
      'Ú': 'U', 'Ù': 'U', 'Ü': 'U', 'Û': 'U',
    };
    accents.forEach((k, v) {
      s = s.replaceAll(k, v);
    });
    return s;
  }

  int get requiredRejections {
    final int eligibleVoters = max(1, _gameState.players.length - 1);
    return (eligibleVoters / 2).ceil();
  }

  bool hasBaseValidity(String answer) {
    final String normAns = normalizeWord(answer);
    final String normLetter = normalizeWord(_gameState.currentLetter ?? '');
    if (normAns.length < 2 || normLetter.isEmpty) return false;
    return normAns.startsWith(normLetter);
  }

  bool isWordValid(String ownerId, String category) {
    final idx = _gameState.players.indexWhere((p) => p.id == ownerId);
    if (idx == -1) return false;
    final String ans = _gameState.players[idx].currentAnswers?[category] ?? '';
    if (!hasBaseValidity(ans)) return false;

    final votes = _gameState.wordVotes[ownerId]?[category] ?? {};
    final int falseVotes = votes.entries
        .where((e) => e.key != ownerId && e.value == false)
        .length;
    return falseVotes < requiredRejections;
  }

  int get nonHostPlayersCount => _gameState.players.where((p) => !p.isHost).length;

  int get confirmedNonHostCount => _gameState.players
      .where((p) => !p.isHost && _gameState.confirmedVoters.contains(p.id))
      .length;

  bool get haveAllGuestsConfirmedVotes => _gameState.players
      .where((p) => !p.isHost)
      .every((p) => _gameState.confirmedVoters.contains(p.id));

  bool get hasLocalPlayerConfirmedVotes =>
      _localPlayer != null && _gameState.confirmedVoters.contains(_localPlayer!.id);

  /// Indica si tras sumar los puntos proyectados de la ronda actual la partida ya concluyó
  /// (ya sea por alcanzar el número de rondas configurado o porque algún jugador alcanzó los puntos para ganar).
  bool get isMatchPointReached {
    if (_gameState.winCondition == 'points') {
      final int goal = _gameState.targetScore > 0 ? _gameState.targetScore : 25000;
      for (final p in _gameState.players) {
        final int roundScore = _gameState.roundScores[p.id] ?? 0;
        if (p.score + roundScore >= goal) {
          return true;
        }
      }
      return false;
    } else {
      return _gameState.currentRound >= _gameState.totalRounds;
    }
  }

  void _triggerBastaAlarmOnce() {
    if (!_alarmPlayedThisRound) {
      _alarmPlayedThisRound = true;
      AudioService().stopBgm();
      AudioService().playThemeAlarm();
    }
  }

  void _scheduleTransitionToScoring() {
    if (_scoringTransitionScheduled) return;
    _scoringTransitionScheduled = true;

    final DateTime pressedAt = _bastaPressedAt ?? DateTime.now();
    final int elapsedMs = DateTime.now().difference(pressedAt).inMilliseconds;
    // Garantizar al menos 2.8 segundos mostrando la manita roja y reproduciendo "¡BASTA!" en todos los equipos
    final int remainingMs = max(0, 2800 - elapsedMs);

    Future.delayed(Duration(milliseconds: remainingMs), () {
      _scoringTransitionScheduled = false;
      if (_localPlayer?.isHost == true &&
          _gameState.phase != GamePhase.scoring &&
          _gameState.phase != GamePhase.leaderboard) {
        evaluatePoints();
        _networkService.sendMessage('state_sync', _gameState.toMap());
        notifyListeners();
      }
    });
  }

  void _handleIncomingMessage(String message) {
    try {
      final data = json.decode(message);
      final String type = data['type'];
      final payload = data['payload'];

      switch (type) {
        case 'player_joined':
          // Si la sala ya está en juego, no permitir que entren nuevos jugadores
          if (_localPlayer?.isHost == true && _gameState.isInGame) {
            return;
          }
          _addPlayer(Player.fromMap(Map<String, dynamic>.from(payload)));
          if (_localPlayer?.isHost == true) {
            _lastPingResponses[payload['id']] = DateTime.now();
            _validateRoomState();
          }
          break;
        case 'state_sync':
          final incomingState = GameState.fromMap(Map<String, dynamic>.from(payload));
          if (incomingState.phase == GamePhase.roulette ||
              incomingState.phase == GamePhase.letterCountdown) {
            _alarmPlayedThisRound = false;
            _bastaPressedAt = null;
          }
          if (incomingState.phase == GamePhase.frozen ||
              (incomingState.frozenById != null && incomingState.frozenById!.isNotEmpty)) {
            _triggerBastaAlarmOnce();
          }
          _gameState = incomingState;
          _syncLocalPlayerFromState();
          notifyListeners();
          break;
        case 'ping':
          if (_localPlayer?.isHost == false && _localPlayer != null) {
            _networkService.sendMessage('pong', {'playerId': _localPlayer!.id});
          }
          break;
        case 'pong':
          if (_localPlayer?.isHost == true) {
            _lastPingResponses[payload['playerId']] = DateTime.now();
          }
          break;
        case 'start_roulette':
          if (_localPlayer?.isHost == true && _gameState.players.length < 2) {
            return;
          }
          _alarmPlayedThisRound = false;
          _bastaPressedAt = null;
          _scoringTransitionScheduled = false;
          final clearedPlayers = _gameState.players
              .map((p) => p.copyWith(score: 0, currentAnswers: {}))
              .toList();
          final int configuredRnds = max(1, _gameState.totalRounds);
          final String activePlayer = clearedPlayers.first.id;

          _gameState = _gameState.copyWith(
            phase: GamePhase.roulette,
            isInGame: true,
            players: clearedPlayers,
            frozenById: '',
            currentLetter: '',
            usedLetters: [],
            currentRound: 1,
            totalRounds: configuredRnds,
            activePlayerId: activePlayer,
            spinTargetIndex: -1,
            spinId: 0,
            wordVotes: {},
            roundScores: {},
            confirmedVoters: [],
          );
          _syncLocalPlayerFromState();
          if (_localPlayer?.isHost == true) {
            _validateRoomState();
            _networkService.sendMessage('state_sync', _gameState.toMap());
          }
          notifyListeners();
          break;
        case 'next_round':
          _alarmPlayedThisRound = false;
          _bastaPressedAt = null;
          _scoringTransitionScheduled = false;
          final clearedPlayers = _gameState.players
              .map((p) => p.copyWith(currentAnswers: {}))
              .toList();
          final int nextRnd = _gameState.currentRound + 1;
          final String activePlayer =
              clearedPlayers[(nextRnd - 1) % clearedPlayers.length].id;

          _gameState = _gameState.copyWith(
            phase: GamePhase.roulette,
            isInGame: true,
            players: clearedPlayers,
            frozenById: '',
            currentLetter: '',
            currentRound: nextRnd,
            activePlayerId: activePlayer,
            spinTargetIndex: -1,
            spinId: 0,
            wordVotes: {},
            roundScores: {},
            confirmedVoters: [],
          );
          _syncLocalPlayerFromState();
          if (_localPlayer?.isHost == true) {
            _validateRoomState();
          }
          notifyListeners();
          break;
        case 'roulette_spin_started':
          final int targetIndex = (payload['targetIndex'] as num).toInt();
          final int spinId = (payload['spinId'] as num).toInt();
          _gameState = _gameState.copyWith(
            spinTargetIndex: targetIndex,
            spinId: spinId,
          );
          notifyListeners();
          break;
        case 'letter_selected':
          _alarmPlayedThisRound = false;
          _bastaPressedAt = null;
          _scoringTransitionScheduled = false;
          final String chosenLetter = (payload['letter'] ?? '').toString();
          final updatedUsed = List<String>.from(_gameState.usedLetters);
          if (updatedUsed.length >= 26) {
            updatedUsed.clear();
          }
          if (chosenLetter.isNotEmpty && !updatedUsed.contains(chosenLetter)) {
            updatedUsed.add(chosenLetter);
          }
          _gameState = _gameState.copyWith(
            phase: GamePhase.letterCountdown,
            isInGame: true,
            currentLetter: chosenLetter,
            usedLetters: updatedUsed,
            spinTargetIndex: -1,
            spinId: 0,
            frozenById: '',
          );
          notifyListeners();
          break;
        case 'start_typing':
          _gameState = _gameState.copyWith(
            phase: GamePhase.playing,
            isInGame: true,
          );
          notifyListeners();
          break;
        case 'basta_pressed':
          // Solo aceptar el primer ¡BASTA! de la ronda y sonar en TODOS los dispositivos
          if (_gameState.phase != GamePhase.frozen &&
              (_gameState.frozenById == null || _gameState.frozenById!.isEmpty)) {
            _bastaPressedAt = DateTime.now();
            _gameState = _gameState.copyWith(
              phase: GamePhase.frozen,
              isInGame: true,
              frozenById: payload['playerId'],
            );
            _triggerBastaAlarmOnce();
            if (_localPlayer?.isHost == true) {
              _networkService.sendMessage('state_sync', _gameState.toMap());
            }
            notifyListeners();
          }
          break;
        case 'submit_answers':
          if (_localPlayer?.isHost == true) {
            final String playerId = payload['playerId'];
            final Map<String, String> answers =
                Map<String, String>.from(payload['answers']);
            final int index =
                _gameState.players.indexWhere((p) => p.id == playerId);
            if (index != -1) {
              final existingPlayer = _gameState.players[index];
              // Preservar el score acumulado real del jugador en _gameState.players
              _updatePlayer(existingPlayer.copyWith(currentAnswers: answers));

              final bool allSubmitted = _gameState.players.every(
                  (p) => p.currentAnswers != null && p.currentAnswers!.isNotEmpty);
              if (allSubmitted &&
                  _gameState.phase != GamePhase.scoring &&
                  _gameState.phase != GamePhase.leaderboard) {
                _scheduleTransitionToScoring();
              }
            }
          }
          break;
        case 'word_vote':
          if (_localPlayer?.isHost == true) {
            final String ownerId = payload['ownerId'];
            final String category = payload['category'];
            final String voterId = payload['voterId'];
            final bool isValid = payload['isValid'] == true;

            final newWordVotes = <String, Map<String, Map<String, bool>>>{};
            _gameState.wordVotes.forEach((k, catMap) {
              newWordVotes[k] = <String, Map<String, bool>>{};
              catMap.forEach((cKey, voterMap) {
                newWordVotes[k]![cKey] = Map<String, bool>.from(voterMap);
              });
            });

            newWordVotes[ownerId] ??= <String, Map<String, bool>>{};
            newWordVotes[ownerId]![category] ??= <String, bool>{};
            newWordVotes[ownerId]![category]![voterId] = isValid;

            _gameState = _gameState.copyWith(wordVotes: newWordVotes);
            evaluatePoints();
            _networkService.sendMessage('state_sync', _gameState.toMap());
            notifyListeners();
          }
          break;
        case 'confirm_votes':
          if (_localPlayer?.isHost == true) {
            final String voterId = payload['playerId'];
            final confirmed = List<String>.from(_gameState.confirmedVoters);
            if (!confirmed.contains(voterId)) {
              confirmed.add(voterId);
            }
            _gameState = _gameState.copyWith(confirmedVoters: confirmed);
            evaluatePoints();
            _networkService.sendMessage('state_sync', _gameState.toMap());
            notifyListeners();
          }
          break;
        case 'leave_room':
          if (_localPlayer?.isHost == true) {
            final pId = payload['playerId'];
            final updatedPlayers =
                _gameState.players.where((p) => p.id != pId).toList();
            _gameState = _gameState.copyWith(players: updatedPlayers);
            _validateRoomState();
            if (!roomClosed) {
              _networkService.sendMessage('state_sync', _gameState.toMap());
              notifyListeners();
            }
          }
          break;
        case 'room_closed':
          if (_localPlayer?.isHost == false) {
            roomClosed = true;
            if (payload is Map && payload['reason'] != null) {
              roomClosedMessage = payload['reason'].toString();
            }
            _networkService.disconnect();
            notifyListeners();
          }
          break;
        case 'host_play_again':
          if (_localPlayer?.isHost == false) {
            hostPlayAgain = true;
            notifyListeners();
          }
          break;
        case 'guest_play_again':
          if (_localPlayer?.isHost == true) {
            final pId = payload['playerId'];
            final idx = _gameState.players.indexWhere((p) => p.id == pId);
            if (idx != -1) {
              final p = _gameState.players[idx];
              _updatePlayer(p.copyWith(score: 0, currentAnswers: {}));
            }
          }
          break;
      }
    } catch (e) {
      debugPrint('Error al procesar mensaje: $e');
    }
  }

  void _addPlayer(Player player) {
    _updatePlayer(player);
  }

  void _updatePlayer(Player player) {
    final players = List<Player>.from(_gameState.players);
    final index = players.indexWhere((p) => p.id == player.id);
    if (index != -1) {
      players[index] = player;
    } else {
      players.add(player);
    }
    _gameState = _gameState.copyWith(players: players);
    _syncLocalPlayerFromState();

    if (_localPlayer?.isHost == true) {
      _validateRoomState();
      if (!roomClosed) {
        _networkService.sendMessage('state_sync', _gameState.toMap());
      }
    }
    notifyListeners();
  }

  void forceEvaluatePoints() {
    if (_localPlayer?.isHost == true &&
        _gameState.phase != GamePhase.scoring &&
        _gameState.phase != GamePhase.leaderboard) {
      evaluatePoints();
      _networkService.sendMessage('state_sync', _gameState.toMap());
      notifyListeners();
    }
  }

  // --- Acciones de Juego ---

  void goToCategorySelection() {
    if (_localPlayer?.isHost == true) {
      _gameState = _gameState.copyWith(
        phase: GamePhase.categorySelection,
        isInGame: false,
      );
      _validateRoomState();
      _networkService.sendMessage('state_sync', _gameState.toMap());
      notifyListeners();
    }
  }

  void startRoulette() {
    if (_localPlayer?.isHost == true) {
      if (_gameState.players.length < 2) return;
      _networkService.sendMessage('start_roulette', {});
    }
  }

  void startRouletteSpin(int targetIndex, String letter) {
    if (_localPlayer?.id == _gameState.activePlayerId) {
      _networkService.sendMessage('roulette_spin_started', {
        'targetIndex': targetIndex,
        'letter': letter,
        'spinId': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  void selectLetter(String letter) {
    if (_localPlayer?.id == _gameState.activePlayerId) {
      _networkService.sendMessage('letter_selected', {'letter': letter});

      Future.delayed(const Duration(milliseconds: 3500), () {
        if (_gameState.phase == GamePhase.letterCountdown) {
          _networkService.sendMessage('start_typing', {});
        }
      });
    }
  }

  void pressBasta() {
    if (_localPlayer != null) {
      _networkService.sendMessage('basta_pressed', {'playerId': _localPlayer!.id});
    }
  }

  void submitAnswers(Map<String, String> answers) {
    if (_localPlayer != null) {
      _localPlayer = _localPlayer!.copyWith(currentAnswers: answers);
      _networkService.sendMessage('submit_answers', {
        'playerId': _localPlayer!.id,
        'answers': answers,
      });
    }
  }

  void evaluatePoints() {
    if (_localPlayer?.isHost == true) {
      final String letter = _gameState.currentLetter ?? '';
      if (letter.isEmpty) return;

      final newRoundScores = <String, int>{};

      for (var player in _gameState.players) {
        int roundScore = 0;
        final answers = player.currentAnswers ?? {};

        for (var cat in _gameState.selectedCategories) {
          final String rawAns = answers[cat] ?? '';
          if (!isWordValid(player.id, cat)) continue; // 0 pts

          final String normAns = normalizeWord(rawAns);
          bool isUnique = true;

          for (var other in _gameState.players) {
            if (other.id == player.id) continue;
            if (!isWordValid(other.id, cat)) continue;

            final String otherNormAns =
                normalizeWord(other.currentAnswers?[cat] ?? '');
            if (otherNormAns == normAns) {
              isUnique = false;
              break;
            }
          }

          if (isUnique) {
            roundScore += 100;
          } else {
            roundScore += 50;
          }
        }

        newRoundScores[player.id] = roundScore;
      }

      _gameState = _gameState.copyWith(
        phase: GamePhase.scoring,
        isInGame: true,
        roundScores: newRoundScores,
      );
    }
  }

  void finalizeRoundAndProceed(bool isLastRound) {
    if (_localPlayer?.isHost == true) {
      if (_gameState.phase != GamePhase.scoring &&
          _gameState.phase != GamePhase.review) {
        return;
      }

      evaluatePoints();

      final updatedPlayers = _gameState.players.map((player) {
        final int roundScore = _gameState.roundScores[player.id] ?? 0;
        return player.copyWith(
          score: player.score + roundScore,
          currentAnswers: {},
        );
      }).toList();

      _alarmPlayedThisRound = false;
      _bastaPressedAt = null;
      _scoringTransitionScheduled = false;

      final bool shouldEndGame = _gameState.winCondition == 'points'
          ? updatedPlayers.any(
              (p) => p.score >= (_gameState.targetScore > 0 ? _gameState.targetScore : 25000))
          : (_gameState.currentRound >= _gameState.totalRounds || isLastRound);

      if (shouldEndGame) {
        _gameState = _gameState.copyWith(
          phase: GamePhase.leaderboard,
          isInGame: true,
          players: updatedPlayers,
          spinTargetIndex: -1,
          spinId: 0,
          roundScores: {},
          confirmedVoters: [],
        );
        _syncLocalPlayerFromState();
        _validateRoomState();
        _networkService.sendMessage('state_sync', _gameState.toMap());
        notifyListeners();
      } else {
        final int nextRnd = _gameState.currentRound + 1;
        final String activePlayer =
            updatedPlayers[(nextRnd - 1) % updatedPlayers.length].id;

        _gameState = _gameState.copyWith(
          phase: GamePhase.roulette,
          isInGame: true,
          players: updatedPlayers,
          frozenById: '',
          currentLetter: '',
          currentRound: nextRnd,
          activePlayerId: activePlayer,
          spinTargetIndex: -1,
          spinId: 0,
          wordVotes: {},
          roundScores: {},
          confirmedVoters: [],
        );
        _syncLocalPlayerFromState();
        _validateRoomState();
        if (!roomClosed) {
          _networkService.sendMessage('state_sync', _gameState.toMap());
          notifyListeners();
        }
      }
    }
  }

  void toggleWordVote(String ownerId, String category, bool isValid) {
    if (_localPlayer != null) {
      _networkService.sendMessage('word_vote', {
        'ownerId': ownerId,
        'category': category,
        'voterId': _localPlayer!.id,
        'isValid': isValid,
      });
    }
  }

  void confirmVotes() {
    if (_localPlayer != null) {
      _networkService.sendMessage('confirm_votes', {
        'playerId': _localPlayer!.id,
      });
    }
  }

  void goToLeaderboard() {
    if (_localPlayer?.isHost == true) {
      _gameState = _gameState.copyWith(phase: GamePhase.leaderboard);
      _networkService.sendMessage('state_sync', _gameState.toMap());
      notifyListeners();
    }
  }

  void nextRound() {
    if (_localPlayer?.isHost == true) {
      if (_gameState.currentRound < _gameState.totalRounds) {
        _networkService.sendMessage('next_round', {});
      }
    }
  }

  void hostWantsToPlayAgain() {
    if (_localPlayer?.isHost == true) {
      final resetPlayers = _gameState.players
          .map((p) => p.copyWith(score: 0, currentAnswers: {}))
          .toList();

      _gameState = _gameState.copyWith(
        phase: GamePhase.lobby,
        isInGame: false,
        players: resetPlayers,
        currentRound: 1,
        currentLetter: '',
        usedLetters: [],
        spinTargetIndex: -1,
        spinId: 0,
        wordVotes: {},
        roundScores: {},
        confirmedVoters: [],
        activePlayerId: null,
      );
      _syncLocalPlayerFromState();
      _validateRoomState();
      _networkService.sendMessage('state_sync', _gameState.toMap());
      _networkService.sendMessage('host_play_again', {});
      notifyListeners();
    }
  }

  void guestWantsToPlayAgain() {
    if (_localPlayer?.isHost == false && _localPlayer != null) {
      _networkService.sendMessage('guest_play_again', {'playerId': _localPlayer!.id});
    }
  }

  void leaveGame() {
    if (_localPlayer?.isHost == true) {
      _networkService.updateRoomMetadata(isInGame: false, playerCount: 0);
      _networkService.sendMessage('room_closed', {'reason': 'El anfitrión cerró la sala.'});
      Future.delayed(const Duration(milliseconds: 500), () {
        resetGame();
      });
      return;
    } else if (_localPlayer != null) {
      _networkService.sendMessage('leave_room', {'playerId': _localPlayer!.id});
    }

    resetGame();
  }

  void resetGame() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _emptyRoomWatchdogTimer?.cancel();
    _emptyRoomWatchdogTimer = null;
    WakelockPlus.disable();
    _gameState = GameState();
    _localPlayer = null;
    hostPlayAgain = false;
    roomClosed = false;
    roomClosedMessage = null;
    _alarmPlayedThisRound = false;
    _bastaPressedAt = null;
    _scoringTransitionScheduled = false;
    notifyListeners();
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_localPlayer?.isHost == true) {
        if (_gameState.players.isEmpty) {
          _validateRoomState();
          return;
        }

        _networkService.sendMessage('ping', {});
        // Actualizar pulso de la sala en Firebase/Local cada 5 segundos
        _networkService.updateRoomMetadata(
          isInGame: _gameState.isInGame,
          playerCount: _gameState.players.length,
        );

        final now = DateTime.now();
        bool playersRemoved = false;
        final updatedPlayers = List<Player>.from(_gameState.players);

        updatedPlayers.removeWhere((p) {
          if (p.id == _localPlayer!.id) return false;
          final lastSeen = _lastPingResponses[p.id];
          if (lastSeen == null) return false;
          if (now.difference(lastSeen).inSeconds > 15) {
            debugPrint('Jugador ${p.name} expulsado por inactividad.');
            playersRemoved = true;
            return true;
          }
          return false;
        });

        if (playersRemoved) {
          _gameState = _gameState.copyWith(players: updatedPlayers);
          _validateRoomState();
          if (!roomClosed) {
            _networkService.sendMessage('state_sync', _gameState.toMap());
            notifyListeners();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _emptyRoomWatchdogTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }
}
