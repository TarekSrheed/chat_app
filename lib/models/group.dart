import 'package:flutter/material.dart';

class Trip {
  final String id;
  final String title;
  final List<String> categories;

  final List<String> activities;
  final List<String> program;
  final int duration;

  final bool isForFamilies;

  const Trip({
    required this.id,
    required this.categories,
    required this.activities,
    required this.duration,
    required this.isForFamilies,
    required this.program,
    required this.title,
  });
}
