import 'dart:async';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitfinder/config.dart' as config;
import 'package:gitfinder/pages/search/search_content_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:io/io.dart';
import 'package:gitfinder/pages/search/search_content.dart';
import 'dart:convert';
import 'package:gitfinder/pages/search/search_filters.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:pluto_grid/pluto_grid.dart';

final searchFoldersProvider = Provider((ref) => SearchPageViewModel().getFiles());
final searchVMProvider = Provider((ref) => SearchPageViewModel());
final searchPidProvider = Provider((ref) => {});

class SearchPageViewModel {
  List<String> getSearchTabs(String folder) {
    try {
      var search = readSearchJson(folder);
      if (search != null) {
        return [
          'Repositories',
          if (search['isCommitChecked']) 'Commits',
          if (search['isIssueChecked']) 'Issues',
        ];
      } else {
        throw '$folder search.json missing';
      }
    } catch (e) {
      return [];
      // print(e);
    }
  }

  List<Widget> getSearchViews(String folder) {
    try {
      var search = readSearchJson(folder);
      if (search != null) {
        return [
          SearchGrid('repositories', folder),
          if (search['isCommitChecked']) SearchGrid('commits', folder),
          if (search['isIssueChecked']) SearchGrid('issues', folder),
        ];
      } else {
        throw '$folder search.json missing';
      }
    } catch (e) {
      return [];
      // print(e);
    }
  }

  Future<crypto.Digest> getHashOfFile(String path) => File(path).openRead().transform(crypto.sha256).first;

  Future<void> startSearch(WidgetRef ref, String folder, List<String> args) async {
    executeCommand(ref, folder, args);
    await waitLogFile(folder);

    ref.read(searchContentProvider(folder).notifier).updateSearchPage();

    bool repoFirstTimeThru = true;
    bool commitFirstTimeThru = true;
    bool issueFirstTimeThru = true;

    crypto.Digest? reposHash;
    crypto.Digest? commitsHash;
    crypto.Digest? issuesHash;

    Future.doWhile(() async {
      bool searchFinished = isSearchFinished(folder);
      if (searchFinished) {
        copyCompletedFolder(folder);
        ref.read(searchPidProvider).remove(folder);
        ref.read(isSearchStartedProvider(folder).notifier).state = false;
        ref.read(isSearchFinishedProvider(folder).notifier).state = true;
        ref.read(needRefreshing(folder).notifier).state = false;
        ref.read(searchContentProvider(folder).notifier).updateSearchContent();
        EasyLoading.showSuccess('Search finished', duration: const Duration(milliseconds: 200));
        return false;
      }
      if (!ref.read(isSearchStartedProvider(folder))) {
        return false;
      }

      if (ref.read(searchContentProvider(folder)).isRepositoriesCsvPresent) {
        crypto.Digest newReposHash = await getHashOfFile('${config.targetFolderResults}/$folder/GitRepositoryInfo.csv');
        if (newReposHash != reposHash) {
          reposHash = newReposHash;

          if (config.settings['general']['autoRefresh']) {
            ref.read(searchContentProvider(folder).notifier).updateSearchContent('repositories');
          } else {
            if (repoFirstTimeThru) {
              ref.read(searchContentProvider(folder).notifier).updateSearchContent('repositories');
              repoFirstTimeThru = false;
            } else {
              ref.read(needRefreshing(folder).notifier).state = true;
            }
          }

          // EasyLoading.showSuccess('Repositories updated', duration: const Duration(milliseconds: 200));
        }
      } else {
        ref.read(searchContentProvider(folder).notifier).updateIsCsvPresent('repositories');
      }

      if (ref.read(searchContentProvider(folder)).isCommitsCsvPresent) {
        crypto.Digest newCommitsHash = await getHashOfFile('${config.targetFolderResults}/$folder/GitCommitInfo.csv');
        if (newCommitsHash != commitsHash) {
          commitsHash = newCommitsHash;

          if (config.settings['general']['autoRefresh']) {
            ref.read(searchContentProvider(folder).notifier).updateSearchContent('commits');
          } else {
            if (commitFirstTimeThru) {
              ref.read(searchContentProvider(folder).notifier).updateSearchContent('commits');
              commitFirstTimeThru = false;
            } else {
              ref.read(needRefreshing(folder).notifier).state = true;
            }
          }

          // EasyLoading.showSuccess('Commits updated', duration: const Duration(milliseconds: 200));
        }
      } else {
        ref.read(searchContentProvider(folder).notifier).updateIsCsvPresent('commits');
      }

      if (ref.read(searchContentProvider(folder)).isIssuesCsvPresent) {
        crypto.Digest newIssuesHash = await getHashOfFile('${config.targetFolderResults}/$folder/GitIssueInfo.csv');
        if (newIssuesHash != issuesHash) {
          issuesHash = newIssuesHash;

          if (config.settings['general']['autoRefresh']) {
            ref.read(searchContentProvider(folder).notifier).updateSearchContent('issues');
          } else {
            if (issueFirstTimeThru) {
              ref.read(searchContentProvider(folder).notifier).updateSearchContent('issues');
              issueFirstTimeThru = false;
            } else {
              ref.read(needRefreshing(folder).notifier).state = true;
            }
          }

          // EasyLoading.showSuccess('Issues updated', duration: const Duration(milliseconds: 200));
        }
      } else {
        ref.read(searchContentProvider(folder).notifier).updateIsCsvPresent('issues');
      }

      await Future.delayed(const Duration(seconds: 1));
      return true;
    });
  }

