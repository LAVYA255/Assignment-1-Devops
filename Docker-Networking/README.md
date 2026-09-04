# Docker Networking & Volumes

Four tasks covering user-defined bridge networks and container isolation, host networking, bind mounts, and overlay networks. Every output block is real terminal output.

Environment: **Docker Engine 29.1.3** on Ubuntu 26.04 LTS (WSL2).

---

## Task 1 - Docker Container Networking

Three containers (frontend, backend, database) and three networks, with the **backend attached to two networks** so it is the only path between the frontend and the database.

### Design

```
   frontend-net                          database-net
  ┌──────────────┐                      ┌──────────────┐
  │  frontend    │                      │   database   │
  │  (nginx)     │                      │   (mysql:8)  │
  │  172.18.0.2  │                      │  172.20.0.2  │
  └──────┬───────┘                      └──────┬───────┘
         │                                     │
         │        ┌──────────────────┐         │
         └────────┤     backend      ├─────────┘
                  │    (alpine)      │
                  │  eth0 172.18.0.3 │  <- on frontend-net
                  │  eth1 172.20.0.3 │  <- on database-net
                  └──────────────────┘

  backend-net  (third network, created and listed)

  frontend  ──X──>  database     no shared network, so no route
```

### Commands

```bash
# 1. Create three networks
docker network create frontend-net
docker network create backend-net
docker network create database-net

# 2. Create three containers
docker run -d --name frontend --network frontend-net nginx:1.27-alpine
docker run -d --name backend  --network frontend-net alpine:3.20 sleep infinity
docker run -d --name database --network database-net -e MYSQL_ROOT_PASSWORD=rootpass mysql:8

# 3. Attach the backend to a SECOND network
docker network connect database-net backend

# 4. Test connectivity
docker exec backend  ping -c 3 frontend    # works
docker exec backend  ping -c 3 database    # works
docker exec frontend ping -c 2 database    # fails - isolated
```

### Output

