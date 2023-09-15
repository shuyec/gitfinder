import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitfinder/pages/settings/theme_provider.dart';

class CustomSwitch extends ConsumerStatefulWidget {
  const CustomSwitch({super.key, required this.selected, this.toggleFunction});

  final bool selected;
  final VoidCallback? toggleFunction;

  @override
  ConsumerState<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends ConsumerState<CustomSwitch> {
  late bool _selected;

  void callToggleFunction() {
    if (widget.toggleFunction != null) {
      widget.toggleFunction!();
    }
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  final MaterialStateProperty<Icon?> thumbIcon = MaterialStateProperty.resolveWith<Icon?>(
    (Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return const Icon(Icons.check, color: Colors.white);
      }
      return const Icon(Icons.close, color: Colors.white);
    },
  );

  @override
  Widget build(BuildContext context) {
    var theme = ref.watch(themeProvider);

    return Switch(
      thumbIcon: thumbIcon,
      value: _selected,
      activeColor: theme.primaryColor,
      onChanged: (bool value) {
        setState(() {
          _selected = value;
        });
        callToggleFunction();
      },
    );
  }
}
