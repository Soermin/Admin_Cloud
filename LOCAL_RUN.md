# Local Run

Jalankan seluruh stack lokal dengan Docker Compose:

```bash
docker compose -f docker-compose.local.yml up --build
```

Endpoint lokal:

- Dashboard: http://localhost:8080
- Farm Data API docs: http://localhost:8000/docs
- Storage API docs: http://localhost:8001/docs
- MinIO console: http://localhost:9001

Credential MinIO lokal:

- User: `admin`
- Password: `minio123`

Service yang dijalankan:

- `postgres` untuk database `farming`
- `minio` untuk storage S3-compatible bucket `reports`
- `farm-data-service` pada port `8000`
- `storage-service` pada port `8001`
- `frontend` pada port `8080`
- `iot-simulator` yang mengirim telemetry setiap 60 detik

Untuk berhenti:

```bash
docker compose -f docker-compose.local.yml down
```

Untuk reset semua data lokal:

```bash
docker compose -f docker-compose.local.yml down -v
```

Untuk menjalankan versi Kubernetes lokal, lihat `KUBERNETES_LOCAL.md`.