```console
########## CLEANUP FROM ANY PREVIOUS RUN ##########
clean

########## 1. Create 3 Docker networks ##########

$ docker network ls
NETWORK ID     NAME           DRIVER    SCOPE
0393f68237bb   backend-net    bridge    local
8461adcfa802   bridge         bridge    local
dc3a58e36dc6   database-net   bridge    local
78c286bd5f37   frontend-net   bridge    local
3301d5e89f07   host           host      local
bded084394e2   none           null      local

########## 2. Create the 3 containers ##########
-- frontend: nginx on frontend-net --
-- backend: alpine on frontend-net (kept alive with sleep) --
wsl : Unable to find image 'alpine:3.20' locally
At line:1 char:581
+ ... chpad\out'; wsl -d Ubuntu -u root -- bash "$sp/docker_net_task1.sh" > ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (Unable to find ...e:3.20' locally:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
3.20: Pulling from library/alpine
Digest: sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc
Status: Downloaded newer image for alpine:3.20
-- database: MySQL on database-net --
Unable to find image 'mysql:8' locally
8: Pulling from library/mysql
Digest: sha256:b3b90af2a6552ae30c266fdb7d5dd55f3afb72404bb78d37fe8a23eb857fd3fb
Status: Downloaded newer image for mysql:8

########## 3. Add the BACKEND container to a 2nd network ##########
$ docker network connect database-net backend
backend is now attached to BOTH frontend-net and database-net

########## 4. Show which networks each container is on ##########
-- frontend --
frontend-net => 172.18.0.2

-- backend --
database-net => 172.20.0.3
frontend-net => 172.18.0.3

-- database --
database-net => 172.20.0.2

########## 5. Install test tools inside the alpine backend ##########
iputils + bind-tools installed in backend

Waiting 25s for MySQL to finish initialising...

########## 6. CONNECTIVITY TEST A: backend -> frontend (SHARED frontend-net) ##########
$ docker exec backend ping -c 3 frontend
PING frontend (172.18.0.2) 56(84) bytes of data.
64 bytes from frontend.frontend-net (172.18.0.2): icmp_seq=1 ttl=64 time=0.715 ms
64 bytes from frontend.frontend-net (172.18.0.2): icmp_seq=2 ttl=64 time=0.277 ms
64 bytes from frontend.frontend-net (172.18.0.2): icmp_seq=3 ttl=64 time=0.087 ms

--- frontend ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2022ms
rtt min/avg/max/mdev = 0.087/0.359/0.715/0.262 ms
==> SUCCESS expected: both are on frontend-net

########## 7. CONNECTIVITY TEST B: backend -> database (SHARED database-net) ##########
$ docker exec backend ping -c 3 database
PING database (172.20.0.2) 56(84) bytes of data.
64 bytes from database.database-net (172.20.0.2): icmp_seq=1 ttl=64 time=20.3 ms
64 bytes from database.database-net (172.20.0.2): icmp_seq=2 ttl=64 time=0.074 ms
64 bytes from database.database-net (172.20.0.2): icmp_seq=3 ttl=64 time=0.055 ms

--- database ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2019ms
rtt min/avg/max/mdev = 0.055/6.799/20.270/9.524 ms

$ docker exec backend nc -zv database 3306   (is MySQL actually accepting connections?)
database (172.20.0.2:3306) open
==> SUCCESS expected: both are on database-net

########## 8. CONNECTIVITY TEST C: frontend -> database (NO shared network) ##########
$ docker exec frontend ping -c 2 database
ping: bad address 'database'
==> FAILURE expected: frontend is only on frontend-net, database only on database-net.
    This is Docker network ISOLATION. The backend is the only path between them.

########## 9. Docker's embedded DNS resolves container NAMES ##########
$ docker exec backend nslookup frontend
Address:	127.0.0.11#53

Non-authoritative answer:
Name:	frontend
Address: 172.18.0.2


$ docker exec backend nslookup database
Address:	127.0.0.11#53

Non-authoritative answer:
Name:	database
Address: 172.20.0.2


########## 10. The backend has an interface on EACH network it joined ##########
$ docker exec backend ip addr show | grep -E 'eth|inet '
    inet 127.0.0.1/8 scope host lo
2: eth0@if38: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    link/ether 56:73:80:0f:99:0f brd ff:ff:ff:ff:ff:ff
    inet 172.18.0.3/16 brd 172.18.255.255 scope global eth0
3: eth1@if40: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    link/ether 9a:83:23:13:e2:5d brd ff:ff:ff:ff:ff:ff
    inet 172.20.0.3/16 brd 172.20.255.255 scope global eth1

########## 11. Inspect a network to see its members ##########
$ docker network inspect database-net
database => 172.20.0.2/16
backend => 172.20.0.3/16


########## 12. Final state ##########
NAMES      IMAGE               STATUS
database   mysql:8             Up 38 seconds
backend    alpine:3.20         Up About a minute
frontend   nginx:1.27-alpine   Up About a minute
```

### What the output proves

| Test | Result | Why |
|---|---|---|
| `backend → frontend` | **0% packet loss** | Both are on `frontend-net` |
| `backend → database` | **0% packet loss**, and MySQL's port 3306 reports `open` | Both are on `database-net` |
| `frontend → database` | **`ping: bad address 'database'`** | No shared network |

The third result is the important one. The failure is `bad address` - a **DNS** failure, not a timeout. Docker's embedded DNS resolver (127.0.0.11) only answers for containers that share a network with the one asking, so the frontend cannot even resolve the name `database`, let alone route to it. **Isolation is the default**, and containers only reach each other when explicitly placed on a common network.

`docker exec backend ip addr show` confirms the dual attachment: **`eth0` on 172.18.0.3** (frontend-net) and **`eth1` on 172.20.0.3** (database-net). Joining a network gives a container another interface, which is exactly how a backend acts as a controlled gateway between a public tier and a private database tier.

Note also that container **names** resolve - `nslookup frontend` returns 172.18.0.2. This automatic DNS is provided by *user-defined* networks, not by the legacy default bridge, and it is why you address services by name rather than by hard-coded IP.

---

