import 'package:flutter/material.dart';

class ListHeader extends StatelessWidget {
  const ListHeader({required this.title, this.trailing, super.key});

  final Widget title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: DefaultTextStyle.merge(
        // Couldn't find actual specs for list subheader typography so this is
        // my best guess
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.secondary,
        ),
        child: title,
      ),
      trailing: trailing,
    );
  }
}
