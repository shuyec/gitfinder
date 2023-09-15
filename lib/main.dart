import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitfinder/pages/search/search_page_viewmodel.dart';
import 'package:gitfinder/pages/settings/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'sidebar_controller.dart';
import 'package:window_size/window_size.dart';
import 'package:windows_single_instance/windows_single_instance.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setWindowTitle("GitFinder");
  await windowManager.ensureInitialized();
  await WindowsSingleInstance.ensureSingleInstance(
    [],
    'GitFinder',
  );
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // setWindowMinSize(const Size(950, 800));
    WindowManager.instance.setMinimumSize(const Size(950, 800));
  }

  runApp(const ProviderScope(
    child: GitFinderApp(),
  ));
}

class GitFinderApp extends ConsumerStatefulWidget {
  const GitFinderApp({Key? key}) : super(key: key);

  @override
  ConsumerState<GitFinderApp> createState() => _GitFinderAppState();
}

class _GitFinderAppState extends ConsumerState<GitFinderApp> with WindowListener {
  final _key = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
    ref.read(searchVMProvider).killAllProcesses(ref);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    ref.read(searchVMProvider).killAllProcesses(ref);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    ref.read(searchVMProvider).killAllProcesses(ref);
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    var theme = ref.watch(themeProvider);

    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'GB'), // English GB
        Locale('it', 'IT'), // Italian
      ],
      title: 'GitFinder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: theme.primaryColor,
        canvasColor: theme.canvasColor,
        scaffoldBackgroundColor: theme.scaffoldBackgroundColor,
        fontFamily: 'Montserrat',
        textTheme: const TextTheme(
          displayMedium: TextStyle(
            color: Colors.white,
            fontSize: 32.0,
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: TextStyle(
            color: Colors.white,
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.0,
          ),
          headlineMedium: TextStyle(
            fontSize: 14.0,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
          ),
          headlineLarge: TextStyle(
            fontSize: 25.0,
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
          bodyLarge: TextStyle(
            color: Colors.white,
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
          bodyMedium: TextStyle(
            color: Colors.white,
            letterSpacing: 1.0,
          ),
        ),
      ),
      home: Builder(
        builder: (context) {
          final isSmallScreen = MediaQuery.of(context).size.width < 600;
          return Scaffold(
            key: _key,
            appBar: isSmallScreen
                ? AppBar(
                    backgroundColor: theme.canvasColor,
                    title: Text(getPageByIndex(ref.watch(sidebarControllerProvider).selectedIndex)),
                    leading: IconButton(
                      onPressed: () {
                        // if (!Platform.isAndroid && !Platform.isIOS) {
                        //   _controller.setExtended(true);
                        // }
                        _key.currentState?.openDrawer();
                      },
                      icon: const Icon(Icons.menu),
                    ),
                  )
                : null,
            drawer: Sidebar(controller: ref.watch(sidebarControllerProvider)),
            body: Row(
              children: [
                if (!isSmallScreen) Sidebar(controller: ref.watch(sidebarControllerProvider)),
                Expanded(
                  child: Center(
                    child: Pages(
                      ref,
                      key: Key((ref.watch(sidebarControllerProvider).selectedIndex - 3).toString()),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      builder: EasyLoading.init(),
    );
  }
}
