import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitfinder/pages/search/search_page_viewmodel.dart';

final searchContentProvider = ChangeNotifierProvider.family<SearchContentNotifier, String>((ref, folder) {
  return SearchContentNotifier(folder);
});

class SearchContentNotifier extends ChangeNotifier {
  SearchContentNotifier(this.folder) {
    repositories = searchPageController.parseCSV(folder, 'repositories');
    commits = searchPageController.parseCSV(folder, 'commits');
    issues = searchPageController.parseCSV(folder, 'issues');
    isRepositoriesCsvPresent = searchPageController.isCsvPresent(folder, 'repositories');
    isCommitsCsvPresent = searchPageController.isCsvPresent(folder, 'commits');
    isIssuesCsvPresent = searchPageController.isCsvPresent(folder, 'issues');
    searchTabs = searchPageController.getSearchTabs(folder);
    searchViews = searchPageController.getSearchViews(folder);
  }
  final String folder;

  final SearchPageViewModel searchPageController = SearchPageViewModel();
  late List<List<dynamic>> repositories;
  late List<List<dynamic>> commits;
  late List<List<dynamic>> issues;
  late bool isRepositoriesCsvPresent;
  late bool isCommitsCsvPresent;
  late bool isIssuesCsvPresent;
  late List<String> searchTabs;
  late List<Widget> searchViews;

  void updateSearchContent([String type = '', bool force = false]) {
    late List<List<dynamic>> repos;
    late List<List<dynamic>> cmts;
    late List<List<dynamic>> iss;
    switch (type) {
      case 'repositories':
        repos = searchPageController.parseCSV(folder, 'repositories');
        if (force) {
          repositories = repos;
          notifyListeners();
        } else if (repositories.length != repos.length) {
          repositories = repos;
          notifyListeners();
        }
        break;
      case 'commits':
        cmts = searchPageController.parseCSV(folder, 'commits');
        if (force) {
          commits = cmts;
          notifyListeners();
        } else if (commits.length != cmts.length) {
          commits = cmts;
          notifyListeners();
        }
        break;
      case 'issues':
        iss = searchPageController.parseCSV(folder, 'issues');
        if (force) {
          issues = iss;
          notifyListeners();
        } else if (issues.length != iss.length) {
          issues = iss;
          notifyListeners();
        }
        break;
      default:
        repos = searchPageController.parseCSV(folder, 'repositories');
        cmts = searchPageController.parseCSV(folder, 'commits');
        iss = searchPageController.parseCSV(folder, 'issues');
        if (repositories.length != repos.length || commits.length != cmts.length || issues.length != iss.length) {
          repositories = repos;
          commits = cmts;
          issues = iss;
          notifyListeners();
        }
    }
  }

  void updateIsCsvPresent([String type = '']) {
    late bool reposPresent;
    late bool commitsPresent;
    late bool issuesPresent;
    switch (type) {
      case 'repositories':
        reposPresent = searchPageController.isCsvPresent(folder, 'repositories');
        if (isRepositoriesCsvPresent != reposPresent) {
          isRepositoriesCsvPresent = reposPresent;
          notifyListeners();
        }
        break;
      case 'commits':
        commitsPresent = searchPageController.isCsvPresent(folder, 'commits');
        if (isCommitsCsvPresent != commitsPresent) {
          isCommitsCsvPresent = commitsPresent;
          notifyListeners();
        }
        break;
      case 'issues':
        issuesPresent = searchPageController.isCsvPresent(folder, 'issues');
        if (isIssuesCsvPresent != issuesPresent) {
          isIssuesCsvPresent = issuesPresent;
          notifyListeners();
        }
        break;
      default:
        reposPresent = searchPageController.isCsvPresent(folder, 'repositories');
        commitsPresent = searchPageController.isCsvPresent(folder, 'commits');
        issuesPresent = searchPageController.isCsvPresent(folder, 'issues');
        if (isRepositoriesCsvPresent != reposPresent || isCommitsCsvPresent != commitsPresent || isIssuesCsvPresent != issuesPresent) {
          isRepositoriesCsvPresent = reposPresent;
          isCommitsCsvPresent = commitsPresent;
          isIssuesCsvPresent = issuesPresent;
          notifyListeners();
        }
    }
  }

  void updateSearchPage() {
    List<String> st = searchPageController.getSearchTabs(folder);
    List<Widget> sv = searchPageController.getSearchViews(folder);
    if (st.length != searchTabs.length || sv.length != searchViews.length) {
      searchTabs = st;
      searchViews = sv;
      notifyListeners();
    }
  }

  void resetSearchContent(WidgetRef ref) {
    repositories = searchPageController.parseCSV(folder, 'repositories');
    commits = searchPageController.parseCSV(folder, 'commits');
    issues = searchPageController.parseCSV(folder, 'issues');
    searchTabs = searchPageController.getSearchTabs(folder);
    searchViews = searchPageController.getSearchViews(folder);
    notifyListeners();
  }

  void updateGridData(WidgetRef ref, String folder, [String type = '']) {
    updateIsCsvPresent(type);
    updateSearchContent(type);
    notifyListeners();
  }
}
