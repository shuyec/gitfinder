import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gitfinder/pages/bookmarks/bookmarks_provider.dart';
import 'package:gitfinder/pages/search/search_content_provider.dart';
import 'package:gitfinder/pages/search/search_filters.dart';
import 'package:gitfinder/pages/search/search_page_viewmodel.dart';
import 'package:gitfinder/pages/settings/settings_page.dart';
import 'package:gitfinder/pages/settings/theme_provider.dart';
import 'package:gitfinder/widgets/custom_tabview.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'dart:ui';

final needRefreshing = StateProvider.family<bool, String>((ref, folder) => false);

class SearchContent extends ConsumerStatefulWidget {
  const SearchContent(this.folder, {Key? key}) : super(key: key);

  final String folder;

  @override
  ConsumerState<SearchContent> createState() => _SearchContentState();
}

class _SearchContentState extends ConsumerState<SearchContent> {
  @override
  Widget build(BuildContext context) {
    String currentFolder = widget.folder;
    return Expanded(
      child: Stack(
        children: [
          Theme(
            data: ThemeData(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            child: ContentTabs(currentFolder),
          ),
        ],
      ),
    );
  }
}

class ContentTabs extends ConsumerStatefulWidget {
  const ContentTabs(this.folder, {super.key});

  final String folder;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ContentTabsState();
}

class _ContentTabsState extends ConsumerState<ContentTabs> {
  @override
  Widget build(BuildContext context) {
    String currentFolder = widget.folder;
    List<String> searchTabs = ref.watch(searchContentProvider(currentFolder).select((content) => content.searchTabs));
    List<Widget> searchViews = ref.watch(searchContentProvider(currentFolder).select((content) => content.searchViews));

    return (searchViews.isNotEmpty & searchTabs.isNotEmpty)
        ? CustomTabView(
            itemCount: searchTabs.length,
            tabBuilder: (context, index) => Tab(text: searchTabs[index]),
            pageBuilder: (context, index) => searchViews[index],
          )
        : const Center(child: Text('New Search'));
  }
}

class SearchGrid extends ConsumerStatefulWidget {
  const SearchGrid(this.type, this.folder, {Key? key}) : super(key: key);

  final String folder;
  final String type;

  @override
  ConsumerState<SearchGrid> createState() => _SearchGridState();
}

class _SearchGridState extends ConsumerState<SearchGrid> with AutomaticKeepAliveClientMixin {
  late PlutoGridStateManager stateManager;
  List<String> columns = [];
  List<PlutoColumn> plutoColumns = [];
  List<PlutoRow> rows = [];
  bool firstTimeThru = true;