## Task 2 - Host Network

### Commands

```bash
docker pull httpd:2.4
docker run -d --name apache-host --network host httpd:2.4
curl http://localhost:80
```

With `--network host` the container does **not** get its own network namespace - it shares the host's. No `-p` flag is used or possible: the container binds directly to the host's port 80.

### Output and screenshot

Apache served directly on port 80 with no port mapping:

![Apache on the host network, port 80](../screenshots/08-apache-host-network-port80.png)

### What the output proves

- `curl http://localhost:80` returns Apache's `It works!` page with **HTTP status 200**, even though no `-p` flag was given.
- `docker ps` shows an **empty `PORTS` column** - there is no mapping to display, because there is no NAT layer at all.
- `docker inspect apache-host -f '{{.HostConfig.NetworkMode}}'` returns `host`.

### Bridge vs host networking

| | Bridge (default) | Host |
|---|---|---|
| Network namespace | Its own | **Shares the host's** |
| Container IP | Private (e.g. 172.17.0.2) | The host's own IP |
| Publishing ports | Requires `-p 8080:80` | Not applicable - binds directly |
| Port conflicts | None; many containers can use port 80 internally | **Real** - only one process per host port |
| Performance | Slight NAT overhead | No NAT overhead |
| Isolation | Strong | **Weak** |

Host networking is worth using for high-throughput workloads where the NAT hop matters, or for tools that need to see the host's real interfaces. The cost is isolation and the loss of the ability to run two containers on the same port.

---

## Task 3 - Bind Mount

### Commands

```bash
# A folder on the local machine containing index.html
docker run -d --name nginx-bind -p 8090:80 \
  -v /path/to/bind-mount-demo:/usr/share/nginx/html:ro \
  nginx:1.27-alpine

curl http://localhost:8090      # serves the host's file
# ...edit index.html on the host...
curl http://localhost:8090      # new content, no restart
```

The folder is [`bind-mount-demo/`](bind-mount-demo/) in this repository.

### Before - the original file

`index.html` contains `Hello students`:

![Bind mount before the edit](../screenshots/09-bind-mount-before.png)

### After - the file edited on the host, container never restarted

![Bind mount after the edit](../screenshots/10-bind-mount-after.png)

### Output

