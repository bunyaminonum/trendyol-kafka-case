FROM confluentinc/cp-kafka-connect:8.1.0

USER root

# 1. JMX Exporter Setup
RUN mkdir -p /opt/jmx-exporter && \
    curl -o /opt/jmx-exporter/jmx_prometheus_javaagent.jar \
    https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.20.0/jmx_prometheus_javaagent-0.20.0.jar && \
    curl -o /opt/jmx-exporter/config.yaml \
    https://raw.githubusercontent.com/confluentinc/jmx-monitoring-stacks/6.1.0-post/shared-assets/jmx-exporter/kafka_connect.yml

# 2. HTTP Connector - JAR dosyalarını direkt indir
RUN mkdir -p /usr/share/confluent-hub-components/kafka-connect-http && \
    cd /usr/share/confluent-hub-components/kafka-connect-http && \
    curl -O https://repo1.maven.org/maven2/com/github/castorm/kafka-connect-http/0.8.11/kafka-connect-http-0.8.11.jar && \
    curl -O https://repo1.maven.org/maven2/com/github/castorm/kafka-connect-http-plugin/0.8.11/kafka-connect-http-plugin-0.8.11.jar

USER appuser