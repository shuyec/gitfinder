import 'package:flutter/material.dart';
import 'package:gitfinder/pages/search/search_page_viewmodel.dart';
import 'package:gitfinder/pages/settings/theme_provider.dart';
import 'package:gitfinder/sidebar_controller.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OptionsItem { itemDelete }

class Homepage extends ConsumerStatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  ConsumerState<Homepage> createState() => _HomepageState();
}

class _HomepageState extends ConsumerState<Homepage> {
  OptionsItem? selectedMenu;
  late List<String> folders;

  @override
  Widget build(BuildContext context) {
    var theme = ref.watch(themeProvider);
    folders = ref.watch(searchFoldersProvider);

    return Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < folders.length + 1; i++)
              i == 0
                  ? SizedBox(
                      width: 210,
                      height: 210,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          ref.read(searchVMProvider).createSearchFolder();
                          ref.invalidate(searchFoldersProvider);
                          ref.invalidate(sidebarControllerProvider);
                        },
                        hoverColor: theme.activatedColor.withOpacity(0.8),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: theme.homeBoxColor as Color,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(10.0)),
                          color: theme.homeBoxColor,
                          child: const Center(
                            child: Icon(
                              HeroIcons.plus,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      width: 210,
                      height: 210,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        hoverColor: theme.activatedColor.withOpacity(0.8),
                        onTap: () {
                          onItemSelected(context, ref, i + 3);
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: theme.homeBoxColor as Color,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(10.0)),
                          color: theme.homeBoxColor,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(width: 10),
                                    Row(
                                      children: [
                                        Container(
                                          height: 20,
                                          color: theme.primaryColor,
                                          child: const Padding(
                                            padding: EdgeInsets.all(2.0),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  HeroIcons.magnifying_glass,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 20,
                                          color: theme.canvasColor,
                                          child: Padding(
                                              padding: const EdgeInsets.all(2.0),
                                              child: Text(
                                                'Search',
                                                style: Theme.of(context).textTheme.headlineSmall,
                                                overflow: TextOverflow.ellipsis,
                                              )),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    PopupMenuButton<OptionsItem>(
                                      initialValue: selectedMenu,
                                      icon: const Icon(
                                        HeroIcons.ellipsis_vertical,
                                        color: Colors.white,
                                      ),
                                      // Callback that sets the selected popup menu item.
                                      onSelected: (OptionsItem item) {
                                        setState(() {
                                          selectedMenu = item;
                                        });
                                      },
                                      itemBuilder: (BuildContext context) => <PopupMenuEntry<OptionsItem>>[
                                        PopupMenuItem<OptionsItem>(
                                          value: OptionsItem.itemDelete,
                                          child: const Text('Delete'),
                                          onTap: () {
                                            ref.read(searchVMProvider).deleteSearchFolder(folders[i - 1]);
                                            ref.invalidate(searchFoldersProvider);
                                            ref.invalidate(sidebarControllerProvider);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Expanded(
                                  child: Text(
                                    ref.read(searchVMProvider).getFolderName(folders[i - 1]),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.headlineMedium,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          HeroIcons.calendar,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          ref.read(searchVMProvider).getFolderName(folders[i - 1], date: 'formatted'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.activatedColor,
                                            letterSpacing: 1.0,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
          ],
        ));
  }
}
