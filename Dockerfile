# Specify a base image
FROM node:18.13.0-alpine as builder

# Set working directory to user app folder
WORKDIR '/app'

# Copy package.json and install depenendencies
COPY package.json .
RUN npm install

# Copy all the other files
COPY ./ ./

# Run Build
RUN npm run build

# Use nginx as the base image
FROM nginx:latest

# Copy the build directory to nginx
COPY --from=builder /app/build /usr/share/nginx/html