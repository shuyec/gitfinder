import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gitfinder/pages/bookmarks/bookmarks_page.dart';
import 'package:gitfinder/pages/bookmarks/bookmarks_provider.dart';
import 'package:gitfinder/pages/homepage/homepage.dart';
import 'package:gitfinder/pages/search/search_filters.dart';
import 'package:gitfinder/pages/search/search_page.dart';
import 'package:gitfinder/pages/search/search_page_viewmodel.dart';
import 'package:gitfinder/pages/settings/settings_page.dart';
import 'package:gitfinder/pages/settings/theme_provider.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:sidebarx/sidebarx.dart';

final sidebarControllerProvider = Provider((ref) => SidebarXController(selectedIndex: 0, extended: true));

class Sidebar extends ConsumerStatefulWidget {
  const Sidebar({
    Key? key,
    required SidebarXController controller,
  })  : _controller = controller,
        super(key: key);

  final SidebarXController _controller;

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  bool isRefreshing = false;
  int index = 0;

  @override
  Widget build(BuildContext context) {
    var theme = ref.watch(themeProvider);
    List<String> folders = ref.watch(searchFoldersProvider);

    return SidebarX(
      controller: widget._controller,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.canvasColor,
          borderRadius: BorderRadius.circular(20),
        ),
        hoverColor: theme.hoverColor,
        textStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        selectedTextStyle: const TextStyle(color: Colors.white),
        itemTextPadding: const EdgeInsets.only(left: 30),
        selectedItemTextPadding: const EdgeInsets.only(left: 30),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.canvasColor),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.actionColor.withOpacity(0.37),
          ),
          gradient: LinearGradient(
            colors: [theme.accentCanvasColor, theme.canvasColor],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 30,
            )
          ],
        ),
        iconTheme: IconThemeData(
          color: Colors.white.withOpacity(0.7),
          size: 20,
        ),
        selectedIconTheme: const IconThemeData(
          color: Colors.white,
          size: 20,
        ),
      ),
      extendedTheme: SidebarXTheme(
        width: 200,
        decoration: BoxDecoration(
          color: theme.canvasColor,
        ),
      ),
      footerDivider: Divider(color: Colors.white.withOpacity(0.3), height: 1),
      headerBuilder: (context, extended) {
        return SizedBox(
          height: 100,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: IconButton(
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                padding: EdgeInsets.zero,
                onPressed: (() {
                  setState(() => isRefreshing = true);
                  ref.invalidate(searchFoldersProvider);
                  ref.invalidate(sidebarControllerProvider);
                  ref.read(bookmarksProvider.notifier).updateGrids(ref, 'repositories', true);
                  ref.read(bookmarksProvider.notifier).updateGrids(ref, 'commits', true);
                  ref.read(bookmarksProvider.notifier).updateGrids(ref, 'issues', true);

                  Future.delayed(const Duration(seconds: 1), () {
                    setState(() {
                      isRefreshing = false;
                    });
                  });
                }),
                icon: isRefreshing ? SpinKitFadingCube(color: theme.gitColor) : Image.asset('assets/logo.png')),
          ),
        );
      },
      items: getSidebarItems(context, ref, folders),
    );
  }
}

class Pages extends ConsumerStatefulWidget {
  const Pages(
    this.wRef, {
    Key? key,
  }) : super(key: key);

  final WidgetRef wRef;

  @override
  ConsumerState<Pages> createState() => _PagesState();
}

class _PagesState extends ConsumerState<Pages> {
  @override
  Widget build(BuildContext context) {
    List<String> folders = ref.watch(searchFoldersProvider);
    return AnimatedBuilder(
      animation: ref.watch(sidebarControllerProvider),
      builder: (context, child) {
        final pageTitle = getPageByIndex(ref.watch(sidebarControllerProvider).selectedIndex);
        Map<int, Widget> pages = {
          0: const Homepage(),
          // Settings
          1: const SettingsPage(),
          // Bookmarks
          2: const BookmarksPage(),
          // Create
          3: Text(
            pageTitle,
            style: Theme.of(context).textTheme.displayMedium,
          ),
        };
        // Folders
        for (int i = 0; i < folders.length; i++) {
          pages[i + 4] = SearchPage(
            key: Key(folders[i]),
            folders[i],
            widget.wRef,
            // key: Key(folders[i]),
          );
        }
        return IndexedStack(
          index: ref.watch(sidebarControllerProvider).selectedIndex,
          children: pages.values.toList(),
        );
      },
    );
  }
}

String getPageByIndex(int index) {
  switch (index) {
    case 0:
      return 'Home';
    case 1:
      return 'Settings';
    case 2:
      return 'Bookmarks';
    case 3:
      return 'Create';
    default:
      return 'Not found page';
  }
}

void onItemSelected(BuildContext context, WidgetRef ref, [int? i]) async {
  List<String> folders = ref.watch(searchFoldersProvider);
  List<SidebarXItem> items = getSidebarItems(context, ref, folders);
  int index = i ?? items.length - 1;
  items[index].onTap?.call();
  ref.read(sidebarControllerProvider).selectIndex(index);
}

List<SidebarXItem> getSidebarItems(BuildContext context, WidgetRef ref, List<String> folders) {
  for (int i = 0; i < folders.length; i++) {
    ref.read(isSearchFinishedProvider(folders[i]).notifier).state = ref.read(searchVMProvider).isSearchFinished(folders[i]);
  }

  List<SidebarXItem> items = [
    const SidebarXItem(
      icon: HeroIcons.home,
      label: 'Home',
      // onTap: () {
      //   debugPrint('Home');
      // },
    ),
    const SidebarXItem(
      icon: HeroIcons.cog_8_tooth,
      label: 'Settings',
    ),
    const SidebarXItem(
      icon: HeroIcons.bookmark_square,
      label: 'Bookmarks',
    ),
    SidebarXItem(
        icon: HeroIcons.plus,
        label: 'Create new',
        onTap: () {
          ref.read(searchVMProvider).createSearchFolder();
          ref.invalidate(searchFoldersProvider);
          ref.invalidate(sidebarControllerProvider);
          onItemSelected(context, ref);
        }),
  ];
  for (int i = 0; i < folders.length; i++) {
    items.add(SidebarXItem(
      icon: ref.watch(isSearchFinishedProvider(folders[i])) ? Bootstrap.file_earmark_check_fill : HeroIcons.document_magnifying_glass,
      label: ref.read(searchVMProvider).getFolderName(folders[i]),
    ));
  }
  return items;
}