  Future waitLogFile(String folder, [Duration pollInterval = const Duration(milliseconds: 300)]) {
    bool logExists = false;
    var completer = Completer();
    check() {
      var filesList = Directory('${config.targetFolderResults}/$folder').listSync(recursive: true);
      for (var file in filesList) {
        if (file.path.endsWith('.log')) logExists = true;
      }
      if (logExists) {
        completer.complete();
      } else {
        Timer(pollInterval, check);
      }
    }

    check();
    return completer.future;
  }

  Future<void> executeCommand(WidgetRef ref, String folder, List<String> args) async {
    // print('Executing command');
    String output = '';
    await Process.start('java', args, workingDirectory: config.targetFolder).then((Process process) {
      process.stdout.transform(utf8.decoder).forEach((s) => output += '$s\n');
      updateSearchPid(ref, folder);
    }).catchError((e) {
      EasyLoading.showError('Error: ${e.toString()}', duration: const Duration(milliseconds: 200));
      // print(e);
    });
    EasyLoading.showSuccess('Search started', duration: const Duration(milliseconds: 200));
    // print('Executing command done');
  }

  void killProcess(WidgetRef ref, String folder) {
    try {
      Process.killPid(ref.read(searchPidProvider)[folder]!);
      ref.read(searchPidProvider).remove(folder);
      EasyLoading.showSuccess('Search stopped', duration: const Duration(milliseconds: 200));
    } catch (e) {
      EasyLoading.showError('Error: ${e.toString()}', duration: const Duration(milliseconds: 200));
    }
  }

  void killAllProcesses(WidgetRef ref) {
    String? javaBinPath = getJavaBinPath();
    if (javaBinPath == null) {
      EasyLoading.showError('Error: JAVA_HOME not set', duration: const Duration(milliseconds: 200));
      return;
    }
    var jps = Process.runSync('jps', [], workingDirectory: javaBinPath, runInShell: true);
    for (var line in LineSplitter.split(jps.stdout)) {
      List<String> parts = line.split(' ');
      int pid = int.parse(parts[0]);
      String name = parts[1];
      if (name == 'git-repositories-finder-1.0-SNAPSHOT-jar-with-dependencies.jar') {
        Process.killPid(pid);
        ref.read(searchPidProvider).removeWhere((key, value) => value == pid);
      }
    }
  }

  bool javaPathCorrect() {
    bool result = true;
    String? javaBinPath = getJavaBinPath();
    if (javaBinPath == 'null\\bin' || javaBinPath == 'null/bin' || javaBinPath == null) {
      result = false;
    }
    try {
      var jps = Process.runSync('jps', [], workingDirectory: javaBinPath, runInShell: true);
      if (jps.stderr.isNotEmpty) {
        result = false;
      }
    } catch (e) {
      // print(e);
      result = false;
    }
    if (!result) {
      EasyLoading.showError('Error: JAVA_HOME not set');
    }
    return result;
  }

