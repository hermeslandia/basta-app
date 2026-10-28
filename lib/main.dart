import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/theme_manager.dart';
import 'core/theme/skin_manager.dart';
import 'services/theme_service.dart';
import 'providers/network_provider.dart';
import 'providers/game_provider.dart';
import 'providers/language_provider.dart';
import 'providers/store_provider.dart';
import 'ui/screens/intro_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  // Carga temas instalados dinámicamente en el almacenamiento del dispositivo
  await SkinManager.loadInstalledThemes();

  // Sincroniza el catálogo de temas en segundo plano
  ThemeService().syncThemesCatalog().catchError((e) {
    debugPrint('Aviso syncThemesCatalog: $e');
    return <SkinTheme>[];
  });

  bool isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  if (isDesktop) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      title: 'Basta P2P',
      minimumSize: Size(800, 600),
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
        ChangeNotifierProxyProvider<NetworkProvider, GameProvider>(
          create: (context) => GameProvider(context.read<NetworkProvider>().activeService),
          update: (context, networkProvider, previous) {
            final provider = previous ?? GameProvider(networkProvider.activeService);
            provider.updateNetworkService(networkProvider.activeService);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
      ],
      child: const BastaApp(),
    ),
  );
}

class BastaApp extends StatefulWidget {
  const BastaApp({Key? key}) : super(key: key);

  @override
  State<BastaApp> createState() => _BastaAppState();
}

class _BastaAppState extends State<BastaApp> with WindowListener {
  bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    if (isDesktop) {
      windowManager.addListener(this);
      // Esto evita que Windows cierre la ventana inmediatamente al darle a la X
      windowManager.setPreventClose(true); 
    }
  }

  @override
  void dispose() {
    if (isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // 1. Limpiamos las conexiones y damos de baja el servicio mDNS
    if (mounted) {
      context.read<NetworkProvider>().disconnect();
    }
    
    // 2. Esperamos medio segundo para que la instrucción de socket viaje por la red
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 3. Forzamos el cierre definitivo de la ventana
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();

    return MaterialApp(
      title: 'Basta P2P',
      theme: themeManager.currentThemeData,
      home: const IntroScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
