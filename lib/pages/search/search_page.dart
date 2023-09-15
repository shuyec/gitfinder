import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitfinder/pages/search/search_content.dart';
import 'search_filters.dart';

class SearchPage extends StatelessWidget {
  const SearchPage(this.folder, this.wRef, {Key? key}) : super(key: key);

  final String folder;
  final WidgetRef wRef;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10.0, 10.0, 0.0, 10.0),
      child: Row(
        children: [
          SearchFilters(
            folder,
            wRef,
            // key: Key('Filter ${widget.folder}'),
          ),
          SearchContent(
            folder,
            // key: Key('Content ${widget.folder}'),
          ),
        ],
      ),
    );
  }
}
