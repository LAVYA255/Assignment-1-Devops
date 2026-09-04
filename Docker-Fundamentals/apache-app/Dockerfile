# ---- Apache HTTP Server Hello World ----
FROM httpd:2.4-alpine

# httpd serves everything in this directory by default
COPY index.html /usr/local/apache2/htdocs/index.html

EXPOSE 80
# The base image's CMD already starts httpd in the foreground
