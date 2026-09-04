# ---- Node.js Hello World ----
FROM node:20-alpine

WORKDIR /usr/src/app

# Copy manifests first so `npm install` is cached unless deps change
COPY package.json ./
RUN npm install --omit=dev

# Now copy the application source
COPY server.js ./

EXPOSE 3000
CMD ["node", "server.js"]
