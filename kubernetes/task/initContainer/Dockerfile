# Use the official NGINX image as the base
FROM nginx:alpine

# Set the working directory inside the container
WORKDIR /usr/share/nginx/html

# Create a simple index.html file for testing
RUN echo '<!DOCTYPE html><html><head><title>Custom NGINX</title></head><body><h1>Welcome to My Custom NGINX!</h1></body></html>' > index.html

# Expose port 80 for the web server
EXPOSE 80

# Start NGINX in the foreground
CMD ["nginx", "-g", "daemon off;"]