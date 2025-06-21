#!/bin/bash

# Ensure the script is run with root privileges if needed for Docker
if [ "$EUID" -ne 0 ]; then
  SUDO="sudo"
else
  SUDO=""
fi

# Load variables from .env into the script's current shell session.
if [ -f .env ]; then
  source ./.env
else
  echo ".env file not found. Please create one with DOMAIN and EMAIL."
  exit 1
fi

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
  echo "DOMAIN and EMAIL must be set in the .env file."
  exit 1
fi

echo "### Initializing setup for domain: $DOMAIN ###"

# Step 1: Create dummy certificate
echo "### Creating dummy certificate... ###"
# FIX: Use --env to pass the DOMAIN variable into the temporary container.
$SUDO docker compose run --rm \
  --env DOMAIN=$DOMAIN \
  --entrypoint "\
    sh -c 'mkdir -p /etc/letsencrypt/live/$DOMAIN && \
           openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
           -keyout \"/etc/letsencrypt/live/$DOMAIN/privkey.pem\" \
           -out \"/etc/letsencrypt/live/$DOMAIN/fullchain.pem\" \
           -subj \"/CN=localhost\"'" certbot
echo

# Step 2: Start Nginx
echo "### Starting Nginx... ###"
$SUDO docker compose up -d nginx
echo

# Step 3: Delete the dummy certificate
echo "### Deleting dummy certificate... ###"
# FIX: Use --env to pass the DOMAIN variable into this container as well.
$SUDO docker compose run --rm \
  --env DOMAIN=$DOMAIN \
  --entrypoint "\
    rm -Rf /etc/letsencrypt/live/$DOMAIN && \
    rm -Rf /etc/letsencrypt/archive/$DOMAIN && \
    rm -Rf /etc/letsencrypt/renewal/$DOMAIN.conf" certbot
echo

# Step 4: Request the real Let's Encrypt certificate
# This part was already correct as it uses the variables directly.
echo "### Requesting Let's Encrypt certificate for $DOMAIN... ###"
$SUDO docker compose run --rm \
  --entrypoint "\
    certbot certonly --webroot -w /var/www/certbot \
      --email $EMAIL -d $DOMAIN \
      --agree-tos --no-eff-email --force-renewal" certbot
echo

# Step 5: Stop and restart all services
echo "### Shutting down services... ###"
$SUDO docker compose down
echo
echo "### Setup complete! Starting all services... ###"
$SUDO docker compose up -d
echo "### Your secure reverse proxy is now running. ###"