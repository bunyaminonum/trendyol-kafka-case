# Observability Stack

## Overview

Comprehensive monitoring and alerting solution for the Kafka cluster using Prometheus, Grafana, and Alertmanager. This stack provides real-time visibility into cluster health, performance metrics, and automated alerting for critical issues.

## Architecture

### Components

**Deployed on Observability Instance (10.0.1.144)**

1. **Prometheus** - Metrics collection and storage
2. **Grafana** - Metrics visualization and dashboards
3. **Alertmanager** - Alert routing and notification
4. **Kafka Exporter** - Additional Kafka-specific metrics
5. **Node Exporter** - System-level metrics (deployed on all nodes)

## Monitoring Coverage

### 1. Infrastructure Monitoring (Node Exporter)

Deployed on all nodes:

- 4 Kafka Brokers (10.0.1.7, 10.0.1.244, 10.0.2.185, 10.0.2.91)
- 3 Kafka Controllers (10.0.1.240, 10.0.2.70, 10.0.3.250)
- 1 Kafka Connect (10.0.1.80)

**Metrics:** CPU, Memory, Disk, Network, System Load

### 2. Kafka Cluster Monitoring (JMX Exporter)

**Kafka Brokers (Port 8080)**

- Partition count, topic count, under-replicated partitions
- Bytes in/out per second, request rate
- Disk usage, CPU usage, memory usage

**Kafka Controllers (Port 8079)**

- Current leader, controller count
- KRaft commit latency
- Disk usage, CPU usage, memory usage

### 3. Kafka Connect Monitoring (Port 8079)

- Total worker count
- Connector status (running, failed)
- Task status (running, failed)
- Producer incoming byte rate
- Heap usage, GC time

## Prometheus Configuration

### Scrape Jobs

```yaml
scrape_configs:
  - job_name: 'prometheus'         # Self-monitoring
  - job_name: 'node_exporter'      # Infrastructure (8 nodes)
  - job_name: 'kafka'              # Brokers + Controllers
  - job_name: 'kafka-connect'      # Kafka Connect cluster
  - job_name: 'kafka-exporter'     # Additional Kafka metrics
```

## Grafana Dashboards

### 1. Kafka Broker Dashboard

**Metrics Displayed:**

- Partition Count
- Topic Count
- Under Replicated Partitions
- Broker Bytes In Per Sec
- Broker Bytes Out Per Sec
- Request Per Sec
- Disk Usage
- CPU Usage
- Memory Usage

### 2. Kafka Connect Dashboard

**Metrics Displayed:**

- Total Worker Count
- Total Connector Count
- Running Connector Count
- Failed Connector Count
- Total Task Count
- Running Task Count
- Failed Task Count
- Heap Usage
- GC Time
- CPU Usage
- Memory Usage
- Producer Incoming Byte Rate

## Prerequisites

### 1. Node Exporter Installation

Install on all Kafka nodes (Brokers, Controllers, Connect):

```bash
cd 3-observability/node_exporter

# Update hosts.yml with actual IPs
ansible-playbook -i hosts.yml install-node-exporter.yml
```

### 2. Observability Instance Access

SSH into the observability node:

```bash
ssh -i kafka-key.pem ubuntu@10.0.1.144
```

## Deployment

### Step 1: Transfer Configuration Files

Transfer the observability directory to the observability instance:

```bash
scp -i "kafka-key.pem" kafka-key.pem ubuntu@<observability-node-ip>:/home/ubuntu/kafka-key.pem
```

### Step 2: Install Docker and Docker Compose

```bash

sudo apt-get update

sudo apt-get install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker $USER
newgrp docker

docker --version
docker run hello-world
```

### Step 3: Deploy Observability Stack

```bash
cd ~/3-observability
docker-compose up -d
```

### Step 4: Verify Deployment

```bash
# Check running containers
docker-compose ps

# Expected output:
# prometheus       - Running on port 9090
# grafana          - Running on port 3000
# alertmanager     - Running on port 9093
# kafka-exporter   - Running on port 9308
```

## Access URLs

- **Grafana**: http://`<observability-node-public-ip>`:3000

  - Default credentials: `admin` / `admin`
- **Prometheus**: http://10.0.1.144:9090
- **Alertmanager**: http://10.0.1.144:9093

## Configuration Files

```
3-observability/
├── docker-compose.yml               # Orchestration file
├── prometheus/
│   ├── prometheus.yml               # Prometheus configuration
│   └── alerts.yml                   # Alert rules
├── grafana/
│   ├── provisioning/
│   │   └── datasources.yml          # Prometheus datasource
│   ├── kafka_dashboard.json         # Kafka Broker dashboard
│   ├── kafka_connect_dashboard.json # Kafka Connect dashboard
│   └── kakfa_dashboard.json         # Additional dashboard
├── alertmanager/
│   └── config.yml                   # Alert routing configuration
└── node_exporter/
    ├── hosts.yml                    # Ansible inventory
    └── install-node-exporter.yml    # Ansible playbook
```

## Grafana Dashboard Setup

### Import Dashboards

1. Navigate to Grafana → Dashboards → Import
2. Upload JSON files from `grafana/` directory:
   - `kafka_dashboard.json`
   - `kafka_connect_dashboard.json`

### Configure Datasource

Datasource is auto-provisioned via `grafana/provisioning/datasources.yml`:

```yaml
- name: Prometheus
  type: prometheus
  url: http://prometheus:9090
  isDefault: true
```

## Alertmanager Configuration

### Webhook Receiver

Default configuration sends alerts to a webhook endpoint:

```yaml
receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://127.0.0.1:5001/'
```

### Customize Alert Routing

Edit `alertmanager/config.yml` to configure:

- Email notifications
- Slack integration
- PagerDuty integration
- Custom webhooks

**Example - Slack Integration:**

```yaml
receivers:
  - name: 'slack-notifications'
    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#kafka-alerts'
        title: 'Kafka Alert'
```

## Verification and Testing

### Check Prometheus Targets

Visit: http://10.0.1.144:9090/targets

All targets should show status: **UP**

### Test Alert Rules

```bash
# SSH to observability instance
ssh -i kafka-key.pem ubuntu@10.0.1.144

# View active alerts
curl http://localhost:9090/api/v1/alerts | jq
```

### Query Metrics

Example PromQL queries:

```promql
# Kafka broker count
count(kafka_server_replicamanager_leadercount)

# Under-replicated partitions
sum(kafka_server_replicamanager_underreplicatedpartitions)

# CPU usage across all nodes
100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

## Troubleshooting

### Issue: Prometheus targets are down

**Solution:**

1. Verify JMX exporter is running on Kafka nodes
2. Check security group allows port 8080 (brokers), 8079 (controllers/connect), 9100 (node_exporter)
3. Test connectivity: `telnet 10.0.1.7 8080`

### Issue: Node exporter not responding

**Solution:**

```bash
# SSH to the problematic node
ssh -i kafka-key.pem ubuntu@<node-ip>

# Check service status
sudo systemctl status node_exporter

# Restart if needed
sudo systemctl restart node_exporter
```

## Next Steps

After observability stack is operational:

1. Review all dashboards and ensure metrics are flowing
2. Test alert rules by simulating failures
3. Proceed to **Section 4: Operation Excellence (REST API)**
4. Add Kafka Connect monitoring after **Section 5** deployment
