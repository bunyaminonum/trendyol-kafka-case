from flask import Flask, jsonify, request
from confluent_kafka.admin import AdminClient, ConfigResource, NewTopic
import os

app = Flask(__name__)

# --- Configuration ---
BOOTSTRAP_SERVERS = os.environ.get('BOOTSTRAP_SERVERS', '10.0.1.7:9092,10.0.1.244:9092,10.0.2.91:9092')

kafka_conf = {
    'bootstrap.servers': BOOTSTRAP_SERVERS,
    'security.protocol': 'SASL_SSL',
    'sasl.mechanism': 'SCRAM-SHA-512',
    'sasl.username': 'admin',
    'sasl.password': 'admin-secret-password',
    'enable.ssl.certificate.verification': False,
    'ssl.endpoint.identification.algorithm': 'none'
}

# ============================================================================
# HEALTH CHECK
# ============================================================================

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({"status": "UP"}), 200


# ============================================================================
# BROKER MANAGEMENT
# ============================================================================

@app.route('/brokers', methods=['GET'])
def list_brokers():
    """
    GET /brokers
    Returns the list of Kafka brokers in the cluster.
    """
    try:
        admin_client = AdminClient(kafka_conf)
        metadata = admin_client.list_topics(timeout=10)

        brokers = []
        for broker_id, broker_metadata in metadata.brokers.items():
            brokers.append({
                "id": broker_id,
                "host": broker_metadata.host,
                "port": broker_metadata.port
            })

        return jsonify({
            "brokers": brokers,
            "count": len(brokers),
            "status": "success"
        })
    except Exception as e:
        return jsonify({
            "error": str(e),
            "status": "failed"
        }), 500


# ============================================================================
# TOPIC MANAGEMENT
# ============================================================================

@app.route('/topics', methods=['GET'])
def list_topics():
    """
    GET /topics
    Returns the list of Kafka topics with basic information.
    """
    try:
        admin_client = AdminClient(kafka_conf)
        metadata = admin_client.list_topics(timeout=10)

        topics_info = []
        for topic_name, topic_metadata in metadata.topics.items():
            # Skip internal topics
            if not topic_name.startswith('_') and not topic_name.startswith('connect-'):
                partition_count = len(topic_metadata.partitions)
                replication_factor = 0
                if partition_count > 0:
                    first_partition = list(topic_metadata.partitions.values())[0]
                    replication_factor = len(first_partition.replicas)

                topics_info.append({
                    "topic_name": topic_name,
                    "partition_count": partition_count,
                    "replication_factor": replication_factor
                })

        return jsonify({
            "topics": topics_info,
            "count": len(topics_info),
            "status": "success"
        })
    except Exception as e:
        return jsonify({
            "error": str(e),
            "status": "failed"
        }), 500


@app.route('/topics', methods=['POST'])
def create_topic():
    """
    POST /topics
    Creates a new Kafka topic.

    Request body example:
    {
        "topic_name": "topic-1",
        "partitions": 3,
        "replication_factor": 3,
        "configs": {
            "retention.ms": "604800000",
            "compression.type": "gzip"
        }
    }
    """
    try:
        admin_client = AdminClient(kafka_conf)

        # Get request data
        data = request.get_json()
        if not data:
            return jsonify({
                "error": "Request body is required",
                "status": "failed"
            }), 400

        # Validate required fields
        topic_name = data.get('topic_name')
        partitions = data.get('partitions', 1)
        replication_factor = data.get('replication_factor', 1)
        configs = data.get('configs', {})

        if not topic_name:
            return jsonify({
                "error": "topic_name is required",
                "status": "failed"
            }), 400

        # Create NewTopic object
        new_topic = NewTopic(
            topic=topic_name,
            num_partitions=partitions,
            replication_factor=replication_factor,
            config=configs
        )

        # Create the topic
        fs = admin_client.create_topics([new_topic])

        # Wait for operation to complete
        for topic, f in fs.items():
            try:
                f.result(timeout=10)
                return jsonify({
                    "message": f"Topic '{topic_name}' created successfully",
                    "topic_name": topic_name,
                    "partitions": partitions,
                    "replication_factor": replication_factor,
                    "configs": configs,
                    "status": "success"
                }), 201
            except Exception as e:
                return jsonify({
                    "error": f"Failed to create topic: {str(e)}",
                    "status": "failed"
                }), 500

    except Exception as e:
        return jsonify({
            "error": str(e),
            "status": "failed"
        }), 500


