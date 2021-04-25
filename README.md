# HashiCorp - related projects

## Consul

I used this repo to practice spinning up and configuring using HashiCorp Consul with [Getting Started with HashiCorp Consul 2021 from Bryan Krausen](https://www.udemy.com/course/hashicorp-consul/?referralCode=6506321DC305903E7BFA)

### To Start

To spin up 3 node cluster + consul agent,

```bash
sudo vagrant up
```

Consul cluster UI = http://192.168.99.100:8500/

## To SSH

``` bash
sudo vagrant ssh consul-server

# or

sudo vagrant ssh consul-node-1

# or 

sudo vagrant ssh consul-node-2

# or 

sudo vagrant ssh web-server
```

![consul](./images/consul.png)

### To Stop

```bash
sudo vagrant down
```

## Nomad
