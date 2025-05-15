kubectl create secret generic tls-kafka-internal \
--from-file=fullchain.pem=kafka-internal.pem \
--from-file=cacerts.pem=root+subca.pem \
--from-file=privkey.pem=kafka-internal.key -o yaml --dry-run=client | kubectl -n cl-ffm-prod apply -f -
