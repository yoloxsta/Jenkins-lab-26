# ==========================
# Stage 1: Build React App
# ==========================
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy all source files
COPY . .

# Build the React app
RUN npm run build


# ==========================
# Stage 2: Serve with Nginx
# ==========================
FROM nginx:alpine

# Optional: Create non-root user (for security scanners)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup \
    && mkdir -p /usr/share/nginx/html \
    && chown -R appuser:appgroup /usr/share/nginx/html /var/cache/nginx /var/run /var/log/nginx

# Switch to non-root user
USER appuser

# Copy React build from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