@app.route('/topics/<topic_name>', methods=['GET'])
def describe_topic(topic_name):
    """
    GET /topics/{topic_name}
    Returns detailed information about a specific topic.
    """
    try:
        admin_client = AdminClient(kafka_conf)
        metadata = admin_client.list_topics(timeout=10)

        # Check if topic exists
        if topic_name not in metadata.topics:
            return jsonify({
                "error": f"Topic '{topic_name}' not found",
                "status": "failed"
            }), 404

        topic_metadata = metadata.topics[topic_name]

        # Get partition details
        partitions = []
        for partition_id, partition_metadata in topic_metadata.partitions.items():
            partitions.append({
                "partition_id": partition_id,
                "leader": partition_metadata.leader,
                "replicas": partition_metadata.replicas,
                "isrs": partition_metadata.isrs
            })

        # Get topic configurations
        resource = ConfigResource('TOPIC', topic_name)
        configs_result = admin_client.describe_configs([resource])

        topic_configs = {}
        for res, future in configs_result.items():
            config_entries = future.result()
            for config_name, config_entry in config_entries.items():
                topic_configs[config_name] = {
                    "value": config_entry.value,
                    "is_default": config_entry.is_default,
                    "is_sensitive": config_entry.is_sensitive
                }

        return jsonify({
            "topic_name": topic_name,
            "partition_count": len(partitions),
            "replication_factor": len(partitions[0]["replicas"]) if partitions else 0,
            "partitions": partitions,
            "configurations": topic_configs,
            "status": "success"
        })
    except Exception as e:
        return jsonify({
            "error": str(e),
            "status": "failed"
        }), 500


@app.route('/topics/<topic_name>', methods=['PUT'])
def alter_topic_config(topic_name):
    """
    PUT /topics/{topic_name}
    Alters topic-level configurations.

    Request body example:
    {
        "configs": {
            "retention.ms": "604800000",
            "compression.type": "gzip",
            "min.insync.replicas": "1"
        }
    }
    """
    try:
        admin_client = AdminClient(kafka_conf)

        # Get configurations from request body
        data = request.get_json()
        if not data or 'configs' not in data:
            return jsonify({
                "error": "Request body must contain 'configs' object",
                "example": {
                    "configs": {
                        "retention.ms": "604800000",
                        "compression.type": "gzip"
                    }
                },
                "status": "failed"
            }), 400

        configs = data['configs']

        # Create ConfigResource for the topic
        resource = ConfigResource('TOPIC', topic_name)

        # Set new configuration values
        for config_name, config_value in configs.items():
            resource.set_config(config_name, str(config_value))

        # Apply the configuration changes
        result = admin_client.alter_configs([resource])

        # Wait for the operation to complete
        for res, future in result.items():
            future.result(timeout=10)

        return jsonify({
            "message": f"Topic '{topic_name}' configuration updated successfully",
            "topic_name": topic_name,
            "updated_configs": configs,
            "status": "success"
        })
    except Exception as e:
        return jsonify({
            "error": str(e),
            "status": "failed"
        }), 500


# ============================================================================
# CONSUMER GROUP MANAGEMENT
# ============================================================================

@app.route('/consumer-groups', methods=['GET'])
def list_consumer_groups():
    """
    GET /consumer-groups
    Returns the list of all consumer groups in the cluster.
    """
    try:
        admin_client = AdminClient(kafka_conf)

        # List consumer groups 
        groups_result = admin_client.list_consumer_groups()
        groups = groups_result.result()

        consumer_groups = []
        for group in groups.valid:
            consumer_groups.append({
                "group_id": group.group_id,
                "is_simple_consumer_group": group.is_simple_consumer_group,
                "state": str(group.state) if hasattr(group, 'state') else "UNKNOWN"
            })

        return jsonify({
            "consumer_groups": consumer_groups,
            "count": len(consumer_groups),
            "status": "success"
        })
    except Exception as e:
        return jsonify({
            "error": str(e),
            "status": "failed"
        }), 500

@app.route('/consumer-groups/<group_id>', methods=['GET'])
def describe_consumer_group(group_id):
    """
    GET /consumer-groups/{group_id}
    Returns detailed information about a specific consumer group.
    """
    try:
        admin_client = AdminClient(kafka_conf)

        # Describe consumer group 
        groups_result = admin_client.describe_consumer_groups([group_id])

        group_details = None
        for group, future in groups_result.items():
            group_description = future.result()

            members = []
            for member in group_description.members:
                assignment = []
                if member.assignment:
                    for topic_partition in member.assignment.topic_partitions:
                        assignment.append({
                            "topic": topic_partition.topic,
                            "partition": topic_partition.partition
                        })

                members.append({
                    "member_id": member.member_id,
                    "client_id": member.client_id,
                    "host": member.host,
                    "assignment": assignment
                })

            group_details = {
                "group_id": group_description.group_id,
                "state": str(group_description.state),
                "protocol_type": group_description.protocol_type,
                "protocol": group_description.protocol,
                "coordinator": {
                    "id": group_description.coordinator.id,
                    "host": group_description.coordinator.host,
                    "port": group_description.coordinator.port
                },
                "members": members,
                "member_count": len(members)
            }

        if group_details:
            return jsonify({
                **group_details,
                "status": "success"
            })
        else:
            return jsonify({
                "error": f"Consumer group '{group_id}' not found",
                "status": "failed"
            }), 404

    except Exception as e:
        return jsonify({
            "error": str(e),
            "status": "failed"
        }), 500

# ============================================================================
# MAIN
# ============================================================================

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=2020)