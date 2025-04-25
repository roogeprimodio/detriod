import 'package:flutter/material.dart';
import 'package:frenzy/core/widgets/common_app_bar.dart';

class AdminScaffold extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Widget body;
  final Widget? floatingActionButton;
  final ScrollController? scrollController;

  const AdminScaffold({
    super.key,
    required this.title,
    this.actions = const [],
    required this.body,
    this.floatingActionButton,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: title,
        actions: actions,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: body,
          );
        },
      ),
      floatingActionButton: floatingActionButton,
    );
  }
} 