# DevOps Assignment 1

**Name:** Lavya
**Enrollment Number:** 24BCS10124

My homework for all seven modules. Everything here was actually run: the output blocks are copied from my terminal and the screenshots are of the containers actually running on my machine.

## What's in here

| Module | What I did |
|---|---|
| [Linux-Fundamentals](Linux-Fundamentals/README.md) | Hard vs soft links, `adduser` vs `useradd`, `journalctl`, cheat sheet |
| [Shell-Scripting](Shell-Scripting/README.md) | `sysinfo.sh`, a system report script |
| [Networking](Networking/README.md) | 15 networking commands and what each one told me |
| [Git-GitHub](Git-GitHub/README.md) | `commit -a -m` vs `commit -m`, and cherry-pick |
| [Docker-Fundamentals](Docker-Fundamentals/README.md) | Six Hello World apps, one container each |
| [Docker-images](Docker-images/README.md) | Multi-stage build on port 8080 |
| [Docker-Networking](Docker-Networking/README.md) | Custom networks, host network, bind mounts, overlay |

## Setup

Docker wasn't installed on my machine, so I installed **Docker Engine 29.1.3 inside WSL2** rather than Docker Desktop, since it doesn't need admin rights or a reboot:

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
sudo usermod -aG docker $USER    # log out and back in
docker run --rm hello-world
```

Everything runs on Ubuntu 26.04 (WSL2), kernel 6.18.33.2.

## The nine apps I built and ran

| App | Port | Image |
|---|---|---|
| Node.js (Express) | 8081 | `hello-nodejs:1.0` |
| Python (Flask) | 8082 | `hello-python:1.0` |
| Java (JDK HttpServer) | 8083 | `hello-java:1.0` |
| Apache | 8084 | `hello-apache:1.0` |
| React (Vite + Nginx) | 8085 | `hello-react:1.0` |
| Nginx | 8086 | `hello-nginx:1.0` |
| Go multi-stage | 8080 | `multistage-hello:1.0` |
| Apache on host network | 80 | `httpd:2.4` |
| Nginx with bind mount | 8090 | `nginx:1.27-alpine` |

All nine answered with HTTP 200:

```console
$ for p in 80 8080 8081 8082 8083 8084 8085 8086 8090; do
>   echo "port $p -> HTTP $(curl -s -o /dev/null -w '%{http_code}' http://localhost:$p)"
> done
port 80 -> HTTP 200
port 8080 -> HTTP 200
port 8081 -> HTTP 200
port 8082 -> HTTP 200
port 8083 -> HTTP 200
port 8084 -> HTTP 200
port 8085 -> HTTP 200
port 8086 -> HTTP 200
port 8090 -> HTTP 200
```

To build and run any of them:

```bash
cd Docker-Fundamentals/nodejs-app
docker build -t hello-nodejs:1.0 .
docker run -d --name hello-nodejs -p 8081:3000 hello-nodejs:1.0
curl http://localhost:8081
```

## Screenshots

All in [`screenshots/`](screenshots/), and embedded in the module READMEs where they're relevant.

| File | What it shows |
|---|---|
| 01 to 06 | The six Hello World apps in a browser |
| 07 | Multi-stage build on port 8080 |
| 08 | Apache on the host network, port 80 |
| 09 and 10 | Bind mount before and after editing the file on the host |

## Things I found interesting

**Multi-stage builds took my image from 477 MB to 7.3 MB.** Same app, 65x smaller, because the final image is `scratch` with just the compiled binary in it. No shell, no package manager, nothing to attack.

**Network isolation is a DNS failure, not a timeout.** My frontend container couldn't even *resolve* the name `database`, because they shared no network. I expected a hang; it failed instantly.

**Bind mounts update live.** I edited `index.html` on my host and refreshed, and the container served the new file without a restart.

**Hard links survive deleting the original.** Soft links don't. Seeing the inode numbers match made this obvious in a way reading about it never did.

**Cherry-pick copies the change, not the commit.** The same change ended up on two branches with two different hashes.
