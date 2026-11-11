# Step 1. Build the app with Node and keep only the packages needed to run it.
FROM node:22.23.3-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build && npm prune --omit=dev

# Step 2. Copy the built app into a small Alpine image with only the Node runtime.
FROM alpine:3.22
RUN apk add --no-cache 'nodejs~22' && addgroup -S kijani && adduser -S kijani -G kijani
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json
RUN chown -R kijani:kijani /app

# Step 3. Run as the kijani user on port 3001. The build passes in the version.
ARG APP_VERSION=dev
ENV NODE_ENV=production PORT=3001 APP_VERSION=${APP_VERSION}
USER kijani
EXPOSE 3001
HEALTHCHECK --interval=10s --start-period=30s CMD wget -qO- http://127.0.0.1:3001/health || exit 1
CMD ["node", "dist/server.js"]
