import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gitfinder/pages/search/search_content.dart';
import 'package:gitfinder/pages/search/search_content_provider.dart';
import 'package:gitfinder/pages/search/search_page_viewmodel.dart';
import 'package:gitfinder/pages/settings/theme_provider.dart';
import 'package:icons_plus/icons_plus.dart';
import 'dart:io';
import 'dart:core';
import 'package:gitfinder/config.dart' as config;

final isSearchStartedProvider = StateProvider.family<bool, String>((ref, folder) => false);
final isSearchFinishedProvider = StateProvider.family<bool, String>((ref, folder) => SearchPageViewModel().isSearchFinished(folder));
final isIssueCheckedProvider = StateProvider.family<bool, String>((ref, folder) => false);
final isCommitCheckedProvider = StateProvider.family<bool, String>((ref, folder) => false);

enum IssueState { all, open, closed }

class SearchFilters extends ConsumerStatefulWidget {
  const SearchFilters(this.folder, this.wRef, {Key? key}) : super(key: key);

  final String folder;
  final WidgetRef wRef;

  @override
  ConsumerState<SearchFilters> createState() => _SearchFiltersState();
}

class _SearchFiltersState extends ConsumerState<SearchFilters> {
  final searchNameController = TextEditingController();
  final reposKeywordsController = TextEditingController();
  final reposStartDateController = TextEditingController();
  final reposEndDateController = TextEditingController();
  final languagesController = TextEditingController();
  final minStarsController = TextEditingController();

  final commitsKeywordsController = TextEditingController();
  final commitsStartDateController = TextEditingController();
  final commitsEndDateController = TextEditingController();

  final issuesKeywordsController = TextEditingController();
  final issuesStartDateController = TextEditingController();
  final issuesEndDateController = TextEditingController();
  final issuesLabelsController = TextEditingController();

  bool isGithubChecked = true;
  bool isGitLabChecked = true;
  bool isIssueChecked = false;
  IssueState issueState = IssueState.all;
  bool isCommitChecked = false;
  bool commitFiles = false;
  bool commitStatus = false;

  bool searchNameEdit = false;
  late List<String> folders;
  late String currentFolder;
  late bool searchExists;
  late Map<String, dynamic>? initFields;
  late ThemeNotifier theme;
  late String folderName;

  @override
  void initState() {
    super.initState();
    currentFolder = widget.folder;
    initFields = ref.read(searchVMProvider).readSearchJson(currentFolder);
    searchExists = File('${config.targetFolderResults}/$currentFolder/search.json').existsSync();

    if (initFields != null && searchExists) {
      initializeFields(initFields!);
    } else {
      reposKeywordsController.text = '';
      reposStartDateController.text = '';
      reposEndDateController.text = '';
      languagesController.text = '';
      minStarsController.text = '0';
      isGithubChecked = true;
      isGitLabChecked = true;
      isCommitChecked = false;
      commitsKeywordsController.text = '';
      commitsStartDateController.text = '';
      commitsEndDateController.text = '';
      isIssueChecked = false;
      issuesKeywordsController.text = '';
      issuesStartDateController.text = '';
      issuesEndDateController.text = '';
      issuesLabelsController.text = '';
      issueState = IssueState.all;
    }
  }

  @override
  void dispose() {
    reposKeywordsController.dispose();
    reposStartDateController.dispose();
    reposEndDateController.dispose();
    languagesController.dispose();
    minStarsController.dispose();

    commitsKeywordsController.dispose();
    commitsStartDateController.dispose();
    commitsEndDateController.dispose();

    issuesKeywordsController.dispose();
    issuesStartDateController.dispose();
    issuesEndDateController.dispose();
    issuesLabelsController.dispose();
    super.dispose();
  }

