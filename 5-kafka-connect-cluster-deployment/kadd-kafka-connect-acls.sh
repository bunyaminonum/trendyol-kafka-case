#!/bin/bash

BOOTSTRAP_SERVER="ip-10-0-1-7.eu-central-1.compute.internal:9092"
CLIENT_CONFIG="/etc/kafka/client.properties"
PRINCIPAL="User:kafka_connect"

echo "🔐 Adding ACLs for $PRINCIPAL..."

# Topic ACLs (Tüm topic'ler)
sudo kafka-acls --bootstrap-server $BOOTSTRAP_SERVER \
    --command-config $CLIENT_CONFIG \
    --add --allow-principal $PRINCIPAL \
    --operation All --topic '*'

# Consumer Group ACLs (Zaten var ama emin olmak için)
sudo kafka-acls --bootstrap-server $BOOTSTRAP_SERVER \
    --command-config $CLIENT_CONFIG \
    --add --allow-principal $PRINCIPAL \
    --operation All --group '*'

# Cluster ACLs
sudo kafka-acls --bootstrap-server $BOOTSTRAP_SERVER \
    --command-config $CLIENT_CONFIG \
    --add --allow-principal $PRINCIPAL \
    --operation All --cluster

# TransactionalId ACLs
sudo kafka-acls --bootstrap-server $BOOTSTRAP_SERVER \
    --command-config $CLIENT_CONFIG \
    --add --allow-principal $PRINCIPAL \
    --operation All --transactional-id '*'

echo "✅ All ACLs added for kafka_connect user!"
echo ""
echo "Verify ACLs:"
sudo kafka-acls --bootstrap-server $BOOTSTRAP_SERVER \
    --command-config $CLIENT_CONFIG \
    --list --principal $PRINCIPAL