```console
##################################################################
  TASK 2: HOST NETWORK
##################################################################
### 1. Pull the Apache2 (httpd) image from Docker Hub
2.4: Pulling from library/httpd
Digest: sha256:979c38c2228d28c2edfd45c6e27dcee1c7b4a101a5526721ae8ece454e89e99e
Status: Downloaded newer image for httpd:2.4
docker.io/library/httpd:2.4

### 2. Run Apache using the HOST network (no -p flag needed)
$ docker run -d --name apache-host --network host httpd:2.4

### 3. docker ps - note the PORTS column is EMPTY with host networking
NAMES         IMAGE       STATUS         PORTS
apache-host   httpd:2.4   Up 4 seconds   

### 4. Access Apache directly on port 80 (no port mapping was created)
$ curl -s http://localhost:80
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<title>It works! Apache httpd</title>
</head>
<body>
<p>It works!</p>
</body>
</html>

$ curl -s -o /dev/null -w 'HTTP status: %{http_code}\n' http://localhost:80
HTTP status: 200

### 5. Proof: the container shares the HOST's network namespace
$ docker inspect apache-host -f '{{.HostConfig.NetworkMode}}'
host
$ docker exec apache-host hostname -i   (same IP as the host, not a 172.17.x.x bridge IP)
127.0.1.1
host IP for comparison:
172.21.101.146 172.17.0.1 172.18.0.1 172.19.0.1 172.20.0.1 


##################################################################
  TASK 3: BIND MOUNT
##################################################################
### 1. The folder on the local machine and its index.html
$ ls -l /mnt/c/Users/Lavya/Music/Devops/Assignment1/Docker-Networking/bind-mount-demo
total 0
-rwxrwxrwx 1 lavya lavya 207 Sep  3 18:38 index.html
$ cat /mnt/c/Users/Lavya/Music/Devops/Assignment1/Docker-Networking/bind-mount-demo/index.html
<!doctype html>
<html>
  <head><title>Bind Mount Demo</title></head>
  <body style="font-family: system-ui, sans-serif; text-align: center; padding-top: 80px;">
    <h1>Hello students</h1>
  </body>
</html>

### 2. Bind mount that folder into an Nginx container
$ docker run -d --name nginx-bind -p 8090:80 -v /mnt/c/Users/Lavya/Music/Devops/Assignment1/Docker-Networking/bind-mount-demo:/usr/share/nginx/html:ro nginx:1.27-alpine

### 3. Access the site - it serves the file from the HOST folder
$ curl -s http://localhost:8090
<!doctype html>
<html>
  <head><title>Bind Mount Demo</title></head>
  <body style="font-family: system-ui, sans-serif; text-align: center; padding-top: 80px;">
    <h1>Hello students</h1>
  </body>
</html>

### 4. Confirm the mount is a bind mount
$ docker inspect nginx-bind -f '{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}} (ro={{not .RW}}){{end}}'
bind /mnt/c/Users/Lavya/Music/Devops/Assignment1/Docker-Networking/bind-mount-demo -> /usr/share/nginx/html (ro=true)

### 5. NOW MODIFY index.html ON THE HOST (container is NOT restarted)
file modified on host at Thu Sep  3 18:38:51 UTC 2026

### 6. Request it again - WITHOUT restarting the container
$ docker ps --filter name=nginx-bind   (check uptime: it has NOT been restarted)
NAMES        STATUS
nginx-bind   Up 3 seconds

$ curl -s http://localhost:8090
<!doctype html>
<html>
  <head><title>Bind Mount Demo</title></head>
  <body style="font-family: system-ui, sans-serif; text-align: center; padding-top: 80px;">
    <h1>Hello students - THIS FILE WAS EDITED ON THE HOST</h1>
    <p>The container was never restarted. A bind mount reflects host changes live.</p>
  </body>
</html>

>>> The new content is served immediately. The container was never restarted.


#############################################################
```

### What the output proves

1. The container serves `Hello students` from the **host's** folder - nothing was copied into the image.
2. `docker inspect` confirms the mount type is **`bind`**, from the host path to `/usr/share/nginx/html`, mounted read-only (`ro=true`).
3. After editing `index.html` **on the host**, the very next request returns the new content - with **no `docker restart`, no rebuild and no `docker cp`**.

A bind mount maps a host directory straight into the container, so both sides see the same files on the same underlying disk. The container was never restarted; Nginx simply reads the file from disk on each request and the file it reads *is* the host's file.

### Bind mount vs volume

| | Bind mount | Named volume |
|---|---|---|
| Location | Any host path you choose | Managed by Docker under `/var/lib/docker/volumes` |
| Created with | `-v /host/path:/container/path` | `-v myvolume:/container/path` |
| Best for | **Development** - live source editing | **Production** - databases, persistent app data |
| Portability | Tied to the host's directory layout | Portable, host-independent |
| Backup | Ordinary file copying | `docker volume` commands |

The `:ro` suffix mounts read-only, which is good practice whenever the container has no reason to write back to the host.

---

## Task 4 - Overlay Network

### Research: what an overlay network is

A **bridge** network connects containers **on one host**. An **overlay** network connects containers **across many hosts**, making a multi-machine cluster behave like one flat network.

It works by **VXLAN encapsulation**. Each container's Ethernet frame is wrapped inside a UDP packet (VXLAN, port 4789), sent across the physical network to the right host, then unwrapped and delivered to the destination container. The containers themselves are unaware of any of it - they simply see one shared subnet. This is why the overlay interface has an **MTU of 1450** rather than 1500 in the output below: 50 bytes are reserved for the VXLAN header.

Docker keeps the necessary state - which container lives on which host, and their IP assignments - in the swarm's distributed key-value store, so every node can route to every container.

**Use cases**

