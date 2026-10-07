import 'package:flutter_flavor/flutter_flavor.dart';

import '../base/utils/extension_list.dart';

enum FlavorValue { dev, prod }

extension FlavorValueEx on FlavorValue {
  bool get supportCharles {
    switch (this) {
      case FlavorValue.dev:
        return true;
      case FlavorValue.prod:
        return false;
    }
  }
}

extension Environment on FlavorValue {
  static FlavorValue of(String? env) =>
      FlavorValue.values.firstWhereOrNull((flavor) => flavor.name == env) ??
      FlavorValue.dev;

  static const _baseUrl = 'BASE_URL';

  String get _name {
    switch (this) {
      case FlavorValue.dev:
        return 'dev';
      case FlavorValue.prod:
        return 'prod';
    }
  }

  Map<String, String> get _variables {
    switch (this) {
      case FlavorValue.dev:
        return {_baseUrl: 'https://jsonplaceholder.typicode.com/'};
      case FlavorValue.prod:
        return {_baseUrl: 'https:prod'};
    }
  }

  static FlavorValue get flavor => of(FlavorConfig.instance.name);

  static void configFlavor(FlavorValue value) {
    FlavorConfig(name: value._name, variables: value._variables);
  }

  static String get baseUrl => FlavorConfig.instance.variables[_baseUrl] ?? '';

  static String get iOSAppId => '';
}
