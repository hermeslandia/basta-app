import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/game_provider.dart';
import '../../providers/network_provider.dart';
import '../../services/audio_service.dart';
import '../widgets/custom_3d_button.dart';
import 'lobby_screen.dart';
import '../../core/theme/skin_manager.dart';
import '../../providers/language_provider.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({Key? key}) : super(key: key);

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final List<String> _defaultCategories = [
    'NOMBRE',
    'APELLIDO',
    'CIUDAD/PAÍS',
    'ANIMAL',
    'COSA',
    'FLOR/FRUTO'
  ];
  List<String> _customCategories = [];
  final Set<String> _selectedCategories = {
    'NOMBRE',
    'APELLIDO',
    'CIUDAD/PAÍS',
    'ANIMAL',
    'COSA',
    'FLOR/FRUTO'
  };

  int _timerSeconds = 60;
  bool _isPrivateRoom = false;
  bool _isCreatingRoom = false;
  String _winCondition = 'rounds'; // 'rounds' (Por Rondas) o 'points' (Puntuación Máxima)

  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roundsController = TextEditingController(text: '3');
  final TextEditingController _targetScoreController = TextEditingController(text: '25000');
  final TextEditingController _customCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final game = context.read<GameProvider>();
    final String userName = game.profileName.trim().isNotEmpty
        ? game.profileName.trim()
        : (game.localPlayer?.name.trim().isNotEmpty == true
            ? game.localPlayer!.name.trim()
            : 'Usuario');
    _roomNameController.text = 'Sala de $userName';
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customCategories = prefs.getStringList('custom_categories') ?? [];
      _selectedCategories.addAll(_customCategories);
    });
  }

  Future<void> _saveCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_categories', _customCategories);
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _roundsController.dispose();
    _targetScoreController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _onStartLobby() async {
    if (_isCreatingRoom) return;
    setState(() => _isCreatingRoom = true);

    final game = context.read<GameProvider>();
    final network = context.read<NetworkProvider>();
    final String userName = game.profileName.trim().isNotEmpty
        ? game.profileName.trim()
        : (game.localPlayer?.name.trim().isNotEmpty == true
            ? game.localPlayer!.name.trim()
            : 'Usuario');

    String roomName = _roomNameController.text.trim();
    if (roomName.isEmpty) {
      roomName = 'Sala de $userName';
    }

    final int parsedRounds = (int.tryParse(_roundsController.text.trim()) ?? 3).clamp(1, 999);
    final int parsedTargetScore =
        (int.tryParse(_targetScoreController.text.trim().replaceAll(',', '')) ?? 25000)
            .clamp(100, 9999999);

    game.updateCategories(_selectedCategories.toList());
    game.updateTimerConfig(_timerSeconds);
    game.updateGameModeConfig(
      winCondition: _winCondition,
      totalRounds: parsedRounds,
      targetScore: parsedTargetScore,
    );

    // Iniciar la sala en la red (Local o Internet con soporte para pública/privada)
    final finalRoomCode = await network.hostGame(
      game.localPlayer!.name,
      roomCode: roomName,
      isPrivate: _isPrivateRoom,
    );

    if (!mounted) return;
    setState(() => _isCreatingRoom = false);

    if (finalRoomCode == null && network.currentMode == NetworkMode.internet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al crear sala en Internet. Revisa tu conexión.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    game.setRoomCode(
      finalRoomCode ?? roomName,
      roomName: roomName,
      isPrivate: _isPrivateRoom,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LobbyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final network = context.watch<NetworkProvider>();
    final lang = context.watch<LanguageProvider>();
    final theme = SkinManager.getTheme(game.profileSkin);
    final bool isInternet = network.currentMode == NetworkMode.internet;

    final List<String> allCategories = [..._defaultCategories, ..._customCategories];

    final bool isDarkTheme = theme.textColor == Colors.white ||
        theme.primaryContainerColor.computeLuminance() < 0.35;
    final Color inputBgColor =
        isDarkTheme ? Colors.black.withValues(alpha: 0.45) : Colors.grey[100]!;
    final Color inputTextColor =
        isDarkTheme ? Colors.white : Colors.black87;
    final Color inputHintColor =
        isDarkTheme ? Colors.white54 : Colors.black38;
    final Color inputBorderColor =
        isDarkTheme ? theme.borderColor.withValues(alpha: 0.6) : Colors.grey[400]!;
    final Color unselectedBtnBg =
        isDarkTheme ? Colors.black.withValues(alpha: 0.4) : Colors.grey[200]!;
    final Color unselectedBtnText =
        isDarkTheme ? Colors.white70 : Colors.black54;
    final Color unselectedBtnBorder =
        isDarkTheme ? theme.borderColor.withValues(alpha: 0.35) : Colors.grey[300]!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          lang.get('config_room_title'),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: theme.titleColor,
            shadows: theme.textShadows,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.titleColor),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.titleColor),
          onPressed: () {
            AudioService().playClickMinor();
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: SkinManager.getBackgroundProvider(theme.id),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  children: [
                    // 1. Configuración de Nombre de Sala y Privacidad
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.primaryContainerColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.borderColor, width: 2),
                        boxShadow: theme.hasNeonGlow
                            ? [BoxShadow(color: theme.borderColor, blurRadius: 10)]
                            : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.get('room_name'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _roomNameController,
                            style: TextStyle(fontWeight: FontWeight.bold, color: inputTextColor),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              hintText: lang.get('room_name_hint'),
                              hintStyle: TextStyle(color: inputHintColor),
                              filled: true,
                              fillColor: inputBgColor,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: inputBorderColor, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.borderColor, width: 2),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          if (isInternet) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  _isPrivateRoom ? Icons.lock : Icons.public,
                                  color: _isPrivateRoom ? Colors.amber[800] : Colors.green[700],
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isPrivateRoom
                                            ? 'Sala Privada (Solo con código)'
                                            : 'Sala Pública (Visible en lista)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: theme.textColor,
                                        ),
                                      ),
                                      Text(
                                        _isPrivateRoom
                                            ? 'Nadie la verá en la lista pública; comparte el código para entrar.'
                                            : 'Aparecerá en tiempo real en la lista de salas disponibles.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.textColor.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isPrivateRoom,
                                  activeColor: Colors.amber[800],
                                  onChanged: (val) {
                                    AudioService().playClickMinor();
                                    setState(() => _isPrivateRoom = val);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2. Modo de Juego: Por Rondas (default 3) o Por Puntuación Máxima (default 25,000 pts)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.primaryContainerColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.borderColor, width: 2),
                        boxShadow: theme.hasNeonGlow
                            ? [BoxShadow(color: theme.borderColor, blurRadius: 10)]
                            : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.get('game_mode_title'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    AudioService().playClickMinor();
                                    setState(() => _winCondition = 'rounds');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: _winCondition == 'rounds'
                                          ? Colors.orange[700]
                                          : unselectedBtnBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _winCondition == 'rounds'
                                            ? Colors.amberAccent
                                            : unselectedBtnBorder,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.repeat,
                                          size: 18,
                                          color: _winCondition == 'rounds'
                                              ? Colors.white
                                              : unselectedBtnText,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            lang.get('mode_by_rounds'),
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                              color: _winCondition == 'rounds'
                                                  ? Colors.white
                                                  : unselectedBtnText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    AudioService().playClickMinor();
                                    setState(() => _winCondition = 'points');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: _winCondition == 'points'
                                          ? Colors.amber[800]
                                          : unselectedBtnBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _winCondition == 'points'
                                            ? Colors.yellowAccent
                                            : unselectedBtnBorder,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.emoji_events,
                                          size: 18,
                                          color: _winCondition == 'points'
                                              ? Colors.white
                                              : unselectedBtnText,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            lang.get('mode_by_points'),
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 13,
                                              color: _winCondition == 'points'
                                                  ? Colors.white
                                                  : unselectedBtnText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_winCondition == 'rounds')
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lang.get('number_of_rounds'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.textColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(Icons.remove_circle, color: theme.textColor),
                                  onPressed: () {
                                    AudioService().playClickMinor();
                                    final current = int.tryParse(_roundsController.text.trim()) ?? 3;
                                    if (current > 1) {
                                      setState(() => _roundsController.text = '${current - 1}');
                                    }
                                  },
                                ),
                                SizedBox(
                                  width: 72,
                                  child: TextField(
                                    controller: _roundsController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: inputTextColor,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      filled: true,
                                      fillColor: inputBgColor,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: inputBorderColor, width: 1.5),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: theme.borderColor, width: 2),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(Icons.add_circle, color: theme.textColor),
                                  onPressed: () {
                                    AudioService().playClickMinor();
                                    final current = int.tryParse(_roundsController.text.trim()) ?? 3;
                                    setState(() => _roundsController.text = '${current + 1}');
                                  },
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        lang.get('points_to_win'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.textColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 130,
                                      child: TextField(
                                        controller: _targetScoreController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: inputTextColor,
                                        ),
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 8),
                                          suffixText: 'pts',
                                          suffixStyle: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: inputTextColor.withValues(alpha: 0.7),
                                          ),
                                          filled: true,
                                          fillColor: inputBgColor,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: inputBorderColor, width: 1.5),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: theme.borderColor, width: 2),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lang.get('points_mode_hint'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textColor.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. Tiempo por Ronda
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.primaryContainerColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.borderColor, width: 2),
                        boxShadow: theme.hasNeonGlow
                            ? [BoxShadow(color: theme.borderColor, blurRadius: 10)]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang.get('time_per_round'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                              fontSize: 15,
                            ),
                          ),
                          DropdownButton<int>(
                            value: _timerSeconds,
                            dropdownColor: theme.primaryContainerColor,
                            style: TextStyle(fontWeight: FontWeight.bold, color: theme.textColor),
                            items: [30, 60, 90, 120]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      '$s ${lang.get('seconds')}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _timerSeconds = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 4. Añadir categoría personalizada
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customCategoryController,
                            style: TextStyle(fontWeight: FontWeight.bold, color: inputTextColor),
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              hintText: 'Añadir categoría personalizada...',
                              hintStyle: TextStyle(color: inputHintColor),
                              filled: true,
                              fillColor: inputBgColor,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: inputBorderColor, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.borderColor, width: 2),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              final word = _customCategoryController.text.trim().toUpperCase();
                              if (word.isNotEmpty &&
                                  !_defaultCategories.contains(word) &&
                                  !_customCategories.contains(word)) {
                                setState(() {
                                  _customCategories.add(word);
                                  _selectedCategories.add(word);
                                });
                                _customCategoryController.clear();
                                _saveCustomCategories();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 5. Lista de Categorías
                    Container(
                      decoration: BoxDecoration(
                        color: theme.primaryContainerColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.borderColor, width: 4),
                        boxShadow: theme.hasNeonGlow
                            ? [BoxShadow(color: theme.borderColor, blurRadius: 10)]
                            : [],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        itemCount: allCategories.length,
                        separatorBuilder: (_, __) => Divider(color: theme.borderColor, thickness: 1),
                        itemBuilder: (context, index) {
                          final cat = allCategories[index];
                          final isCustom = index >= _defaultCategories.length;
                          return SwitchListTile(
                            dense: true,
                            secondary: isCustom
                                ? IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () {
                                      setState(() {
                                        _customCategories.remove(cat);
                                        _selectedCategories.remove(cat);
                                      });
                                      _saveCustomCategories();
                                    },
                                  )
                                : null,
                            title: Text(
                              _defaultCategories.contains(cat) ? lang.get(cat) : cat,
                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.textColor),
                            ),
                            value: _selectedCategories.contains(cat),
                            activeColor: theme.hasNeonGlow ? Colors.cyanAccent : Colors.green,
                            onChanged: (bool value) {
                              AudioService().playClickMinor();
                              setState(() {
                                if (value) {
                                  _selectedCategories.add(cat);
                                } else {
                                  _selectedCategories.remove(cat);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Custom3DButton(
                  text: _isCreatingRoom ? 'CREANDO SALA...' : lang.get('create_lobby_room'),
                  color: _isCreatingRoom ? Colors.grey : Colors.green,
                  shadowColor: _isCreatingRoom ? Colors.grey[800]! : Colors.green[900]!,
                  onPressed: () {
                    if (_isCreatingRoom) return;
                    AudioService().playClickMajor();
                    _onStartLobby();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
