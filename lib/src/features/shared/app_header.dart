import 'package:flutter/material.dart';

import 'design_tokens.dart';

class RecallAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RecallAppBar({
    super.key,
    required this.title,
    required this.onMenuPressed,
    this.actions = const [],
  });

  final Widget title;
  final VoidCallback onMenuPressed;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: RecallColors.white.withValues(alpha: 0.8),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leadingWidth: 44,
      titleSpacing: 0,
      leading: HeaderMenuButton(onPressed: onMenuPressed),
      title: title,
      actions: actions,
      bottom: const HeaderBottomDivider(),
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + HeaderBottomDivider.height);
}

class HeaderTitle extends StatelessWidget {
  const HeaderTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: RecallTextStyles.headerTitle,
    );
  }
}

class HeaderMenuButton extends StatelessWidget {
  const HeaderMenuButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu, size: 20),
      onPressed: onPressed,
      tooltip: 'Menu',
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: const EdgeInsets.all(8),
    );
  }
}

class HeaderIconAction extends StatelessWidget {
  const HeaderIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: const EdgeInsets.all(8),
    );
  }
}

class HeaderAddButton extends StatelessWidget {
  const HeaderAddButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 28,
          decoration: BoxDecoration(
            color: RecallColors.neutral900,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: RecallColors.shadow,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: RecallColors.white, size: 16),
        ),
      ),
    );
  }
}

class HeaderBottomDivider extends StatelessWidget
    implements PreferredSizeWidget {
  const HeaderBottomDivider({super.key});

  static const double height = 1;

  @override
  Widget build(BuildContext context) {
    return const PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: Divider(
        height: 1,
        thickness: 1,
        color: RecallColors.neutral200,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(height);
}
