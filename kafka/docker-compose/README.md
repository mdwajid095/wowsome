# kafka setup with docker-compose

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
