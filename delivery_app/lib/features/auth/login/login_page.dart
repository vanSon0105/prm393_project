import 'dart:convert';

import 'package:delivery_app/features/auth/login/login_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer(
        builder: (context, ref, child) {
          final loginViewModel = ref.watch(loginViewModelProvider);
          return loginViewModel.when(
            data: (data) {
              return Container(
                color: Colors.cyan,
                child: Text(
                  data.posts.map((e) => jsonEncode(e.toJson())).join('\n'),
                ),
              );
            },
            error: (error, stack) {
              return Container(color: Colors.red);
            },
            loading: () {
              return Center(child: CircularProgressIndicator());
            },
          );
        },
      ),
    );
  }
}
