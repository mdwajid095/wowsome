##
 
# Kafka Cluster Deployment Preparation
 
## Configuration Files
0. Write conf file with correct DNS.
1. Generate CSR and key using `generate-key-csr.sh`.
2. Use CSR to generate PEM.
3. Create Kafka internal certificates with `create-kafka-secret.sh`.
4. Create other required certificates like password-encoder-secret, credential etc.
5. Deploy Zookeeper, Kafka, and Schema Registry.
 
NOTE:
1. kafka need to have data capacity/broker as per source cluster. if created with less broker, it will not benefit to increase broker after cluster linking creation. As all replica already sitted on broker availvale at the time of cluster linking creation. To distribute over all broker, we have create the cluster linking again by deleting the existing one.
2. schemaregistry need to have externally expose. As schema-exporter will be deployed at source side. So, it need to be accessible from soude cluster.
 
Below property need to added in both source and destination schema/kafka cluster.
  enableSchemaExporter: true    #only in schema CR
  passwordEncoder:              #both schema and kafka CR
    secretRef: password-encoder-secret
 
For more info/validation, `explore BIN DIRECTORY.`
https://docs.confluent.io/operator/current/blueprints/cob-cluster-linking.html
 
## destination initiated cluster linking commnad
 
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
 
### End of Cluster Linking ###
 
 
## schema exporter need to be at source cluster
 
# As schema-exporter at source side. so, we have expose the schemaregistry cluster to use in schemaExporter CR.
#1 Apply scheme-exporter.yaml with kubectl apply -f scheme-exporter.yaml
#2 get, describe the schemaExporter with kubectl get schemaexporter
#3 status should be in RUNNING state
 
#4 validate schema exporter fuctionality from destination cluster
curl -k -X GET https://10.190.136.157:443/contexts   #schema external ip
curl -k -X GET https://10.190.136.157:443/subjects
 
#5 Destination Schema Registry is placed in "IMPORT" mode globally by default via schema exporter, So you need to update the mode to "READWRITE" at global level
curl -i -k -X "PUT" -H "Accept: application/vnd.schemaregistry.v1+json" -H "Content-Type: application/vnd.schemaregistry.v1+json" -d '{"mode":"READWRITE"}'
https://schemaregistry.cl-ffm-prod.svc.cluster.local:8081/mode
 
 
### End of Schema Exporter ###
