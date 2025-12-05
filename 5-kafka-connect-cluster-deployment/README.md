# Kafka Connect Cluster Deployment

## Overview

Distributed Kafka Connect cluster deployed using Docker Compose with production-grade security, JMX monitoring, and Datagen source connector for testing data generation.

## Architecture

- **Deployment**: Docker Compose on Kafka Connect instance (10.0.1.80)
- **Image**: confluentinc/cp-kafka-connect:8.1.0
- **Ports**:
  - 8083: REST API
  - 8079: JMX metrics (Prometheus)
- **Security**: SASL_SSL with SCRAM-SHA-512
- **Connectors**: Datagen Source Connector

## Components

### 1. Kafka Connect Worker

Distributed mode worker that:

- Connects to Kafka cluster from Section 2
- Stores connector configurations in Kafka topics
- Exposes REST API for connector management
- Provides JMX metrics for monitoring

### 2. Datagen Connector

Source connector that generates test data:

- Pre-installed via confluent-hub
- Supports multiple quickstart schemas (users, pageviews, etc.)
- Used for testing and demonstrations

### 3. JMX Exporter

Prometheus JMX exporter for monitoring:

- Exposes Kafka Connect metrics
- Integrated with observability stack
- Monitors connector and task status

## Prerequisites

### 1. SSH Access to Connect Instance

```bash
ssh -i kafka-key.pem ubuntu@10.0.1.80
```

### 2. Stop Conflicting Services

```bash
sudo systemctl stop confluent-kafka-connect
sudo systemctl disable confluent-kafka-connect
```

### 3. Install Docker and Docker Compose

