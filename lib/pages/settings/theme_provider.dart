import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitfinder/config.dart' as config;
import 'package:gitfinder/pages/settings/settings_page_viewmodel.dart';

final themeProvider = ChangeNotifierProvider<ThemeNotifier>((ref) {
  var theme = ThemeNotifier();
  theme.setTheme(config.settings['general']['theme']);
  return theme;
});

class ThemeNotifier extends ChangeNotifier {
  String selectedTheme = config.settings['general']['theme'];

  var homeBoxColor = Colors.grey[800];
  var activatedColor = const Color(0xFFD6D6D6);
  var primaryColor = const Color.fromARGB(255, 240, 79, 51);
  var canvasColor = const Color(0xff1f1f1f);
  var scaffoldBackgroundColor = const Color(0xff181818);
  var hoverColor = Colors.grey[700];
  var accentCanvasColor = const Color.fromARGB(255, 92, 92, 92);
  var actionColor = Colors.grey.withOpacity(0.6);
  var gitColor = const Color.fromARGB(255, 240, 79, 51);
  var stopColor = const Color(0xFFeb7171);
  var startColor = const Color(0xFF57965c);
  var tabColor = const Color(0xff242424);
  var tabBorderColor = const Color(0xff1f1f1f);
  var tabIndicatorColor = const Color.fromARGB(255, 240, 79, 51);

  // late var homeBoxColor;
  // late var activatedColor;
  // late var primaryColor;
  // late var canvasColor;
  // late var scaffoldBackgroundColor;
  // late var hoverColor;
  // late var accentCanvasColor;
  // late var actionColor;
  // late var gitColor;
  // late var stopColor;
  // late var startColor;
  // late var tabColor;
  // late var tabBorderColor;
  // late var tabIndicatorColor;

  Map<String, bool> selectedThemeMap = {
    'violet': 'violet' == config.settings['general']['theme'],
    'dark': 'dark' == config.settings['general']['theme'],
  };

  Map<String, Color?> violetTheme = {
    'homeBoxColor': const Color(0xFF464667),
    'activatedColor': const Color(0xFFD6D2FF),
    'primaryColor': const Color(0xFF867BFF),
    'canvasColor': const Color(0xFF2E2E48),
    'scaffoldBackgroundColor': const Color(0xFF464667),
    'hoverColor': const Color(0xFF464667),
    'accentCanvasColor': const Color(0xFF3E3E61),
    'actionColor': const Color(0xFF5F5FA7).withOpacity(0.6),
    'gitColor': const Color.fromARGB(255, 240, 79, 51),
    'stopColor': const Color(0xFFeb7171),
    'startColor': const Color(0xFF57965c),
    'tabColor': const Color(0xFF2E2E48),
    'tabBorderColor': const Color(0xFF2E2E48),
    'tabIndicatorColor': const Color(0xFF867BFF),
  };

  Map<String, Color?> darkTheme = {
    'homeBoxColor': Colors.grey[800],
    'activatedColor': const Color(0xFFD6D6D6),
    'primaryColor': const Color.fromARGB(255, 240, 79, 51),
    'canvasColor': const Color(0xff1f1f1f),
    'scaffoldBackgroundColor': const Color(0xff181818),
    'hoverColor': Colors.grey[700],
    'accentCanvasColor': const Color.fromARGB(255, 92, 92, 92),
    'actionColor': Colors.grey.withOpacity(0.6),
    'gitColor': const Color.fromARGB(255, 240, 79, 51),
    'stopColor': const Color(0xFFeb7171),
    'startColor': const Color(0xFF57965c),
    'tabColor': const Color(0xff242424),
    'tabBorderColor': const Color(0xff1f1f1f),
    'tabIndicatorColor': const Color.fromARGB(255, 240, 79, 51),
  };

  void setTheme(String theme) {
    switch (theme.toLowerCase()) {
      case 'violet':
        homeBoxColor = violetTheme['homeBoxColor'] as Color;
        activatedColor = violetTheme['activatedColor'] as Color;
        primaryColor = violetTheme['primaryColor'] as Color;
        canvasColor = violetTheme['canvasColor'] as Color;
        scaffoldBackgroundColor = violetTheme['scaffoldBackgroundColor'] as Color;
        hoverColor = violetTheme['hoverColor'] as Color;
        accentCanvasColor = violetTheme['accentCanvasColor'] as Color;
        actionColor = violetTheme['actionColor'] as Color;
        gitColor = violetTheme['gitColor'] as Color;
        stopColor = violetTheme['stopColor'] as Color;
        startColor = violetTheme['startColor'] as Color;
        tabColor = violetTheme['tabColor'] as Color;
        tabBorderColor = violetTheme['tabBorderColor'] as Color;
        tabIndicatorColor = violetTheme['tabIndicatorColor'] as Color;
        notifyListeners();
        break;
      default:
        homeBoxColor = darkTheme['homeBoxColor'] as Color;
        activatedColor = darkTheme['activatedColor'] as Color;
        primaryColor = darkTheme['primaryColor'] as Color;
        canvasColor = darkTheme['canvasColor'] as Color;
        scaffoldBackgroundColor = darkTheme['scaffoldBackgroundColor'] as Color;
        hoverColor = darkTheme['hoverColor'] as Color;
        accentCanvasColor = darkTheme['accentCanvasColor'] as Color;
        actionColor = darkTheme['actionColor'] as Color;
        gitColor = darkTheme['gitColor'] as Color;
        stopColor = darkTheme['stopColor'] as Color;
        startColor = darkTheme['startColor'] as Color;
        tabColor = darkTheme['tabColor'] as Color;
        tabBorderColor = darkTheme['tabBorderColor'] as Color;
        tabIndicatorColor = darkTheme['tabIndicatorColor'] as Color;
        break;
    }
    updateSelectedTheme(theme.toLowerCase());
    changeTheme(theme.toLowerCase());
    notifyListeners();
  }

  void updateSelectedTheme(String theme) {
    selectedThemeMap.forEach((key, value) {
      selectedThemeMap[key] = key == theme;
    });
    notifyListeners();
  }

  Map<String, Color?> getTheme(String theme) {
    switch (theme) {
      case 'violet':
        return violetTheme;
      default:
        return darkTheme;
    }
  }
}
