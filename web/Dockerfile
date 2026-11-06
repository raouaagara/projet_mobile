# ─────────────────────────────────────────────
#  Stage 1 – Build Angular 18
# ─────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files first (layer-cache friendly)
COPY package.json package-lock.json ./

# Install dependencies (clean install, faster than npm install)
RUN npm ci --legacy-peer-deps

# Copy source code
COPY . .

# Build production bundle
RUN npm run build -- --configuration production

# ─────────────────────────────────────────────
#  Stage 2 – Runtime (Nginx)
# ─────────────────────────────────────────────
FROM nginx:1.27-alpine

# Remove default nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copy Angular build output
# angular.json outputPath = dist/front-freelance-app/browser (Angular 18)
COPY --from=builder /app/dist/front-freelance-app/browser /usr/share/nginx/html

# Copy custom nginx config (handles Angular routing)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
