# Run the local API with Docker

The phone and this computer must be on the same Wi-Fi network. Find the
computer's Wi-Fi IPv4 address with `Get-NetIPAddress -InterfaceAlias Wi-Fi
-AddressFamily IPv4` in PowerShell.

1. Copy `.env.example` to `.env` and set `PUBLIC_BASE_URL` to
   `http://<Wi-Fi IPv4>:8080`.
2. From `delivery_server`, run `docker compose up -d`.
3. Check startup with `docker compose logs api` and `docker compose ps`.
4. Set the dev URL in `delivery_app/lib/config/environment.dart` to the same
   `PUBLIC_BASE_URL`, then run `flutter run --flavor dev -t lib/main_dev.dart`
   on an Android device.

MySQL uses the isolated `delivery_server_mysql_data` Docker volume. On first
startup, Docker imports `SQL_GENERATE.txt` into `mydb`. Later `docker compose
up -d` commands keep the data. `docker compose down` stops the containers and
preserves the volume.

To inspect the database without Workbench:

```powershell
docker compose exec db mysql -uroot -proot -e "SHOW TABLES FROM mydb;"
```

The current Flutter registration and Admin screens still use local prototype
state. Starting the API does not connect those screens to MySQL automatically.
