import 'package:flutter/material.dart';

class StepAchievement {
  final String id;
  final String titleKey;
  final String descKey;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0
  final String missionText;

  StepAchievement({
    required this.id,
    required this.titleKey,
    required this.descKey,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
    this.progress = 0.0,
    required this.missionText,
  });

  StepAchievement copyWith({
    bool? isUnlocked,
    double? progress,
  }) {
    return StepAchievement(
      id: id,
      titleKey: titleKey,
      descKey: descKey,
      icon: icon,
      color: color,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      missionText: missionText,
    );
  }
}
