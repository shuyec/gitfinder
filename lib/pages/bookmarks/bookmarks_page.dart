import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitfinder/pages/bookmarks/bookmarks_provider.dart';
import 'package:gitfinder/pages/search/search_page_viewmodel.dart';
import 'package:gitfinder/pages/settings/settings_page.dart';
import 'package:gitfinder/pages/settings/theme_provider.dart';
import 'package:gitfinder/widgets/custom_tabview.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'dart:ui';

class BookmarksPage extends ConsumerStatefulWidget {
  const BookmarksPage({Key? key}) : super(key: key);

  @override
  ConsumerState<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends ConsumerState<BookmarksPage> {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: CustomTabView(
        itemCount: 3,
        tabBuilder: (context, index) => Tab(text: ['Repositories', 'Commits', 'Issues'][index]),
        pageBuilder: (context, index) => [
          const BookmarksGrid('repositories_bookmarks'),
          const BookmarksGrid('commits_bookmarks'),
          const BookmarksGrid('issues_bookmarks'),
        ][index],
      ),
    );
  }
}

class BookmarksGrid extends ConsumerStatefulWidget {
  const BookmarksGrid(this.type, {super.key});

  final String type;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BookmarksGridState();
}

class _BookmarksGridState extends ConsumerState<BookmarksGrid> with AutomaticKeepAliveClientMixin {
  late PlutoGridStateManager stateManager;
  List<String> columns = [];
  List<PlutoColumn> plutoColumns = [];
  List<PlutoRow> rows = [];
  bool firstTimeThru = true;

  void handleOnRowChecked(PlutoGridOnRowCheckedEvent event) {
    if (event.isRow && event.row?.checked == true) {
      ref.read(bookmarksProvider.notifier).saveRows(ref, [event.row!], widget.type, columns, true);
    } else if (event.isRow && event.row?.checked == false) {
      ref.read(bookmarksProvider.notifier).deleteRows(ref, [event.row!], widget.type, columns, true);
    } else if (event.isChecked != null && event.isChecked!) {
      ref.read(bookmarksProvider.notifier).saveRows(ref, stateManager.rows, widget.type, columns, true);
    } else if (event.isChecked != null && !event.isChecked!) {
      ref.read(bookmarksProvider.notifier).deleteRows(ref, stateManager.rows, widget.type, columns, true);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var theme = ref.watch(themeProvider);

    late String typeString;
    List<List<dynamic>> csv = [];
    switch (widget.type) {
      case 'repositories':
      case 'repositories_bookmarks':
        typeString = 'repositories';
        csv = ref.watch(bookmarksProvider).reposBookmarks;
        break;
      case 'commits':
      case 'commits_bookmarks':
        typeString = 'commits';
        csv = ref.watch(bookmarksProvider).commitsBookmarks;
        break;
      case 'issues':
      case 'issues_bookmarks':
        typeString = 'issues';
        csv = ref.watch(bookmarksProvider).issuesBookmarks;
        break;
    }

    if (csv.isEmpty || csv.length == 1) {
      return Center(child: Text('No $typeString bookmark'));
    }

    plutoColumns = csv[0].asMap().entries.map((entry) {
      int idx = entry.key;
      String column = entry.value.toString();
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
