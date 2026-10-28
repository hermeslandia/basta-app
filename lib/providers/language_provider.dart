import 'package:flutter/material.dart';

enum AppLanguage { es, en, pt }

class LanguageProvider extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.es;

  AppLanguage get currentLanguage => _currentLanguage;

  void setLanguage(AppLanguage language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      notifyListeners();
    }
  }

  String get(String key) {
    return _localizedStrings[_currentLanguage]?[key] ?? _localizedStrings[AppLanguage.es]![key] ?? key;
  }

  static const Map<AppLanguage, Map<String, String>> _localizedStrings = {
    AppLanguage.es: {
      // HomeScreen
      'create_profile_first': '¡Primero crea tu Perfil!',
      'available_rooms': 'Salas Disponibles',
      'local_room': 'Sala Local',
      'join': 'Unirse',
      'enter_firebase_code': 'Ingresa el Código de Sala Firebase',
      'search_internet': 'Buscar en Internet',
      'my_profile': 'MI PERFIL',
      'play_local': 'JUGAR EN RED LOCAL',
      'play_internet': 'JUGAR POR INTERNET',
      'create_room': 'Crear Sala',
      'join_room': 'Unirse a Sala',
      
      // ProfileScreen
      'profile_title': 'TU PERFIL',
      'player_name': 'Nombre de Jugador',
      'name_hint': 'Ej. Ana',
      'visual_theme': 'Tema Visual (Skin)',
      'choose_avatar': 'Elige tu Avatar',
      'save_profile': 'GUARDAR PERFIL',
      'gender': 'Género',
      'male': 'Hombre',
      'female': 'Mujer',
      
      // CategorySelectionScreen
      'config_room_title': 'CONFIGURAR SALA',
      'room_config_subtitle': 'Configuración de la Sala',
      'room_name': 'Nombre de la Sala',
      'room_name_hint': 'Ej. Fiesta de Ana',
      'game_mode_title': 'Modo de Juego',
      'mode_by_rounds': 'Por Rondas',
      'mode_by_points': 'Puntuación Máxima',
      'number_of_rounds': 'Número de Rondas',
      'points_to_win': 'Puntos para Ganar',
      'points_mode_hint': 'El juego termina cuando el primer jugador alcance o supere esta puntuación.',
      'goal_pts': 'Meta',
      'round_label': 'Ronda',
      'time_per_round': 'Tiempo por Ronda',
      'seconds': 'Segundos',
      'create_lobby_room': 'CREAR LOBBY DE SALA',

      // LobbyScreen
      'room_title': 'SALA',
      'local_room_title': 'SALA LOCAL',
      'host_crown': '👑 Host',
      'start_game': 'INICIAR PARTIDA',
      'waiting_host': 'Esperando al Host...',
      'waiting_more_players': 'Esperando a más integrantes... (Mínimo 2)',

      // RouletteScreen
      'drawing_letter': 'Sorteando Letra...',
      'spin_again': 'GIRAR DE NUEVO',
      'waiting_host_spin': 'Esperando que el Host gire...',

      // GameScreen
      'letter_title': 'LETRA',
      'stop_button': '¡BASTA!',
      'someone_pressed_stop': 'Alguien presionó el botón.',
      'waiting_server': 'Esperando al servidor...',

      // ReviewScreen
      'review_title': 'REVISIÓN',
      'waiting_answers': 'Esperando respuestas y evaluación...',
      'evaluate_results': 'EVALUAR RESULTADOS',
      'pts': 'pts',
      'total_pts': 'Total',
      '100_unique': '100 ÚNICA',
      '50_repeated': '50 REPETIDA',
      '0_empty': '0 VACÍA',
      'view_final_podium': 'VER PODIO FINAL',
      'confirm_ratings': 'CONFIRMAR CALIFICACIONES',
      'ratings_confirmed_wait': 'Calificaciones confirmadas. Esperando a los demás...',
      'waiting_players_ratings': 'ESPERANDO CALIFICACIONES',
      'confirmed_badge': 'Listo',
      'rating_badge': 'Calificando...',

      // LeaderboardScreen
      'final_results': 'RESULTADOS FINALES',
      'back_home': 'VOLVER AL INICIO',
      'next_round': 'SIGUIENTE RONDA',
      'waiting_host_next_round': 'Esperando al host para la siguiente ronda...',
      'return_to_lobby': 'Regresar a Lobby',
      'leave_room': 'Salir de Sala',
      
      // Validation
      'write_all_categories': 'Debes llenar todas las categorías antes de presionar ¡BASTA!',
      'invalid_words': 'Todas las palabras deben empezar con la letra y tener al menos 2 caracteres.',

      // Categories
      'NOMBRE': 'NOMBRE',
      'APELLIDO': 'APELLIDO',
      'CIUDAD/PAÍS': 'CIUDAD/PAÍS',
      'ANIMAL': 'ANIMAL',
      'COSA': 'COSA',
      'FLOR/FRUTO': 'FLOR/FRUTO',
    },
    AppLanguage.en: {
      // HomeScreen
      'create_profile_first': 'Create your Profile first!',
      'available_rooms': 'Available Rooms',
      'local_room': 'Local Room',
      'join': 'Join',
      'enter_firebase_code': 'Enter Firebase Room Code',
      'search_internet': 'Search on Internet',
      'my_profile': 'MY PROFILE',
      'play_local': 'PLAY ON LOCAL NETWORK',
      'play_internet': 'PLAY OVER INTERNET',
      'create_room': 'Create Room',
      'join_room': 'Join Room',

      // ProfileScreen
      'profile_title': 'YOUR PROFILE',
      'player_name': 'Player Name',
      'name_hint': 'e.g. John',
      'visual_theme': 'Visual Theme (Skin)',
      'choose_avatar': 'Choose your Avatar',
      'save_profile': 'SAVE PROFILE',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',

      // CategorySelectionScreen
      'config_room_title': 'ROOM CONFIG',
      'room_config_subtitle': 'Room Configuration',
      'room_name': 'Room Name',
      'room_name_hint': 'e.g. John\'s Party',
      'game_mode_title': 'Game Mode',
      'mode_by_rounds': 'By Rounds',
      'mode_by_points': 'Max Score',
      'number_of_rounds': 'Number of Rounds',
      'points_to_win': 'Points to Win',
      'points_mode_hint': 'The game ends when the first player reaches or exceeds this score.',
      'goal_pts': 'Goal',
      'round_label': 'Round',
      'time_per_round': 'Time per Round',
      'seconds': 'Seconds',
      'create_lobby_room': 'CREATE LOBBY ROOM',

      // LobbyScreen
      'room_title': 'ROOM',
      'local_room_title': 'LOCAL ROOM',
      'host_crown': '👑 Host',
      'start_game': 'START GAME',
      'waiting_host': 'Waiting for Host...',
      'waiting_more_players': 'Waiting for more players... (Minimum 2)',

      // RouletteScreen
      'drawing_letter': 'Drawing Letter...',
      'spin_again': 'SPIN AGAIN',
      'waiting_host_spin': 'Waiting for Host to spin...',

      // GameScreen
      'letter_title': 'LETTER',
      'stop_button': 'STOP!',
      'someone_pressed_stop': 'Someone pressed the button.',
      'waiting_server': 'Waiting for server...',

      // ReviewScreen
      'review_title': 'REVIEW',
      'waiting_answers': 'Waiting for answers and evaluation...',
      'evaluate_results': 'EVALUATE RESULTS',
      'pts': 'pts',
      'total_pts': 'Total',
      '100_unique': '100 UNIQUE',
      '50_repeated': '50 REPEATED',
      '0_empty': '0 EMPTY',
      'view_final_podium': 'VIEW FINAL PODIUM',
      'confirm_ratings': 'CONFIRM RATINGS',
      'ratings_confirmed_wait': 'Ratings confirmed. Waiting for others...',
      'waiting_players_ratings': 'WAITING FOR RATINGS',
      'confirmed_badge': 'Ready',
      'rating_badge': 'Rating...',

      // LeaderboardScreen
      'final_results': 'FINAL RESULTS',
      'back_home': 'BACK HOME',
      'next_round': 'NEXT ROUND',
      'waiting_host_next_round': 'Waiting for host to start next round...',
      'return_to_lobby': 'Return to Lobby',
      'leave_room': 'Leave Room',

      // Validation
      'write_all_categories': 'You must fill all categories before pressing STOP!',
      'invalid_words': 'All words must start with the correct letter and have at least 2 characters.',

      // Categories
      'NOMBRE': 'NAME',
      'APELLIDO': 'LAST NAME',
      'CIUDAD/PAÍS': 'CITY/COUNTRY',
      'ANIMAL': 'ANIMAL',
      'COSA': 'THING',
      'FLOR/FRUTO': 'FLOWER/FRUIT',
    },
    AppLanguage.pt: {
      // HomeScreen
      'create_profile_first': 'Crie seu perfil primeiro!',
      'available_rooms': 'Salas Disponíveis',
      'local_room': 'Sala Local',
      'join': 'Entrar',
      'enter_firebase_code': 'Digite o Código da Sala Firebase',
      'search_internet': 'Pesquisar na Internet',
      'my_profile': 'MEU PERFIL',
      'play_local': 'JOGAR NA REDE LOCAL',
      'play_internet': 'JOGAR PELA INTERNET',
      'create_room': 'Criar Sala',
      'join_room': 'Entrar na Sala',

      // ProfileScreen
      'profile_title': 'SEU PERFIL',
      'player_name': 'Nome do Jogador',
      'name_hint': 'Ex. João',
      'visual_theme': 'Tema Visual (Skin)',
      'choose_avatar': 'Escolha seu Avatar',
      'save_profile': 'SALVAR PERFIL',
      'gender': 'Gênero',
      'male': 'Homem',
      'female': 'Mulher',

      // CategorySelectionScreen
      'config_room_title': 'CONFIGURAR SALA',
      'room_config_subtitle': 'Configuração da Sala',
      'room_name': 'Nome da Sala',
      'room_name_hint': 'Ex. Festa do João',
      'game_mode_title': 'Modo de Jogo',
      'mode_by_rounds': 'Por Rodadas',
      'mode_by_points': 'Pontuação Máxima',
      'number_of_rounds': 'Número de Rodadas',
      'points_to_win': 'Pontos para Vencer',
      'points_mode_hint': 'O jogo termina quando o primeiro jogador atingir ou superar esta pontuação.',
      'goal_pts': 'Meta',
      'round_label': 'Rodada',
      'time_per_round': 'Tempo por Rodada',
      'seconds': 'Segundos',
      'create_lobby_room': 'CRIAR SALA LOBBY',

      // LobbyScreen
      'room_title': 'SALA',
      'local_room_title': 'SALA LOCAL',
      'host_crown': '👑 Anfitrião',
      'start_game': 'INICIAR PARTIDA',
      'waiting_host': 'Aguardando Anfitrião...',
      'waiting_more_players': 'Aguardando mais jogadores... (Mínimo 2)',

      // RouletteScreen
      'drawing_letter': 'Sorteando Letra...',
      'spin_again': 'GIRAR NOVAMENTE',
      'waiting_host_spin': 'Aguardando o Anfitrião girar...',

      // GameScreen
      'letter_title': 'LETRA',
      'stop_button': 'BASTA!',
      'someone_pressed_stop': 'Alguém pressionou o botão.',
      'waiting_server': 'Aguardando o servidor...',

      // ReviewScreen
      'review_title': 'REVISÃO',
      'waiting_answers': 'Aguardando respostas e avaliação...',
      'evaluate_results': 'AVALIAR RESULTADOS',
      'pts': 'pts',
      'total_pts': 'Total',
      '100_unique': '100 ÚNICA',
      '50_repeated': '50 REPETIDA',
      '0_empty': '0 VAZIA',
      'view_final_podium': 'VER PÓDIO FINAL',
      'confirm_ratings': 'CONFIRMAR AVALIAÇÕES',
      'ratings_confirmed_wait': 'Avaliações confirmadas. Aguardando os outros...',
      'waiting_players_ratings': 'AGUARDANDO AVALIAÇÕES',
      'confirmed_badge': 'Pronto',
      'rating_badge': 'Avaliando...',

      // LeaderboardScreen
      'final_results': 'RESULTADOS FINAIS',
      'back_home': 'VOLTAR AO INÍCIO',
      'next_round': 'PRÓXIMA RODADA',
      'waiting_host_next_round': 'Aguardando o anfitrião para a próxima rodada...',
      'return_to_lobby': 'Voltar ao Lobby',
      'leave_room': 'Sair da Sala',

      // Validation
      'write_all_categories': 'Você deve preencher todas as categorias antes de apertar BASTA!',
      'invalid_words': 'Todas as palavras devem começar com a letra correta e ter pelo menos 2 caracteres.',

      // Categories
      'NOMBRE': 'NOME',
      'APELLIDO': 'SOBRENOME',
      'CIUDAD/PAÍS': 'CIDADE/PAÍS',
      'ANIMAL': 'ANIMAL',
      'COSA': 'COISA',
      'FLOR/FRUTO': 'FLOR/FRUTA',
    }
  };
}
