# Admin and driver finance APIs

The Flutter screens use the routes currently registered in `delivery_server/go-ride-hailing-api.go`.

| Screen | Method and path | Purpose |
| --- | --- | --- |
| Drivers | `GET /api/admin/drivers` | Approved drivers and documents |
| Driver account requests | `GET /api/admin/drivers/requests` | Pending registrations |
| Driver account requests | `POST /api/admin/drivers/{id}/approve` | Approve or reject with a reason |
| Admin bank account | `GET /api/{admin_profile_id}/bank-info` | Read saved bank details |
| Admin bank account | `POST /api/{admin_profile_id}/bank-info` | Save multipart bank details and optional QR image |
| Driver top-up | `GET /api/admin/bank-info` | Show the first admin bank account to the driver |
| Driver top-up | `POST /api/driver/topup` | Submit a request and receipt |
| Driver top-up | `GET /api/driver/{driver_id}/topup/requests` | List that driver's requests |
| Driver top-up | `GET /api/topup/{transaction_id}` | Read one request |
| Driver top-up | `PUT /api/driver/topup/{transaction_id}/update` | Update a rejected request |
| Admin top-up | `GET /api/admin/topup/requests` | List all requests; optional `status` filter |
| Admin top-up | `PATCH /api/admin/topup/{transaction_id}/review` | Approve or reject |

Top-up list responses are JSON arrays. Detail, create, update, review and bank responses wrap the result in `data`. A top-up row contains `transaction_id`, `driver_id`, `driver_name`, `balance`, `image_transaction`, `active`, `status`, `time`, and `reject_reason`. Status is `PENDING`, `APPROVED`, or `REJECTED`.

To create or update a request, send multipart fields `driver_id`, integer `balance`, and `image_transaction`. To review, send `{"status":true}` for approval or `{"status":false,"reason":"..."}` for rejection. Driver registration and resubmission send `license_plate_expired_date` as `YYYY-MM-DD`.

The Admin overview and Users tab still contain sample/local data. Flutter web requires CORS support from the server origin.
