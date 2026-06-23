# ==================================
# Stage 1 - Build React/Vite App
# ==================================

FROM node:20-alpine AS build

# Application directory
WORKDIR /app

# Copy dependency files first
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application source code
COPY . .

# Build-time environment variable
ARG VITE_API_URL

ENV VITE_API_URL=$VITE_API_URL

# Create production build
RUN npm run build

# ==================================
# Stage 2 - Serve with Nginx
# ==================================

FROM nginx:stable-alpine

# Copy built application
COPY --from=build /app/dist /usr/share/nginx/html

# Expose Nginx port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]