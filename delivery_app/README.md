# Delivery app
Project use riverpod flutter

## Admin UI

The three admin screens (dashboard, driver directory, account requests) are
available at `/admin`. The route is intentionally separate from the current
login and main navigation so the team can connect it to role based access later.
Use `AppNavigate.instance.gotoAdmin()` or navigate to `AppRoute.admin.rawValue`.

The admin screens currently use local sample data. Search, selected screen,
pending requests, and dashboard metrics are managed with Riverpod. Approve and
reject only update the in-memory sample state; they do not call a backend or
persist across app restarts. Add an authenticated repository before using these
actions in production.

To preview these screens on the Android dev flavor, run
`flutter run -d emulator-5554 --flavor dev -t lib/main.dart`. The regular
`main_dev.dart` and `main_prod.dart` entrypoints still start at the splash page.

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
