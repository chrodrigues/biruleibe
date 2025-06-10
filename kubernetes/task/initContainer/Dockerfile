# Use the official NGINX image as the base
FROM nginx:alpine

WORKDIR /usr/share/nginx/html

# Copy a custom index.html file to the NGINX web root
COPY index.html /usr/share/nginx/html
# Copy custom NGINX configuration
#COPY nginx.conf /etc/nginx/conf.d/default.conf
# Ensure proper permissions for NGINX to read the file
RUN chmod 644 index.html && chown nginx:nginx index.html
# Expose port 80 for the web server
EXPOSE 80
# Start NGINX in the foreground
CMD ["nginx", "-g", "daemon off;"]