file='file.txt'
topics=""
while read line; do
  topics+="$line,"
done < $file

# Remove the trailing comma
topics=${topics%,}

kafka-mirrors --failover --bootstrap-server kafka.cl-ffm-prod.svc.cluster.local:9071 --command-config /tmp/destination.properties --topics "$topics"
