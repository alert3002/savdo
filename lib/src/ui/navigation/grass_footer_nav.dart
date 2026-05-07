import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// PNG-ҳо ба `assets/nav_icons/` нусха карда шудаанд, то дар web/desktop
// ҳамеша бо `Image.asset` кор кунанд.
const _kPngHome = 'assets/nav_icons/home.png';
const _kPngCatalog = 'assets/nav_icons/catalog.png';
const _kPngCart = 'assets/nav_icons/cart.png';
const _kPngMlm = 'assets/nav_icons/mlm.png';
const _kPngProfile = 'assets/nav_icons/profile.png';

class GrassFooterNav extends StatelessWidget {
  const GrassFooterNav({
    super.key,
    required this.navigationShell,
    this.cartBadgeCount = 0,
    required this.allowedBranches,
  });

  final StatefulNavigationShell navigationShell;
  final int cartBadgeCount;
  final List<int> allowedBranches;

  void _go(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentBranch = navigationShell.currentIndex;

    final bg = scheme.surfaceContainerHighest.withValues(alpha: 0.22);
    final border = scheme.primary.withValues(alpha: 0.95);
    final selectedColor = scheme.primary;
    final unselectedColor = scheme.onSurface.withValues(alpha: 0.72);

    Widget navForBranch(int branchIndex) {
      switch (branchIndex) {
        case 0:
          return _NavItem(
            label: 'Главная',
            iconPath: _kPngHome,
            fallbackIcon: Icons.home_outlined,
            selected: branchIndex == currentBranch,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
            onTap: () => _go(0),
          );
        case 1:
          return _NavItem(
            label: 'Каталог',
            iconPath: _kPngCatalog,
            fallbackIcon: Icons.crop_square_outlined,
            selected: branchIndex == currentBranch,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
            onTap: () => _go(1),
          );
        case 2:
          return _CartNavItem(
            label: 'Корзина',
            iconPath: _kPngCart,
            selected: branchIndex == currentBranch,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
            badgeCount: cartBadgeCount,
            onTap: () => _go(2),
          );
        case 3:
          return _NavItem(
            label: 'MLM',
            iconPath: _kPngMlm,
            fallbackIcon: Icons.account_tree_outlined,
            selected: branchIndex == currentBranch,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
            onTap: () => _go(3),
          );
        case 4:
        default:
          return _NavItem(
            label: 'Профиль',
            iconPath: _kPngProfile,
            fallbackIcon: Icons.person_outline,
            selected: branchIndex == currentBranch,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
            onTap: () => _go(4),
          );
      }
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        child: _NotchedFooter(
          backgroundColor: bg,
          borderColor: border,
          child: Row(
            children: [
              for (final b in allowedBranches) navForBranch(b),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.iconPath,
    required this.fallbackIcon,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final IconData fallbackIcon;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.labelSmall?.copyWith(
      height: 1.0,
      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      color: selected ? selectedColor : unselectedColor,
    );

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(
                  size: 22,
                  color: selected ? selectedColor : unselectedColor,
                ),
                child: _PngFooterIcon(
                  path: iconPath,
                  fallback: fallbackIcon,
                  color: selected ? selectedColor : unselectedColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartNavItem extends StatelessWidget {
  const _CartNavItem({
    required this.label,
    required this.iconPath,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.badgeCount,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fill = scheme.surfaceContainerHighest.withValues(alpha: 0.30);
    final labelStyle = textTheme.labelSmall?.copyWith(
      height: 1.0,
      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      color: selected ? selectedColor : unselectedColor,
    );

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Transform.translate(
            offset: const Offset(0, -8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected
                              ? scheme.primary.withValues(alpha: 0.55)
                              : scheme.outlineVariant.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Center(
                        child: _PngFooterIcon(
                          path: iconPath,
                          fallback: Icons.shopping_bag_outlined,
                          color: selected ? selectedColor : unselectedColor,
                          size: 25,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 2,
                      child: _Badge(count: badgeCount),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: labelStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PngFooterIcon extends StatelessWidget {
  const _PngFooterIcon({
    required this.path,
    required this.fallback,
    required this.color,
    required this.size,
  });

  final String path;
  final IconData fallback;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(fallback, color: color, size: size),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.surface, width: 2),
      ),
      child: Text(
        '$count',
        style: textTheme.labelSmall?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _NotchedFooter extends StatelessWidget {
  const _NotchedFooter({
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const height = 72.0;
    const bumpRadius = 34.0;
    const bumpHeight = 14.0;
    const radius = 34.0;

    return SizedBox(
      height: height + bumpHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            painter: _NotchedFooterBorderPainter(
              borderColor: borderColor,
              radius: radius,
              bumpRadius: bumpRadius,
              bumpHeight: bumpHeight,
            ),
            child: ClipPath(
              clipper: _NotchedFooterClipper(
                radius: radius,
                bumpRadius: bumpRadius,
                bumpHeight: bumpHeight,
              ),
              child: Container(
                height: height + bumpHeight,
                color: backgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotchedFooterClipper extends CustomClipper<Path> {
  _NotchedFooterClipper({
    required this.radius,
    required this.bumpRadius,
    required this.bumpHeight,
  });

  final double radius;
  final double bumpRadius;
  final double bumpHeight;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final cy = bumpHeight;
    final cx = w / 2;

    final path = Path();
    path.moveTo(radius, cy);
    path.lineTo(cx - bumpRadius, cy);
    path.quadraticBezierTo(
      cx - bumpRadius * 0.75,
      0,
      cx,
      0,
    );
    path.quadraticBezierTo(
      cx + bumpRadius * 0.75,
      0,
      cx + bumpRadius,
      cy,
    );
    path.lineTo(w - radius, cy);
    path.quadraticBezierTo(w, cy, w, cy + radius);
    path.lineTo(w, h - radius);
    path.quadraticBezierTo(w, h, w - radius, h);
    path.lineTo(radius, h);
    path.quadraticBezierTo(0, h, 0, h - radius);
    path.lineTo(0, cy + radius);
    path.quadraticBezierTo(0, cy, radius, cy);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _NotchedFooterClipper oldClipper) {
    return radius != oldClipper.radius ||
        bumpRadius != oldClipper.bumpRadius ||
        bumpHeight != oldClipper.bumpHeight;
  }
}

class _NotchedFooterBorderPainter extends CustomPainter {
  _NotchedFooterBorderPainter({
    required this.borderColor,
    required this.radius,
    required this.bumpRadius,
    required this.bumpHeight,
  });

  final Color borderColor;
  final double radius;
  final double bumpRadius;
  final double bumpHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _NotchedFooterClipper(
      radius: radius,
      bumpRadius: bumpRadius,
      bumpHeight: bumpHeight,
    ).getClip(size);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = borderColor
      ..strokeWidth = 2;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NotchedFooterBorderPainter oldDelegate) {
    return borderColor != oldDelegate.borderColor ||
        radius != oldDelegate.radius ||
        bumpRadius != oldDelegate.bumpRadius ||
        bumpHeight != oldDelegate.bumpHeight;
  }
}
