# Docker Multi-Stage Build

**Name:** Lavya

**Enrollment Number:** 24BCS10124

---

## Task 1 — Run the Multi-Stage Dockerfile

A Go web application is compiled in a `golang` builder stage, and only the resulting static binary is copied into a `scratch` image. The application serves **`Hello World from Docker multi-stage build`** on **port 8080**.

### The multi-stage Dockerfile

```dockerfile
# ---------- Stage 1: BUILD ----------
FROM golang:1.23-alpine AS builder

WORKDIR /src

# Copy the module definition first so dependency resolution is layer-cached
COPY go.mod ./
RUN go mod download

COPY main.go ./

# CGO_ENABLED=0 produces a fully static binary, which is what lets us run it
# on `scratch` (an image with no libc and no shell at all).
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/server main.go


# ---------- Stage 2: RUNTIME ----------
FROM scratch

# Only the binary is carried across the stage boundary
COPY --from=builder /app/server /server

EXPOSE 8080
ENTRYPOINT ["/server"]
```

### Commands

```bash
docker build -t multistage-hello:1.0 .
docker run -d --name multistage-hello -p 8080:8080 multistage-hello:1.0
docker ps
curl http://localhost:8080
```

### Full output

```console
########## 1. Build the image from the MULTI-STAGE Dockerfile ##########
wsl : DEPRECATED: The legacy builder is deprecated and will be removed in a future release.
At line:1 char:581
+ ... chpad\out'; wsl -d Ubuntu -u root -- bash "$sp/build_multistage.sh" > ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (DEPRECATED: The...future release.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
            Install the buildx component to build images with BuildKit:
            https://docs.docker.com/go/buildx/

Sending build context to Docker daemon  6.656kB

Step 1/10 : FROM golang:1.23-alpine AS builder
1.23-alpine: Pulling from library/golang
Digest: sha256:383395b794dffa5b53012a212365d40c8e37109a626ca30d6151c8348d380b5f
Status: Downloaded newer image for golang:1.23-alpine
Step 2/10 : WORKDIR /src
Step 3/10 : COPY go.mod ./
Step 4/10 : RUN go mod download
[91mgo: no module dependencies to download
[0m ---> Removed intermediate container 35be420eb5c3
Step 5/10 : COPY main.go ./
Step 6/10 : RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/server main.go
Step 7/10 : FROM scratch
Step 8/10 : COPY --from=builder /app/server /server
Step 9/10 : EXPOSE 8080
Step 10/10 : ENTRYPOINT ["/server"]
Successfully built 53f7c49a38b6
Successfully tagged multistage-hello:1.0

########## 2. Build the SINGLE-STAGE equivalent for comparison ##########
DEPRECATED: The legacy builder is deprecated and will be removed in a future release.
            Install the buildx component to build images with BuildKit:
            https://docs.docker.com/go/buildx/

Sending build context to Docker daemon  6.656kB

Step 1/6 : FROM golang:1.23-alpine
Step 2/6 : WORKDIR /src
Step 3/6 : COPY go.mod main.go ./
Step 4/6 : RUN CGO_ENABLED=0 go build -o /app/server main.go
Step 5/6 : EXPOSE 8080
Step 6/6 : ENTRYPOINT ["/app/server"]
Successfully built b22297c37a3b
Successfully tagged singlestage-hello:1.0

########## 3. Compare the two image sizes ##########
REPOSITORY          TAG             SIZE
singlestage-hello   1.0             477MB
multistage-hello    1.0             7.3MB

########## 4. Run a container from the multi-stage image on port 8080 ##########

########## 5. Verify with docker ps (container running on port 8080) ##########
NAMES              IMAGE                  STATUS         PORTS
multistage-hello   multistage-hello:1.0   Up 3 seconds   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp

########## 6. Access the application inside the container ##########
$ curl -s http://localhost:8080/plain
Hello World from Docker multi-stage build

$ curl -s http://localhost:8080
<!doctype html>
<html>
  <head><title>Docker Multi-Stage Build</title></head>
  <body style="font-family: system-ui, sans-serif; text-align: center; padding-top: 80px;">
    <h1>Hello World from Docker multi-stage build</h1>
    <p>This binary was compiled in a Go builder stage and copied into a scratch image.</p>
  </body>
</html>

########## 7. Prove the final image really is empty apart from the binary ##########
$ docker history multistage-hello:1.0
IMAGE          CREATED          CREATED BY                                      SIZE      COMMENT
53f7c49a38b6   15 seconds ago   /bin/sh -c #(nop)  ENTRYPOINT ["/server"]       0B        
b3f0ce16cc53   15 seconds ago   /bin/sh -c #(nop)  EXPOSE 8080                  0B        
f99dddc64c24   15 seconds ago   /bin/sh -c #(nop) COPY file:b8aa357b02f6cc3c…   5.08MB    

$ docker run --rm --entrypoint /bin/sh multistage-hello:1.0 -c 'ls'   # there is NO shell in scratch
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "/bin/sh": stat /bin/sh: no such file or directory

Run 'docker run --help' for more information
```