  void initializeFields(Map<String, dynamic> initFields) {
    reposKeywordsController.text = initFields['keywords'];
    reposStartDateController.text = initFields['startDate'];
    reposEndDateController.text = initFields['endDate'];
    languagesController.text = initFields['languages'];
    minStarsController.text = initFields['minStars'];
    if (initFields['providers'].contains('github')) {
      isGithubChecked = true;
    } else {
      isGithubChecked = false;
    }
    if (initFields['providers'].contains('gitlab')) {
      isGitLabChecked = true;
    } else {
      isGitLabChecked = false;
    }
    if (initFields['isCommitChecked']) {
      isCommitChecked = true;
    } else {
      isCommitChecked = false;
    }
    commitsKeywordsController.text = initFields['commitsKeywords'];
    commitsStartDateController.text = initFields['commitStartDate'];
    commitsEndDateController.text = initFields['commitEndDate'];
    if (initFields['commitFiles']) {
      commitFiles = true;
    } else {
      commitFiles = false;
    }
    if (initFields['commitStatus']) {
      commitStatus = true;
    } else {
      commitStatus = false;
    }
    if (initFields['isIssueChecked']) {
      isIssueChecked = true;
    } else {
      isIssueChecked = false;
    }
    issuesKeywordsController.text = initFields['issuesKeywords'];
    issuesStartDateController.text = initFields['issueStartDate'];
    issuesEndDateController.text = initFields['issueEndDate'];
    issuesLabelsController.text = initFields['issueLabels'];
    if (initFields['issueState'] == 'all') {
      issueState = IssueState.all;
    } else if (initFields['issueState'] == 'open') {
      issueState = IssueState.open;
    } else if (initFields['issueState'] == 'closed') {
      issueState = IssueState.closed;
    }
  }

