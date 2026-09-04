# Docker Fundamentals - Hello World Applications

Six Hello World web applications, each in its own folder with its own Dockerfile, each built into an image, run as a container and verified in a browser.

Environment: **Docker Engine 29.1.3** on Ubuntu 26.04 LTS (WSL2).

---

## Folder structure

```
Docker-Fundamentals/
├── nodejs-app/     server.js, package.json, Dockerfile, .dockerignore
├── python-app/     app.py, requirements.txt, Dockerfile
├── java-app/       HelloWorld.java, Dockerfile
├── apache-app/     index.html, Dockerfile
├── react-app/      src/, index.html, vite.config.js, package.json, Dockerfile
└── nginx-app/      index.html, Dockerfile
```

---

## Summary

| Application | Base image | Container port | Host port | Image size | Status |
|---|---|---|---|---|---|
| Node.js (Express) | `node:20-alpine` | 3000 | 8081 | 209 MB | Verified |
| Python (Flask) | `python:3.12-slim` | 5000 | 8082 | 208 MB | Verified |
| Java (JDK HttpServer) | `eclipse-temurin:21` | 8080 | 8083 | 286 MB | Verified |
| Apache (httpd) | `httpd:2.4-alpine` | 80 | 8084 | 96.1 MB | Verified |
| React (Vite + Nginx) | `nginx:1.27-alpine` | 80 | 8085 | 73.8 MB | Verified |
| Nginx | `nginx:1.27-alpine` | 80 | 8086 | 73.6 MB | Verified |

---

## Build and run

```bash
# Build all six images
docker build -t hello-nodejs:1.0 ./nodejs-app
docker build -t hello-python:1.0 ./python-app
docker build -t hello-java:1.0   ./java-app
docker build -t hello-apache:1.0 ./apache-app
docker build -t hello-react:1.0  ./react-app
docker build -t hello-nginx:1.0  ./nginx-app

# Run all six containers
docker run -d --name hello-nodejs -p 8081:3000 hello-nodejs:1.0
docker run -d --name hello-python -p 8082:5000 hello-python:1.0
docker run -d --name hello-java   -p 8083:8080 hello-java:1.0
docker run -d --name hello-apache -p 8084:80   hello-apache:1.0
docker run -d --name hello-react  -p 8085:80   hello-react:1.0
docker run -d --name hello-nginx  -p 8086:80   hello-nginx:1.0
```

### Build results

```console
REPOSITORY     TAG       SIZE
hello-react    1.0       73.8MB
hello-nginx    1.0       73.6MB
hello-apache   1.0       96.1MB
hello-java     1.0       286MB
hello-python   1.0       208MB
hello-nodejs   1.0       209MB
```

### All six containers running

```console
$ docker ps
NAMES          IMAGE              STATUS         PORTS
hello-nginx    hello-nginx:1.0    Up 6 seconds   0.0.0.0:8086->80/tcp,   [::]:8086->80/tcp
hello-react    hello-react:1.0    Up 6 seconds   0.0.0.0:8085->80/tcp,   [::]:8085->80/tcp
hello-apache   hello-apache:1.0   Up 6 seconds   0.0.0.0:8084->80/tcp,   [::]:8084->80/tcp
hello-java     hello-java:1.0     Up 7 seconds   0.0.0.0:8083->8080/tcp, [::]:8083->8080/tcp
hello-python   hello-python:1.0   Up 7 seconds   0.0.0.0:8082->5000/tcp, [::]:8082->5000/tcp
hello-nodejs   hello-nodejs:1.0   Up 7 seconds   0.0.0.0:8081->3000/tcp, [::]:8081->3000/tcp
```

---

## 1. Node.js application

Express server rendering the page and reporting the Node version and container hostname.

**Dockerfile** - copies `package.json` and installs dependencies *before* copying the source, so the `npm install` layer stays cached when only application code changes.

```dockerfile
FROM node:20-alpine
WORKDIR /usr/src/app
COPY package.json ./
RUN npm install --omit=dev
COPY server.js ./
EXPOSE 3000
CMD ["node", "server.js"]
```

![Node.js Hello World](../screenshots/01-nodejs-app.png)

---

## 2. Python application

