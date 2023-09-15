import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitfinder/config.dart' as config;
import 'package:gitfinder/pages/search/search_page_viewmodel.dart';
import 'package:gitfinder/pages/settings/settings_page.dart';
import 'package:io/io.dart';

Map<String, dynamic> readSettingsFile() {
  checkSettings();
  File settingsFile = File('${config.targetConfigFolder}/settings.json');
  Map<String, dynamic> settings = json.decode(settingsFile.readAsStringSync());
  return settings;
}

Map<String, dynamic> writeSettingsFile(Map<String, dynamic> settings) {
  File settingsFile = File('${config.targetConfigFolder}/settings.json');
  settingsFile.writeAsStringSync(const JsonEncoder.withIndent("     ").convert(settings));
  return settings;
}

void changeCompletedFolder(WidgetRef ref, String newCompletedFolder) {
  if (ref.read(searchPidProvider).isEmpty) {
    String oldCompletedFolder = config.settings['completedFolder'];
    if (oldCompletedFolder == newCompletedFolder) {
      return;
    }
    copyPathSync(oldCompletedFolder, newCompletedFolder);
    Directory(oldCompletedFolder).deleteSync(recursive: true);
    Directory(config.targetCompletedDefaultFolder).createSync(recursive: true);
    config.settings['completedFolder'] = newCompletedFolder;
    writeSettingsFile(config.settings);
  } else {
    throw Exception('Cannot change completed folder while searching');
  }
}

void checkSettings() {
  bool settingsExists = File('${config.targetConfigFolder}/settings.json').existsSync();

  if (!settingsExists) {
    File('${config.targetConfigFolder}/settings.json').createSync();
    writeSettingsFile(config.defaultSettings);
  } else {
    File settingsFile = File('${config.targetConfigFolder}/settings.json');
    if (settingsFile.readAsStringSync().isEmpty) {
      writeSettingsFile(config.defaultSettings);
    }
  }
}

List<String> readTokensConfigFile(String provider) {
  String providerConfigFile = getProviderConfigFile(provider);
  File file = File('${config.targetConfigFolder}/$providerConfigFile');
  return file.readAsLinesSync();
}

void writeTokensConfigFile(String provider, List<String> tokens) {
  List<String> lines = readTokensConfigFile(provider);
  File file = File('${config.targetConfigFolder}/${getProviderConfigFile(provider)}');
  // List<String> newTokens = [];

  if (lines.isEmpty) {
    throw Exception('Error reading $provider config file');
  }

  // newTokens = getTokens(lines)..addAll(tokens);
  lines[2] = 'TOKENS=[${tokens.join(',')}]';
  file.writeAsStringSync(lines.join('\n'));
}

List<String> getTokens(List<String> lines) {
  String tokens = lines[2].substring(lines[2].indexOf('[') + 1, lines[2].indexOf(']'));
  return tokens.split(',');
}

String getProviderConfigFile(String provider) {
  late String providerConfigFile;
  switch (provider) {
    case 'github':
      providerConfigFile = 'github.properties';
      break;
    case 'gitlab':
      providerConfigFile = 'gitlab.properties';
      break;
    default:
      throw Exception('Invalid provider');
  }
  return providerConfigFile;
}

void toggleRefresh(WidgetRef ref) {
  config.settings['general']['autoRefresh'] = !config.settings['general']['autoRefresh'];
  writeSettingsFile(config.settings);
  ref.read(searchVMProvider).updateNeedRefreshing(ref, false);
}

void changeTheme(String theme) {
  config.settings['general']['theme'] = theme;
  writeSettingsFile(config.settings);
}

void toggleGridDarkTheme(WidgetRef ref) {
  config.settings['general']['gridDarkTheme'] = !config.settings['general']['gridDarkTheme'];
  writeSettingsFile(config.settings);
  ref.read(gridDarkThemeProvider.notifier).state = config.settings['general']['gridDarkTheme'];
  ref.read(searchVMProvider).updateNeedRefreshing(ref, false);
}