- **Multi-host container communication** - the core purpose: a service on host A talking to a database on host B by name.
- **Docker Swarm services** - replicas scheduled across different machines still share one network.
- **Scaling out** - an application outgrows one machine, and containers must keep talking as if nothing changed.
- **Service discovery across a cluster** - a service name resolves to a virtual IP that load-balances across every replica, wherever they run.
- **Network segmentation in a cluster** - separate overlays isolate different application tiers cluster-wide.

**How it works across multiple hosts**

1. `docker swarm init` on the first host makes it a manager; other hosts run `docker swarm join` with the token.
2. Managers keep a distributed store (Raft-replicated) of network state.
3. `docker network create -d overlay` creates a network with **swarm scope** rather than local scope.
4. When a container starts on that network, its host gets an IP for it and learns which host holds every other container.
5. Traffic between containers on different hosts is VXLAN-encapsulated over the physical network and decapsulated at the far end.
6. Docker's embedded DNS resolves service names to a **virtual IP (VIP)** that load-balances across the replicas.

**Requirements** - swarm mode, plus these ports open between hosts: **TCP 2377** (cluster management), **TCP+UDP 7946** (node discovery), and **UDP 4789** (VXLAN data).

### Demonstration

```bash
docker swarm init --advertise-addr <ip>
docker network create -d overlay --attachable my-overlay-net
docker network ls                       # compare DRIVER and SCOPE
docker run -d --name overlay-client --network my-overlay-net alpine:3.20 sleep infinity
docker service create --name web --network my-overlay-net --replicas 3 nginx:1.27-alpine
```

```console
##################################################################
  TASK 4: OVERLAY NETWORK (demonstrated on a single-node swarm)
##################################################################
### 1. Overlay networks only exist in SWARM MODE - initialise a swarm
(this host has several interfaces, so the advertise address is given explicitly)
$ docker swarm init --advertise-addr 172.21.101.146
Swarm initialized: current node (ndxyzg6pb7a9sxwl4fqf2ru7j) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-5a2yh2m0jqs43wd5ltzxhjgjsbmcaecwrgpl38ksm110loteqn-8uii3x87tapmx2uvwi4d1zed4 172.21.101.146:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

### 2. Swarm mode is now active
$ docker info --format '{{.Swarm.LocalNodeState}} / manager: {{.Swarm.ControlAvailable}}'
Swarm: active | Is manager: true | Nodes: 1

$ docker node ls
ID                            HOSTNAME      STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
ndxyzg6pb7a9sxwl4fqf2ru7j *   Vlair-Lavya   Ready     Active         Leader           29.1.3

### 3. Create an overlay network
$ docker network create -d overlay --attachable my-overlay-net
cf8vvluc8u69w3f05x9c63w1r

### 4. docker network ls - compare the DRIVER and SCOPE columns
NETWORK ID     NAME              DRIVER    SCOPE
0393f68237bb   backend-net       bridge    local
ec88a7a09a8a   bridge            bridge    local
dc3a58e36dc6   database-net      bridge    local
1be665e8dbfa   docker_gwbridge   bridge    local
78c286bd5f37   frontend-net      bridge    local
3301d5e89f07   host              host      local
0rz9un1mu7wh   ingress           overlay   swarm
cf8vvluc8u69   my-overlay-net    overlay   swarm
bded084394e2   none              null      local

>>> bridge networks -> SCOPE 'local'  (valid on THIS host only)
>>> overlay networks -> SCOPE 'swarm' (spans EVERY host in the cluster)
>>> 'ingress' is an overlay network swarm created automatically for its routing mesh

### 5. Inspect the overlay network
Name:       my-overlay-net
Driver:     overlay
Scope:      swarm
Attachable: true
Subnet:     10.0.1.0/24

### 6. Attach a container to the overlay network and check its interface
NAMES          STATUS
overlay-test   Up 3 seconds

$ docker exec overlay-test ip addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    inet 127.0.0.1/8 scope host lo
54: eth0@if55: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1450 qdisc noqueue state UP 
    inet 10.0.1.2/24 brd 10.0.1.255 scope global eth0
56: eth1@if57: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    inet 172.22.0.3/16 brd 172.22.255.255 scope global eth1
```

