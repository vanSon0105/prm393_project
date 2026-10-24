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
