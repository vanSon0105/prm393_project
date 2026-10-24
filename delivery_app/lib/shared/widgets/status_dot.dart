import 'package:flutter/material.dart';

class StatusDot extends StatelessWidget {
  const StatusDot(this.color, {super.key});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
