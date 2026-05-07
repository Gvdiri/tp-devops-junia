#!/usr/bin/env sh
set -eu

NAMESPACE="${K8S_NAMESPACE:-default}"
IMAGE_NAME="${IMAGE_NAME:-robo2575/node-api}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

kubectl apply -n "$NAMESPACE" -f k8S/mysql-secret.yaml
kubectl apply -n "$NAMESPACE" -f k8S/mysql-pvc.yaml
kubectl apply -n "$NAMESPACE" -f k8S/mysql-deployment.yaml
kubectl apply -n "$NAMESPACE" -f k8S/mysql-service.yaml

kubectl apply -n "$NAMESPACE" -f k8S/api-deployment.yaml
kubectl apply -n "$NAMESPACE" -f k8S/api-service.yaml
kubectl apply -n "$NAMESPACE" -f k8S/api-hpa.yaml
kubectl set image deployment/node-api node-api="${IMAGE_NAME}:${IMAGE_TAG}" -n "$NAMESPACE"
kubectl rollout status deployment/node-api -n "$NAMESPACE" --timeout=180s

kubectl apply -f k8S/monitoring/namespace.yaml
kubectl apply -f k8S/monitoring
kubectl rollout status deployment/prometheus -n monitoring --timeout=180s
kubectl rollout status deployment/grafana -n monitoring --timeout=180s
