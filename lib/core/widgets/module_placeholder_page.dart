import 'package:flutter/material.dart';

class ModulePlaceholderPage extends StatelessWidget {
  const ModulePlaceholderPage({required this.name, super.key});
  final String name;

  @override
  Widget build(BuildContext context) => Center(child: Text(name));
}
