import 'package:delivery_app/data/local/sharepreference/share_preference_repository.dart';
import 'package:delivery_app/di/repository_module.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingUiState {
  const SettingUiState({
    this.selectedLanguage = 'en-US',
    this.selectedMapType = 'default',
  });

  final String selectedLanguage;
  final String selectedMapType;

  SettingUiState copyWith({String? selectedLanguage, String? selectedMapType}) {
    return SettingUiState(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      selectedMapType: selectedMapType ?? this.selectedMapType,
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

  void selectMapType(String value) {
    state = state.copyWith(selectedMapType: value);
  }
}

final settingUiProvider = NotifierProvider<SettingUiNotifier, SettingUiState>(
  SettingUiNotifier.new,
);