---

## Task 2 — Documentation and Evidence

### Application running successfully

The browser shows the required message served from the container on port 8080:

![Multi-stage build running on port 8080](../screenshots/07-multistage-build-8080.png)

Confirmed from the command line as well:

```console
$ curl -s http://localhost:8080/plain
Hello World from Docker multi-stage build
```

### `docker ps` showing the container on port 8080

```console
$ docker ps
NAMES              IMAGE                  STATUS         PORTS
multistage-hello   multistage-hello:1.0   Up 3 seconds   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

The `PORTS` column confirms **`0.0.0.0:8080->8080/tcp`** — host port 8080 mapped to container port 8080, exactly as required.

### The size difference

The same application was also built from a single-stage Dockerfile (`Dockerfile.singlestage`, kept in this folder purely for comparison):

```console
REPOSITORY          TAG   SIZE
singlestage-hello   1.0   477MB
multistage-hello    1.0   7.3MB
```

**477 MB → 7.3 MB, a 65× reduction**, for a byte-for-byte identical application.

---

## Why multi-stage builds matter

A single-stage image keeps everything used to *build* the application: the compiler, the module cache, the source code and every intermediate artefact. None of that is needed to *run* it.

A multi-stage build draws a line between the two. `COPY --from=builder` reaches back into an earlier stage and takes only the finished artefact; everything else in that stage is discarded when the build ends.

The benefits are concrete:

- **Size** — 7.3 MB instead of 477 MB. Faster to push, pull and deploy, and much cheaper to store across many versions.
- **Security** — the final image is `scratch`: no shell, no package manager, no compiler. An attacker who reaches the container has no tools to work with. The output above shows this directly: running `/bin/sh` inside the image fails, because there is no shell in it at all.
- **No source leakage** — the Go source never reaches the shipped image.
- **Reproducibility** — the build toolchain is pinned inside the Dockerfile, so the build does not depend on what happens to be installed on the machine running it.

The same pattern appears in the other apps in this repository: the [React app](../Docker-Fundamentals/react-app/Dockerfile) builds with Node and ships on Nginx, and the [Java app](../Docker-Fundamentals/java-app/Dockerfile) compiles on the JDK and ships on the JRE.

---

## Task 3 — Deploy at Least 3 Different Types of Applications

Three application types were built and deployed as containers, each verified with a browser screenshot and an HTTP 200 response. Full details are in [Docker-Fundamentals](../Docker-Fundamentals/README.md).

| # | Type | Framework | Image | Port | Evidence |
|---|---|---|---|---|---|
| 1 | **Node.js** | Express | `hello-nodejs:1.0` | 8081 | [screenshot](../screenshots/01-nodejs-app.png) |
| 2 | **Python** | Flask | `hello-python:1.0` | 8082 | [screenshot](../screenshots/02-python-app.png) |
| 3 | **Java** | JDK HttpServer | `hello-java:1.0` | 8083 | [screenshot](../screenshots/03-java-app.png) |

Three more were deployed beyond the requirement — Apache (8084), React (8085) and Nginx (8086).

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

### Node.js

![Node.js Hello World](../screenshots/01-nodejs-app.png)

### Python

![Python Hello World](../screenshots/02-python-app.png)

### Java

![Java Hello World](../screenshots/03-java-app.png)