  void updateSearchPid(WidgetRef ref, String folder) {
    String? javaBinPath = getJavaBinPath();
    bool pidAdded = false;
    while (!pidAdded) {
      // print('Updating search pid');
      var jps = Process.runSync('jps', [], workingDirectory: javaBinPath, runInShell: true);
      for (var line in LineSplitter.split(jps.stdout)) {
        List<String> parts = line.split(' ');
        int pid = int.parse(parts[0]);
        String name = parts[1];
        if (name == 'git-repositories-finder-1.0-SNAPSHOT-jar-with-dependencies.jar' && !ref.read(searchPidProvider).containsKey(folder)) {
          ref.read(searchPidProvider)[folder] = pid;
          pidAdded = true;
          break;
        }
      }
      // print('Updating search pid done');
    }
  }

  String? getJavaBinPath() {
    String? javaHomePath = Platform.environment['JAVA_HOME'];
    if (javaHomePath != null) {
      return '${Platform.environment['JAVA_HOME']}\\bin';
    } else if (Platform.isWindows) {
      var p = Process.runSync('java', ['-XshowSettings:properties', '-version', '2>&1', '|', 'findstr', 'java.home'], runInShell: true);
      if (p.stdout != null) {
        return p.stdout.substring(p.stdout.indexOf('=') + 1).trim() + '\\bin';
      }
    } else if (Platform.isMacOS) {
      var p = Process.runSync('/usr/libexec/java_home', []);
      if (p.stdout != null) {
        return p.stdout.trim() + '/bin';
      }
    } else {
      var p =
          Process.runSync('java', ['-XshowSettings:properties', '-version', '2>&1', '>', '/dev/null', '|', 'grep', 'java.home'], runInShell: true);
      if (p.stdout != null) {
        return p.stdout.substring(p.stdout.indexOf('=') + 1).trim() + '\\bin';
      }
    }
    return null;
  }

  List<String>? generateCommand({
    required String folder,
    required String reposKeywords,
    required String startDate,
    required String endDate,
    String languages = '',
    int minStars = 0,
    bool github = true,
    bool gitlab = true,
    bool isCommitChecked = false,
    String commitsKeywords = '',
    String commitStartDate = '',
    String commitEndDate = '',
    bool commitFiles = false,
    bool commitStatus = false,
    bool isIssueChecked = false,
    String issuesKeywords = '',
    String issueStartDate = '',
    String issueEndDate = '',
    String issueLabels = '',
    String issueState = 'all',
  }) {
    // RegExp: spaces before and after comma
    RegExp re = RegExp(r"\s+,\s+");

    // Check if all required fields are filled
    if (folder == '' || reposKeywords == '' || startDate == '' || endDate == '') {
      return null;
    }
    if (DateTime.parse(startDate).isAfter(DateTime.parse(endDate))) {
      throw 'Start date must be before end date.';
    }

    if (isCommitChecked) {
      try {
        if (DateTime.parse(commitStartDate).isAfter(DateTime.parse(commitEndDate))) {
          throw 'Commits start date must be before commits end date.';
        }
      } catch (e) {
        EasyLoading.showError('Error: commits dates needed');
        // print(e);
      }
      if (commitsKeywords == '' || commitStartDate == '' || commitEndDate == '') {
        return null;
      }
    }

    if (isIssueChecked) {
      try {
        if (DateTime.parse(issueStartDate).isAfter(DateTime.parse(issueEndDate))) {
          throw 'Issues start date must be before issues end date.';
        }
      } catch (e) {
        EasyLoading.showError('Error: issues dates needed');
        // print(e);
      }
      if (issuesKeywords == '' || issueStartDate == '' || issueEndDate == '') {
        return null;
      }
    }

    List<String> cmdArgs = [
      '-jar',
      'git-repositories-finder-1.0-SNAPSHOT-jar-with-dependencies.jar',
      '-name',
      folder,
      '-start',
      startDate,
      '-end',
      endDate,
      '-repository',
      reposKeywords.trim().replaceAll(re, ',')
    ];
    if (languages != '') {
      cmdArgs.addAll(['-languages', languages.replaceAll(re, ',')]);
    }
    if (minStars != 0) {
      cmdArgs.addAll(['-minStars', minStars.toString()]);
    }

    String providers = getProviders(github, gitlab);
    cmdArgs.addAll(['-providers', providers]);

    if (commitsKeywords != '' && isCommitChecked) {
      cmdArgs.addAll(['-commits', commitsKeywords.trim().replaceAll(re, ',')]);
      try {
        if (commitStartDate != '' && commitEndDate != '') {
          cmdArgs.addAll(['-cstart', commitStartDate, '-cend', commitEndDate]);
        } else {
          throw 'Commits date range needed.';
        }

        if (commitFiles) {
          cmdArgs.addAll(['--commitFiles']);
        }

        if (commitStatus) {
          cmdArgs.addAll(['--commitStatus']);
        }
      } catch (e) {
        EasyLoading.showError('Error: ${e.toString()}');
        // print(e);
      }
    }

    if (issuesKeywords != '' && isIssueChecked) {
      cmdArgs.addAll(['-issues', issuesKeywords.trim().replaceAll(re, ',')]);
      try {
        if (issueStartDate != '' && issueEndDate != '') {
          cmdArgs.addAll(['-istart', issueStartDate, '-iend', issueEndDate]);
        } else {
          throw 'Issues date range needed.';
        }

        if (issueLabels.isNotEmpty) {
          cmdArgs.addAll(['-ik', issueLabels.trim().replaceAll(re, ',')]);
        }

        if (issueState != 'all') {
          cmdArgs.addAll(['-is', issueState]);
        }
      } catch (e) {
        EasyLoading.showError('Error: ${e.toString()}');
        // print(e);
      }
    }
    // print(cmdArgs);
    return cmdArgs;
  }

