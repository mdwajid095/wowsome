# Kafka Cluster Setup Preparation

This guide provides step-by-step instructions for setting up and configuring a Kafka cluster, including generating necessary certificates and deploying Zookeeper, Kafka, and Schema Registry.

## Steps

1. **Write Configuration File**
   - Ensure the configuration file includes the correct DNS settings.

2. **Generate CSR and Key**
   - Use the script `generate-key-csr.sh` to generate the Certificate Signing Request (CSR) and key.

3. **Generate PEM**
   - Use the CSR to generate the PEM file.

4. **Create Kafka Internal Certificates**
   - Run the script `create-kafka-secret.sh` to create Kafka internal certificates.

5. **Create Other Required Certificates**
   - Generate additional certificates such as `password-encoder-secret` and credentials.

6. **Deploy Services**
   - Deploy Zookeeper, Kafka, and Schema Registry.

## Important Notes

1. **Kafka Broker Capacity**
   - Ensure Kafka has the data capacity per broker as per the source cluster. If created with fewer brokers, increasing the number of brokers after cluster linking creation will not be beneficial. All replicas will already be seated on the brokers available at the time of cluster linking creation. To distribute over all brokers, you must recreate the cluster linking by deleting the existing one.

2. **Schema Registry Exposure**
   - The Schema Registry needs to be externally exposed as the schema-exporter will be deployed at the source side. It needs to be accessible from the source cluster.

## Configuration Properties

Add the following properties to both the source and destination schema/Kafka clusters:

```yaml
enableSchemaExporter: true    # Only in schema CR
passwordEncoder:              # Both schema and Kafka CR
  secretRef: password-encoder-secret
```

 
For more info/validation, `explore BIN DIRECTORY.`

Cluster Linking Doc: https://docs.confluent.io/operator/current/blueprints/cob-cluster-linking.html

---
## Destination initiated cluster linking setup commnad
 ```yaml
Note: Commnad need to run inside destination kafka cluster pod

#1 create kafka-cluster-links
kafka-cluster-links --bootstrap-server kafka.cl-ffm-prod.svc.cluster.local:9071 --create --link sample --command-config /tmp/destination.properties --config-file /tmp/source.properties  --consumer-group-filters-json-file /tmp/consumer.offset.sync.json --topic-filters-json-file /tmp/topic-filters.json --acl-filters-json-file /tmp/acls-filters.json
 
#2 list/describe the kafka-cluster-links
kafka-cluster-links --list --bootstrap-server kafka.cl-ffm-prod.svc.cluster.local:9071 --command-config /tmp/destination.properties
kafka-cluster-links --describe --bootstrap-server kafka.cl-ffm-prod.svc.cluster.local:9071 --command-config /tmp/destination.properties
 
#3 list/describe kafka-mirrors topics
kafka-mirrors --list --link sample --bootstrap-server kafka.cl-ffm-prod.svc.cluster.local:9071 --command-config /tmp/destination.properties
kafka-mirrors --describe --links sample --bootstrap-server kafka.cl-ffm-prod.svc.cluster.local:9071 --command-config /tmp/destination.properties
 
#4 consumer-groups status
kafka-consumer-groups --bootstrap-server kafka.cl-ffm-prod.svc.cluster.local:9071 --describe --command-config /tmp/destination.properties --all-groups
 
#5 replicas-status
kafka-replica-status --bootstrap-server kafka.cl-ffm-prod.svc.cluster.local:9071 --admin.config /tmp/destination.properties
 
#6 CONVERT MIRROR TOPICS TO NORMAL
kafka-mirrors --failover --bootstrap-server kafka.cl-ffm-prod.svc.cluster.local:9071 --command-config /tmp/destination.roperties --topics topicName
# use script mirror2normal-topic.sh
 
#7 delete kafka-cluster-links
kafka-cluster-links --delete --link sample --bootstrap-server kafka.cl-ffm-prod.svc.cluster.local:9071 --command-config /tmp/destination.properties
 ```
---

## Schema exporter need to be at source cluster
 
As schema-exporter at source side. so, we have expose the schemaregistry cluster to use in schemaExporter CR.
```yaml
#1 Apply scheme-exporter.yaml with kubectl apply -f scheme-exporter.yaml
#2 get, describe the schemaExporter with kubectl get schemaexporter
#3 status should be in RUNNING state
 
#4 validate schema exporter fuctionality from destination cluster
curl -k -X GET https://10.190.136.157:443/contexts   #schema external ip
curl -k -X GET https://10.190.136.157:443/subjects
 
#5 Destination Schema Registry is placed in "IMPORT" mode globally by default via schema exporter, So you need to update the mode to "READWRITE" at global level
curl -i -k -X "PUT" -H "Accept: application/vnd.schemaregistry.v1+json" -H "Content-Type: application/vnd.schemaregistry.v1+json" -d '{"mode":"READWRITE"}'
https://schemaregistry.cl-ffm-prod.svc.cluster.local:8081/mode
 ```
