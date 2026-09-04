# =============================================================================
#  MULTI-STAGE DOCKERFILE
#
#  Stage 1 ("builder") has the full Go toolchain (~800 MB) and compiles the
#  binary. Stage 2 starts from `scratch` (a completely empty image) and copies
#  ONLY the compiled binary out of stage 1.
#
#  The Go toolchain, the source code and the build cache never reach the final
#  image, so the shipped image is a few MB instead of several hundred.
# =============================================================================

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