  String getProviders(bool github, bool gitlab) {
    String providers = '';
    if (github && gitlab) {
      providers += 'github,gitlab';
    } else if (gitlab) {
      providers += 'gitlab';
    } else if (github) {
      providers += 'github';
    } else {
      providers = 'github,gitlab';
    }
    return providers;
  }

  List<String> getFiles([String folder = config.targetFolderResults]) {
    Directory dir = Directory(folder);
    List<String> files = [];
    List<FileSystemEntity> dirs = dir.listSync();

    for (int i = 0; i < dirs.length; i++) {
      String dir = dirs[i].toString();
      files.add(dir.substring(0, dir.length - 1).split('\\').last);
    }
    return files;
  }

  String? renameFolder(WidgetRef ref, String oldName, String newName) {
    // RegExp: max 20 alphanumeric characters, spaces and dashes allowed
    var reg = RegExp(r'^(?!\/s*$)[a-zA-Z0-9- ]{1,30}$');
    if (reg.hasMatch(newName)) {
      String regexNewName = '';
      regexNewName = newName.trim().replaceAll('-', '#-').replaceAll(' ', '-');
      String targetFolderResultsPath = config.targetFolderResults;
      String date = getFolderName(oldName, date: 'raw');
      String oldNameNoDate = getFolderName(oldName);
      if (oldNameNoDate == newName || newName == '') return null;
      try {
        String fullNewName = '$date#$regexNewName';
        if (ref.read(isSearchFinishedProvider(oldName))) {
          Directory('${config.settings['completedFolder']}/$oldName').renameSync('${config.settings['completedFolder']}/$fullNewName');
        }
        Directory('$targetFolderResultsPath/$oldName').renameSync('$targetFolderResultsPath/$fullNewName');
        return fullNewName;
      } catch (e) {
        // print(e);
        EasyLoading.showError('Error renaming folder.');
      }
    } else {
      throw 'Only 30 alphanumeric characters, spaces and dashes allowed.';
    }
    return null;
  }

  void copyCompletedFolder(String folder) {
    String fromPath = '${config.targetFolderResults}/$folder';
    String toPath = '${config.settings['completedFolder']}/$folder';
    copyPathSync(fromPath, toPath);
  }

  void createSearchFolder() {
    DateTime now = DateTime.now();
    var iso8601 = DateFormat('yyyyMMddTHHmmss.SS');
    String formattedDate = iso8601.format(now);
    String filename = '$formattedDate#New-search';

    Directory('${config.targetFolderResults}/$filename').createSync(recursive: true);
    EasyLoading.showSuccess('New search folder created', duration: const Duration(milliseconds: 200));
  }

