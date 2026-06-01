# Kubernetes Local Run

Panduan ini untuk menjalankan stack SmartFarming di Kubernetes lokal seperti MicroK8s.

## Prasyarat

Aktifkan add-on dasar jika memakai MicroK8s:

```bash
microk8s enable dns hostpath-storage metrics-server registry
```

Catatan:
- `hostpath-storage` dipakai oleh PVC PostgreSQL dan MinIO.
- `metrics-server` dipakai oleh HPA.
- `registry` dipakai untuk image `localhost:32000/...`.

## Build dan Push Image Lokal

```bash
docker build -t localhost:32000/farm-data-service:latest farm-data-service
docker build -t localhost:32000/storage-service:latest storage-service
docker build -t localhost:32000/frontend:latest frontend-app
docker build -t localhost:32000/iot-simulator:latest iot-simulator

docker push localhost:32000/farm-data-service:latest
docker push localhost:32000/storage-service:latest
docker push localhost:32000/frontend:latest
docker push localhost:32000/iot-simulator:latest
```

Jika registry MicroK8s sedang tidak tersedia, import image langsung ke containerd MicroK8s:

```bash
docker save -o /tmp/farm-data-service.tar localhost:32000/farm-data-service:latest
docker save -o /tmp/storage-service.tar localhost:32000/storage-service:latest
docker save -o /tmp/frontend.tar localhost:32000/frontend:latest
docker save -o /tmp/iot-simulator.tar localhost:32000/iot-simulator:latest

microk8s ctr image import /tmp/farm-data-service.tar
microk8s ctr image import /tmp/storage-service.tar
microk8s ctr image import /tmp/frontend.tar
microk8s ctr image import /tmp/iot-simulator.tar
```

Jika memakai command MicroK8s, ganti `kubectl` menjadi `microk8s kubectl`.

## Deploy

Terapkan resource pendukung lokal lebih dulu:

```bash
kubectl apply -f k8s-local/
```

Lalu deploy aplikasi:

```bash
kubectl apply -f farm-data-service/farmdata-deploy.yaml
kubectl apply -f storage-service/storage-deploy.yaml
kubectl apply -f iot-simulator/simulator-deploy.yaml
kubectl apply -f frontend-app/frontend-deploy.yaml
```

## Cek Status

```bash
kubectl get pods -n farm-db-svc
kubectl get pods -n storage-svc
kubectl get pods -n frontend-svc
kubectl get hpa -A
```

## Akses dari Browser

Dashboard:

```bash
kubectl -n frontend-svc port-forward svc/frontend 8080:80
```

Jika browser dibuka dari mesin lain atau dari host di luar terminal server, buka port-forward ke semua interface:

```bash
kubectl -n frontend-svc port-forward --address 0.0.0.0 svc/frontend 8080:80
```

Lalu akses:

```text
http://<IP-server-aktif>:8080
```

Catatan: service `frontend` bertipe `ClusterIP`, jadi tidak bisa langsung diakses lewat IP node tanpa `port-forward`, `NodePort`, atau `Ingress`.

Farm Data API docs:

```bash
kubectl -n farm-db-svc port-forward svc/farm-data-service 8000:8000
```

Storage API docs:

```bash
kubectl -n storage-svc port-forward svc/storage-service 8001:8000
```

MinIO console:

```bash
kubectl -n storage-svc port-forward svc/minio-local 9001:9001
```

Endpoint lokal setelah port-forward:
- Dashboard: http://localhost:8080
- Farm Data API docs: http://localhost:8000/docs
- Storage API docs: http://localhost:8001/docs
- MinIO console: http://localhost:9001

Credential MinIO lokal:
- User: `admin`
- Password: `minio123`

## Cleanup

```bash
kubectl delete -f frontend-app/frontend-deploy.yaml
kubectl delete -f iot-simulator/simulator-deploy.yaml
kubectl delete -f storage-service/storage-deploy.yaml
kubectl delete -f farm-data-service/farmdata-deploy.yaml
kubectl delete -f k8s-local/
```
