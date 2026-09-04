# ---- Nginx Hello World ----
FROM nginx:1.27-alpine

# nginx serves this directory by default
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
# The base image's CMD already starts nginx in the foreground
