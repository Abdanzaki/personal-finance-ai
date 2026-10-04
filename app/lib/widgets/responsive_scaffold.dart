import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class NavItem {
  final String label;
  final String path;
  final IconData icon;
  final IconData? activeIcon;
  final bool isMobilePrimary;

  const NavItem({
    required this.label,
    required this.path,
    required this.icon,
    this.activeIcon,
    this.isMobilePrimary = false,
  });
}

const List<NavItem> kNavItems = [
  NavItem(
    label: 'Home',
    path: '/dashboard',
    icon: Icons.account_balance_outlined,
    activeIcon: Icons.account_balance,
    isMobilePrimary: true,
  ),
  NavItem(
    label: 'Transactions',
    path: '/transactions',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long,
    isMobilePrimary: true,
  ),
  NavItem(
    label: 'Budgets',
    path: '/budgets',
    icon: Icons.pie_chart_outline,
    activeIcon: Icons.pie_chart,
    isMobilePrimary: true,
  ),
  NavItem(
    label: 'Goals',
    path: '/goals',
    icon: Icons.savings_outlined,
    activeIcon: Icons.savings,
    isMobilePrimary: true,
  ),
  NavItem(
    label: 'AI Assistant',
    path: '/ai-chat',
    icon: Icons.auto_awesome_outlined,
    activeIcon: Icons.auto_awesome,
    isMobilePrimary: true,
  ),
  NavItem(
    label: 'Insights',
    path: '/insights',
    icon: Icons.lightbulb_outline,
    activeIcon: Icons.lightbulb,
    isMobilePrimary: false,
  ),
  NavItem(
    label: 'Reports',
    path: '/reports',
    icon: Icons.bar_chart_outlined,
    activeIcon: Icons.bar_chart,
    isMobilePrimary: false,
  ),
  NavItem(
    label: 'Settings',
    path: '/settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
    isMobilePrimary: false,
  ),
];

class ResponsiveScaffold extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const ResponsiveScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= 1024) {
          return _buildDesktopLayout(context, ref);
        } else if (width >= 600) {
          return _buildTabletLayout(context, ref);
        } else {
          return _buildMobileLayout(context, ref);
        }
      },
    );
  }

  // --- MOBILE LAYOUT (<600px) ---
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    final primaryNavItems = kNavItems.where((item) => item.isMobilePrimary).toList();
    final currentIndex = primaryNavItems.indexWhere((item) => currentPath.startsWith(item.path));

    final currentTitle = kNavItems
        .firstWhere(
          (item) => currentPath.startsWith(item.path),
          orElse: () => const NavItem(label: 'Home', path: '/dashboard', icon: Icons.home),
        )
        .label;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: AppColors.primaryContainer,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: AppSpacing.margin,
            right: AppSpacing.margin,
          ),
          alignment: Alignment.center,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 32,
                      width: 32,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.onPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spaceSm),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Finance AI',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          currentTitle,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.go('/settings'),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.slate200, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.person,
                        color: AppColors.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: child,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex >= 0 ? currentIndex : 0,
        onDestinationSelected: (idx) {
          context.go(primaryNavItems[idx].path);
        },
        destinations: primaryNavItems.map((item) {
          return NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon ?? item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  // --- TABLET LAYOUT (600px - 1024px) ---
  Widget _buildTabletLayout(BuildContext context, WidgetRef ref) {
    final selectedIndex = kNavItems.indexWhere((item) => currentPath.startsWith(item.path));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.primaryContainer,
            selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
            onDestinationSelected: (idx) {
              context.go(kNavItems[idx].path);
            },
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.spaceMd),
              child: Image.asset(
                'assets/images/logo.png',
                height: 36,
                width: 36,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.spaceMd),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.onPrimaryContainer),
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/login');
                    },
                  ),
                ),
              ),
            ),
            labelType: NavigationRailLabelType.all,
            selectedLabelTextStyle: AppTypography.labelSmall.copyWith(
              color: AppColors.secondaryFixed,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: AppTypography.labelSmall.copyWith(
              color: AppColors.onPrimaryContainer,
            ),
            selectedIconTheme: const IconThemeData(color: AppColors.secondaryFixed),
            unselectedIconTheme: const IconThemeData(color: AppColors.onPrimaryContainer),
            destinations: kNavItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon ?? item.icon),
                label: Text(item.label),
              );
            }).toList(),
          ),
          const VerticalDivider(width: 1, color: AppColors.slate200),
          Expanded(child: child),
        ],
      ),
    );
  }

  // --- DESKTOP LAYOUT (>1024px) ---
  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          // Persistent Dark Navy Sidebar (#0A1628 / #101C2E)
          Container(
            width: 260,
            height: double.infinity,
            color: AppColors.obsidianNavy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.spaceLg),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0x1FFFFFFF), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: AppRadii.borderDefault,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.obsidianNavy,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personal Finance AI',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'SMART MONEY INDIA',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.onPrimaryContainer,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.spaceMd),

                // Nav Links List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMd),
                    itemCount: kNavItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, idx) {
                      final item = kNavItems[idx];
                      final isSelected = currentPath.startsWith(item.path);

                      return Material(
                        color: isSelected ? AppColors.growthEmerald : Colors.transparent,
                        borderRadius: AppRadii.borderDefault,
                        child: InkWell(
                          borderRadius: AppRadii.borderDefault,
                          hoverColor: const Color(0x1AFFFFFF),
                          onTap: () => context.go(item.path),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.spaceMd,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                                  size: 20,
                                  color: isSelected
                                      ? AppColors.onPrimary
                                      : AppColors.onPrimaryContainer,
                                ),
                                const SizedBox(width: AppSpacing.spaceMd),
                                Text(
                                  item.label,
                                  style: AppTypography.labelLarge.copyWith(
                                    color: isSelected
                                        ? AppColors.onPrimary
                                        : AppColors.onPrimaryContainer,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Sidebar Footer (User Info & Logout)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.spaceMd),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0x1FFFFFFF), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.secondaryFixed, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Rohan Sharma',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user?.email ?? 'rohan.sharma@gmail.com',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.onPrimaryContainer,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.logout,
                          size: 18,
                          color: AppColors.onPrimaryContainer,
                        ),
                        tooltip: 'Logout',
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          context.go('/login');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main View Canvas
          Expanded(
            child: Column(
              children: [
                // Top Context Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginDesktop),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border(bottom: BorderSide(color: AppColors.slate200, width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            kNavItems
                                .firstWhere(
                                  (item) => currentPath.startsWith(item.path),
                                  orElse: () => const NavItem(
                                      label: 'Dashboard', path: '/dashboard', icon: Icons.home),
                                )
                                .label,
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.spaceMd),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.emerald50,
                              borderRadius: AppRadii.borderFull,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.growthEmerald,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'AI Sync Active',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.growthEmerald,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none,
                                color: AppColors.onSurfaceVariant),
                            onPressed: () {},
                          ),
                          const SizedBox(width: AppSpacing.spaceSm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: AppRadii.borderDefault,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.currency_rupee, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'INR (₹)',
                                  style: AppTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content View
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
