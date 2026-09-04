# Docker Networking and Volumes

---

## Task 1: Three containers, three networks

I made a frontend (Nginx), a backend (Alpine) and a database (MySQL), then put them on separate networks with the backend bridging two of them:

```
frontend-net:   frontend  <->  backend
database-net:                  backend  <->  database
backend-net:    (third network, created but unused)
```

```bash
docker network create frontend-net
docker network create backend-net
docker network create database-net

docker run -d --name frontend --network frontend-net nginx:1.27-alpine
docker run -d --name backend  --network frontend-net alpine:3.20 sleep infinity
docker run -d --name database --network database-net -e MYSQL_ROOT_PASSWORD=rootpass mysql:8

docker network connect database-net backend    # backend joins a 2nd network
```

After that, the backend has an interface on each network it joined:

```console
backend
database-net => 172.20.0.3
frontend-net => 172.18.0.3
```

### Testing connectivity

Backend to frontend works, and backend to database works, because each pair shares a network. The interesting one is frontend to database:

```console
$ docker exec backend ping -c 3 database
64 bytes from database.database-net (172.20.0.2): icmp_seq=1 ttl=64 time=20.3 ms
3 packets transmitted, 3 received, 0% packet loss, time 2019ms

$ docker exec backend nc -zv database 3306
database (172.20.0.2:3306) open

$ docker exec frontend ping -c 2 database
ping: bad address 'database'
```

That last line is the part I didn't expect. I assumed an isolation failure would look like a timeout, but it's `bad address` instead. The name doesn't even **resolve**. Docker runs a DNS server per network, so a container can only look up names of containers it shares a network with. The database isn't unreachable so much as invisible, and it fails instantly rather than hanging.

So the backend is the only route between the frontend and the database, which is exactly how you'd separate tiers in a real app.

<details>
<summary>Full Task 1 output (networks, IPs, DNS lookups, inspect)</summary>

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
Unable to find image 'alpine:3.20' locally
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
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

</details>

---

## Task 2: Host network

With `--network host` the container skips Docker's virtual networking and uses the host's network stack directly. No `-p` flag, and no port mapping to set up.

```bash
docker pull httpd:2.4
docker run -d --name apache-host --network host httpd:2.4
```

```console
$ docker ps
NAMES         IMAGE       STATUS         PORTS
apache-host   httpd:2.4   Up 4 seconds   

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
```

Note the **PORTS column is empty**. With bridge networking it would show `0.0.0.0:80->80/tcp`. There's no mapping because there's nothing to map: Apache is listening on the host's port 80 as if I'd installed it directly.

![Apache on the host network, port 80](../screenshots/08-apache-host-network-port80.png)

It's faster since there's no NAT layer, but you lose isolation and you can only have one container per port.

---

## Task 3: Bind mount

A bind mount points a folder on my machine straight into the container, so the container reads my actual files rather than a copy.

```bash
docker run -d --name nginx-bind -p 8090:80 \
  -v /path/to/bind-mount-demo:/usr/share/nginx/html:ro \
  nginx:1.27-alpine
```

I started with an `index.html` saying "Hello students":

![Bind mount serving the original file](../screenshots/09-bind-mount-before.png)

Then I edited that file on my host and refreshed, **without touching the container**:

![The same container after editing the file on the host](../screenshots/10-bind-mount-after.png)

```console
$ docker ps --filter name=nginx-bind
NAMES        STATUS
nginx-bind   Up 3 seconds

$ curl -s http://localhost:8090
    <h1>Hello students - THIS FILE WAS EDITED ON THE HOST</h1>
```

The `Up` time confirms it was never restarted. The new content appeared straight away, because Nginx opens the file fresh on each request and that file is genuinely mine, not a copy baked into the image.

I mounted it `:ro` (read only) so the container can serve the files but can't modify them. This is why bind mounts are so useful in development: edit code locally, refresh, done, with no rebuild.

The tradeoff is that it depends on the host's directory structure, so for production data you'd normally use a named volume instead.

