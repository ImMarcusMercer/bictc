import 'dart:math' as math;

import 'package:bictc/app/design_system.dart';
import 'package:flutter/material.dart';

/// Navigation tabs and the separate voice-help action share one accessible bar.
class HelpNavigationBar extends StatelessWidget {
  const HelpNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onHelpRequested,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onHelpRequested;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(13) / 13;
            final helpSize = math
                .min(
                  96 + math.max(0, textScale - 1) * 32,
                  constraints.maxWidth - 4 * AppDesign.minTouchTarget,
                )
                .clamp(88.0, 160.0)
                .toDouble();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _tab('Places', Icons.place_outlined, Icons.place, 0),
                  _tab('Map', Icons.map_outlined, Icons.map, 1),
                  SizedBox(
                    key: const Key('request-voice-help'),
                    width: helpSize,
                    height: textScale > 1.3
                        ? math.max(helpSize, 52 + 4 * 14.3 * textScale)
                        : helpSize,
                    child: Tooltip(
                      message: 'Request voice assistance',
                      child: FilledButton(
                        onPressed: onHelpRequested,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          padding: const EdgeInsets.all(8),
                          shape: textScale > 1.3
                              ? RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                )
                              : const CircleBorder(),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.support_agent, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              'I need help!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _tab('Community', Icons.people_outline, Icons.people, 2),
                  _tab('More', Icons.menu, Icons.menu, 3),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _tab(String label, IconData icon, IconData selectedIcon, int index) {
    final selected = selectedIndex == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        onTap: () => onDestinationSelected(index),
        child: InkWell(
          onTap: () => onDestinationSelected(index),
          borderRadius: BorderRadius.circular(AppDesign.controlRadius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      selected ? selectedIcon : icon,
                      color: selected ? AppColors.primary : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? AppColors.primary : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
