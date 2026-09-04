# Networking

I ran 15 networking commands and wrote down what each one actually told me.

## The commands, and what I got from them

**`ip addr show`** lists every network interface and its IP. My WSL machine's `eth0` is on `172.21.101.146/20`. This is the modern replacement for `ifconfig`.

**`ip route show`** shows where traffic goes. The `default via ...` line is the gateway, which is where anything not on my local network gets sent. If this line is missing, nothing outside your subnet works.

```console
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
```

**`hostname -I`** is the quick way to get the machine's IP without reading through `ip addr`.

**`ping`** sends ICMP packets to test if a host is reachable and how long the round trip takes. To `8.8.8.8` I got 0% loss at around 20ms average. Ping tells you reachability and latency, but nothing about whether a specific *service* is up, since a machine can answer ping while the web server on it is dead.

**`traceroute`** shows every router between me and the target. Going to 8.8.8.8 took 7 hops: my WSL gateway, my home router, my ISP, then into Google's network. It works by sending packets with increasing TTL so each router in turn reports back. Useful for finding *where* a connection slows down rather than just that it's slow.

Interesting: `traceroute google.com` only showed hop 1 and then nothing, while `8.8.8.8` traced all the way. Plenty of routers just don't reply to these probes, so gaps in a traceroute are normal and don't mean the path is broken.

**`nslookup`** and **`dig`** both do DNS lookups, turning a name into an IP. `dig` gives much more detail; `dig google.com +short` cuts it down when you only want the answer. I used `dig google.com MX` to see mail servers.

**`ss -tuln`** lists listening sockets, so it answers "what is running on my machine and on which port". It's the modern, faster replacement for `netstat`. I also ran **`netstat -tuln`** to compare, and the output is nearly the same.

**`curl`** makes an actual HTTP request. `curl -I` fetches just the headers, which is the fastest way to check a status code or a redirect. This is what I used all through the Docker tasks to confirm containers were really serving pages.

**`wget`** also downloads over HTTP, but it saves to a file by default and can recurse through a site. Rough rule I settled on: `curl` to inspect something, `wget` to download it.

**`ip neigh`** shows the ARP table, which maps IP addresses to MAC addresses on the local network. IP routing gets a packet to the right network, then ARP gets it to the right physical machine.

**`nc -zv host port`** tests whether a single TCP port is open. This was the most genuinely useful thing I learned: port 443 on google.com came back `succeeded`, while port 81 timed out. Ping only tells you the machine is alive, but `nc` tells you the *service* is actually accepting connections, which is the question you usually care about.

**`/etc/resolv.conf`** holds the DNS servers the machine uses, and **`/etc/hosts`** is checked before DNS, so it can override any name locally.

## What tied it together

Debugging a connection now has an order to it: `ip addr` (do I have an IP?), `ip route` (is there a gateway?), `ping` (can I reach it?), `dig` (does the name resolve?), `nc` (is the port open?), then `curl` (does the app respond?). Each step rules out one layer.

<details>
<summary>Full output of all 15 commands</summary>

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

</details>
