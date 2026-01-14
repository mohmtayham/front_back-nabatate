import 'package:flutter/material.dart';

class AppMenuItem {
  final String title;
  final IconData icon;
  final Widget screen;
  final Color color;
  final String? permission;

  const AppMenuItem({
    required this.title,
    required this.icon,
    required this.screen,
    this.color = Colors.white,
    this.permission,
  });
}