  void deleteSearchFolder(String folder) {
    if (isSearchFinished(folder)) {
      Directory('${config.settings['completedFolder']}/$folder').deleteSync(recursive: true);
    }
    Directory('${config.targetFolderResults}/$folder').deleteSync(recursive: true);
  }

  String getCsvBookmarkPath(String type) {
    late String csv;
    late String path;
    switch (type) {
      case 'repositories':
      case 'repositories_bookmarks':
        csv = 'GitRepositoryBookmarks.csv';
        path = config.targetBookmarks;
        break;
      case 'commits':
      case 'commits_bookmarks':
        csv = 'GitCommitBookmarks.csv';
        path = config.targetBookmarks;
        break;
      case 'issues':
      case 'issues_bookmarks':
        csv = 'GitIssueBookmarks.csv';
        path = config.targetBookmarks;
        break;
      default:
        throw 'Invalid type';
    }
    return '$path/$csv';
  }

  String getCsvPath(String type, String folder) {
    late String csv;
    late String path;
    switch (type) {
      case 'repositories':
        csv = 'GitRepositoryInfo.csv';
        path = '${config.targetFolderResults}/$folder';
        break;
      case 'commits':
        csv = 'GitCommitInfo.csv';
        path = '${config.targetFolderResults}/$folder';
        break;
      case 'issues':
        csv = 'GitIssueInfo.csv';
        path = '${config.targetFolderResults}/$folder';
        break;
      default:
        throw 'Invalid type';
    }
    return '$path/$csv';
  }

  List<List<dynamic>> parseCSV(String folder, String type) {
    late String csvPath;
    // print('type: $type');
    if (folder == config.targetBookmarks) {
      csvPath = getCsvBookmarkPath(type);
    } else {
      csvPath = getCsvPath(type, folder);
    }

    try {
      final input = File(csvPath).readAsStringSync(encoding: const Latin1Codec());
      return const CsvToListConverter(eol: '\n').convert(input);
    } catch (e) {
      // print(e);
      return [];
    }
  }

  String getFolderName(String name, {String date = ''}) {
    if (date == 'formatted') {
      String date = DateTime.parse(name.substring(0, name.indexOf('#'))).toString();
      return date.substring(0, date.length - 4);
    } else if (date == 'raw') {
      return name.substring(0, name.indexOf('#'));
    }
    return name.substring(name.indexOf('#') + 1).replaceAll('#-', ':').replaceAll('-', ' ').replaceAll(':', '-');
  }

  void writeSearchToJson({
    required String folder,
    required String reposKeywords,
    required String startDate,
    required String endDate,
    String languages = '',
    int minStars = 0,
    bool github = true,
    bool gitlab = true,
    bool isCommitChecked = false,
    String commitsKeywords = '',
    String commitStartDate = '',
    String commitEndDate = '',
    bool commitFiles = false,
    bool commitStatus = false,
    bool isIssueChecked = false,
    String issuesKeywords = '',
    String issueStartDate = '',
    String issueEndDate = '',
    String issueLabels = '',
    String issueState = 'all',
  }) {
    Map<String, dynamic> search;
    File file = File('${config.targetFolderResults}/$folder/search.json');

    // providers
    String providers = getProviders(github, gitlab);

    search = {
      'keywords': reposKeywords,
      'startDate': startDate,
      'endDate': endDate,
      'languages': languages,
      'minStars': minStars.toString(),
      'providers': providers,
      'isCommitChecked': isCommitChecked,
      'commitsKeywords': commitsKeywords,
      'commitStartDate': commitStartDate,
      'commitEndDate': commitEndDate,
      'commitFiles': commitFiles,
      'commitStatus': commitStatus,
      'isIssueChecked': isIssueChecked,
      'issuesKeywords': issuesKeywords,
      'issueStartDate': issueStartDate,
      'issueEndDate': issueEndDate,
      'issueLabels': issueLabels.isNotEmpty ? issueLabels : '',
      'issueState': issueState,
    };

    file.writeAsStringSync(const JsonEncoder.withIndent("     ").convert(search));
  }

