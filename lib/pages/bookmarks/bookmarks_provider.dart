import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitfinder/pages/search/search_content.dart';
import 'package:gitfinder/pages/search/search_content_provider.dart';
import 'package:gitfinder/pages/search/search_page_viewmodel.dart';
import 'package:gitfinder/config.dart' as config;
import 'package:pluto_grid/pluto_grid.dart';

final bookmarksProvider = ChangeNotifierProvider<BookmarksNotifier>((ref) {
  return BookmarksNotifier();
});

class BookmarksNotifier extends ChangeNotifier {
  final SearchPageViewModel searchPageController = SearchPageViewModel();
  var reposBookmarks = SearchPageViewModel().parseCSV(config.targetBookmarks, 'repositories_bookmarks');
  var commitsBookmarks = SearchPageViewModel().parseCSV(config.targetBookmarks, 'commits_bookmarks');
  var issuesBookmarks = SearchPageViewModel().parseCSV(config.targetBookmarks, 'issues_bookmarks');

  void updateBookmarks(String type) {
    switch (type) {
      case 'repositories':
      case 'repositories_bookmarks':
        reposBookmarks = searchPageController.parseCSV(config.targetBookmarks, 'repositories_bookmarks');
        break;
      case 'commits':
      case 'commits_bookmarks':
        commitsBookmarks = searchPageController.parseCSV(config.targetBookmarks, 'commits_bookmarks');
        break;
      case 'issues':
      case 'issues_bookmarks':
        issuesBookmarks = searchPageController.parseCSV(config.targetBookmarks, 'issues_bookmarks');
        break;
      default:
        throw 'Invalid type';
    }
    notifyListeners();
  }

  void updateGrids(WidgetRef ref, String type, [bool isCsv = false]) {
    List<String> folders = ref.read(searchFoldersProvider);
    for (int i = 0; i < folders.length; i++) {
      if (isCsv) ref.read(searchContentProvider(folders[i]).notifier).updateIsCsvPresent(type);
      ref
          .read(searchContentProvider(folders[i]).notifier)
          .updateSearchContent(type.contains('_') ? type.substring(0, type.indexOf('_')) : type, true);
      ref.read(needRefreshing(folders[i]).notifier).state = false;
    }
  }

  void saveRows(WidgetRef ref, List<PlutoRow> rows, String type, List<String> columns, bool isBookmarks) {
    searchPageController.saveRows(rows, type, columns);
    updateBookmarks(type);
    if (isBookmarks) updateGrids(ref, type);
    notifyListeners();
  }

  void deleteRows(WidgetRef ref, List<PlutoRow> rows, String type, List<String> columns, bool isBookmarks) {
    searchPageController.deleteRows(rows, type, columns);
    updateBookmarks(type);
    if (isBookmarks) updateGrids(ref, type);
    notifyListeners();
  }
}
