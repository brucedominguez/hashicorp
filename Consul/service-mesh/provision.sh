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


## Copy server tls certs - consul-agent-ca.pem
if [ ! -f /etc/systemd/system/consul.d/consul-agent-ca.pem ]; then
	cd /home/vagrant/
	cp /vagrant/consul-agent-ca.pem /etc/systemd/system/consul.d/consul-agent-ca.pem
fi

## Copy server tls certs - dc1-server-consul-0.pem
if [ ! -f /etc/systemd/system/consul.d/dc1-server-consul-0.pem ]; then
	cd /home/vagrant/
	cp /vagrant/dc1-server-consul-0.pem /etc/systemd/system/consul.d/dc1-server-consul-0.pem
fi

## Copy server tls certs - dc1-server-consul-0-key.pem
if [ ! -f /etc/systemd/system/consul.d/dc1-server-consul-0-key.pem ]; then
	cd /home/vagrant/
	cp /vagrant/dc1-server-consul-0-key.pem /etc/systemd/system/consul.d/dc1-server-consul-0-key.pem
fi

# install envoy agent 
if [ ! -f /usr/local/bin/envoy ]; then
	cd /usr/local/bin

	curl -L https://getenvoy.io/cli | bash -s -- -b /usr/local/bin
	getenvoy run standard:1.13.6 -- --version
	sudo cp ~/.getenvoy/builds/standard/1.13.6/linux_glibc/bin/envoy /usr/local/bin/
fi
