# Networking Fundamentals

Networking commands practised on **Ubuntu 26.04 LTS** (WSL2), with the real output of each and an explanation of what it does and what the result means.

---

## Command reference

| Command | What it does |
|---|---|
| `ip addr show` | Lists network interfaces and their IP addresses |
| `ip route show` | Shows the routing table, including the default gateway |
| `hostname` / `hostname -I` | The machine's name / its IP addresses |
| `ping host` | Tests reachability and measures round-trip latency using ICMP |
| `traceroute host` | Shows every router hop between you and the destination |
| `nslookup domain` | Resolves a domain name to an IP address |
| `dig domain` | Detailed DNS query with full record information |
| `ss -tuln` | Lists listening sockets (the modern replacement for `netstat`) |
| `netstat -tuln` | Legacy equivalent of `ss` |
| `curl url` | Makes an HTTP request from the command line |
| `wget url` | Downloads a file over HTTP/HTTPS |
| `ip neigh` | The ARP table - MAC addresses of local neighbours |
| `nc -zv host port` | Tests whether a specific TCP port is open |
| `cat /etc/resolv.conf` | Shows which DNS servers the system uses |
| `cat /etc/hosts` | Static, local name-to-IP mappings checked before DNS |

Flags worth knowing: `-t` TCP, `-u` UDP, `-l` listening only, `-n` numeric (skip DNS lookups, much faster), `-c N` send N pings, `-z` scan without sending data, `-v` verbose.

---

## Output of every command

