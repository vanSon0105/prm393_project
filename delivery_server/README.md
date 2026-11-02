# Delivery server

## Structure

- `cmd/api/main.go`: entry point.
- `internal/server/server.go`: database connection and HTTP routes.
- `internal/server/admin.go`, `auth.go`, `trips.go`, `tracking.go`, `roles.go`: handlers grouped by feature.
- `internal/server/state.go`: shared types and helpers.
- `db/schema.sql`: database schema and seed data (previously `SQL_GENERATE.txt`).
- `docs/api_examples.md`: example requests.
- `testdata/`: sample driver documents.
- `image/`: images served by `/image/` and written during driver registration.

## Run locally

1. Import `db/schema.sql` into MySQL. The default connection is `root:root@tcp(127.0.0.1:3306)/mydb`; set `DB_DSN` to override it.
2. From `delivery_server`, run `go run ./cmd/api`.
3. Run the Flutter dev app with your computer's Wi-Fi IPv4 address:

   ```powershell
   flutter run --flavor dev -t lib/main_dev.dart --dart-define=API_BASE_URL=http://<YOUR_WIFI_IP>:8080
   ```

   Run the Flutter command from `delivery_app`. The phone and computer must be on the same Wi-Fi. For an Android emulator, use `http://10.0.2.2:8080` instead of a Wi-Fi IP.

`GET /api/admin/drivers` returns an array of approved drivers (`active = 1`). Each item has `driver_id`, `full_name`, `phone_number`, `address`, `avatar_url`, and document image URLs. The endpoint currently has no authentication middleware and does not provide a vehicle plate, rating, or online status.

Set `PUBLIC_BASE_URL` when the API is behind a container or proxy so returned image URLs point to the address the phone can reach.

Flutter web served from `localhost` or `127.0.0.1` is allowed to call the API. For another web origin, add its full origin to the comma-separated `CORS_ALLOWED_ORIGINS` environment variable.

The Flutter Admin Drivers tab calls this endpoint. Other Admin widgets still use sample data.
