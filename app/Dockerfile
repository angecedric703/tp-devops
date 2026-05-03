# Étape 1 : build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Étape 2 : image finale légère
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY src/ ./src/
COPY config/ ./config/
COPY package.json ./

ENV NODE_ENV=production

EXPOSE 3000

CMD ["node", "src/index.js"]
