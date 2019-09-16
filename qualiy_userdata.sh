#!/bin/bash
echo 'Start of QualiY user-data'
echo "Sidecar: $SIDECAR_API_URL"
echo "Status updater script: $QUALIY_STATUS_UPDATER_URL"

echo 'Downloading status updater script...'
wget -O /bin/qualiy_status_updater $QUALIY_STATUS_UPDATER_URL
chmod +x /bin/qualiy_status_updater

echo 'Register status notifier service...'
cd /lib/systemd/system/
cat > qualiy_status_notifier.service << EOL
[Unit]
Description=Notifiying sidecar about qualiy status

[Service]
Type=oneshot
RemainAfterExit=true
Environment="SIDECAR_API_URL=$SIDECAR_API_URL"
ExecStart=/bin/qualiy_status_updater --on
ExecStop=/bin/qualiy_status_updater --turning-off

[Install]
WantedBy=multi-user.target
EOL

systemctl enable qualiy_status_notifier.service

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
docker run -d --restart always --name guacamole-server -d guacamole/guacd:1.0.0

echo 'Staring guacamole-client...'

#if no env variables 
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
	docker run -d --restart always --name guacamole-client --link guacamole-server:guacd -p 8080:8080 dockergil90/guacamole-client-debugable:1.6.12
else 
	#bucket name ,region,key name
	docker run -d --restart always --name guacamole-client --link guacamole-server:guacd -p 8080:8080  -e $1 -e $2 -e $3 dockergil90/guacamole-client-debugable:1.6.12
fi

echo "Resolving sidecar dns to ip..."

SIDECAR_API_DNS=$(echo $SIDECAR_API_URL | grep -Po '(http\:\/\/)?\K(.*)(?=:)')
echo "SIDECAR_API_DNS: $SIDECAR_API_DNS"
DNS_RESOLUTION_RESULT=$(until getent hosts $SIDECAR_API_DNS; do sleep 10; done)
echo $DNS_RESOLUTION_RESULT >> /etc/hosts;


TURN_OFF=$(for i in "$@" ; do [[ $i == "turn-off" ]] && echo true && break; done)
if [[ $TURN_OFF ]]; then
  echo "Shutting down in 20 seconds"
  echo "qualiy_status_updater --turning-off 2>&1 | logger --tag qualiy_status_updater; sleep 20; sudo shutdown -h now" | at now
else
  echo "Starting qualiy_status_notifier service"
  systemctl start qualiy_status_notifier
fi

echo 'End of QualiY user-data'
