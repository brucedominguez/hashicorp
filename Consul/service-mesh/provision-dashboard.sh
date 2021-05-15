#!/bin/bash

if [ ! -f /home/vagrant/dashboard-service_linux_amd64 ]; then
	cd /home/vagrant/

	version='0.0.3.1'
	wget https://github.com/hashicorp/demo-consul-101/releases/download/${version}/dashboard-service_linux_amd64.zip -O dashboard-service.zip
	unzip dashboard-service.zip
	rm dashboard-service.zip
fi

## Copy over service definition
if [ ! -f /home/vagrant/dashboard.hcl ]; then
	cd /home/vagrant/
	cp /vagrant/dashboard.hcl /home/vagrant/dashboard.hcl
fi

## Register service
consul services register dashboard.hcl

consul connect envoy -sidecar-for dashboard > dashboard-proxy.log &

PORT=9002 COUNTING_SERVICE_URL="http://localhost:5000" ./dashboard-service_linux_amd64 > /dev/null 2>&1 &