<details>
<summary>Full Task 2 and 3 output</summary>

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


##################################################################
  TASK 4: OVERLAY NETWORK (demonstrated on a single-node swarm)
##################################################################
### 1. Overlay networks require swarm mode - initialise it
$ docker swarm init
Error response from daemon: could not choose an IP address to advertise since this system has multiple addresses on different interfaces (10.255.255.254 on lo and 172.21.101.146 on eth0) - specify one with --advertise-addr

### 2. Create an overlay network
$ docker network create -d overlay --attachable my-overlay-net
Error response from daemon: This node is not a swarm manager. Use "docker swarm init" or "docker swarm join" to 
connect this node to swarm and try again.
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 

### 3. List networks - note the DRIVER and SCOPE columns
$ docker network ls
NETWORK ID     NAME           DRIVER    SCOPE
0393f68237bb   backend-net    bridge    local
668ede996151   bridge         bridge    local
dc3a58e36dc6   database-net   bridge    local
78c286bd5f37   frontend-net   bridge    local
3301d5e89f07   host           host      local
bded084394e2   none           null      local

>>> bridge networks have SCOPE 'local' (this host only)
>>> overlay networks have SCOPE 'swarm' (spans ALL hosts in the cluster)

### 4. Inspect the overlay network
$ docker network inspect my-overlay-net

Error response from daemon: network my-overlay-net not found

### 5. Attach a container to the overlay network
docker: Error response from daemon: failed to set up container networking: network my-overlay-net not found

Run 'docker run --help' for more information
Error response from daemon: container 3ef8a16eaf2f0919231487915c4f1669298e9dd930641e38141731b5a0753a5c is not running

### 6. The ingress network was created automatically by swarm init
NETWORK ID   NAME      DRIVER    SCOPE
```

</details>

---

## Task 4: Overlay networks

Everything above is a **bridge** network, which only works on one host. An **overlay** network spans multiple Docker hosts, so a container on machine A can talk to one on machine B by name as if they were side by side. It does this by wrapping container traffic in VXLAN tunnels between the hosts.

Overlay networks need swarm mode, so I set up a single-node swarm:

```bash
docker swarm init --advertise-addr 172.21.101.146
docker network create -d overlay --attachable my-overlay-net
```

The `SCOPE` column is the thing to look at:

```console
NETWORK ID     NAME              DRIVER    SCOPE
0393f68237bb   backend-net       bridge    local
78c286bd5f37   frontend-net      bridge    local
0rz9un1mu7wh   ingress           overlay   swarm
cf8vvluc8u69   my-overlay-net    overlay   swarm
                    ... (bridge, host, none and the other bridge networks omitted)
```

`local` means the network only exists on this machine. `swarm` means it's shared across every node in the cluster. `ingress` is created automatically and handles the routing mesh.

I ran a 3-replica service on it and reached it by name from another container:

```console
$ docker service ls
ID             NAME      MODE         REPLICAS   IMAGE               PORTS
bnj2ap2i3evb   web       replicated   3/3        nginx:1.27-alpine

$ docker exec overlay-client nslookup web
Name:	web
Address: 10.0.1.7

$ docker exec overlay-client wget -qO- http://web
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

The address `10.0.1.7` is a **virtual IP**. It isn't any one of the three replicas; Docker load balances across them behind that single address, so the client just asks for `web` and doesn't care which replica answers.

**One honest limitation:** when I first published a port on the service (`-p 8095:80`), the replicas kept restarting and the port never served anything. The swarm routing mesh needs IPVS and iptables features the WSL2 kernel doesn't provide, and dockerd was logging nftables errors. Without a published port, running purely on the overlay, everything worked fine. So the overlay networking itself is genuinely working here; it's only the host-port publishing part that WSL can't do.

**Where you'd use one:** any time containers span more than one machine, which in practice means Swarm or Kubernetes clusters. On a single host a bridge network is simpler and faster.

<details>
<summary>Full Task 4 output (swarm init, network inspect, service, DNS)</summary>

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

</details>
