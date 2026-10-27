import 'package:delivery_app/features/auth/domain/entities/role.dart';
import 'package:delivery_app/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class RoleItem extends StatelessWidget {
  const RoleItem({super.key, required this.role, this.selected = false});

  final Role role;
  final bool selected;

  ColorFilter? get colorSelected =>
      selected ? ColorFilter.mode(ColorName.primary, BlendMode.srcIn) : null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: selected ? ColorName.white : Colors.transparent,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        children: [
          role.getIcon(colorFilter: colorSelected),
          const SizedBox(height: 3),
          Text(role.title),
        ],
      ),
    );
  }
}
