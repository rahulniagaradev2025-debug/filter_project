import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            label: 'Dashboard',
            active: currentIndex == 0,
            activeAsset: 'assests/images/home_button_active.png',
            inactiveIcon: Icons.home_outlined,
            onTap: () => onTap(0),
          ),
          _NavItem(
            label: 'Report',
            active: currentIndex == 1,
            activeAsset: 'assests/images/report_button_active.png',
            inactiveAsset: 'assests/images/report_button_inactive.png',
            onTap: () => onTap(1),
          ),
          _NavItem(
            label: 'Settings',
            active: currentIndex == 2,
            activeAsset: 'assests/images/settings_button_active.png',
            inactiveAsset: 'assests/images/settings_button_inactive.png',
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool active;
  final String? activeAsset;
  final String? inactiveAsset;
  final IconData? inactiveIcon;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.active,
    required this.onTap,
    this.activeAsset,
    this.inactiveAsset,
    this.inactiveIcon,
  });

  @override
  Widget build(BuildContext context) {
    final content = active
        ? Image.asset(activeAsset!, width: 22, height: 22)
        : inactiveAsset != null
            ? Image.asset(inactiveAsset!, width: 22, height: 22)
            : Icon(inactiveIcon, color: const Color(0xFFB0B0B0), size: 22);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              content,
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active
                      ? const Color(0xFF2F80ED)
                      : const Color(0xFFB0B0B0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
