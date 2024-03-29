# SRE@Kyndryl

## SRE Public Labs - OBSSIM

* Version: `0.1.2`
* License: `MIT`

### Architecture

![arch](./images/sre-public-labs-obssim.png)

### Learning objectives

* Learn the basics on monitoring and alerting tools

* Learn how to deploy a monitoring platform to a Kubernetes cluster

* Learn how use Prometheus, Grafana, Alertmanager, and exporters together

### Pre-requisite knowledge

* Familiarity with Kubernetes

* Basic notions on Node.js (JavaScript) programming language

* Good understanding of YAML (Yet Another Markup Language)

### Kubernetes cluster

This lab runs on any K8s cluster with few adjusts on the ingresses, we recommend using a free trial account on either the Google Cloud Platform or Microsoft Azure.

You can create one through this [documentation](https://cloud.google.com/free). You can download and install the Google CLI `gcloud` by checking this [document](https://cloud.google.com/sdk/docs/install).

Alternatively, you can create one through this [documentation](https://azure.microsoft.com/free/). You can download and install the Azure CLI `az` by checking this [document](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli).

#### Google Kubernetes Engine

In case you use a GCP account for this lab, we provided the Google Kubernetes Engine (GKE) recommended configuration below:

* GKE Configuration

| **Parameter** | **Value** |
|:--------------------------------|:--------------------------------|
| GKE mode | `Standard with static K8s version` |
| Location type | `Zonal` |
| Release channel | `None` |
| Kubernetes version | `1.27.x` |
| Number of nodes | `3` |
| Machine type | `e2-standard-2` |
| Image type | `cos_containerd` |
| | |

* GKE cluster creation

You can create a K8s cluster for this lab with the following commands:

```shell
gcloud auth login
gcloud container clusters create cluster-1 --no-enable-autoupgrade --enable-service-externalips --enable-kubernetes-alpha --region=<your_closest_region> --cluster-version=<k8s_version> --machine-type=e2-standard-2 --monitoring=NONE
```

* kubectl configuration

You can configure your local `kubectl` environment and credentials with the following command:

```shell
gcloud container clusters get-credentials cluster-1 --zone <your_closest_region> --project <your_project_id>
```

#### Azure Kubernetes Services

In case you use a Azure account for this lab, we provided the Azure Kubernetes Services (AKS) recommended configuration below:

* AKS Configuration

| **Parameter** | **Value** |
|:--------------------------------|:--------------------------------|
| AKS SKU | `Basic`, `Free` |
| Type | `Microsoft.ContainerService/ManagedClusters` |
| Location | `East US` (closest to you`) |
| Auto Upgrade Type | `Disabled` |
| Kubernetes version | `1.27.x` |
| Node pools | `1 node pool` |
| Node size | `Standard_B4ms` |
| Network type | `Kubenet` |
| Network policy | `calico` |
| | |

* AKS cluster creation

You can create a K8s cluster for this lab with the following commands:

```shell
az login
az account set --subscription <your_subscription_id>
az aks create -g <your_resource_group_name> -n cluster-1 --auto-upgrade-channel none --network-plugin kubenet --network-policy calico --location <your_closest_location> --node-vm-size Standard_B4ms --kubernetes-version <1.24.x> 
```

* kubectl configuration

You can configure your local `kubectl` environment and credentials with the following command:

```shell
az aks get-credentials --resource-group <your_resource_group_name> --name cluster-1
```

### Contents

* Application

Folder: `microservices`

| **File / folder** | **Description** |
|:--------------------------------|:--------------------------------|
| k8s | `Kubernetes manifest files` |
| docker-app.sh | `Shell script to deploy the app into a K8s cluster` |
| docker-build.sh | `Shell script used to build and push the Docker image` |
| Dockerfile | `Docker commands to build the image` |
| server.js | `Node.js application` |
| | |

* Monitoring platform

Folder: `monitoring`

| **File / folder** | **Description** |
|:--------------------------------|:--------------------------------|
| grafana | `Kubernetes manifest files to deploy Grafana` |
| kube-state | `Kuberenetes manifest files to deploy kube-state-metrics (KSM)` |
| prom-alert | `Kubernetes manifest files to deploy Alermanager` |
| prom-blackbox | `Kubernetes manifest files to deploy Blackbox exporter` |
| prom-node | `Kubernetes manifest files to deploy Node exporter` |
| prom-server | `Kubernetes manifest files to deploy Prometheus Server` |
| deploy-monitoring.sh | `Shell script to deploy the monitoring platform into a K8s cluster` |
| promql-samples.md | `Examples of PromQL metrics that be used on Prometheus and Grafana` |
| | |

### Installation

* Application deployment

The dummy Node.js application is located in this Docker hub [repo](https://hub.docker.com/repository/docker/rod4n4m1/node-api). To deploy this app to your K8s cluster, use the following commands:

```shell
cd microservices
./deploy-app.sh
```

The `deploy-app.sh` script will create a *Deployment* in the `default` namespace that has 3 *pods*. Also, it will create a `NodePort` *service* and a GKE `LoadBalancer` *service* in the same namespace.

* Monitoring platform deployment

To deploy Prometheus Server, Alertmanager, Grafana, kube-state-metrics, Node exporter, and Blackbox exporter, use the following commands:

```shell
cd microservices
./deploy-monitoring.sh
```

The `deploy-monitoring.sh` script will create the following objects inside the K8s cluster:

| **Component** | **namespace** | **Objects** |
|:--------------------------------|:--------------------------------|:--------------------------------|
| Prometheus | *monitoring* | `ClusterRole`, `ClusterRoleBinding`, `Deployment`, `StorageClass`, `PersistentVolumeClaim`, `ConfigMap`, `Service`, and GKE `Ingress` |
| Alertmanager | *monitoring* | `Deployment`, `ConfigMap`, and `Service` |
| Node exporter | *monitoring* | `DeamonSet` and `Service` |
| Blackbox exporter | *monitoring* | `Deployment`, `ConfigMap`, and `Service` |
| Grafana | *monitoring* | `Deployment`, `ConfigMap`, `Service`, and GKE `Ingress` |
| kube-state-metrics | *kube-system* | `ClusterRole`, `ClusterRoleBinding`, `Deployment`, `ServiceAccount`, and `Service` |
| | | |

### Configuration

* App runtime config

This app follows most of the Twelve-Factor App framework, so you can pass environment variables to change its behavior. For instance, you can change the listener port and the memory threshold.

File: **`microservices/k8s/node-api-deployment.yaml`**

```yaml
env:
  - name: PORT
    value: "8081"
  - name: MEMORY_THRESHOLD
    value: "50000000"
```

If you change the web server port, you will need to change the services (NodePort and LoadBalancer) as well.

* Prometheus rules

File: **`monitoring/prom-server/prometheus-configmap.yaml`**

There are two alerts configured for the lab.

```yaml
groups:
- name: OBSSIM Alerts
  rules:
  - alert: HighPodMemory
    expr: (container_memory_usage_bytes{namespace="default",image!="k8s.gcr.io/pause:3.5",name!=""} / (1024*1024) > 14)
    for: 5m
    labels:
      severity: critical
    annotations:
      title: Pods memory usage
      description: "Pods with high memory utilization\n VALUE = {{ printf \"%.2f\" $value}} MB\n LABELS = {{ $labels }}"
      message: "Pods have consumed over 14 Mbytes - (instance(s): {{  $labels.pod }})"
      summary: "Pods High Memory Usage - (instance(s): {{ $labels.pod }})"
      runbook_url: "https://ansibletower.example.com"
      dashboard_url: "https://grafana.example.com"
  - alert: AppHTTPResolveTimePercentile
    expr: (quantile_over_time(0.90,probe_http_duration_seconds{instance="http://<load-balancer-vip>:60000/fortune",phase="resolve"}[28d]) > 0.5)
    for: 5m
    labels:
      severity: critical
    annotations:
      title: App response time
      description: "App with high resolve time\n VALUE = {{ printf \"%.2f\" $value}} ms\n LABELS = {{ $labels }}"
      message: "App have high resolve time over SLO - (instance(s): {{  $labels.pod }})"
      summary: "App with high resolve time - (instance(s): {{ $labels.pod }})"
      runbook_url: "https://ansibletower.example.com"
      dashboard_url: "https://grafana.example.com"
```

* Prometheus config

File: **`monitoring/prom-server/prometheus-configmap.yaml`**

The Prometheus Server configuration is in the `prometheus.yml` section in this manifest file.

Global parameters are under the `global` sub-section:

```yaml
global:
  scrape_interval: 10s
  evaluation_interval: 10s
```

Alerting parameters are under the `alerting` sub-section:

```yaml
alerting:
  alertmanagers:
  - scheme: http
    static_configs:
    - targets:
      - "alertmanager-service.monitoring.svc:9093"
```

Monitoring targets and their configurations are under the `scrape_configs` sub-section:

```yaml
scrape_configs:
  # Blackbox exporter section (Static)
  - job_name: 'blackbox-exporter'
    scrape_interval: 10m
    metrics_path: /probe
    params:
      module: [http_2xx]
  ...
```

* Alertmanager templates

File: **`monitoring/prom-alert/alertmanager-templateconfig.yaml`**

The Alertmanager templates for the notification systems is in this manifest file. `default.tmpl` has the general definitions of an alert for all notification systems. `pagerduty.tmpl` has specific template fields for a PagerDuty alert. `slack.tmpl` has the specific template fields for a Slack message.

* Alertmanager config

File: **`monitoring/prom-alert/alertmanager-configmap.yaml`**

The Alertmanager global configuration is in this manifest file. It's pre-configured for PagerDuty and Slack integrations. You need to have a Slack app and PagerDuty instance available.

To configure the PagerDuty integration, you need to provide the integration key:

```yaml
pagerduty_configs:
  - service_key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

To configure the Slack integration, you need to provide the Slack incoming webhook URL and channel name:

```yaml
slack_configs:
- api_url: https://hooks.slack.com/services/XXXXXXXXXXX/YYYYYYYYYYY/000000000000000000000000
  channel: '#obssim-demo'
```

You can find more information on setting a PagerDuty development instance at this [link](https://developer.pagerduty.com/).

And you can consult instructions on configuring a Slack incoming webhook at this [link](https://api.slack.com/messaging/webhooks).

* Grafana config

File: **`monitoring/grafana/grafana-config.yaml`**

The `Grafana` global configuration is described in this manifest file.

```yaml
prometheus.yaml: |-
  {
      "apiVersion": 1,
      "datasources": [
          {
             "access":"proxy",
              "editable": true,
              "name": "prometheus",
              "orgId": 1,
              "type": "prometheus",
              "url": "http://prometheus-service.monitoring.svc:9090",
              "version": 1
          }
      ]
  }
```

It defines a `Grafana` datasource to be the Prometheus server inside the same namespace.

## End of document
