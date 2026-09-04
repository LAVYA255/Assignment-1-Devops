# DevOps Homework - Assignment 1

**Name:** Lavya

**Enrollment Number:** 24BCS10124

Completed homework for all seven modules: Linux Fundamentals, Shell Scripting, Networking, Git/GitHub, Docker Fundamentals, Dockerfiles & Images, and Docker Networking.

Every command in this repository was actually executed, and every output block is real captured terminal output. Every screenshot is a real browser capture of a running container.

---

## Contents

| Module | Folder | What it covers |
|---|---|---|
| Linux Fundamentals | [Linux-Fundamentals](Linux-Fundamentals/README.md) | Soft vs hard links, `adduser` vs `useradd`, `journalctl`, command cheat sheet |
| Shell Scripting | [Shell-Scripting](Shell-Scripting/README.md) | `sysinfo.sh` - system report with user input and output redirection |
| Networking | [Networking](Networking/README.md) | 15 networking commands with output and explanations |
| Git / GitHub | [Git-GitHub](Git-GitHub/README.md) | `git commit -a -m` vs `git commit -m`, cherry-pick |
| Docker Fundamentals | [Docker-Fundamentals](Docker-Fundamentals/README.md) | Six Hello World web apps, each containerised |
| Dockerfiles & Images | [Docker-images](Docker-images/README.md) | Multi-stage build on port 8080 |
| Docker Networking | [Docker-Networking](Docker-Networking/README.md) | Custom networks, host network, bind mounts, overlay networks |

---

## Environment

| | |
|---|---|
| OS | Ubuntu 26.04 LTS (WSL2 on Windows 11), kernel 6.18.33.2 |
| Docker | Docker Engine 29.1.3 |
| Node.js | 20 (Alpine, in-container) |
| Python | 3.12 (in-container) |
| Java | Eclipse Temurin 21 (in-container) |
| Go | 1.23 (build stage only) |

---

## Applications built and verified

Nine containers were built, run and confirmed to return HTTP 200.

| Application | Image | Host port | Module |
|---|---|---|---|
| Node.js (Express) | `hello-nodejs:1.0` | 8081 | Docker Fundamentals |
| Python (Flask) | `hello-python:1.0` | 8082 | Docker Fundamentals |
| Java (JDK HttpServer) | `hello-java:1.0` | 8083 | Docker Fundamentals |
| Apache (httpd) | `hello-apache:1.0` | 8084 | Docker Fundamentals |
| React (Vite + Nginx) | `hello-react:1.0` | 8085 | Docker Fundamentals |
| Nginx | `hello-nginx:1.0` | 8086 | Docker Fundamentals |
| Go multi-stage build | `multistage-hello:1.0` | 8080 | Dockerfiles & Images |
| Apache on host network | `httpd:2.4` | 80 | Docker Networking |
| Nginx with bind mount | `nginx:1.27-alpine` | 8090 | Docker Networking |

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

---

## Screenshots

All screenshots are in [`screenshots/`](screenshots/).

| Screenshot | Shows |
|---|---|
| [01-nodejs-app.png](screenshots/01-nodejs-app.png) | Node.js Hello World, port 8081 |
| [02-python-app.png](screenshots/02-python-app.png) | Python Hello World, port 8082 |
| [03-java-app.png](screenshots/03-java-app.png) | Java Hello World, port 8083 |
| [04-apache-app.png](screenshots/04-apache-app.png) | Apache Hello World, port 8084 |
| [05-react-app.png](screenshots/05-react-app.png) | React Hello World, port 8085 |
| [06-nginx-app.png](screenshots/06-nginx-app.png) | Nginx Hello World, port 8086 |
| [07-multistage-build-8080.png](screenshots/07-multistage-build-8080.png) | Multi-stage build message, port 8080 |
| [08-apache-host-network-port80.png](screenshots/08-apache-host-network-port80.png) | Apache on the host network, port 80 |
| [09-bind-mount-before.png](screenshots/09-bind-mount-before.png) | Bind mount serving the original file |
| [10-bind-mount-after.png](screenshots/10-bind-mount-after.png) | Same container after editing the file on the host |

---

## Repository structure

```
Assignment1/
├── README.md
├── Linux-Fundamentals/
│   └── README.md
├── Shell-Scripting/
│   ├── README.md
│   └── sysinfo.sh
├── Networking/
│   └── README.md
├── Git-GitHub/
│   └── README.md
├── Docker-Fundamentals/
│   ├── README.md
│   ├── nodejs-app/    server.js, package.json, Dockerfile, .dockerignore
│   ├── python-app/    app.py, requirements.txt, Dockerfile
│   ├── java-app/      HelloWorld.java, Dockerfile
│   ├── apache-app/    index.html, Dockerfile
│   ├── react-app/     src/, index.html, vite.config.js, package.json, Dockerfile
│   └── nginx-app/     index.html, Dockerfile
├── Docker-images/
│   ├── README.md
│   ├── main.go, go.mod
│   ├── Dockerfile               (multi-stage)
│   └── Dockerfile.singlestage   (for size comparison)
├── Docker-Networking/
│   ├── README.md
│   └── bind-mount-demo/index.html
└── screenshots/
```

---

## Reproducing this work

Docker Engine was installed inside WSL2 rather than via Docker Desktop, since it installs without administrator rights or a reboot:

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
sudo usermod -aG docker $USER      # log out and back in for this to take effect
docker run --rm hello-world
```

Then build and run any application:

```bash
cd Docker-Fundamentals/nodejs-app
docker build -t hello-nodejs:1.0 .
docker run -d --name hello-nodejs -p 8081:3000 hello-nodejs:1.0
curl http://localhost:8081
```

The running containers were given `--restart unless-stopped`, so they come back automatically after a Docker daemon or WSL restart.

---

## Highlights

**Multi-stage builds cut the image from 477 MB to 7.3 MB** - a 65× reduction for the same application, with no shell or package manager left in the final `scratch` image. See [Docker-images](Docker-images/README.md).

**Container network isolation demonstrated, not just described.** The frontend cannot even *resolve* the database's name, because they share no network - a DNS failure rather than a timeout. See [Docker-Networking](Docker-Networking/README.md).

**Bind mounts reflect host edits live.** The same container, never restarted, serves updated content the instant the host file changes - captured in before/after screenshots.

**Hard links survive deleting the original; soft links do not.** Proven with inode numbers and link counts. See [Linux-Fundamentals](Linux-Fundamentals/README.md).

**Cherry-pick copies the change, not the commit.** The graph shows the same change on two branches under two different hashes. See [Git-GitHub](Git-GitHub/README.md).
