import 'package:gitfinder/pages/settings/settings_page_viewmodel.dart';

const String targetFolderResults = 'target/GitFinderResult';
const String targetConfigFolder = './target/config/';
const String targetFolder = './target';
const String targetCompletedDefaultFolder = './target/GitFinderResultCompleted';
const String targetBookmarks = './target/GitFinderBookmarks';

Map<String, dynamic> settings = readSettingsFile();

const Map<String, dynamic> defaultSettings = {
  'completedFolder': targetCompletedDefaultFolder,
  'general': {
    'autoRefresh': true,
    'theme': 'dark',
    'gridDarkTheme': false,
  },
};
