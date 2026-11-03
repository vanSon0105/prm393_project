# Admin APIs and finance screens

## Available in `delivery_server`

| Screen | Method and path | Purpose |
| --- | --- | --- |
| Drivers | `GET /api/admin/drivers` | Approved drivers, including document URLs |
| Driver account requests | `GET /api/admin/drivers/requests` | Pending driver registrations and document URLs |
| Driver account requests | `POST /api/admin/drivers/{id}/approve` | Approve (`{"driver_id": id, "status": true}`) or reject (`{"driver_id": id, "status": false, "reason": "..."}`) |

The Admin overview and Users tab still include sample/local user and metric data. They need additional list and summary APIs when those screens move to live data.

## Needed for the new Admin screens

These endpoints **do not exist yet**. The Flutter screens are wired to this contract and show an error/retry state until the backend implements it.
Flutter web needs server CORS support for the app origin and `GET`, `POST`, and `PUT` requests. This PR leaves the Go server unchanged; the backend team can add CORS alongside the finance endpoints.

| Screen | Method and path | Request | Response |
| --- | --- | --- | --- |
| Bank details | `GET /api/admin/bank-account` | — | `{"data":{"bank_name":"...","account_number":"...","account_holder":"...","transfer_note":"..."}}` (`data: null` before setup) |
| Bank details | `PUT /api/admin/bank-account` | Same four fields | `200` with `{"data":{...}}` |
| Top-up requests | `GET /api/admin/top-up-requests?status=pending` | — | `{"data":[{"id":1,"driver_id":5,"driver_name":"...","amount":50000,"status":"pending","transfer_reference":"...","proof_url":"...","created_at":"2026-11-03T10:00:00Z"}]}` |
| Top-up requests | `POST /api/admin/top-up-requests/{id}/approve` | `{}` | `200` with updated request data |
| Top-up requests | `POST /api/admin/top-up-requests/{id}/reject` | `{"reason":"..."}` | `200` with updated request data |

Amounts are integer VND. Approval must verify a real bank transfer and atomically change the pending request to approved **and** add the amount to `DriverWallet`. A repeated approval must never credit the wallet twice. Rejection requires a reason and must not change the wallet. The backend needs an audit trail, unique transfer reference handling, and admin authentication/authorization for these endpoints. The current server has no request-level admin authorization, so wallet-crediting endpoints must not be exposed until that is added.

For a future driver submission screen, also provide `GET /api/driver/bank-account` (the current recipient details) and `POST /api/driver/top-up-requests` (amount, transfer reference, and proof). The driver must only be able to read their own requests. The current task adds only the two Admin screens.
