#!/bin/bash

if [ ! -f /home/vagrant/counting-service_linux_amd64 ]; then
	cd /home/vagrant/

	version='0.0.3.1'
	wget https://github.com/hashicorp/demo-consul-101/releases/download/${version}/counting-service_linux_amd64.zip -O counting-service.zip
	unzip counting-service.zip
	rm counting-service.zip
fi

## Copy over service definition
if [ ! -f /home/vagrant/counting.hcl ]; then
	cd /home/vagrant/
	cp /vagrant/counting.hcl /home/vagrant/counting.hcl
fi

## Register service
consul services register counting.hcl

consul connect envoy -sidecar-for counting-1 -admin-bind localhost:19001 > counting-proxy.log &

PORT=9003 ./counting-service_linux_amd64 > /dev/null 2>&1 &

