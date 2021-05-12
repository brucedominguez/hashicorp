# HashiCorp - Consul

I used this repo to practice spinning up and configuring using HashiCorp Consul with [Getting Started with HashiCorp Consul 2021 from Bryan Krausen](https://www.udemy.com/course/hashicorp-consul/?)

## To Start

To spin up 3 node cluster and "web server" node.
The web server has a web api with the sole function to connect to the Postgres database

```bash
sudo vagrant up
```

Consul cluster UI = http://192.168.99.100:8500/

## SSH  commands to boxes

``` bash
sudo vagrant ssh consul-server
# or
sudo vagrant ssh consul-node-1
# or 
sudo vagrant ssh consul-node-2
# or 
sudo vagrant ssh web-server-1
# or 
sudo vagrant ssh web-server-2
```

![consul](./images/consul.png)

The web-server `/health` endpoint responds with `200` if there is a successful connection to the Postgres database (all in docker). 
Expected response example:

```json
{
  "status": "OK",
  "version": "0.1.0-local",
  "time": "2021-02-15 07:36:02",
  "db_information": "PostgreSQL 13.1 (Debian 13.1-1.pgdg100+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 8.3.0-6) 8.3.0, 64-bit",
  "error": ""
}
```

![front-end-eCommerce](./images/healthcheck.png)

### Check the service catalog for the service

```bash
dig @192.168.99.100 -p 8600 front-end-eCommerce.service.consul
```

### Check the dns for the service

```bash
dig @192.168.99.100 -p 8600 front-end-eCommerce.service.consul
```

### Prepared query

SSH onto the `consul-server`

```bash
sudo vagrant ssh consul-server
```

Create the prepared query (prepared-query-v1.json file already exists on server) by running:

```bash
curl --request POST --data @prepared-query-v1.json http://192.168.99.101:8500/v1/query | jq

{
   "ID":"1cb38a85-c4ff-130c-4ae6-2d11321a79eb" ## this will be different for you
}
```

Check the results by using the ID provided to only get `v1.0.0` of service front-end-eCommerce

```bash
curl http://192.168.99.101:8500/v1/query/1cb38a85-c4ff-130c-4ae6-2d11321a79eb | jq ## note your ID will be different

[
  {
    "ID": "1cb38a85-c4ff-130c-4ae6-2d11321a79eb",
    "Name": "eCommerce",
    "Session": "",
    "Token": "",
    "Template": {
      "Type": "",
      "Regexp": "",
      "RemoveEmptyTags": false
    },
    "Service": {
      "Service": "front-end-eCommerce",
      "Failover": {
        "NearestN": 0,
        "Datacenters": null
      },
      "OnlyPassing": false,
      "IgnoreCheckIDs": null,
      "Near": "",
      "Tags": [
        "v1.0.0",
        "production"
      ],
      "NodeMeta": null,
      "ServiceMeta": null,
      "Connect": false
    },
    "DNS": {
      "TTL": ""
    },
    "CreateIndex": 258,
    "ModifyIndex": 258
  }
]
```

Alternatively you can perform a DNS query against the prepared query to get the IP of v1.0.0 of the service

```bash
dig @192.168.99.101 -p 8600 eCommerce.query.consul
```

To update the query to show the new version `v2.0.0`, update the query by running

```bash
curl --request PUT --data @prepared-query-v2.json http://192.168.99.101:8500/v1/query/<YOUR QUERY ID>
```

Test by running a `dig @192.168.99.101 -p 8600 eCommerce.query.consul` and the address should now be `192.168.99.152`

### Use Consul KV to pull env vars

Environment variables used for the `Docker-compose` are set using the [web-server.sh](./web-server.sh)

Consul KV path

```bash
POSTGRES_HOST=production/apps/eCommerce/POSTGRES_HOST
POSTGRES_USER=production/apps/eCommerce/POSTGRES_USER
POSTGRES_PASSWORD=production/apps/eCommerce/POSTGRES_PASSWORD
POSTGRES_DB=production/apps/eCommerce/POSTGRES_DB
```

Example, to retrieve the key/value database_host

```bash
consul kv get production/apps/eCommerce/POSTGRES_HOST
```

### Use envconsul to set service variables

When the web-server starts it will use the `envconsul` binary to grab the variables above to use for the docker-compose startup.

```bash
envconsul -upcase -prefix apps/eCommerce docker-compose up -d
```

### Use consul-template to update config files on startup

Consul-template can be used to pull Key/Value pairs and update template files.
In this example the `config.yaml.tmpl` file on the web-server's (below), uses the set environment variable `ENVIRONMENT` to pull down the correct consul key/value.
In this case the `ENVIRONMENT` is `production` and so will grab `production/apps/eCommerce/POSTGRES_HOST` values.

```go
{{ $ENVIRONMENT :=  env "ENVIRONMENT" }}
environment: {{ $ENVIRONMENT }}
database_host: { printf "%s/apps/eCommerce/POSTGRES_HOST" $ENVIRONMENT | key}}
database_name: {{ printf "%s/apps/eCommerce/POSTGRES_DB" $ENVIRONMENT | key}}
```

This is done by the below command in the `web-server.sh` script and creating a `config.yaml` file with the correct values

```bash
consul-template -template "config.yaml.tmpl:config.yaml" --once
```

To view SSH on to the web-server `sudo vagrant ssh web-server-1` and view the file

```bash
$  cat config.yaml

environment: production
database_host: postgres
database_name: postgres
```

## To Stop

```bash
sudo vagrant down
```