Flask server on port 5000, reporting the Python version and container hostname.

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py ./
EXPOSE 5000
CMD ["python", "app.py"]
```

![Python Hello World](../screenshots/02-python-app.png)

---

## 3. Java application

Uses the JDK's built-in `com.sun.net.httpserver`, so no external framework or build tool is needed. The Dockerfile is **multi-stage**: it compiles with the full JDK, then ships only the compiled `.class` files on the smaller JRE image.

```dockerfile
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /build
COPY HelloWorld.java ./
RUN javac HelloWorld.java

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /build/*.class ./
EXPOSE 8080
CMD ["java", "HelloWorld"]
```

![Java Hello World](../screenshots/03-java-app.png)

---

## 4. Apache application

The `httpd` image serves whatever is in `/usr/local/apache2/htdocs`, so the whole Dockerfile is one `COPY`. The base image already starts httpd in the foreground, so no `CMD` is needed.

```dockerfile
FROM httpd:2.4-alpine
COPY index.html /usr/local/apache2/htdocs/index.html
EXPOSE 80
```

![Apache Hello World](../screenshots/04-apache-app.png)

---

## 5. React application

A real Vite + React build, not a static page. The Dockerfile is **multi-stage**: Node builds the production bundle, then only the compiled `dist/` output is copied into an Nginx image - so Node and `node_modules` never reach the final image. That is why this image is **73.8 MB** rather than several hundred.

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json ./
RUN npm install
COPY vite.config.js index.html ./
COPY src ./src
RUN npm run build

FROM nginx:1.27-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
```

The click counter in the screenshot is live React state - proof the JavaScript bundle is executing, not just being served.

![React Hello World](../screenshots/05-react-app.png)

---

## 6. Nginx application

```dockerfile
FROM nginx:1.27-alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

![Nginx Hello World](../screenshots/06-nginx-app.png)

---

## Verification - HTTP response from every application

Each container was also verified from the command line. All six return **HTTP 200**.

```console
==============================================
  nodejs-app  ->  http://localhost:8081
==============================================
$ curl -s http://localhost:8081
<!doctype html>
<html>
  <head><title>Node.js Hello World</title></head>
  <body style="font-family: system-ui, sans-serif; text-align: center; padding-top: 80px;">
    <h1>Hello World from Node.js</h1>
    <p>Served by Express inside a Docker container</p>
    <p>Node v20.20.2 &middot; host 911e2724d30b</p>
  </body>
</html>
HTTP status: 200

==============================================
  python-app  ->  http://localhost:8082
==============================================
$ curl -s http://localhost:8082
<!doctype html>
<html>
  <head><title>Python Hello World</title></head>
  <body style="font-family: system-ui, sans-serif; text-align: center; padding-top: 80px;">
    <h1>Hello World from Python</h1>
    <p>Served by Flask inside a Docker container</p>
    <p>Python 3.12.14 &middot; host 2c68177e7f71</p>
  </body>
</html>
HTTP status: 200

==============================================
  java-app  ->  http://localhost:8083
==============================================
$ curl -s http://localhost:8083
<!doctype html>
<html>
  <head><title>Java Hello World</title></head>
  <body style="font-family: system-ui, sans-serif; text-align: center; padding-top: 80px;">
    <h1>Hello World from Java</h1>
    <p>Served by the built-in JDK HttpServer inside a Docker container</p>
    <p>Java 21.0.12 &middot; host 95b01db6c231</p>
  </body>
</html>

HTTP status: 200

==============================================
  apache-app  ->  http://localhost:8084
==============================================
$ curl -s http://localhost:8084
<!doctype html>
<html>
  <head><title>Apache Hello World</title></head>
  <body style="font-family: system-ui, sans-serif; text-align: center; padding-top: 80px;">
    <h1>Hello World from Apache</h1>
    <p>Static page served by the Apache HTTP Server (httpd) inside a Docker container</p>
  </body>
</html>

HTTP status: 200

==============================================
  react-app  ->  http://localhost:8085
==============================================
$ curl -s http://localhost:8085
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>React Hello World</title>
    <script type="module" crossorigin src="/assets/index-Bw0aSBPs.js"></script>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>

HTTP status: 200

==============================================
  nginx-app  ->  http://localhost:8086
==============================================
$ curl -s http://localhost:8086
<!doctype html>
<html>
  <head><title>Nginx Hello World</title></head>
  <body style="font-family: system-ui, sans-serif; text-align: center; padding-top: 80px;">
    <h1>Hello World from Nginx</h1>
    <p>Static page served by Nginx inside a Docker container</p>
  </body>
</html>

HTTP status: 200
```

---

## What these six applications demonstrate

**Two ways to containerise an application.** The Apache and Nginx apps just `COPY` a file into an image that already knows how to serve it. The Node.js, Python and Java apps install dependencies or compile code, then define the process to run.

**Layer caching.** In the Node.js and Python Dockerfiles the dependency manifest is copied and installed *before* the source code. Docker caches each instruction as a layer and invalidates every layer after the first change, so ordering it this way means editing `server.js` does not trigger a fresh `npm install`.

**Multi-stage builds cut image size dramatically.** The React app builds with Node but ships on Nginx (73.8 MB), and the Java app compiles on the JDK but ships on the JRE. Build tools are needed to *produce* an artefact, never to *run* it - the smaller final image is faster to ship and has a smaller attack surface.

**Port mapping is explicit.** `-p 8081:3000` maps host port 8081 to container port 3000. `EXPOSE` in a Dockerfile is only documentation; the `-p` flag is what actually publishes the port.

**Containers are isolated.** Each page reports its own hostname - `911e2724d30b`, `2c68177e7f71`, `95b01db6c231` - which is the container ID. Six web servers run simultaneously on one machine, each with its own filesystem, process space and network namespace, with no port conflicts.