  // Date picker function
  Future<void> _selectDate(BuildContext context, TextEditingController controller, [String oldSelectedDate = '']) async {
    late DateTime selectedStartDate;
    try {
      if (oldSelectedDate != '') {
        selectedStartDate = DateTime.parse(oldSelectedDate);
      } else {
        selectedStartDate = DateTime.now();
      }
    } catch (e) {
      selectedStartDate = DateTime.now();
    }
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate,
      firstDate: DateTime(2007, 10),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: theme.scaffoldBackgroundColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: theme.scaffoldBackgroundColor,
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(
                color: Colors.black,
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedStartDate) {
      setState(() {
        controller.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  void _renameFolder() {
    try {
      String? folder = ref.read(searchVMProvider).renameFolder(ref, currentFolder, searchNameController.text);
      if (folder != null) {
        setState(() {
          currentFolder = folder;
          ref.invalidate(searchFoldersProvider);
          searchNameEdit = false;
        });
      } else {
        setState(() {
          searchNameEdit = false;
        });
      }
    } catch (e) {
      setState(() {
        searchNameEdit = false;
        searchNameController.text = folderName;
      });
      EasyLoading.showError('Error renaming folder: ${e.toString()}');
    }
  }

  bool isRefreshing = false;
  @override
  Widget build(BuildContext context) {
    theme = ref.watch(themeProvider);

    folders = ref.watch(searchFoldersProvider);
    // initFields = ref.read(searchControllerProvider).readSearchJson(currentFolder);
    // searchExists = File('${config.targetFolderResults}/$currentFolder/search.json').existsSync();

    // if (initFields != null && searchExists) {
    //   initializeFields(initFields!);
    // }

    folderName = ref.read(searchVMProvider).getFolderName(currentFolder);
    searchNameController.text = folderName;
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: theme.canvasColor,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20.0), topLeft: Radius.circular(20.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 30.0),
        child: Column(
          children: [
            SizedBox(
              height: 25,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Text(
                    'Search',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              isRefreshing = true;
                              initFields ??= ref.read(searchVMProvider).readSearchJson(currentFolder);
                              if (initFields != null) initializeFields(initFields!);
                              Future.delayed(const Duration(milliseconds: 400), () {
                                setState(() {
                                  isRefreshing = false;
                                });
                              });
                            });
                          },
                          icon: isRefreshing
                              ? const SpinKitRing(
                                  lineWidth: 3,
                                  size: 20,
                                  color: Colors.white,
                                )
                              : const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 25,
                                )),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),
            searchNameEdit
                ? TextField(
                    textAlign: TextAlign.center,
                    minLines: 1,
                    maxLines: 1,
                    controller: searchNameController,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      border: OutlineInputBorder(),
                      labelText: 'Search name',
                      labelStyle: TextStyle(
                        color: Colors.white30,
                      ),
                    ),
                    onSubmitted: (value) {
                      _renameFolder();
                    },
                    onTapOutside: (value) {
                      _renameFolder();
                    },
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        folderName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            searchNameEdit = true;
                          });
                        },
                        icon: const Icon(
                          HeroIcons.pencil_square,
                          color: Colors.white,
                          size: 18.0,
                        ),
                      )
                    ],
                  ),
            const SizedBox(height: 15),
            !ref.watch(isSearchStartedProvider(currentFolder))
                ? SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ref.watch(isSearchFinishedProvider(currentFolder)) ? theme.primaryColor.withOpacity(0.7) : theme.startColor,
                        // splashFactory: NoSplash.splashFactory,
                      ),
                      onPressed: () async {
                        if (int.tryParse(minStarsController.text) != null) {
                          RegExp re = RegExp(r"\s+,\s+");
                          reposKeywordsController.text = reposKeywordsController.text.trim().replaceAll(re, ',');
                          reposStartDateController.text = reposStartDateController.text.trim();
                          reposEndDateController.text = reposEndDateController.text.trim();
                          languagesController.text = languagesController.text.trim().replaceAll(re, ',');
                          commitsKeywordsController.text = commitsKeywordsController.text.trim().replaceAll(re, ',');
                          commitsStartDateController.text = commitsStartDateController.text.trim();
                          commitsEndDateController.text = commitsEndDateController.text.trim();
                          issuesKeywordsController.text = issuesKeywordsController.text.trim().replaceAll(re, ',');
                          issuesStartDateController.text = issuesStartDateController.text.trim();
                          issuesEndDateController.text = issuesEndDateController.text.trim();
                          issuesLabelsController.text = issuesLabelsController.text.trim().replaceAll(re, ',');

                          bool isSearchSame = ref.read(searchVMProvider).isSearchSame(
                                folder: currentFolder,
                                reposKeywords: reposKeywordsController.text,
                                startDate: reposStartDateController.text,
                                endDate: reposEndDateController.text,
                                languages: languagesController.text,
                                minStars: minStarsController.text == '' ? 0 : int.parse(minStarsController.text),
                                github: isGithubChecked,
                                gitlab: isGitLabChecked,
                                isCommitChecked: isCommitChecked,
                                commitsKeywords: commitsKeywordsController.text,
                                commitStartDate: commitsStartDateController.text,
                                commitEndDate: commitsEndDateController.text,
                                commitFiles: commitFiles,
                                commitStatus: commitStatus,
                                isIssueChecked: isIssueChecked,
                                issuesKeywords: issuesKeywordsController.text,
                                issueStartDate: issuesStartDateController.text,
                                issueEndDate: issuesEndDateController.text,
                                issueLabels: issuesLabelsController.text,
                                issueState: issueState.name,
                              );
                          try {
                            List<String>? cmd = ref.read(searchVMProvider).generateCommand(
                                  folder: currentFolder,
                                  reposKeywords: reposKeywordsController.text,
                                  startDate: reposStartDateController.text,
                                  endDate: reposEndDateController.text,
                                  languages: languagesController.text,
                                  minStars: minStarsController.text == '' ? 0 : int.parse(minStarsController.text),
                                  github: isGithubChecked,
                                  gitlab: isGitLabChecked,
                                  isCommitChecked: isCommitChecked,
                                  commitsKeywords: commitsKeywordsController.text,
                                  commitStartDate: commitsStartDateController.text,
                                  commitEndDate: commitsEndDateController.text,
                                  commitFiles: commitFiles,
                                  commitStatus: commitStatus,
                                  isIssueChecked: isIssueChecked,
                                  issuesKeywords: issuesKeywordsController.text,
                                  issueStartDate: issuesStartDateController.text,
                                  issueEndDate: issuesEndDateController.text,
                                  issueLabels: issuesLabelsController.text,
                                  issueState: issueState.name,
                                );
                            // print(cmd);
                            // print('java ${cmd!.join(' ')}');
                            if (!isGitLabChecked && !isGithubChecked) {
                              setState(() {
                                isGitLabChecked = true;
                                isGithubChecked = true;
                              });
                            }
                            if (cmd == null) {
                              EasyLoading.showError('Please fill all required the fields');
                            } else {
                              ref.read(isSearchFinishedProvider(currentFolder).notifier).state =
                                  ref.read(searchVMProvider).isSearchFinished(currentFolder);
                              if (ref.read(isSearchFinishedProvider(currentFolder))) {
                                setState(() {
                                  initFields ??= ref.read(searchVMProvider).readSearchJson(currentFolder);
                                  initializeFields(initFields!);
                                  isSearchSame = true;
                                });
                                EasyLoading.showInfo('Search already finished!', duration: const Duration(milliseconds: 200));
                              } else if (searchExists && !isSearchSame) {
                                print('search exists and is not the same');
                                showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) => AlertDialog(
                                    title: const Text(
                                      'Search already exists',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    content: const Text(
                                      'Are you sure you want to overwrite the existing search? This action is irreversible.',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            initFields ??= ref.read(searchVMProvider).readSearchJson(currentFolder);
                                            initializeFields(initFields!);
                                            isSearchSame = true;
                                          });
                                          Navigator.pop(context, 'Cancel');
                                          return;
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          ref.read(searchVMProvider).resetSearch(ref, currentFolder);

                                          ref.read(searchVMProvider).writeSearchToJson(
                                                folder: currentFolder,
                                                reposKeywords: reposKeywordsController.text,
                                                startDate: reposStartDateController.text,
                                                endDate: reposEndDateController.text,
                                                languages: languagesController.text,
                                                minStars: minStarsController.text == '' ? 0 : int.parse(minStarsController.text),
                                                github: isGithubChecked,
                                                gitlab: isGitLabChecked,
                                                isCommitChecked: isCommitChecked,
                                                commitsKeywords: commitsKeywordsController.text,
                                                commitStartDate: commitsStartDateController.text,
                                                commitEndDate: commitsEndDateController.text,
                                                commitFiles: commitFiles,
                                                commitStatus: commitStatus,
                                                isIssueChecked: isIssueChecked,
                                                issuesKeywords: issuesKeywordsController.text,
                                                issueStartDate: issuesStartDateController.text,
                                                issueEndDate: issuesEndDateController.text,
                                                issueLabels: issuesLabelsController.text,
                                                issueState: issueState.name,
                                              );
                                          Navigator.pop(context, 'OK');
                                          ref.read(isCommitCheckedProvider(currentFolder).notifier).state = isCommitChecked;
                                          ref.read(isIssueCheckedProvider(currentFolder).notifier).state = isIssueChecked;
                                          if (ref.read(searchVMProvider).javaPathCorrect()) {
                                            setState(() => ref.read(isSearchStartedProvider(currentFolder).notifier).state = true);
                                            ref.read(searchContentProvider(currentFolder).notifier).resetSearchContent(ref);
                                            ref.read(searchVMProvider).startSearch(widget.wRef, currentFolder, cmd);
                                          }
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (!searchExists) {
                                print('search does not exist');
                                ref.read(searchVMProvider).writeSearchToJson(
                                      folder: currentFolder,
                                      reposKeywords: reposKeywordsController.text,
                                      startDate: reposStartDateController.text,
                                      endDate: reposEndDateController.text,
                                      languages: languagesController.text,
                                      minStars: minStarsController.text == '' ? 0 : int.parse(minStarsController.text),
                                      github: isGithubChecked,
                                      gitlab: isGitLabChecked,
                                      isCommitChecked: isCommitChecked,
                                      commitsKeywords: commitsKeywordsController.text,
                                      commitStartDate: commitsStartDateController.text,
                                      commitEndDate: commitsEndDateController.text,
                                      commitFiles: commitFiles,
                                      commitStatus: commitStatus,
                                      isIssueChecked: isIssueChecked,
                                      issuesKeywords: issuesKeywordsController.text,
                                      issueStartDate: issuesStartDateController.text,
                                      issueEndDate: issuesEndDateController.text,
                                      issueLabels: issuesLabelsController.text,
                                      issueState: issueState.name,
                                    );
                                ref.read(isCommitCheckedProvider(currentFolder).notifier).state = isCommitChecked;
                                ref.read(isIssueCheckedProvider(currentFolder).notifier).state = isIssueChecked;
                                if (ref.read(searchVMProvider).javaPathCorrect()) {
                                  setState(() {
                                    ref.watch(isSearchStartedProvider(currentFolder).notifier).state = true;
                                    searchExists = true;
                                  });
                                  await ref.read(searchVMProvider).startSearch(widget.wRef, currentFolder, cmd);
                                }
                              } else if (isSearchSame) {
                                print('search exists and is the same');
                                if (ref.read(searchVMProvider).javaPathCorrect()) {
                                  setState(() => ref.watch(isSearchStartedProvider(currentFolder).notifier).state = true);
                                  await ref.read(searchVMProvider).startSearch(widget.wRef, currentFolder, cmd);
                                }
                              }
                            }
                          } catch (e) {
                            EasyLoading.showError('Error: ${e.toString()}');
                          }
                        } else {
                          EasyLoading.showError('Min stars must be a number');
                        }
                      },
                      child: Text(
                        ref.watch(isSearchFinishedProvider(currentFolder)) ? 'Search finished' : 'Start',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.stopColor,
                        // splashFactory: NoSplash.splashFactory,
                      ),
                      onPressed: () {
                        try {
                          ref.read(searchVMProvider).killProcess(ref, currentFolder);
                          setState(() {
                            ref.read(isSearchStartedProvider(currentFolder).notifier).state = false;
                            ref.read(searchContentProvider(currentFolder).notifier).updateGridData(ref, currentFolder);
                            ref.read(needRefreshing(currentFolder).notifier).state = false;
                          });
                        } catch (e) {
                          EasyLoading.showError('Error stopping search: ${e.toString()}');
                          // print(e);
                        }
                      },
                      child: const Text(
                        'Stop',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
            const SizedBox(
              height: 15.0,
            ),
            if (ref.watch(needRefreshing(currentFolder)))
              Padding(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: (() {
                          ref.read(searchContentProvider(currentFolder).notifier).updateGridData(ref, currentFolder);
                          ref.read(needRefreshing(currentFolder).notifier).state = false;
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.activatedColor,
                          padding: const EdgeInsets.all(8.0),
                          textStyle: Theme.of(context).textTheme.bodyLarge,
                        ),
                        child: Text('Refresh possible', style: TextStyle(color: theme.canvasColor)),
                      ),
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'Repositories *',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(
                    height: 15.0,
                  ),
                  TextField(
                    minLines: 1,
                    maxLines: 10,
                    controller: reposKeywordsController,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      border: OutlineInputBorder(),
                      labelText: 'Repositories keywords',
                      labelStyle: TextStyle(
                        color: Colors.white30,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 15.0,
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 55,
                        child: Text('From *'),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: TextField(
                          controller: reposStartDateController,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            border: OutlineInputBorder(),
                            labelText: 'Start date',
                            labelStyle: TextStyle(
                              color: Colors.white30,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 20,
                        icon: const Icon(
                          HeroIcons.calendar,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _selectDate(context, reposStartDateController, reposStartDateController.text);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 15.0,
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 55,
                        child: Text('To *'),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: TextField(
                          controller: reposEndDateController,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            border: OutlineInputBorder(),
                            labelText: 'End date',
                            labelStyle: TextStyle(
                              color: Colors.white30,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 20,
                        icon: const Icon(
                          HeroIcons.calendar,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _selectDate(context, reposEndDateController, reposEndDateController.text);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 15.0,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: languagesController,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            border: OutlineInputBorder(),
                            labelText: 'Languages',
                            labelStyle: TextStyle(
                              color: Colors.white30,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 5.0,
                      ),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: minStarsController,
                          keyboardType: TextInputType.number,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: const InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            border: OutlineInputBorder(),
                            labelText: 'Min stars',
                            labelStyle: TextStyle(
                              color: Colors.white30,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 15.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Github'),
                          leading: Checkbox(
                            checkColor: Colors.white,
                            value: isGithubChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                isGithubChecked = value!;
                              });
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('Gitlab'),
                          leading: Checkbox(
                            checkColor: Colors.white,
                            value: isGitLabChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                isGitLabChecked = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  const Divider(),
                  const SizedBox(
                    height: 10.0,
                  ),
                  // COMMITS SECTION
                  Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            checkColor: Colors.white,
                            value: isCommitChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                isCommitChecked = value!;
                              });
                            },
                          ),
                          const Text('Commits'),
                        ],
                      ),
                      if (isCommitChecked)
                        Column(
                          children: [
                            const SizedBox(height: 15.0),
                            TextField(
                              minLines: 1,
                              maxLines: 10,
                              controller: commitsKeywordsController,
                              style: Theme.of(context).textTheme.bodyMedium,
                              decoration: const InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                border: OutlineInputBorder(),
                                labelText: 'Commits keywords *',
                                labelStyle: TextStyle(
                                  color: Colors.white30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15.0),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 55,
                                  child: Text('From *'),
                                ),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: commitsStartDateController,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    decoration: const InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white),
                                      ),
                                      border: OutlineInputBorder(),
                                      labelText: 'Start date',
                                      labelStyle: TextStyle(
                                        color: Colors.white30,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  iconSize: 20,
                                  icon: const Icon(
                                    HeroIcons.calendar,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _selectDate(context, commitsStartDateController, commitsStartDateController.text);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 15.0),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 55,
                                  child: Text('To *'),
                                ),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: commitsEndDateController,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    decoration: const InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white),
                                      ),
                                      border: OutlineInputBorder(),
                                      labelText: 'End date',
                                      labelStyle: TextStyle(
                                        color: Colors.white30,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  iconSize: 20,
                                  icon: const Icon(
                                    HeroIcons.calendar,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _selectDate(context, commitsEndDateController, commitsEndDateController.text);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 15.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      checkColor: Colors.white,
                                      value: commitFiles,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          commitFiles = value!;
                                        });
                                      },
                                    ),
                                    const Text('Files'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                      checkColor: Colors.white,
                                      value: commitStatus,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          commitStatus = value!;
                                        });
                                      },
                                    ),
                                    const Text('Status'),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  const Divider(),
                  const SizedBox(
                    height: 10.0,
                  ),
                  // ISSUES SECTION
                  Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            checkColor: Colors.white,
                            value: isIssueChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                isIssueChecked = value!;
                              });
                            },
                          ),
                          const Text('Issues'),
                        ],
                      ),
                      if (isIssueChecked)
                        Column(
                          children: [
                            const SizedBox(height: 15.0),
                            TextField(
                              minLines: 1,
                              maxLines: 10,
                              controller: issuesKeywordsController,
                              style: Theme.of(context).textTheme.bodyMedium,
                              decoration: const InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                border: OutlineInputBorder(),
                                labelText: 'Issues keywords *',
                                labelStyle: TextStyle(
                                  color: Colors.white30,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 15.0,
                            ),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 55,
                                  child: Text('From *'),
                                ),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: issuesStartDateController,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    decoration: const InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white),
                                      ),
                                      border: OutlineInputBorder(),
                                      labelText: 'Start date',
                                      labelStyle: TextStyle(
                                        color: Colors.white30,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  iconSize: 20,
                                  icon: const Icon(
                                    HeroIcons.calendar,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _selectDate(context, issuesStartDateController, issuesStartDateController.text);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 15.0),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 55,
                                  child: Text('To *'),
                                ),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: issuesEndDateController,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    decoration: const InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white),
                                      ),
                                      border: OutlineInputBorder(),
                                      labelText: 'End date',
                                      labelStyle: TextStyle(
                                        color: Colors.white30,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  iconSize: 20,
                                  icon: const Icon(
                                    HeroIcons.calendar,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _selectDate(context, issuesEndDateController, issuesEndDateController.text);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 15.0),
                            TextField(
                              minLines: 1,
                              maxLines: 10,
                              controller: issuesLabelsController,
                              style: Theme.of(context).textTheme.bodyMedium,
                              decoration: const InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                border: OutlineInputBorder(),
                                labelText: 'Issue labels',
                                labelStyle: TextStyle(
                                  color: Colors.white30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('Issue state'),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: ListTile(
                                        title: const Text('All'),
                                        leading: Radio<IssueState>(
                                          value: IssueState.all,
                                          groupValue: issueState,
                                          onChanged: (IssueState? value) {
                                            setState(() {
                                              issueState = value!;
                                            });
                                          },
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    Expanded(
                                      child: ListTile(
                                        title: const Text('Open'),
                                        leading: Radio<IssueState>(
                                          value: IssueState.open,
                                          groupValue: issueState,
                                          onChanged: (IssueState? value) {
                                            setState(() {
                                              issueState = value!;
                                            });
                                          },
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    Expanded(
                                      child: ListTile(
                                        title: const Text('Closed'),
                                        leading: Radio<IssueState>(
                                          value: IssueState.closed,
                                          groupValue: issueState,
                                          onChanged: (IssueState? value) {
                                            setState(() {
                                              issueState = value!;
                                            });
                                          },
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
