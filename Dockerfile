# Stage 1: Build the Vue.js application
FROM node:20.17.0-alpine3.20 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Serve the application with Nginx
FROM nginx:1.29.1-alpine-slim
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# --- THIS IS THE FIX ---
# Create the modelmanager directory and copy the built assets into it.
# This makes the container's file structure match the URL structure.
WORKDIR /usr/share/nginx/html
RUN mkdir modelmanager
COPY --from=builder /app/dist/ ./modelmanager/

EXPOSE 80