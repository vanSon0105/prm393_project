import 'package:delivery_app/data/local/sharepreference/share_preference_repository.dart';
import 'package:delivery_app/di/repository_module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingUiState {
  const SettingUiState({this.selectedLanguage = 'en-US'});

  final String selectedLanguage;

  SettingUiState copyWith({String? selectedLanguage}) {
    return SettingUiState(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
    );
  }
}

class SettingUiNotifier extends Notifier<SettingUiState> {
  @override
  SettingUiState build() => const SettingUiState();

  Future<void> logout() async {
    final prefers = ref.read(appSharePreferencesProvider);
    await prefers.saveData(null);
  }

  void selectLanguage(String value) {
    state = state.copyWith(selectedLanguage: value);
  }
}

final settingUiProvider = NotifierProvider<SettingUiNotifier, SettingUiState>(
  SettingUiNotifier.new,
);
