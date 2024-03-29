# Default compose args
COMPOSE_ARGS=" -f jenkins.yml -p jenkins"

# Make sure old containers are gone
sudo docker-compose $COMPOSE_ARGS stop
sudo docker-compose $COMPOSE_ARGS rm --force -v

# build the system
sudo docker-compose $COMPOSE_ARGS build --no-cache
# connect and ignore error
sudo docker network connect jenkins_default jenkins || true
sudo docker-compose $COMPOSE_ARGS up -d

# Run unit tests
sudo docker-compose $COMPOSE_ARGS run --no-deps --rm -e ENV=UNIT identidock
ERR=$?

# Run system test if unit tests passed
if [ $ERR -eq 0 ]; then
	# must use the new type to get IP Address
	IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' jenkins_identidock_1)
	CODE=$(curl -sL -w "%{http_code}" $IP:9090/monster/bla -o /dev/null) || true
	if [ $CODE -ne 200 ]; then
		echo "Site returned " $CODE
		ERR=1
	fi
fi

# Pull down the system
sudo docker-compose $COMPOSE_ARGS stop
sudo docker-compose $COMPOSE_ARGS rm --force -v

return $ERR
