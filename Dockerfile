# Stage 1: Build the Vue.js application
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
ENV APP_BUILD_HASH=${BUILD_HASH}
RUN npm run build

# Stage 2: Serve the application with Nginx
FROM nginx:1.25-alpine
# Copy the built files from the 'dist' directory of the builder stage
COPY --from=builder /app/dist /usr/share/nginx/html
# Copy the custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
