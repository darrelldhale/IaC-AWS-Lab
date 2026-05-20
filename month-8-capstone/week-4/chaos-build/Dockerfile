FROM nginx:alpine

# Copy the custom JSON Logging config - replaces nginx default plain-text log format
COPY nginx.conf /etc/nginx/nginx.conf


# Copy the app HTML
COPY index.html /usr/share/nginx/html/index.html
