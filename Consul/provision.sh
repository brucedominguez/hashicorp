#!/bin/bash

# update and unzip
dpkg -s unzip &>/dev/null || {
	sudo apt-get -y update && sudo apt-get install -y unzip jq
}

# install consul 
if [ ! -f /usr/local/bin/consul ]; then
	cd /usr/local/bin

	version='1.9.4'
	wget https://releases.hashicorp.com/consul/${version}/consul_${version}_linux_amd64.zip -O consul.zip
	unzip consul.zip
	rm consul.zip

	chmod +x consul
fi

if [ ! -f /etc/systemd/system/consul.service ]; then
	cp /vagrant/consul.service /etc/systemd/system/consul.service
fi

if [ ! -d /etc/systemd/system/consul.d ]; then
	mkdir -p /etc/systemd/system/consul.d
fi