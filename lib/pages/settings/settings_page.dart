import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitfinder/pages/search/search_page_viewmodel.dart';
import 'package:gitfinder/pages/settings/settings_page_viewmodel.dart';
import 'package:gitfinder/pages/settings/theme_provider.dart';
import 'package:gitfinder/widgets/custom_switch.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:gitfinder/config.dart' as config;

final settingsIndexProvider = StateProvider((ref) => 0);
final gridDarkThemeProvider = StateProvider<bool>((ref) => config.settings['general']['gridDarkTheme']);

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late List<String> _githubTokens;
  late List<String> _gitlabTokens;
  List<TextEditingController> _githubControllers = [];
  List<TextField> _githubFields = [];
  Map<TextEditingController, IconButton> _githubDeleteButtons = {};
  List<TextEditingController> _gitlabControllers = [];
  List<TextField> _gitlabFields = [];
  Map<TextEditingController, IconButton> _gitlabDeleteButtons = {};

  bool isRefreshing = false;
  String? selectedDirectory = readSettingsFile()['completedFolder'];
  final ScrollController _githubScrollController = ScrollController();
  final ScrollController _gitlabScrollController = ScrollController();

  bool automaticRefresh = config.settings['general']['autoRefresh'];
  bool gridDarkTheme = config.settings['general']['gridDarkTheme'];

  @override
  void initState() {
    super.initState();
    _githubTokens = getTokens(readTokensConfigFile('github'));
    _gitlabTokens = getTokens(readTokensConfigFile('gitlab'));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // init github tokens
    _githubTokens = getTokens(readTokensConfigFile('github'));
    _githubFields = [];
    _githubControllers = [];
    _githubDeleteButtons = {};
    _initTokens('github');
    // init gitlab tokens
    _gitlabFields = [];
    _gitlabControllers = [];
    _gitlabDeleteButtons = {};
    _gitlabTokens = getTokens(readTokensConfigFile('gitlab'));
    _initTokens('gitlab');
  }

  @override
  void dispose() {
    for (final controller in _githubControllers) {
      controller.dispose();
    }
    for (final controller in _gitlabControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initTokens(String provider) {
    List<TextEditingController> controllers = [];
    List<TextField> fields = [];
    List<String> tokens = [];
    Map<TextEditingController, IconButton> deleteButtons = {};

    switch (provider) {
      case 'github':
        controllers = _githubControllers;
        fields = _githubFields;
        _githubTokens = getTokens(readTokensConfigFile('github'));
        tokens = _githubTokens;
        deleteButtons = _githubDeleteButtons;
        break;
      case 'gitlab':
        controllers = _gitlabControllers;
        fields = _gitlabFields;
        _gitlabTokens = getTokens(readTokensConfigFile('gitlab'));
        tokens = _gitlabTokens;
        deleteButtons = _gitlabDeleteButtons;
        break;
      default:
        throw Exception('Invalid provider');
    }

    for (int i = 0; i < tokens.length; i++) {
      final controller = TextEditingController();
      final field = TextField(
        controller: controller,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          suffixIcon: IconButton(
            onPressed: controller.clear,
            icon: const Icon(
              HeroIcons.x_mark,
              color: Colors.white,
            ),
          ),
          border: const OutlineInputBorder(),
          labelText: '${provider[0].toUpperCase() + provider.substring(1)} token ${controllers.length + 1}',
          labelStyle: const TextStyle(
            color: Colors.white30,
          ),
        ),
      );
      final deleteButton = IconButton(
        onPressed: () => _removeTile(provider, field, controller),
        icon: const Icon(HeroIcons.trash),
        color: Colors.white,
      );
      deleteButtons[controller] = deleteButton;
      controller.text = tokens[i];
      controllers.add(controller);
      fields.add(field);
    }
  }

  void _reset([String provider = '']) {
    switch (provider) {
      case 'github':
        setState(() {
          _githubControllers = [];
          _githubFields = [];
          _githubDeleteButtons = {};
          _initTokens('github');
        });
        break;
      case 'gitlab':
        setState(() {
          _gitlabControllers = [];
          _gitlabFields = [];
          _gitlabDeleteButtons = {};
          _initTokens('gitlab');
        });
        break;
      case '':
        setState(() {
          _githubControllers = [];
          _githubFields = [];
          _gitlabControllers = [];
          _gitlabFields = [];
          _githubDeleteButtons = {};
          didChangeDependencies();
        });
        break;
      default:
        throw Exception('Invalid provider');
    }
  }

  Widget _addTile(String provider) {
    List<TextEditingController> controllers = [];
    List<TextField> fields = [];
    Map<TextEditingController, IconButton> deleteButtons = {};

    switch (provider) {
      case 'github':
        controllers = _githubControllers;
        fields = _githubFields;
        deleteButtons = _githubDeleteButtons;
        break;
      case 'gitlab':
        controllers = _gitlabControllers;
        fields = _gitlabFields;
        deleteButtons = _gitlabDeleteButtons;
        break;
      default:
        throw Exception('Invalid provider');
    }
    var theme = ref.watch(themeProvider);
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: ListTile(
        hoverColor: theme.primaryColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          // side: const BorderSide(
          //   color: Colors.white,
          // ),
        ),
        title: const Icon(
          HeroIcons.plus,
          color: Colors.white,
        ),
        onTap: () {
          final controller = TextEditingController();
          final field = TextField(
            controller: controller,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              suffixIcon: IconButton(
                onPressed: controller.clear,
                icon: const Icon(
                  HeroIcons.x_mark,
                  color: Colors.white,
                ),
              ),
              border: const OutlineInputBorder(),
              labelText: '${provider[0].toUpperCase() + provider.substring(1)} token ${controllers.length + 1}',
              labelStyle: const TextStyle(
                color: Colors.white30,
              ),
            ),
          );
          final deleteButton = IconButton(
            onPressed: () => _removeTile(provider, field, controller),
            icon: const Icon(HeroIcons.trash),
            color: Colors.white,
          );
          setState(() {
            deleteButtons[controller] = deleteButton;
            controllers.add(controller);
            fields.add(field);
          });
        },
      ),
    );
  }

  void _removeTile(String provider, TextField field, TextEditingController controller) {
    setState(() {
      switch (provider) {
        case 'github':
          _githubControllers.remove(controller);
          _githubFields.remove(field);
          _githubDeleteButtons.remove(controller);
          break;
        case 'gitlab':
          _gitlabControllers.remove(controller);
          _gitlabFields.remove(field);
          _gitlabDeleteButtons.remove(controller);
          break;
        default:
          throw Exception('Invalid provider');
      }
    });
  }

  Widget _listView(String provider) {
    List<TextField> fields = [];
    late ScrollController scrollController;
    Map<TextEditingController, IconButton> deleteButtons = {};
    List<TextEditingController> controllers = [];

    switch (provider) {
      case 'github':
        fields = _githubFields;
        scrollController = _githubScrollController;
        deleteButtons = _githubDeleteButtons;
        controllers = _githubControllers;
        break;
      case 'gitlab':
        fields = _gitlabFields;
        scrollController = _gitlabScrollController;
        deleteButtons = _gitlabDeleteButtons;
        controllers = _gitlabControllers;
        break;
      default:
        throw Exception('Invalid provider');
    }

    return Scrollbar(
      thumbVisibility: true,
      thickness: 10,
      controller: scrollController,
      child: ListView.builder(
        shrinkWrap: true,
        controller: scrollController,
        itemCount: fields.length,
        itemBuilder: (context, index) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.all(5),
            child: ListTile(
              title: fields[index],
              trailing: deleteButtons[controllers[index]],
            ),
          );
        },
      ),
    );
  }

  Widget _saveButton(String provider) {
    late List<TextEditingController> controllers;
    List<String> newTokens = [];

    switch (provider) {
      case 'github':
        controllers = _githubControllers;
        break;
      case 'gitlab':
        controllers = _gitlabControllers;
        break;
      default:
        throw Exception('Invalid provider');
    }

    return ElevatedButton(
      onPressed: () async {
        controllers.where((element) => element.text != '').fold(null, (acc, element) => newTokens.add(element.text));
        try {
          switch (provider) {
            case 'github':
              _githubTokens = newTokens;
              break;
            case 'gitlab':
              _gitlabTokens = newTokens;
              break;
          }
          writeTokensConfigFile(provider, newTokens);
          setState(() {
            isRefreshing = true;
            _reset(provider);
            isRefreshing = false;
          });
          EasyLoading.showSuccess('Tokens saved', duration: const Duration(milliseconds: 500));
        } catch (e) {
          EasyLoading.showError('Error saving tokens');
        }
        setState(() {});
      },
      child: const Text('SAVE'),
    );
  }

  Widget _resetButton(String provider) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          isRefreshing = true;
          _reset(provider);
          EasyLoading.showSuccess('Tokens reset', duration: const Duration(milliseconds: 500));
          isRefreshing = false;
        });
      },
      child: const Text('RESET'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SettingsSideMenu(),
                const SizedBox(width: 50),
                Expanded(
                  child: IndexedStack(
                    index: ref.watch(settingsIndexProvider),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('COMPLETED FOLDER ', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 15),
                          if (ref.read(settingsIndexProvider) == 0)
                            ElevatedButton(
                              onPressed: () async {
                                String? directory = await FilePicker.platform.getDirectoryPath();
                                if (directory != null) {
                                  setState(() {
                                    selectedDirectory = directory;
                                  });
                                  try {
                                    changeCompletedFolder(ref, directory);
                                  } catch (e) {
                                    EasyLoading.showError('Error: $e.toString()');
                                  }
                                }
                                // print(selectedDirectory);
                              },
                              child: selectedDirectory != null ? Text(selectedDirectory!) : const Text(''),
                            ),
                        ],
                      ),
                      // Github tokens
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GITHUB TOKENS', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 15),
                          _addTile('github'),
                          const SizedBox(height: 10),
                          Expanded(child: _listView('github')),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _resetButton('github'),
                              _saveButton('github'),
                            ],
                          ),
                        ],
                      ),

                      // Gitlab tokens
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GITLAB TOKENS', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 15),
                          _addTile('gitlab'),
                          const SizedBox(height: 10),
                          Expanded(child: _listView('gitlab')),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _resetButton('gitlab'),
                              _saveButton('gitlab'),
                            ],
                          ),
                        ],
                      ),

                      // CONTENT
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CONTENT', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 15),
                          ListTile(
                            title: Text('Automatic refresh', style: Theme.of(context).textTheme.bodyMedium),
                            leading: CustomSwitch(selected: automaticRefresh, toggleFunction: () => toggleRefresh(ref)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),

                      // THEME
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('THEME', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 15),
                          const Row(
                            children: [
                              ThemeCircle(theme: 'Dark'),
                              SizedBox(width: 20),
                              ThemeCircle(theme: 'Violet'),
                            ],
                          ),
                          const SizedBox(height: 15),
                          ListTile(
                            title: Text('Dark grid', style: Theme.of(context).textTheme.bodyMedium),
                            leading: CustomSwitch(selected: gridDarkTheme, toggleFunction: () => toggleGridDarkTheme(ref)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsSideMenu extends ConsumerStatefulWidget {
  const SettingsSideMenu({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsSideMenu> createState() => _SettingsSideMenuState();
}

class _SettingsSideMenuState extends ConsumerState<SettingsSideMenu> {
  final List<String> _menuItems = ['Completed folder', 'Github tokens', 'Gitlab tokens', 'Content', 'Theme'];

  @override
  Widget build(BuildContext context) {
    var theme = ref.watch(themeProvider);

    final TextStyle selectedStyle = TextStyle(
      color: theme.primaryColor,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
      // decoration: TextDecoration.underline,
    );

    const TextStyle categoryStyle = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Folders', style: categoryStyle),
          TextButton(
              onPressed: () {
                ref.read(settingsIndexProvider.notifier).state = _menuItems.indexOf('Completed folder');
              },
              child: ref.watch(settingsIndexProvider) == _menuItems.indexOf('Completed folder')
                  ? Text('Completed folder', style: selectedStyle)
                  : Text('Completed folder', style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(height: 15),
          const Text('Tokens', style: categoryStyle),
          TextButton(
              onPressed: () {
                ref.read(settingsIndexProvider.notifier).state = _menuItems.indexOf('Github tokens');
              },
              child: ref.watch(settingsIndexProvider) == _menuItems.indexOf('Github tokens')
                  ? Text('Github tokens', style: selectedStyle)
                  : Text('Github tokens', style: Theme.of(context).textTheme.bodyMedium)),
          TextButton(
              onPressed: () {
                ref.read(settingsIndexProvider.notifier).state = _menuItems.indexOf('Gitlab tokens');
              },
              child: ref.watch(settingsIndexProvider) == _menuItems.indexOf('Gitlab tokens')
                  ? Text('Gitlab tokens', style: selectedStyle)
                  : Text('Gitlab tokens', style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(height: 15),
          const Text('General', style: categoryStyle),
          TextButton(
              onPressed: () {
                ref.read(settingsIndexProvider.notifier).state = _menuItems.indexOf('Content');
              },
              child: ref.watch(settingsIndexProvider) == _menuItems.indexOf('Content')
                  ? Text('Content', style: selectedStyle)
                  : Text('Content', style: Theme.of(context).textTheme.bodyMedium)),
          TextButton(
              onPressed: () {
                ref.read(settingsIndexProvider.notifier).state = _menuItems.indexOf('Theme');
              },
              child: ref.watch(settingsIndexProvider) == _menuItems.indexOf('Theme')
                  ? Text('Theme', style: selectedStyle)
                  : Text('Theme', style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}

class ThemeCircle extends ConsumerStatefulWidget {
  const ThemeCircle({super.key, required this.theme});

  final String theme;

  @override
  ConsumerState<ThemeCircle> createState() => _ThemeCircleState();
}

class _ThemeCircleState extends ConsumerState<ThemeCircle> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    var theme = ref.watch(themeProvider);
    var thisTheme = theme.getTheme(widget.theme.toLowerCase());
    var selectedTheme = theme.getTheme(config.settings['general']['theme']);
    bool selected = ref.watch(themeProvider).selectedThemeMap[widget.theme.toLowerCase()]!;
    var labelColor = Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        MouseRegion(
          cursor: selected ? SystemMouseCursors.basic : SystemMouseCursors.click,
          onHover: (event) => setState(() => hovering = true),
          onExit: (event) => setState(() => hovering = false),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (config.settings['general']['theme'] != null && config.settings['general']['theme'] != widget.theme.toLowerCase()) {
                  ref.watch(themeProvider.notifier).setTheme(widget.theme.toLowerCase());

                  // update all needRefreshing providers to false because changing the theme will rebuild the grids
                  ref.read(searchVMProvider).updateNeedRefreshing(ref, false);
                }
              });
            },
            child: CircleAvatar(
              backgroundColor: selected ? selectedTheme['gitColor'] : Colors.white,
              radius: 28,
              child: CircleAvatar(
                radius: 25,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        thisTheme['canvasColor']!,
                        thisTheme['primaryColor']!,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hovering)
          Positioned(
            top: -35,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  Bootstrap.chat_square_fill,
                  color: labelColor,
                  size: 40,
                ),
                Positioned(
                  top: -1,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: labelColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          widget.theme,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (selected)
          const Positioned(
            top: -5,
            right: -5,
            child: Icon(
              HeroIcons.check_circle,
              color: Colors.white,
              size: 30,
            ),
          ),
      ],
    );
  }
}
