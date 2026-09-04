import 'package:flutter/material.dart';

class ExerciseCatalogItem {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final IconData icon;
  final bool available;

  const ExerciseCatalogItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.icon,
    this.available = true,
  });
}

const exerciseCatalog = <ExerciseCatalogItem>[
  ExerciseCatalogItem(
    id: 'squat',
    name: 'Squat',
    subtitle: 'Leg strength • form focus',
    description: 'Live depth and movement feedback.',
    icon: Icons.directions_run_rounded,
  ),
  ExerciseCatalogItem(
    id: 'push_up',
    name: 'Push-up',
    subtitle: 'Upper body • form focus',
    description: 'Track elbow depth and body alignment.',
    icon: Icons.fitness_center_rounded,
  ),
  ExerciseCatalogItem(
    id: 'lunge',
    name: 'Lunge',
    subtitle: 'Leg control • balance',
    description: 'Track knee depth and torso control.',
    icon: Icons.accessibility_new_rounded,
  ),
];

ExerciseCatalogItem exerciseById(String id) =>
    exerciseCatalog.firstWhere((e) => e.id == id);
