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

Consul provides an optional Access Control List (ACL) system which can be used to control access to data and APIs. 
The acl bootstrap command will request Consul to generate a new token with unlimited privileges to use for management purposes and output its details.

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

### Creating An ACL Policy - Example

Policies allow the grouping of a set of rules into a logical unit that can be reused and linked with many tokens.

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

Requests to Consul are authorized by using bearer token.
Each ACL token has a public Accessor ID which is used to name a token, and a Secret ID which is used as the bearer token used to make requests to Consul.

Get the list of acls by:

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

### Secure gossip communication with encryption

Consul uses a gossip protocol to manage membership and broadcast messages to the cluster.
There are two different systems that need to be configured separately to encrypt communication within the datacenter: gossip encryption and TLS. 
TLS is used to secure the RPC calls between agents.
Gossip communication is secured with a symmetric key, since gossip between agents is done over UDP

### Enable Gossip Encryption - Example

SSH into the consul-server `sudo vagrant ssh consul-server` and generate a new gossip encryption key and store it for later.

```bash
consul keygen
jgRZfrj41tdxYNDElhIbDnTgRBEl1kifAYIn1KcIMjc=
```

Update the current config.hcl `sudo vi  /etc/systemd/system/consul.d/config.hcl` and the below parameters:

```json
... 
"encrypt": "jgRZfrj41tdxYNDElhIbDnTgRBEl1kifAYIn1KcIMjc=", <-- gossip key here
"encrypt_verify_incoming": false,
"encrypt_verify_outgoing": false,
...
```

Add the same config to all other nodes (`consul-node-1`,`consul-node-2`,`server-01`,`server-02`)

Restart the consul service on the nodes with `sudo systemctl restart consul`

Confirm that Gossip Encryption is not enabled by running  `journalctl -u consul`

```bash
 ==> Starting Consul agent...
            Version: '1.9.4'
            Node ID: 'be16bb68-0e34-bba1-1091-ea2290c0f39b'
          Node name: 'consul-server'
         Datacenter: 'dc1' (Segment: '<all>')
             Server: true (Bootstrap: true)
        Client Addr: [0.0.0.0] (HTTP: 8500, HTTPS: -1, gRPC: 8502, DNS: 8600)
       Cluster Addr: 192.168.99.100 (LAN: 8301, WAN: 8302)
            Encrypt: Gossip: false, TLS-Outgoing: false, TLS-Incoming: false, Auto-Encrypt-TLS: false
```

Now modify the Consul agent config and update the `encrypt_verify_outgoing` parameter to `true`.

To update the config run `sudo vi /etc/systemd/system/consul.d/config.hcl` and add update the below:

```json
"encrypt_verify_outgoing": true,
```

Restart the consul service on the nodes with `sudo systemctl restart consul`

Next modify the `encrypt_verify_incoming` parameter to `true`.

To update the config run `sudo vi /etc/systemd/system/consul.d/config.hcl` and add update the below:

```json
"encrypt_verify_incoming": true,
```

Restart the consul service on the nodes with `sudo systemctl restart consul`

```bash
 ==> Starting Consul agent...
            Version: '1.9.4'
            Node ID: 'be16bb68-0e34-bba1-1091-ea2290c0f39b'
          Node name: 'consul-server'
         Datacenter: 'dc1' (Segment: '<all>')
             Server: true (Bootstrap: true)
        Client Addr: [0.0.0.0] (HTTP: 8500, HTTPS: -1, gRPC: 8502, DNS: 8600)
       Cluster Addr: 192.168.99.100 (LAN: 8301, WAN: 8302)
            Encrypt: Gossip: true, TLS-Outgoing: false, TLS-Incoming: false, Auto-Encrypt-TLS: false
```

```

### Secure Consul agent communication with TLS encryption

Initialize the built-in CA. 
This will create the `consul-agent-key.pem` and `consul-agent-ca.pem`

```bash
consul tls ca create
```

Create the server certificate for datacenter `dc1` and domain `consul`.
This will create the `dc1-server-consul-0-key.pem` and `dc1-server-consul-0.pem`

```bash
consul tls cert create -server
```

Copy these files to your servers

* `consul-agent-ca.pem`: CA public certificate.
* `dc1-server-consul-0.pem`: Consul server node public certificate for the dc1 datacenter.
* `dc1-server-consul-0-key.pem`: Consul server node private key for the dc1 datacenter.

Update the `config.hcl` with the below information for `Auto encryption`

```json
{
  "verify_incoming": true,
  "verify_outgoing": true,
  "verify_server_hostname": true,
  "ca_file": "consul-agent-ca.pem",
  "cert_file": "dc1-server-consul-0.pem",
  "key_file": "dc1-server-consul-0-key.pem",
  "auto_encrypt": {
    "allow_tls": true
  }
}
```

Copy these files to your consul agents

* `consul-agent-ca.pem`: CA public certificate.

Update the `config.hcl` with the below information for `Auto encryption`

```json
{
  "verify_incoming": false,
  "verify_outgoing": true,
  "verify_server_hostname": true,
  "ca_file": "consul-agent-ca.pem",
  "auto_encrypt": {
    "tls": true
  }
}

```

```bash
==> Starting Consul agent...
           Version: '1.9.4'
           Node ID: '97db3749-bfbc-3203-3808-6e8acd459404'
         Node name: 'server-01'
        Datacenter: 'dc1' (Segment: '')
            Server: false (Bootstrap: false)
       Client Addr: [127.0.0.1] (HTTP: 8500, HTTPS: -1, gRPC: 8502, DNS: 8600)
      Cluster Addr: 192.168.99.151 (LAN: 8301, WAN: 8302)
           Encrypt: Gossip: true, TLS-Outgoing: true, TLS-Incoming: false, Auto-Encrypt-TLS: true
==> Log data will now stream in as it occurs:
```
## To Stop

```bash
sudo vagrant down
```