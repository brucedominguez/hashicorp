#!/bin/bash

# install docker
if [ -x "$(command -v docker)" ]; then
      echo "Docker installed"
else
      echo "Installing Docker..."
      sudo apt-get update
      sudo apt-get remove docker docker-engine docker.io
      echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections
      sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y
      sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  sudo apt-key add -
      sudo apt-key fingerprint 0EBFCD88
      sudo add-apt-repository \
            "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) \
            stable"
      sudo apt-get update
      sudo apt-get install -y docker-ce
      # Restart docker to make sure we get the latest version of the daemon if there is an upgrade
      sudo service docker restart
      # Make sure we can actually use docker as the vagrant user
      sudo usermod -aG docker vagrant

      sudo curl -L https://github.com/docker/compose/releases/download/1.29.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
fi

if [ ! -f /home/vagrant/docker-compose.yml ]; then
	cp /vagrant/docker-compose.yml /home/vagrant/docker-compose.yml
fi

# install envconsul - used to grab values from consul
if [ ! -f /usr/local/bin/envconsul ]; then
	cd /usr/local/bin

	version='0.11.0'
	wget https://releases.hashicorp.com/envconsul/${version}/envconsul_${version}_linux_amd64.zip -O envconsul.zip
	unzip envconsul.zip
	rm envconsul.zip
fi

# install envconsul - used to grab values from consul
if [ ! -f /usr/local/bin/consul-template ]; then
	cd /usr/local/bin

	version='0.25.2'
	wget https://releases.hashicorp.com/consul-template/${version}/consul-template_${version}_linux_amd64.zip -O consul-template.zip
	unzip consul-template.zip
	rm consul-template.zip
fi

## Set Environment Variable
export ENVIRONMENT="production"

## Use Consul-template to set arbitrary config file based on Environment
if [ ! -f /home/vagrant/config.yaml.tmpl ]; then
	cp /vagrant/config.yaml.tmpl /home/vagrant/config.yaml.tmpl
fi

cd /home/vagrant/
consul-template -template "config.yaml.tmpl:config.yaml" --once


## Grab env variables from Consul KV and start docker-compose
echo "Grabbing Environment Variables set by Consul and starting docker-compose"
envconsul -upcase -prefix $ENVIRONMENT/apps/eCommerce docker-compose up -d

## Register webapi service
if [ ! -f /home/vagrant/service.hcl ]; then
	cp /vagrant/service.hcl /home/vagrant/service.hcl
fi

if [ ! -f /home/vagrant/prepared-query-v1.json ]; then
	cp /vagrant/prepared-query-v1.json /home/vagrant/prepared-query-v1.json
fi

if [ ! -f /home/vagrant/prepared-query-v12.json ]; then
	cp /vagrant/prepared-query-v2.json /home/vagrant/prepared-query-v2.json
fi

## Register service
consul services register service.hcl 

