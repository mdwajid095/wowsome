# kafka setup with docker-compose
Run simple kafka cluster with docker-compose in both mode, zk or kraft.

For zookeeper mode, use config file: zk-dokcer-compose.yml,
For kraft mode, use config file: dokcer-compose.yml 

```sh
# create kafka cluster
docker-compose up
docker-compose up -d
docker-compose -f zk-dokcer-compose.yml up -d

# check status
docker ps
docker ps -a

# destroy kafka cluster
docker-compose down
docker-compose down -v
docker-compose -f zk-dokcer-compose.yml down -v
