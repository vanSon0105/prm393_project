import 'package:delivery_app/base/widget/app_scaffold.dart';
import 'package:delivery_app/features/auth/domain/entities/role_model.dart';
import 'package:delivery_app/features/auth/login/widget/role_item.dart';
import 'package:delivery_app/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showAppbar: false,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: ColorName.backgroundDefaultColor,
              padding: EdgeInsets.all(5),
              child: Row(
                children: Role.values
                    .map((e) => Expanded(flex: 1, child: RoleItem(role: e)))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
