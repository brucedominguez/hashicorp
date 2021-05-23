# Consul - Service Mesh

This example is used to practice and understand:

* Consul Connect (Service Mesh)
* Bootstraping ACL's

This example leverages the learn.hashicorp example of [Secure Service Communication with Consul Service Mesh and Envoy](https://learn.hashicorp.com/tutorials/consul/service-mesh-with-envoy-proxy?in=consul/developer-mesh)

![consul-connect](../../images/consul-connect.png)

## Requirements

* Vagrant

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/vagrant
```

* [Oracle Virtual Box](https://www.virtualbox.org/wiki/Downloads)

## To Start

To spin up 3 node cluster consul cluster and 2 servers with Envoy enabled as the sidecar proxy.

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
sudo vagrant ssh counting-1
# or 
sudo vagrant ssh dashboard-1
```

![consul](../../images/consul-service-mesh.png)

### Bootstrap ACL

SSH onto the `consul-server`

```bash
sudo vagrant ssh consul-server
```

Reconfigure the Consul Agent configuration file to enable Consul ACLs with `sudo vi /etc/consul.d/config.hcl`

```json
.....
"acl": {
    "enabled": true,
    "default_policy": "allow",
     "down_policy": "extend-cache"
    },
```

Restart the consul server to pick up the new configuration `sudo systemctl restart consul`

Run the bootstrap ACL command `consul acl bootstrap`

The below output should provide bootstrap/master token that has the global-management policy, as an example below:

```bash
AccessorID:       b5560187-c2b9-8d02-0d5c-a35efbb32280
SecretID:         78d70448-16ff-5f8c-9042-a3efd2b2e870
Description:      Bootstrap Token (Global Management)
Local:            false
Create Time:      2021-05-16 13:32:43.016004687 +0000 UTC
Policies:
   00000000-0000-0000-0000-000000000001 - global-management
```

### Creating An ACL - Example

Create a new policy file for the server01 node

```bash
vi rules-server.hcl

```

```json
node_prefix "server-01" {
  policy = "write"
}
service_prefix "dashboard" {
  policy = "write"
}
session_prefix "" {
  policy = "write"
}
key_prefix "" {
  policy = "read"
}
```

Create the acl

```bash

consul acl policy create -name "dashboard" \
                                 -description "Dashboard service" \
                                 -datacenter "dc1" \
                                 -rules @rules-server.hcl \
                                 -token <ADD TOKEN>
```

### Create a Token to be used

Get the list of acls

```bash
consul acl policy list -token <token>

global-management:
   ID:           00000000-0000-0000-0000-000000000001
   Description:  Builtin Policy that grants unlimited access
   Datacenters:  
counting:
   ID:           b4a9ce0f-217e-0643-c46f-df27a2d511bf
   Description:  Counting service
   Datacenters:  
dashboard:
   ID:           d732cb0b-e881-b5b3-7054-994a8a88d86b
   Description:  Dashboard service
   Datacenters:  
```

Create the token for server-01/service to use

```bash
consul acl token create -description "server-01" \
                        -policy-id d732cb0b-e881-b5b3-7054-994a8a88d8 \
                        -token <token>

AccessorID:       69de5a67-2176-fb50-4b1d-525410c84cac
SecretID:         7c1398ad-8cc8-6007-e38f-bbde5e409282 <-- token HERE
Description:      server-01
Local:            false
Create Time:      2021-05-23 07:50:59.325258232 +0000 UTC
Policies:
   d732cb0b-e881-b5b3-7054-994a8a88d86b - dashboard

```


## To Stop

```bash
sudo vagrant down
```