import 'package:delivery_app/features/auth/domain/entities/role.dart';

class AppState {
  final Role? role;
  final int? profileId;

  AppState({this.role, this.profileId});

  AppState copyWith({Role? role, int? profileId}) {
    return AppState(
      role: role ?? this.role,
      profileId: profileId ?? this.profileId,
    );
  }
}