  Map<String, dynamic>? readSearchJson(String folder) {
    try {
      File file = File('${config.targetFolderResults}/$folder/search.json');
      String contents = file.readAsStringSync();
      Map<String, dynamic> search = json.decode(contents);
      return search;
    } catch (e) {
      // EasyLoading.showError('Error reading search.json', duration: const Duration(milliseconds: 200));
      // print(e);
    }
    return null;
  }

  void resetSearch(WidgetRef ref, String folder) {
    deleteSearchFolder(folder);
    ref.read(searchContentProvider(folder).notifier).updateIsCsvPresent();
    ref.read(searchContentProvider(folder).notifier).resetSearchContent(ref);
    Directory('${config.targetFolderResults}/$folder').createSync(recursive: true);
  }

  bool isSearchSame({
    required String folder,
    required String reposKeywords,
    required String startDate,
    required String endDate,
    String languages = '',
    int minStars = 0,
    bool github = true,
    bool gitlab = true,
    bool isCommitChecked = false,
    String commitsKeywords = '',
    String commitStartDate = '',
    String commitEndDate = '',
    bool commitFiles = false,
    bool commitStatus = false,
    bool isIssueChecked = false,
    String issuesKeywords = '',
    String issueStartDate = '',
    String issueEndDate = '',
    String issueLabels = '',
    String issueState = 'all',
  }) {
    Map<String, dynamic>? search = readSearchJson(folder);
    if (search != null &&
        search['keywords'] == reposKeywords &&
        search['startDate'] == startDate &&
        search['endDate'] == endDate &&
        search['languages'] == languages &&
        search['minStars'] == minStars.toString() &&
        search['providers'] == getProviders(github, gitlab) &&
        search['isCommitChecked'] == isCommitChecked &&
        search['commitsKeywords'] == commitsKeywords &&
        search['commitStartDate'] == commitStartDate &&
        search['commitEndDate'] == commitEndDate &&
        search['commitFiles'] == commitFiles &&
        search['commitStatus'] == commitStatus &&
        search['isIssueChecked'] == isIssueChecked &&
        search['issuesKeywords'] == issuesKeywords &&
        search['issueStartDate'] == issueStartDate &&
        search['issueEndDate'] == issueEndDate &&
        search['issueLabels'] == issueLabels &&
        search['issueState'] == issueState) {
      return true;
    }
    return false;
  }

  bool isSearchFinished(String folder) {
    bool result = false;
    try {
      late String logFile;
      var stream = Directory('${config.targetFolderResults}/$folder').listSync(recursive: true);
      for (var file in stream) {
        if (file is File && file.path.endsWith('.log')) logFile = file.uri.pathSegments.last;
      }
      String path = '${config.targetFolderResults}/$folder/$logFile';

      List lines = File(path).readAsLinesSync();
      if (lines[lines.length - 1].contains('GitFinder - Search finished!!!')) {
        if (!Directory('${config.settings['completedFolder']}/$folder').existsSync()) {
          copyCompletedFolder(folder);
        }
        result = true;
      }
    } catch (e) {
      return false;
      // print(e);
    }
    return result;
  }

  bool isCsvPresent(String folder, String type) {
    String csvPath = getCsvPath(type, folder);
    try {
      return File(csvPath).existsSync();
    } catch (e) {
      return false;
      // print(e);
    }
  }

  void saveRows(List<PlutoRow> rows, String type, List<String> columns, [List<List> csv = const []]) {
    if (csv.isEmpty) csv = parseCSV(config.targetBookmarks, type);
    String csvPath = getCsvBookmarkPath(type);
    List<String> bookmarksColumns = getBookmarksColumns(type);
    if (csv.isEmpty) {
      csv.add(columns);
      bookmarksColumns = columns;
    }
    if (columns.length > bookmarksColumns.length && csv.length != 1) {
      csv[0] = columns;
      for (int i = 1; i < csv.length; i++) {
        List<String> rowList = List.filled(columns.length, '', growable: true);
        for (int j = 0; j < columns.length; j++) {
          if (bookmarksColumns.contains(columns[j])) {
            rowList[j] = csv[i][bookmarksColumns.indexOf(columns[j])].toString();
          } else {
            rowList[j] = '';
          }
        }
        csv[i] = rowList;
      }
      bookmarksColumns = columns;
    }

    for (int i = 0; i < rows.length; i++) {
      if (isRowSaved(rows[i], type, columns, csv)) {
        rows[i].setChecked(true);
        if (rows.length == 1) {
          EasyLoading.showError('Row already saved', duration: const Duration(milliseconds: 200));
          return;
        }
      } else {
        csv.add(convertPlutoRowtoList(rows[i], type, columns));
      }
    }

    String csvString = const ListToCsvConverter(eol: '\n').convert(csv);
    File(csvPath).writeAsStringSync('$csvString\n', encoding: const Latin1Codec());
    EasyLoading.showSuccess('Row saved', duration: const Duration(milliseconds: 200));
  }

