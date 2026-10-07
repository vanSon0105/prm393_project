# Delivery app
Project use riverpod flutter

# Environment
Flutter : 3.47.6
Android Studio Meerkat | 2024.3.1
JDK 17
XCode Version 26.3 (17C529)

# Generate assets
dart run build_runner build --delete-conflicting-outputs

# Generate resource
dart pub run easy_localization:generate -f keys -o locale_keys.g.dart

# Flavor
```txt
dev
prod
```

## Run
dev
```
flutter run apk -t lib/main_dev.dart --flavor=dev
```

prod
```
flutter run apk -t lib/main_prod.dart --flavor=prod
```

## Build
dev
```
flutter build apk -t lib/main_dev.dart --flavor=dev
flutter build appbundle -t lib/main_dev.dart --flavor=dev

```

prod
```
flutter build apk -t lib/main_prod.dart --flavor=prod
flutter build appbundle -t lib/main_prod.dart --flavor=prod

```

### Release
```
flutter build apk -t lib/main_prod.dart --flavor=prod
flutter build appbundle -t lib/main_prod.dart --flavor=prod
```