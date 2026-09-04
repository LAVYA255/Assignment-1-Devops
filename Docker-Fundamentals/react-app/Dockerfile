# ---- React Hello World (multi-stage: build the bundle, ship only static files) ----

# Stage 1: build the production bundle with Node
FROM node:20-alpine AS builder
WORKDIR /app

COPY package.json ./
RUN npm install

COPY vite.config.js index.html ./
COPY src ./src
RUN npm run build

# Stage 2: serve the built assets with Nginx — no Node in the final image
FROM nginx:1.27-alpine
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
