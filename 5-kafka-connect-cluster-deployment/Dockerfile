FROM confluentinc/cp-kafka-connect:8.1.0

USER root

# 1. JMX Exporter Setup (Burası Aynen Kalsın)
RUN mkdir -p /opt/jmx-exporter && \
    curl -o /opt/jmx-exporter/jmx_prometheus_javaagent.jar \
    https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.20.0/jmx_prometheus_javaagent-0.20.0.jar && \
    curl -o /opt/jmx-exporter/config.yaml \
    https://raw.githubusercontent.com/confluentinc/jmx-monitoring-stacks/6.1.0-post/shared-assets/jmx-exporter/kafka_connect.yml

# 2. Datagen Connector Kurulumu (HTTP yerine bunu kullanıyoruz)
# Bu komut gerekli her şeyi otomatik indirir ve kurar.
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-datagen:0.6.0

USER appuser