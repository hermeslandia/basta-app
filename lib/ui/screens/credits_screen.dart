import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/audio_service.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  Timer? _scrollTimer;
  final double _scrollSpeed = 50.0; // Píxeles por segundo

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Iniciar el auto-scroll despues de un pequeño retraso
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1), () {
        _startAutoScroll();
      });
    });
  }

  void _startAutoScroll() {
    if (!mounted) return;
    
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_scrollController.hasClients) return;
      
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      
      // Calculate delta based on speed (50px/sec at 60fps ~ 0.8px/frame)
      final double delta = _scrollSpeed * (16 / 1000);
      
      if (currentScroll >= maxScroll) {
        // Detener al llegar al final
        timer.cancel();
      } else {
        _scrollController.jumpTo(currentScroll + delta);
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Área de Créditos con Scroll
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const NeverScrollableScrollPhysics(), // Evitar scroll manual para efecto cine puro
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  children: [
                    // Espacio inicial para que empiece desde abajo de la pantalla
                    SizedBox(height: MediaQuery.of(context).size.height),
                    
                    const Text(
                      '¡BASTA!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Desarrollado con ❤️ por Hermes para noches de juegos inolvidables.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 60),
                    
                    _buildSection(
                      'AGRADECIMIENTOS ESPECIALES',
                      'A toda la familia y amigos que ayudaron a probar el juego y dieron sus valiosos comentarios para mejorarlo.',
                    ),
                    _buildSection(
                      'AVISO DE PRIVACIDAD',
                      'Esta aplicación respeta tu privacidad. No recolectamos información personal identificable sin tu consentimiento. Los datos del perfil se guardan de forma local en tu dispositivo. Al jugar en línea, tu nombre de perfil y avatar se comparten temporalmente con otros jugadores en la sala.',
                    ),
                    _buildSection(
                      'TÉRMINOS Y CONDICIONES',
                      'Al utilizar "¡BASTA!", aceptas usar la aplicación de manera responsable y respetuosa con otros jugadores. No nos hacemos responsables del contenido generado por los usuarios durante las partidas (palabras ingresadas). Las compras con la aplicación son definitivas según los términos de la plataforma correspondiente.',
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 30.0),
                      child: Text(
                        'CRÉDITOS Y ATRIBUCIONES',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 60.0),
                      child: Column(
                        children: [
                          const Text(
                            'ARTE Y DISEÑO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Image.asset(
                            'assets/global/images/studio_logo.png',
                            width: 140,
                            height: 140,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Ilustraciones, Avatares y Diseño Visual por\nCaduceo Antigravity Studio\nen colaboración con Hermes',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildSection(
                      'MÚSICA Y EFECTOS',
                      'Holiday (Ukulele) by MaxKoMusic\nhttps://maxkomusic.com/\n\n'
                      'Error by BloodPixelHero (CC0)\n'
                      'UI Button Click by dimapain (CC BY 4.0)\n'
                      'Pop Sound by Tony_Cannoli (CC0)\n'
                      'Baby Pranks by AudioCoffee (CC BY-NC 4.0)\n'
                      'Game Menu Achievement by CogFireStudios (CC0)\n'
                      'IR Camera Switch by nikerk (CC0)',
                    ),
                    _buildSection(
                      '¡AVISO!',
                      'El uso de esta aplicación implica la aceptación de los términos de servicio. ¡Basta! no se hace responsable de daños causados durante la emoción del juego.',
                    ),
                    
                    const SizedBox(height: 100),
                    const Text(
                      'GRACIAS POR JUGAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    
                    // Espacio final para que el texto salga por arriba
                    SizedBox(height: MediaQuery.of(context).size.height),
                  ],
                ),
              ),
            ),
          ),
          
          // Botón de Salida (Aparece estático encima del scroll)
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
              onPressed: () {
                AudioService().playClickMinor();
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60.0),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