  void handleOnRowChecked(PlutoGridOnRowCheckedEvent event) {
    if (event.isRow && event.row?.checked == true) {
      ref.read(bookmarksProvider.notifier).saveRows(ref, [event.row!], widget.type, columns, false);
    } else if (event.isRow && event.row?.checked == false) {
      ref.read(bookmarksProvider.notifier).deleteRows(ref, [event.row!], widget.type, columns, false);
    } else if (event.isChecked != null && event.isChecked!) {
      ref.read(bookmarksProvider.notifier).saveRows(ref, stateManager.checkedRows, widget.type, columns, false);
    } else if (event.isChecked != null && !event.isChecked!) {
      ref.read(bookmarksProvider.notifier).deleteRows(ref, stateManager.rows, widget.type, columns, false);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var theme = ref.watch(themeProvider);
    columns = [];

    late List<List<dynamic>> csv;
    switch (widget.type) {
      case 'repositories':
        csv = ref.watch(searchContentProvider(widget.folder)).repositories;
        break;
      case 'commits':
        csv = ref.watch(searchContentProvider(widget.folder)).commits;
        break;
      case 'issues':
        csv = ref.watch(searchContentProvider(widget.folder)).issues;
        break;
    }

    if (ref.watch(isSearchFinishedProvider(widget.folder)) && csv.isEmpty) {
      return const Center(
        child: Text('Search finished with no data'),
      );
    } else if (!ref.watch(isSearchStartedProvider(widget.folder)) &&
        ref.read(searchVMProvider).readSearchJson(widget.folder) != null &&
        csv.isEmpty) {
      return const Center(
        child: Text('No data found'),
      );
    } else if (ref.watch(isSearchStartedProvider(widget.folder)) && (csv.isEmpty || csv.length == 1)) {
      return const Center(
        child: SpinKitPulsingGrid(
          color: Colors.white,
        ),
      );
    }

    plutoColumns = csv[0].asMap().entries.map((entry) {
      int idx = entry.key;
      String column = entry.value;
      columns.add(column);
      return PlutoColumn(
        title: column,
        field: column,
        type: PlutoColumnType.text(),
        enableRowChecked: idx == 0 ? true : false,
      );
    }).toList();

    if (firstTimeThru == true) {
      rows = csv.sublist(1).map((item) {
        List rowCells = item.map((row) {
          return PlutoCell(
            value: row.toString(),
          );
        }).toList();
        Map<String, PlutoCell> plutoCellsMap = {for (int i = 0; i < rowCells.length; i++) columns[i]: rowCells[i]};
        PlutoRow plutoRow = PlutoRow(cells: plutoCellsMap);
        if (ref.read(searchVMProvider).isRowSaved(plutoRow, widget.type, columns)) {
          plutoRow.setChecked(true);
        }
        return plutoRow;
      }).toList();
      firstTimeThru = false;
    } else {
      List<PlutoRow> aRows = csv.sublist(1).map((item) {
        List rowCells = item.map((row) {
          return PlutoCell(
            value: row.toString(),
          );
        }).toList();
        Map<String, PlutoCell> plutoCellsMap = {for (int i = 0; i < rowCells.length; i++) columns[i]: rowCells[i]};
        PlutoRow plutoRow = PlutoRow(cells: plutoCellsMap);
        if (ref.read(searchVMProvider).isRowSaved(plutoRow, widget.type, columns)) {
          plutoRow.setChecked(true);
        }
        return plutoRow;
      }).toList();
      stateManager.removeAllRows(notify: false);
      stateManager.appendRows(aRows);
    }

    late PlutoGridConfiguration configuration;
    if (ref.watch(gridDarkThemeProvider)) {
      configuration = const PlutoGridConfiguration.dark(
        scrollbar: PlutoGridScrollbarConfig(
          dragDevices: {
            // PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.unknown,
          },
          onlyDraggingThumb: false,
          isAlwaysShown: true,
          scrollbarThickness: 10,
          scrollbarThicknessWhileDragging: 15,
          hoverWidth: 15,
          longPressDuration: Duration.zero,
        ),
      );
    } else {
      configuration = PlutoGridConfiguration(
        scrollbar: const PlutoGridScrollbarConfig(
          dragDevices: {
            // PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.unknown,
          },
          onlyDraggingThumb: false,
          isAlwaysShown: true,
          scrollbarThickness: 10,
          scrollbarThicknessWhileDragging: 15,
          hoverWidth: 15,
          longPressDuration: Duration.zero,
        ),
        style: PlutoGridStyleConfig(
          activatedBorderColor: theme.primaryColor,
          activatedColor: theme.activatedColor,
        ),
      );
    }

    return PlutoGrid(
      onRowChecked: handleOnRowChecked,
      columns: plutoColumns,
      rows: rows,
      // onChanged: (PlutoGridOnChangedEvent event) {
      //   print(event);
      // },
      onLoaded: (PlutoGridOnLoadedEvent event) {
        event.stateManager.setSelectingMode(PlutoGridSelectingMode.row);
        event.stateManager.setShowColumnFilter(true);

        stateManager = event.stateManager;
      },
      configuration: configuration,
      createFooter: (stateManager) {
        // stateManager.setPageSize(100, notify: false); // default 40
        return PlutoPagination(stateManager);
      },
      mode: PlutoGridMode.readOnly,
    );
  }
}
