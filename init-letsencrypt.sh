#!/bin/bash

# Dane do skonfigurowania
domains=(casiopea.piwo.org)
rsa_key_size=4096
email="admin@casiopea.piwo.org"  # Zmień na swój adres e-mail
staging=0 # Ustaw na 1, aby testować konfigurację (nie generuje prawdziwych certyfikatów)

# Tworzenie katalogów dla certbot
mkdir -p certbot/conf/live/$domains
mkdir -p certbot/www

echo "### Tworzenie tymczasowego certyfikatu ..."
path="/etc/letsencrypt/live/$domains"
# Tworzymy tymczasowy certyfikat, żeby nginx mógł wystartować
docker-compose run --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1\
    -keyout '$path/privkey.pem' \
    -out '$path/fullchain.pem' \
    -subj '/CN=localhost'" certbot

echo "### Pobieranie rekomendowanych parametrów TLS ..."
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > certbot/conf/options-ssl-nginx.conf
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > certbot/conf/ssl-dhparams.pem

echo "### Uruchamianie kontenerów ..."
docker-compose up -d

echo "### Usuwanie tymczasowego certyfikatu ..."
docker-compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$domains" certbot

echo "### Wnioskowanie o nowy certyfikat ..."
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Wybór trybu: staging/produkcja
case "$staging" in
  0) staging_arg="--force-renewal" ;;
  1) staging_arg="--staging --force-renewal" ;;
esac

docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $staging_arg \
    $domain_args \
    --email $email \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --no-eff-email" certbot

echo "### Restart kontenerów ..."
docker-compose down
docker-compose up -d 