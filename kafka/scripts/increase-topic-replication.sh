#!/bin/bash

# Inputs
TOPIC_NAME="your-topic-name"
REPLICATION_FACTOR=3
BROKER_LIST="1,2,3"
BOOTSTRAP_SERVER="localhost:9092"

# Step 1: Create topics.json
cat <<EOF > topics.json
{
  "topics": [
    {"topic": "$TOPIC_NAME"}
  ],
  "version": 1
}
EOF

# Step 2: Generate reassignment plan
kafka-reassign-partitions.sh \
  --bootstrap-server $BOOTSTRAP_SERVER \
  --topics-to-move-json-file topics.json \
  --generate \
  --replication-factor $REPLICATION_FACTOR \
  --broker-list $BROKER_LIST \
  --output-file reassignment.json

# Step 3: Execute reassignment
kafka-reassign-partitions.sh \
  --bootstrap-server $BOOTSTRAP_SERVER \
  --reassignment-json-file reassignment.json \
  --execute
