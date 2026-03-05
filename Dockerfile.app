# NanoClaw App Container
# Multi-stage build: compiles native modules and TypeScript, then strips build tools.

# Stage 1: Build
FROM node:20-slim AS builder

RUN apt-get update && apt-get install -y python3 make g++ && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Stage 2: Runtime
FROM node:20-slim

# Install Docker CLI so the app can spawn agent containers via the mounted socket
RUN apt-get update && apt-get install -y docker.io && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

# Persist data directories as volumes
RUN mkdir -p groups store data logs

CMD ["node", "dist/index.js"]
