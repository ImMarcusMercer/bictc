import 'package:flutter/material.dart';

enum AccessibilityNeed {
  wheelchair,
  visual,
  hearing,
  walker,
  senior,
  cognitive,
  sensory,
  chronic,
}

extension AccessibilityNeedDisplay on AccessibilityNeed {
  String get label => switch (this) {
    AccessibilityNeed.wheelchair => 'Wheelchair',
    AccessibilityNeed.visual => 'Visual',
    AccessibilityNeed.hearing => 'Hearing',
    AccessibilityNeed.walker => 'Crutches',
    AccessibilityNeed.senior => 'Senior',
    AccessibilityNeed.cognitive => 'Cognitive',
    AccessibilityNeed.sensory => 'Sensory',
    AccessibilityNeed.chronic => 'Chronic',
  };

  String get description => switch (this) {
    AccessibilityNeed.wheelchair => 'I use a wheelchair',
    AccessibilityNeed.visual => 'I have a visual impairment',
    AccessibilityNeed.hearing => 'I have a hearing impairment',
    AccessibilityNeed.walker => 'I use crutches or a walker',
    AccessibilityNeed.senior => 'I am a senior citizen',
    AccessibilityNeed.cognitive => 'I have cognitive access needs',
    AccessibilityNeed.sensory => 'I have sensory access needs',
    AccessibilityNeed.chronic => 'I have a chronic illness',
  };

  IconData get icon => switch (this) {
    AccessibilityNeed.wheelchair => Icons.accessible_rounded,
    AccessibilityNeed.visual => Icons.visibility_outlined,
    AccessibilityNeed.hearing => Icons.hearing_outlined,
    AccessibilityNeed.walker => Icons.assist_walker_outlined,
    AccessibilityNeed.senior => Icons.elderly_outlined,
    AccessibilityNeed.cognitive => Icons.psychology_outlined,
    AccessibilityNeed.sensory => Icons.graphic_eq_rounded,
    AccessibilityNeed.chronic => Icons.health_and_safety_outlined,
  };
}
