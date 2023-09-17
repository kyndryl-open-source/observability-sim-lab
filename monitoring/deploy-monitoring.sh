#!/bin/bash

# Prometheus - create a namespace for monitoring
kubectl create namespace monitoring

# Prometheus Server - create a clusterrole and clusterrolebinding
kubectl create -f prom-server/prometheus-rbac.yaml

# Prometheus Server - create a configmap with prometheus server config
kubectl create -f prom-server/prometheus-configmap.yaml

# Prometheus Server - create a storage StorageClass
if [ $1 == "aks" ]; then
    kubectl create -f prom-server/aks-storage-class.yaml
elif [ $1 ==  "gke" ]; then 
    kubectl create -f prom-server/gke-storage-class.yaml
else
    echo "Please indicate the cloud provider in the first argument: aks or gke"
fi

# Prometheus Server - create a persistentVolumeClaim for prometheus
kubectl create -f prom-server/prometheus-pvc.yaml

# Prometheus Server - create a deployment for prometheus server
kubectl create  -f prom-server/prometheus-deployment.yaml

# Prometheus Server - check if prometheus servers is running
kubectl get deployments -n monitoring

# Prometheus Server - create a service to expose the prometheus console using a NodePort service
kubectl create -f prom-server/prometheus-service.yaml

# You can alse create a secure ingress for prometheus server, but out of scope for this demo
# kubectl create secret tls secure-ingress \
#    --namespace monitoring \
#    --key server.key \
#    --cert server.crt

# Prometheus Server - Create a service (basic ingress with external LB or LB only)
if [ $1 ==  "aks" ]; then
    kubectl create -f prom-server/prometheus-lb-service.yaml
elif [ $1 ==  "gke" ]; then 
    kubectl create -f prom-server/prometheus-basic-ingress.yaml
else
    echo "Please indicate the cloud provider in the first argument: aks or gke"
fi

# K8s - deploy kube-state-metrics
kubectl apply -f kube-state/

# AlertManager - create config maps
kubectl create -f prom-alert/alertmanager-configmap.yaml
kubectl create -f prom-alert/alertmanager-templateconfig.yaml

# AlertManager - create deployment
kubectl create -f prom-alert/alertmanager-deployment.yaml

# AlertManager - create service
kubectl create -f prom-alert/alertmanager-service.yaml

# Node exporter
# Node exporter - create daemonset
kubectl create -f prom-node/node-exporter-daemonset.yaml

# Node exporter - create service
kubectl create -f prom-node/node-exporter-service.yaml

# Blackbox exporter
# Blackbox exporter - create config map
kubectl create -f prom-blackbox/blackbox-exporter-configmap.yaml

# Blackbox exporter - create deployment
kubectl create -f prom-blackbox/blackbox-exporter-deployment.yaml

# Blackbox exporter - create service
kubectl create -f prom-blackbox/blackbox-exporter-service.yaml

# Blackbox exporter - test service
# kubectl -n monitoring port-forward svc/blackbox-service 9115:9115

# Grafana
# https://grafana.com/docs/grafana/latest/setup-grafana/installation/kubernetes/

# Grafana - create config map
kubectl create -f grafana/grafana-config.yaml

# Grafana - create deployment
kubectl create -f grafana/grafana-deployment.yaml

# Grafana - create service
kubectl create -f grafana/grafana-service.yaml

# Grafana - create basic ingress or LB service
if [ $1 == "aks" ]; then
    kubectl create -f grafana/grafana-lb-service.yaml
elif [ $1 ==  "gke" ]; then 
    kubectl create -f grafana/grafana-basic-ingress.yaml
else
    echo "Please indicate the cloud provider in the first argument: aks or gke"
fi


# Grafana - access UI
# kubectl -n monitoring port-forward svc/grafana-service 3000:3000
