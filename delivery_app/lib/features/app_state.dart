import 'package:delivery_app/features/auth/domain/entities/role.dart';

class AppState {
  final Role? role;

  AppState({this.role});

  AppState copyWith({Role? role}) {
    return AppState(role: role ?? this.role);
  }
}