```console
########## 1. ip addr - show interfaces and IP addresses ##########
$ ip addr show
---
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet 10.255.255.254/32 brd 10.255.255.254 scope global lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host proto kernel_lo 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:e9:63:f6 brd ff:ff:ff:ff:ff:ff
    altname enx00155de963f6
    inet 172.21.101.146/20 brd 172.21.111.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::215:5dff:fee9:63f6/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 52:5f:70:2a:ef:90 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::505f:70ff:fe2a:ef90/64 scope link proto kernel_ll 
       valid_lft forever preferred_lft forever


########## 2. ip route - show the routing table ##########
$ ip route show
---
default via 172.21.96.1 dev eth0 proto kernel 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
172.21.96.0/20 dev eth0 proto kernel scope link src 172.21.101.146 


########## 3. hostname - identify the machine ##########
$ hostname
---
Vlair-Lavya


$ hostname -I
---
172.21.101.146 172.17.0.1 


########## 4. ping - test reachability + measure latency ##########
$ ping -c 4 8.8.8.8
---
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=119 time=17.7 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=119 time=31.2 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=119 time=16.0 ms
64 bytes from 8.8.8.8: icmp_seq=4 ttl=119 time=18.5 ms

--- 8.8.8.8 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
rtt min/avg/max/mdev = 15.978/20.848/31.164/6.026 ms


$ ping -c 3 google.com
---
PING google.com (192.178.173.102) 56(84) bytes of data.
64 bytes from lcbome-in-f102.1e100.net (192.178.173.102): icmp_seq=1 ttl=115 time=19.9 ms
64 bytes from lcbome-in-f102.1e100.net (192.178.173.102): icmp_seq=2 ttl=115 time=27.9 ms
64 bytes from lcbome-in-f102.1e100.net (192.178.173.102): icmp_seq=3 ttl=115 time=15.8 ms

--- google.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 15.762/21.180/27.879/5.028 ms


########## 5. traceroute - show the hop-by-hop path ##########
﻿$ traceroute -m 12 -w 1 -q 1 google.com
---
traceroute to google.com (192.178.173.113), 12 hops max, 60 byte packets
 1  Vlair-Lavya.mshome.net (172.21.96.1)  0.342 ms
$ traceroute -m 12 -w 1 -q 1 8.8.8.8
---
traceroute to 8.8.8.8 (8.8.8.8), 12 hops max, 60 byte packets
 1  Vlair-Lavya.mshome.net (172.21.96.1)  0.639 ms
 2  wifi.height8tech.com (100.128.160.1)  121.872 ms
 3  114.79.130.29.dvois.com (114.79.130.29)  141.076 ms
 4  72.14.208.165 (72.14.208.165)  141.025 ms
 5  192.178.110.123 (192.178.110.123)  141.015 ms
 6  192.178.86.243 (192.178.86.243)  140.984 ms
 7  dns.google (8.8.8.8)  131.781 ms


########## 6. nslookup - DNS lookup ##########
$ nslookup google.com
---
Server:		10.255.255.254
Address:	10.255.255.254#53

Non-authoritative answer:
Name:	google.com
Address: 192.178.173.113
Name:	google.com
Address: 192.178.173.100
Name:	google.com
Address: 192.178.173.138
Name:	google.com
Address: 192.178.173.139
Name:	google.com
Address: 192.178.173.101
Name:	google.com
Address: 192.178.173.102
Name:	google.com
Address: 2404:6800:4000:101d::64
Name:	google.com
Address: 2404:6800:4000:101d::8a
Name:	google.com
Address: 2404:6800:4000:101d::66
Name:	google.com
Address: 2404:6800:4000:101d::8b



########## 7. dig - detailed DNS query ##########
$ dig google.com +noall +answer
---
google.com.		243	IN	A	192.178.173.138
google.com.		243	IN	A	192.178.173.139
google.com.		243	IN	A	192.178.173.101
google.com.		243	IN	A	192.178.173.102
google.com.		243	IN	A	192.178.173.113
google.com.		243	IN	A	192.178.173.100


$ dig google.com MX +short
---
10 smtp.google.com.


########## 8. ss - socket statistics (modern netstat) ##########
$ ss -tuln
---
Netid State  Recv-Q Send-Q  Local Address:Port  Peer Address:Port
udp   UNCONN 0      0          127.0.0.54:53         0.0.0.0:*   
udp   UNCONN 0      0       127.0.0.53%lo:53         0.0.0.0:*   
udp   UNCONN 0      0      10.255.255.254:53         0.0.0.0:*   
udp   UNCONN 0      0           127.0.0.1:323        0.0.0.0:*   
udp   UNCONN 0      0           127.0.0.1:323        0.0.0.0:*   
udp   UNCONN 0      0               [::1]:323           [::]:*   
udp   UNCONN 0      0               [::1]:323           [::]:*   
tcp   LISTEN 0      4096          0.0.0.0:8083       0.0.0.0:*   
tcp   LISTEN 0      4096          0.0.0.0:8082       0.0.0.0:*   
tcp   LISTEN 0      4096          0.0.0.0:8081       0.0.0.0:*   
tcp   LISTEN 0      4096          0.0.0.0:8080       0.0.0.0:*   
tcp   LISTEN 0      4096          0.0.0.0:8086       0.0.0.0:*   
tcp   LISTEN 0      4096          0.0.0.0:8085       0.0.0.0:*   
tcp   LISTEN 0      4096          0.0.0.0:8084       0.0.0.0:*   
tcp   LISTEN 0      1000   10.255.255.254:53         0.0.0.0:*   
tcp   LISTEN 0      4096        127.0.0.1:35433      0.0.0.0:*   
tcp   LISTEN 0      4096    127.0.0.53%lo:53         0.0.0.0:*   
tcp   LISTEN 0      4096       127.0.0.54:53         0.0.0.0:*   
tcp   LISTEN 0      4096             [::]:8083          [::]:*   
tcp   LISTEN 0      4096             [::]:8082          [::]:*   
tcp   LISTEN 0      4096             [::]:8081          [::]:*   
tcp   LISTEN 0      4096             [::]:8080          [::]:*   
tcp   LISTEN 0      4096             [::]:8086          [::]:*   
tcp   LISTEN 0      4096             [::]:8085          [::]:*   
tcp   LISTEN 0      4096             [::]:8084          [::]:*   


########## 9. netstat - listening ports (legacy tool) ##########
$ netstat -tuln | head -15
---
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State      
tcp        0      0 0.0.0.0:8083            0.0.0.0:*               LISTEN     
tcp        0      0 0.0.0.0:8082            0.0.0.0:*               LISTEN     
tcp        0      0 0.0.0.0:8081            0.0.0.0:*               LISTEN     
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN     
tcp        0      0 0.0.0.0:8086            0.0.0.0:*               LISTEN     
tcp        0      0 0.0.0.0:8085            0.0.0.0:*               LISTEN     
tcp        0      0 0.0.0.0:8084            0.0.0.0:*               LISTEN     
tcp        0      0 10.255.255.254:53       0.0.0.0:*               LISTEN     
tcp        0      0 127.0.0.1:35433         0.0.0.0:*               LISTEN     
tcp        0      0 127.0.0.53:53           0.0.0.0:*               LISTEN     
tcp        0      0 127.0.0.54:53           0.0.0.0:*               LISTEN     
tcp6       0      0 :::8083                 :::*                    LISTEN     
tcp6       0      0 :::8082                 :::*                    LISTEN     


########## 10. curl - make an HTTP request ##########
$ curl -s -I https://www.google.com | head -8
---
HTTP/2 200 
content-type: text/html; charset=ISO-8859-1
content-security-policy-report-only: object-src 'none';base-uri 'self';script-src 'nonce-Ia_wptZ3c09TDuAb9Z7hOQ' 'strict-dynamic' 'report-sample' 'unsafe-eval' 'unsafe-inline' https: http:;report-uri https://csp.withgoogle.com/csp/gws/other-hp
accept-ch: Sec-CH-Prefers-Color-Scheme
p3p: CP="This is not a P3P policy! See g.co/p3phelp for more info."
date: Thu, 03 Sep 2026 18:35:25 GMT
server: gws
x-xss-protection: 0


$ curl -s https://api.github.com/zen
---
Anything added dilutes everything else.

########## 11. wget - download over HTTP ##########
$ wget -q -O /tmp/gh.html https://github.com && ls -lh /tmp/gh.html && echo 'download OK'
---
-rw-r--r-- 1 root root 560K Sep  3 18:35 /tmp/gh.html
download OK


########## 12. arp / ip neigh - MAC address table ##########
$ ip neigh show
---
172.17.0.4 dev docker0 lladdr 3a:e7:63:43:0c:d0 STALE 
172.17.0.3 dev docker0 lladdr 4a:0a:64:f7:aa:80 STALE 
172.17.0.2 dev docker0 lladdr ca:af:64:03:ac:2e STALE 
172.21.96.1 dev eth0 lladdr 00:15:5d:db:63:f8 REACHABLE 
172.17.0.8 dev docker0 lladdr 06:e3:66:6e:00:67 REACHABLE 
172.17.0.7 dev docker0 lladdr 62:4d:7a:86:9e:38 STALE 
172.17.0.6 dev docker0 lladdr c2:c9:d7:4d:e5:f4 STALE 
172.17.0.5 dev docker0 lladdr 82:bf:0a:db:20:dc STALE 


########## 13. nc (netcat) - test whether a TCP port is open ##########
$ nc -zv -w 3 google.com 443
---
Connection to google.com (192.178.173.101) 443 port [tcp/https] succeeded!


$ nc -zv -w 3 google.com 81
---
nc: connect to google.com (192.178.173.113) port 81 (tcp) timed out: Operation now in progress
nc: connect to google.com (192.178.173.100) port 81 (tcp) timed out: Operation now in progress
nc: connect to google.com (192.178.173.138) port 81 (tcp) timed out: Operation now in progress
nc: connect to google.com (192.178.173.139) port 81 (tcp) timed out: Operation now in progress
nc: connect to google.com (192.178.173.101) port 81 (tcp) timed out: Operation now in progress
nc: connect to google.com (192.178.173.102) port 81 (tcp) timed out: Operation now in progress
nc: connect to google.com (2404:6800:4000:101d::64) port 81 (tcp) failed: Network is unreachable
nc: connect to google.com (2404:6800:4000:101d::8a) port 81 (tcp) failed: Network is unreachable
nc: connect to google.com (2404:6800:4000:101d::66) port 81 (tcp) failed: Network is unreachable
nc: connect to google.com (2404:6800:4000:101d::8b) port 81 (tcp) failed: Network is unreachable


########## 14. DNS resolver configuration ##########
$ cat /etc/resolv.conf
---
# This file was automatically generated by WSL. To stop automatic generation of this file, add the following entry to /etc/wsl.conf:
# [network]
# generateResolvConf = false
nameserver 10.255.255.254


########## 15. /etc/hosts - local name resolution ##########
$ cat /etc/hosts
---
# This file was automatically generated by WSL. To stop automatic generation of this file, add the following entry to /etc/wsl.conf:
# [network]
# generateHosts = false
127.0.0.1	localhost
127.0.1.1	Vlair-Lavya.localdomain	Vlair-Lavya

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

---

## What I understood from each command

### 1. `ip addr show`
Lists every network interface with its IP address, MAC address and state. Here `eth0` holds **172.21.101.146/20** - the address WSL2 gets on its virtual switch - alongside the `lo` loopback interface on 127.0.0.1. This is the first command to run when a machine "has no network": if there is no IP on the interface, nothing else will work. The `docker0` interface on **172.17.0.1/16** is the bridge Docker created for containers - it shows up here as soon as Docker is installed.

### 2. `ip route show`
The routing table - the kernel's decision list for where to send a packet. The `default via ...` line is the **default gateway**, used for any destination not matched by a more specific route. A missing default route is the classic cause of "I can ping local machines but not the internet".

### 3. `hostname` / `hostname -I`
`hostname` returns the machine's name (`Vlair-Lavya`); `-I` prints just its IP addresses, which is handy in scripts because it avoids parsing `ip addr` output.

### 4. `ping`
Sends ICMP echo requests and reports which came back and how long each took. Both tests show **0% packet loss**, with round-trip times around 16-31 ms to 8.8.8.8. `ping google.com` additionally proves DNS is working, because the name had to be resolved to 192.178.173.102 before any packet was sent. The `ttl=119` value is the remaining time-to-live: each router decrements it, so a lower number means more hops were crossed.

Pinging an **IP** tests pure connectivity; pinging a **name** tests DNS *and* connectivity. Comparing the two isolates a DNS fault from a routing fault.

### 5. `traceroute`
Maps the path to a destination by sending packets with deliberately small TTL values, so each router along the way is forced to reply. The trace to 8.8.8.8 shows the full seven-hop path: the WSL gateway (172.21.96.1), the local ISP (`wifi.height8tech.com`, `dvois.com`), then Google's network (72.14.208.165 onwards) and finally `dns.google`. This pinpoints *where* latency appears - the 121 ms jump at hop 2 is the local ISP link.

The trace to `google.com` stops after hop 1 because those routers are configured not to reply to the probes. `*` or an early stop means "this hop stayed silent", not necessarily "the path is broken".

### 6. `nslookup`
The basic DNS lookup: a domain name in, IP addresses out. It also names the resolver that answered, which matters when you are debugging whether a stale or wrong DNS server is being used.

### 7. `dig`
A more detailed DNS tool. `dig google.com +noall +answer` prints just the answer section with the record type and its **TTL** (how long it may be cached). `dig google.com MX +short` fetches mail-exchanger records, showing that DNS carries far more than address records - `A`, `AAAA`, `MX`, `CNAME`, `TXT`, `NS`.

### 8. `ss -tuln`
Lists sockets in the listening state. This answers "is my service actually up, and on which interface?" A service bound to `127.0.0.1` accepts only local connections, while one bound to `0.0.0.0` accepts connections from anywhere - a distinction that explains a great many "the port is open but I cannot connect" problems.

### 9. `netstat -tuln`
The older tool that does the same job. It still appears everywhere in documentation, but `ss` is faster and is what modern systems ship, so `ss` is the one to reach for.

### 10. `curl`
Makes HTTP requests from the terminal. `curl -I` fetches only the **response headers**, which is enough to check a status code, a redirect target or which server is answering, without downloading the body. `curl` is the standard tool for testing an API or confirming a web service is alive.

### 11. `wget`
Downloads files over HTTP/HTTPS. The practical split: `curl` is for *inspecting* and interacting with endpoints, `wget` is for *retrieving* files (and, with `-r`, recursively mirroring a site).

### 12. `ip neigh`
The ARP table, mapping IP addresses to the MAC addresses of machines on the local segment. ARP is what makes delivery on a local network possible, since Ethernet frames are addressed by MAC, not IP. Relevant only to the local subnet - anything beyond the gateway is never in this table.

### 13. `nc` (netcat)
Tests whether a TCP port accepts connections. The contrast in the output is the useful part: port **443 on google.com reports `open`**, while port **81 times out**. This distinguishes "the host is up but the service is not listening" from "the host is unreachable", and is the fastest way to check whether a firewall is blocking a port.

### 14. `/etc/resolv.conf`
Lists the DNS servers (`nameserver` entries) the system consults. If name resolution fails while raw IP connectivity works, this file is the first place to look.

### 15. `/etc/hosts`
Static name-to-IP mappings, checked **before** DNS. Useful for pointing a hostname at a test server locally without touching real DNS - and worth remembering, because an entry here silently overrides the DNS answer.

---

## The mental model

The commands map onto the network stack, and that ordering is what makes troubleshooting systematic:

| Layer | Question | Command |
|---|---|---|
| Interface | Do I have an IP? | `ip addr` |
| Routing | Do I know where to send packets? | `ip route` |
| Reachability | Can I reach the destination? | `ping` |
| Path | Where does it break or slow down? | `traceroute` |
| Naming | Do names resolve to addresses? | `nslookup`, `dig` |
| Ports | Is the service listening / reachable? | `ss`, `nc` |
| Application | Does the service answer correctly? | `curl` |

Working down that list in order localises almost any connectivity fault to a single layer.
