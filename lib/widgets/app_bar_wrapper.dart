import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_router.dart';

class AppBarWrapper extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool canPop;

  const AppBarWrapper({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.canPop = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (!canPop) return false;
        if (onBackPressed != null) {
          onBackPressed!();
          return false;
        }
        AppRouter.goBackOrHome(context);
        return false;
      },
      child: AppBar(
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: showBackButton && (context.canPop() || onBackPressed != null)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (onBackPressed != null) {
                    onBackPressed!();
                  } else {
                    AppRouter.goBackOrHome(context);
                  }
                },
              )
            : null,
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
