# Stage 1: Build the Vue.js application
FROM node:20.17.0-alpine3.20 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Serve the application with Nginx
FROM nginx:1.29.1-alpine-slim
# Remove the default Nginx configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy our custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the built files from the 'dist' directory of the builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Change ownership of the static files to the non-root 'nginx' user
# The nginx:alpine image already creates this user for us
RUN chown -R nginx:nginx /usr/share/nginx/html

# Expose port 80
EXPOSE 80
