#!/bin/sh
# This script is the new entrypoint for the Nginx container.
# It first generates the configuration file from the template,
# then executes the main Nginx process.

# Tell envsubst to only substitute the variables listed.
# All other variables (like Nginx's $host, $scheme) will be ignored.
# This is the most reliable way to perform the substitution.
export DOLLAR='$'
envsubst '$DOMAIN' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/conf.d/default.conf

# Start the main Nginx process.
# The 'exec' command replaces the shell process with the Nginx process,
# which is a best practice for Docker containers.
exec nginx -g 'daemon off;'
