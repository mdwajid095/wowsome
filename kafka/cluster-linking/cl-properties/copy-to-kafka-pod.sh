# Function to copy configuration files to the Kafka pod

NS=ffm-prod

copy_to_kafka_pod() {
  local file=$1
  kubectl cp "$file" kafka-thales-0:/tmp -n "$NS"
}

# Copy the necessary files
copy_to_kafka_pod source.properties
copy_to_kafka_pod consumer.offset.sync.json
copy_to_kafka_pod destination.properties
copy_to_kafka_pod topic-filters.json
copy_to_kafka_pod acls-filters.json