  void deleteRows(List<PlutoRow> rows, String type, List<String> columns, [List<List> csv = const []]) {
    if (csv.isEmpty) csv = parseCSV(config.targetBookmarks, type);
    String csvPath = getCsvBookmarkPath(type);
    final input = const CsvToListConverter(eol: '\n').convert(File(csvPath).readAsStringSync(encoding: const Latin1Codec()));

    for (int i = 0; i < rows.length; i++) {
      if (isRowSaved(rows[i], type, columns, csv)) {
        int idIndex = csv[0].indexOf('Id');

        try {
          List<String> rowList = convertPlutoRowtoList(rows[i], type, columns);
          for (int i = 1; i < input.length; i++) {
            String inputId = input[i][idIndex].toString();
            String rowId = rowList[idIndex].toString();
            if (inputId == rowId) {
              input.removeAt(i);
            }
          }
        } catch (e) {
          EasyLoading.showError('Row not deleted', duration: const Duration(milliseconds: 200));
          // print(e);
        }
      } else {
        if (rows.length == 1) {
          EasyLoading.showError('Row not saved', duration: const Duration(milliseconds: 200));
          return;
        }
      }
    }
    String inputString = const ListToCsvConverter(eol: '\n').convert(input);
    File(csvPath).writeAsStringSync('$inputString\n');
    EasyLoading.showSuccess('Row deleted', duration: const Duration(milliseconds: 200));
  }

  List<String> getBookmarksColumns(String type) {
    late List<String> columns;
    List<List> csv = parseCSV(config.targetBookmarks, type);
    if (csv.isEmpty) {
      return [];
    } else {
      columns = csv[0].map((e) => e.toString()).toList();
      return columns;
    }
  }

  List<String> convertPlutoRowtoList(PlutoRow row, String type, List<String> columns) {
    List<String> bookmarksColumns = getBookmarksColumns(type);
    if (columns.length > bookmarksColumns.length) {
      bookmarksColumns = columns;
    }

    List<String> rowList = List.filled(bookmarksColumns.length, '', growable: true);
    for (int i = 0; i < bookmarksColumns.length; i++) {
      var rowCell = row.cells[bookmarksColumns[i]];
      if (rowCell != null) {
        rowList[i] = rowCell.value.toString();
      }
    }
    return rowList;
  }

  bool isRowSaved(PlutoRow row, String type, List<String> columns, [List<List> csv = const []]) {
    try {
      if (csv.isEmpty) csv = parseCSV(config.targetBookmarks, type);
      int idIndex = csv[0].indexOf('Id');
      List<String> rowList = convertPlutoRowtoList(row, type, columns);
      for (int i = 1; i < csv.length; i++) {
        String bookmarkId = csv[i][idIndex].toString();
        String rowId = rowList[idIndex].toString();
        if (bookmarkId == rowId) {
          return true;
        }
      }
    } catch (e) {
      // print(e);
      return false;
    }
    return false;
  }

  void updateNeedRefreshing(WidgetRef ref, bool value, [String folder = '', bool all = false]) {
    if (folder.isNotEmpty) {
      ref.read(needRefreshing(folder).notifier).state = value;
    } else if (all) {
      // reset all needRefreshing providers to false because changing the theme will refresh the search content
      List<String> folders = ref.read(searchFoldersProvider);
      for (int i = 0; i < folders.length; i++) {
        ref.read(needRefreshing(folders[i]).notifier).state = value;
      }
    }
  }
}
