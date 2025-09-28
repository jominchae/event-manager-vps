# Multi-stage build for Event Manager VPS deployment
FROM node:20-alpine AS base

# Install system dependencies
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies
COPY package.json package-lock.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy application code
COPY . .

# Build the application
FROM base AS builder
RUN npm ci
RUN npm run build

# Production image
FROM node:20-alpine AS runner
WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs
RUN adduser -S eventmanager -u 1001

# Copy production dependencies and built application
COPY --from=base /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/server ./server
COPY --from=builder /app/shared ./shared
COPY --from=builder /app/package.json ./package.json

# Create directories for file storage
RUN mkdir -p /app/uploads/public /app/uploads/private
RUN chown -R eventmanager:nodejs /app/uploads

USER eventmanager

# Expose port
EXPOSE 5000

# Environment variables
ENV NODE_ENV=production
ENV PORT=5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:5000/api/health', (res) => process.exit(res.statusCode === 200 ? 0 : 1))"

# Start the application
CMD ["node", "server/index.js"]