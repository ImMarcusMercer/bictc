import 'package:bictc/app/design_system.dart';
import 'package:bictc/features/needs/models/accessibility_need.dart';
import 'package:flutter/material.dart';

class AccessibilityNeedsScreen extends StatefulWidget {
  const AccessibilityNeedsScreen({
    required this.initialNeeds,
    required this.onSaved,
    super.key,
  });

  final Set<AccessibilityNeed> initialNeeds;
  final ValueChanged<Set<AccessibilityNeed>> onSaved;

  @override
  State<AccessibilityNeedsScreen> createState() =>
      _AccessibilityNeedsScreenState();
}

class _AccessibilityNeedsScreenState extends State<AccessibilityNeedsScreen> {
  late final Set<AccessibilityNeed> _selected = {...widget.initialNeeds};

  void _toggle(AccessibilityNeed need) {
    setState(() {
      if (!_selected.add(need)) _selected.remove(need);
    });
  }

  void _save() {
    widget.onSaved({..._selected});
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final count = _selected.length;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final largeText = textScale > 1.4;
    final cardHeight = 164.0 + ((textScale - 1).clamp(0, 2) * 90);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Accessibility Needs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ColoredBox(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF3984C4),
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          'No sign-in needed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Personalize place recommendations for your practical access needs.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3984C4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_box_outlined,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$count ${count == 1 ? 'need' : 'needs'} selected',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What are your needs?',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Select all that apply. You can change this anytime.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: largeText ? 600 : 230,
                mainAxisExtent: cardHeight,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _needCard(AccessibilityNeed.values[index]),
                childCount: AccessibilityNeed.values.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No account is required. Your selections stay in this app session and are used only to personalize discovery.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save My Needs'),
        ),
      ),
    );
  }

  Widget _needCard(AccessibilityNeed need) {
    final selected = _selected.contains(need);
    return Semantics(
      key: Key('need-${need.name}'),
      button: true,
      selected: selected,
      label: '${need.label}. ${need.description}',
      child: Material(
        color: selected ? const Color(0xFFE8F0FE) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.cardRadius),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => _toggle(need),
          borderRadius: BorderRadius.circular(AppDesign.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(need.icon, size: 34, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  need.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  need.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                if (selected) ...[
                  const SizedBox(height: 5),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.accessible,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Selected',
                        style: TextStyle(
                          color: AppColors.accessible,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