```bash
# Update system
sudo apt-get update

# Install prerequisites
sudo apt-get install -y ca-certificates curl gnupg

# Add Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

## Deployment

### Step 1: Prepare SSL Certificates

```bash
# Ensure Docker can read SSL certificates
sudo chmod +x /var/ssl/private
sudo chmod 644 /var/ssl/private/*.jks
```

### Step 2: Deploy Kafka Connect

```bash
# On Connect instance
cd ~
docker compose up -d --build
```

### Step 3: Verify Deployment

```bash
# Check container status
docker ps

# View logs
docker compose logs -f kafka-connect

# Check REST API
curl http://localhost:8083/ | jq
```

Expected output:

```json
{
  "version": "8.1.0-ccs",
  "commit": "ad96a4ab36bd815bac5069d4cc428d234a9f955a",
  "kafka_cluster_id": "TBmK1unHRFKxrYU-6y9rMQ"
}
```

### Step 5: Verify Connector Plugins

```bash
curl http://localhost:8083/connector-plugins | jq
```

Should list Datagen and other available connectors.

### Step 6: Verify JMX Metrics

```bash
curl -s http://localhost:8079/metrics | head -n 20
```

Should show Prometheus-format metrics.

## Kafka Connect Configuration

### Internal Kafka Topics

Kafka Connect uses these topics for coordination:

- `connect-configs` - Connector configurations
- `connect-offsets` - Source connector offsets
- `connect-status` - Connector and task status

Replication factor: 3 (for high availability)

### Security Configuration

```yaml
CONNECT_SECURITY_PROTOCOL: "SASL_SSL"
CONNECT_SASL_MECHANISM: "SCRAM-SHA-512"
CONNECT_SASL_JAAS_CONFIG: 'org.apache.kafka.common.security.scram.ScramLoginModule 
  required username="kafka_connect" password="kafka_connect-secret";'
```

### Worker Configuration

- **Group ID**: `connect-cluster`
- **Key Converter**: JsonConverter
- **Value Converter**: JsonConverter
- **REST Port**: 8083
- **JMX Port**: 8079

## Kafka Connect REST API Operations

### Cluster Information

#### Get Connect Cluster Info

```bash
curl http://10.0.1.80:8083/ | jq
```

#### List Connector Plugins

```bash
curl http://10.0.1.80:8083/connector-plugins | jq
```

#### Validate Connector Config

```bash
curl -X PUT http://10.0.1.80:8083/connector-plugins/DatagenConnector/config/validate \
  -H "Content-Type: application/json" \
  -d '{
    "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
    "kafka.topic": "test-topic",
    "quickstart": "users",
    "tasks.max": "1"
  }' | jq
```

### Connector CRUD Operations

#### Create Connector

```bash
curl -X POST http://10.0.1.80:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "datagen-users",
    "config": {
      "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
      "kafka.topic": "topic-1",
      "quickstart": "users",
      "key.converter": "org.apache.kafka.connect.storage.StringConverter",
      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter.schemas.enable": "false",
      "max.interval": "1000",
      "iterations": "10000000",
      "tasks.max": "1"
    }
  }' | jq
```

#### List All Connectors

```bash
curl http://10.0.1.80:8083/connectors | jq
```

#### Get Connector Details

```bash
curl http://10.0.1.80:8083/connectors/datagen-users | jq
```

#### Get Connector Status

```bash
curl http://10.0.1.80:8083/connectors/datagen-users/status | jq
```

#### Update Connector Configuration

```bash
curl -X PUT http://10.0.1.80:8083/connectors/datagen-users/config \
  -H "Content-Type: application/json" \
  -d '{
    "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
    "kafka.topic": "topic-1",
    "quickstart": "users",
    "max.interval": "500",
    "iterations": "10000000",
    "tasks.max": "1"
  }' | jq
```

#### Delete Connector

```bash
curl -X DELETE http://10.0.1.80:8083/connectors/datagen-users
```

### Connector Task Operations

#### List Connector Tasks

```bash
curl http://10.0.1.80:8083/connectors/datagen-users/tasks | jq
```

#### Get Task Status

```bash
curl http://10.0.1.80:8083/connectors/datagen-users/tasks/0/status | jq
```

#### Restart Task

```bash
curl -X POST http://10.0.1.80:8083/connectors/datagen-users/tasks/0/restart
```

#### Restart Connector

```bash
curl -X POST http://10.0.1.80:8083/connectors/datagen-users/restart
```

## HTTP Source Connector Example

Create HTTP source connector that polls the Kafka REST API:

```bash
curl -X POST http://10.0.1.80:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "http-source-topics-list",
    "config": {
      "connector.class": "com.github.castorm.kafka.connect.http.HttpSourceConnector",
      "http.request.url": "http://10.0.1.144:2020/topics",
      "http.request.method": "GET",
      "kafka.topic": "topic-1",
      "http.timer.interval.millis": "60000",
      "tasks.max": "1"
    }
  }' | jq
```

## Integration with Observability

### Prometheus Configuration

Prometheus scrapes Kafka Connect metrics:

```yaml
- job_name: 'kafka-connect'
  static_configs:
    - targets:
      - '10.0.1.80:8079'
      labels:
        role: 'connect'
```

### Grafana Dashboard Metrics

- Total Worker Count
- Connector Count (Running/Failed)
- Task Count (Running/Failed)
- Heap Usage
- GC Time
- Producer Incoming Byte Rate

## Configuration Files

```
5-kafka-connect-cluster-deployment/
├── Dockerfile                    # Custom image with Datagen
├── docker-compose.yml            # Service definition
├── kafka-connect-rest-output.txt # Sample REST API operations
└── notes.txt                     # Deployment notes
```

## Troubleshooting

### Issue: Container fails to start

**Solution:**

```bash
# Check logs
docker compose logs kafka-connect

# Common issues:
# - SSL certificates not accessible
# - Kafka cluster not reachable
# - SASL credentials incorrect
```

### Issue: Cannot connect to Kafka cluster

**Solution:**

1. Verify broker hostnames in docker-compose.yml `extra_hosts`
2. Check security group allows traffic from Connect instance
3. Test connectivity: `telnet 10.0.1.7 9092`

### Issue: SSL handshake failure

**Solution:**

1. Verify truststore path: `/etc/kafka/secrets/kafka_connect.truststore.jks`
2. Check truststore password in docker-compose.yml
3. Ensure certificates were copied during Ansible deployment

### Issue: Connector fails to start

**Solution:**

```bash
# Check connector status
curl http://localhost:8083/connectors/connector-name/status | jq

# View error details in trace field
# Common issues:
# - Topic doesn't exist
# - Insufficient permissions
# - Invalid configuration
```

### Issue: JMX metrics not accessible

**Solution:**

1. Verify KAFKA_OPTS includes JMX agent configuration
2. Check port 8079 is exposed in docker-compose.yml
3. Test metrics: `curl http://localhost:8079/metrics`

## Design Decisions

1. **Docker Deployment**: Easier management and version control vs. native installation
2. **Distributed Mode**: Scalable architecture (can add more workers)
3. **Datagen Connector**: Reliable test data generation without external dependencies
4. **JMX Exporter**: Integrated monitoring with Prometheus
5. **Configuration in Kafka**: Centralized storage for high availability

## Performance Considerations

- Increase `KAFKA_HEAP_OPTS` for heavy workloads
- Adjust `tasks.max` based on throughput requirements
- Monitor heap usage and GC time in Grafana
- Consider multiple workers for horizontal scaling

## Security Considerations

 **Production Recommendations:**

- Restrict REST API access (firewall/proxy)
- Enable HTTPS for REST API
- Use secrets management for credentials
- Regularly update connector plugins
- Enable SSL verification for production CA certificates

## Next Steps

After deploying Kafka Connect:

1. Create sample connectors for testing
2. Verify connectors appear in Grafana dashboards
3. Monitor connector and task status
4. Test connector operations via REST API
5. Review project documentation and prepare final submission
