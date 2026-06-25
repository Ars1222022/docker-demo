# Use nginx web server as base image
FROM nginx:alpine

# Copy our HTML file to the web server
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80 (web server port)
EXPOSE 80
