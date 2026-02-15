import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool? showBackButton;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const StandardAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.onBack,
    this.showBackButton,
    this.backgroundColor,
    this.foregroundColor,
  }) : assert(
          title != null || titleWidget != null,
          'Provide either title or titleWidget',
        );

  Widget _buildTitle() {
    if (titleWidget != null) {
      return titleWidget!;
    }
    return Text(title!);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = GoRouter.of(context).canPop();
    final shouldShowBackButton = showBackButton ?? canPop;

    return AppBar(
      title: _buildTitle(),
      leading: shouldShowBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack ?? () => context.pop(),
            )
          : null,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}
