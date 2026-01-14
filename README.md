# CI/CD Python API – Deployment Guide

This document explains how to build, deploy, manage, and clean up the API and PostgreSQL database using Docker, Kubernetes, and Kustomize.

---

## 1. Build Docker Images

### Basic build

```bash
docker build -t api .
```

### Improved build using environments (multi-stage Dockerfile)

Build the **development** image:

```bash
docker build -f Dockerfile --target prod -t lean-dev .
```

Build the **production** image:

```bash
docker build -f Dockerfile --target prod -t lean-prod .
```

---

## 2. Deploy to Kubernetes with Kustomize

Apply all Kubernetes manifests (with Helm enabled):

```bash
kustomize build --enable-helm . | kubectl apply -f -
```

---

## 3. PostgreSQL Management

### Create the database

```bash
kubectl exec -it postgresql-0 -n blazing -- psql -U admin -c "CREATE DATABASE blazing;"
```

### List databases

```bash
kubectl exec -it postgresql-0 -n blazing -- psql -U admin -l
```

---

## 4. Restart the API Deployment

After updating secrets, config maps, or images:

```bash
kubectl rollout restart deployment api-deployment -n blazing
```

---

## 5. Access the API Locally (Port Forwarding)

Expose the API service to your local machine:

```bash
kubectl -n blazing port-forward services/api-service 8080:80
```

The API will be available at:

```
http://localhost:8080
```

---

## 6. Push Docker Image to Docker Hub

```bash
docker push juandago/api:latest
```

Make sure you are logged in first:

```bash
docker login
```

---

## 7. Cleanup – Delete Deployments and Pods

If you have finished testing and want to remove everything so it no longer appears in `docker ps` or `kubectl get pods`:

### Delete API deployment and service

```bash
kubectl delete deployment api-deployment -n blazing
kubectl delete service api-service -n blazing
```

### Delete PostgreSQL database

```bash
kubectl delete statefulset postgresql -n blazing
```

---

## Notes

* Ensure you are using the correct Kubernetes context before applying or deleting resources.
* PostgreSQL credentials must match the values defined in Kubernetes Secrets.
* For a full reset, also delete related PersistentVolumeClaims (PVCs) if needed.

---

✅ End of README
