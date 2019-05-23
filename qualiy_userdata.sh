#!/bin/bash
echo 'Start of QualiY user-data'

echo 'Installing docker...'
apt-get update
apt-get install -y --no-install-recommends --no-install-suggests \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update
apt-get install -y --no-install-recommends --no-install-suggests docker-ce

echo 'Staring guacamole-server...'
docker run -d --name guacamole-server -d guacamole/guacd:0.9.14

echo 'Staring guacamole-client...'

#if no env variables 
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	docker run -d --name guacamole-client --link guacamole-server:guacd -p 8080:8080 quali/guacamole-client:0.9.14
else 
	docker run -d --name guacamole-client --link guacamole-server:guacd -p 8080:8080 -p 8000:8000 -e $1 -e $2 -e $3 dockergil90/qualiy_debug
fi

echo 'End of QualiY user-data'
