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

## Start Webapi + Postgres DB
cd /home/vagrant/
docker-compose up -d

## Register webapi service
if [ ! -f /home/vagrant/service.hcl ]; then
	cp /vagrant/service.hcl /home/vagrant/service.hcl
fi

## Register service
consul services register service.hcl 

