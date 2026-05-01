# Use a specific version of Node.js on Alpine for a smaller, more secure base image
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Final stage
FROM node:20-alpine

# Set secure environment
ENV NODE_ENV=production
RUN addgroup -S nodeapp && adduser -S nodeapp -G nodeapp

WORKDIR /app

# Copy from builder
COPY --from=builder /app/node_modules ./node_modules
COPY . .

# Run as non-root user
USER nodeapp

EXPOSE 3000

CMD ["node", "index.js"]