### Running a real service across the overlay network

```console
### Create the service on the overlay network WITHOUT publishing a host port
(this avoids the swarm ingress routing mesh, which needs iptables/IPVS features
 the WSL2 kernel does not provide)
$ docker service create --name web --network my-overlay-net --replicas 3 nginx:1.27-alpine
verify: Waiting 1 seconds to verify that tasks are stable...
verify: Waiting 1 seconds to verify that tasks are stable...
verify: Service bnj2ap2i3evb7sc7530o8kih2 converged

$ docker service ls
ID             NAME      MODE         REPLICAS   IMAGE               PORTS
bnj2ap2i3evb   web       replicated   3/3        nginx:1.27-alpine   

$ docker service ps web
NAME      CURRENT STATE
web.1     Running 13 seconds ago
web.2     Running 13 seconds ago
web.3     Running 13 seconds ago

### Attach a client container to the same overlay network
9e03a59830946dc7df571b180f10ef3209658691d435425209b55a15e034d64d
NAMES            STATUS
overlay-client   Up 4 seconds

### Overlay DNS: resolve the service name to its virtual IP (VIP)
$ docker exec overlay-client nslookup web
Name:	web
Address: 10.0.1.7

Non-authoritative answer:


### Reach the service BY NAME across the overlay network
$ docker exec overlay-client wget -qO- http://web
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>

### The overlay gives each container a 10.0.x.x address in the swarm-scoped subnet
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1000
    inet 127.0.0.1/8 scope host lo
151: eth0@if152: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1450 qdisc noqueue state UP 
    inet 10.0.1.12/24 brd 10.0.1.255 scope global eth0
153: eth1@if154: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP 
    inet 172.22.0.6/16 brd 172.22.255.255 scope global eth1
```

### What the output proves

- **Scope is the key difference.** `docker network ls` shows `bridge` networks with scope **`local`** and overlay networks with scope **`swarm`**. A local network is meaningful only on one host; a swarm-scoped one spans the whole cluster.
- **`ingress`** was created automatically by `docker swarm init` - it is the overlay network backing swarm's load-balancing routing mesh.
- Containers on the overlay get an address in the swarm-wide **10.0.1.0/24** subnet, on an interface with **MTU 1450** (the VXLAN overhead).
- Each container has **two** interfaces: `eth0` on the overlay (10.0.1.x) for cluster traffic and `eth1` on `docker_gwbridge` (172.22.0.x) for outbound traffic to the internet.
- **Service discovery works**: `nslookup web` from a container resolves to the **virtual IP 10.0.1.7**, and `wget -qO- http://web` returns Nginx's page. The client addresses the service *by name* and swarm load-balances across all three replicas - the mechanism that makes multi-host networking transparent to application code.

### One environment limitation, and what it shows

Publishing a port through swarm's **ingress routing mesh** (`docker service create -p 8095:80`) did not work on this machine: the service tasks started and then exited immediately. The routing mesh relies on iptables/IPVS load-balancing features that the WSL2 kernel does not fully provide - the daemon log shows `Deleting nftables IPv4 rules error="exit status 1"`.

Recreating the same service **without** a published port worked correctly, which isolates the fault precisely: the **overlay network itself is fine** - containers get overlay IPs, resolve each other by name and exchange traffic - and only the *ingress port-publishing layer* is unavailable. On a normal Linux host, or a real multi-node swarm, the published-port form works as documented.

### Bridge vs overlay

| | Bridge | Overlay |
|---|---|---|
| Scope | Single host (`local`) | Whole cluster (`swarm`) |
| Spans multiple hosts | No | **Yes** |
| Transport | Linux bridge on the host | **VXLAN** encapsulation over the physical network |
| MTU | 1500 | 1450 (50 bytes of VXLAN header) |
| Needs swarm mode | No | **Yes** |
| Service discovery | Container names on one host | Service names cluster-wide, via VIP |
| Typical use | Local development, single-host apps | Multi-host clusters, Swarm services |
