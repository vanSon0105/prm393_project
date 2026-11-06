# Admin APIs and finance screens

## Available in delivery_server

| Screen | Method and path | Purpose |
| --- | --- | --- |
| Drivers | `GET /api/admin/drivers` | Approved drivers and documents |
| Driver account requests | `GET /api/admin/drivers/requests` | Pending registrations |
| Driver account requests | `POST /api/admin/drivers/{id}/approve` | Approve or reject with a reason |
| Admin bank details | `GET /api/{profile_id}/bank-info` | Read the signed-in admin's bank details |
| Admin bank details | `POST /api/{profile_id}/bank-info` | Update bank details with multipart form data |

The bank response uses `data.bank_name`, `data.bank_account_number`, `data.bank_account_name`, and `data.bank_qr_code`. The update request uses the same field names; `bank_qr_code` is an optional image file. The admin profile ID comes from the login response.

## Still needed for top-up requests

The current backend does not provide these endpoints. The top-up screen shows an error and retry action until they are implemented.

| Method and path | Request | Response |
| --- | --- | --- |
| `GET /api/admin/top-up-requests?status=pending` | None | `{"data":[{"id":1,"driver_id":5,"driver_name":"...","amount":50000,"status":"pending","transfer_reference":"...","proof_url":"...","created_at":"2026-11-03T10:00:00Z"}]}` |
| `POST /api/admin/top-up-requests/{id}/approve` | `{}` | Updated request |
| `POST /api/admin/top-up-requests/{id}/reject` | `{"reason":"..."}` | Updated request |

Amounts are integer VND. Approval must verify a real bank transfer and atomically mark the request approved and credit DriverWallet. Repeated approval must not credit twice. Rejection requires a reason and must not change the wallet. These endpoints also need admin authorization and an audit trail.

The Admin overview and Users tab still contain sample/local data. Flutter web requires CORS support from the server origin.
