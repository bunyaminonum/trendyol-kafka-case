## 4. Kafka REST API Service

### Overview

A production-ready REST API service for managing Kafka cluster operations using AdminClient.

### Architecture

- **Language**: Python 3.9
- **Framework**: Flask
- **Port**: 2020
- **Deployment**: Docker Container on D (observability instance)
- **Security**: SASL_SSL with SCRAM-SHA-512

### Build and Deployment

```bash
# Build Docker image
cd kafka-api
docker build -t kafka-rest-api:latest .

# Run container
docker run -d \
  --name kafka-api \
  -p 2020:2020 \
  -e BOOTSTRAP_SERVERS='10.0.1.7:9092,10.0.1.244:9092' \
  kafka-rest-api:latest
```

### API Endpoints

#### Topic Management

- `GET /brokers` - List all brokers
- `POST /topics` - Create new topic
- `GET /topics` - List all topics
- `GET /topics/{topic_name}` - Get topic details
- `PUT /topics/{topic_name}` - Update topic configuration

#### Consumer Group Management

- `GET /consumer-groups` - List all consumer groups
- `GET /consumer-groups/{group_id}` - Get group details

### Testing

See test commands in deployment section above.
