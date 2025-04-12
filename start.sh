#!/bin/bash

# Kolory dla lepszej czytelności
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Dane do konfiguracji Let's Encrypt
domains=(casiopea.piwo.org)
rsa_key_size=4096
email="admin@casiopea.piwo.org"  # Zmień na swój adres e-mail
staging=0 # Ustaw na 1, aby testować konfigurację (nie generuje prawdziwych certyfikatów)
setup_letsencrypt=1 # Ustaw na 0, aby pominąć konfigurację Let's Encrypt

echo -e "${YELLOW}Pobieranie najnowszej wersji z repozytorium...${NC}"

# Sprawdzanie czy repozytorium już istnieje
if [ -d ".git" ]; then
    # Jeśli repozytorium istnieje, wykonaj git pull
    git pull origin master
else
    # Jeśli repozytorium nie istnieje, wykonaj git clone
    git clone https://github.com/elroyski/casiopea.piwo.org.git .
fi

# Sprawdzanie czy Docker jest zainstalowany
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker nie jest zainstalowany. Proszę zainstalować Docker.${NC}"
    exit 1
fi

# Sprawdzanie czy Docker Compose jest dostępny
has_docker_compose_v1=0
has_docker_compose_v2=0

if command -v docker-compose &> /dev/null; then
    has_docker_compose_v1=1
elif docker compose version &> /dev/null; then
    has_docker_compose_v2=1
else
    echo -e "${YELLOW}Docker Compose nie jest zainstalowany. Proszę zainstalować Docker Compose.${NC}"
    exit 1
fi

# Funkcja do uruchamiania docker-compose
run_docker_compose() {
    if [ $has_docker_compose_v1 -eq 1 ]; then
        docker-compose $@
    else
        docker compose $@
    fi
}

# Konfiguracja Let's Encrypt
if [ $setup_letsencrypt -eq 1 ]; then
    echo -e "${YELLOW}Konfiguracja Let's Encrypt...${NC}"
    
    # Tworzenie katalogów dla certbot
    mkdir -p certbot/conf/live/$domains
    mkdir -p certbot/www
    
    echo -e "${YELLOW}Tworzenie tymczasowego certyfikatu...${NC}"
    path="/etc/letsencrypt/live/$domains"
    # Tworzymy tymczasowy certyfikat, żeby nginx mógł wystartować
    run_docker_compose run --rm --entrypoint "\
      openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1\
        -keyout '$path/privkey.pem' \
        -out '$path/fullchain.pem' \
        -subj '/CN=localhost'" certbot
    
    echo -e "${YELLOW}Pobieranie rekomendowanych parametrów TLS...${NC}"
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > certbot/conf/options-ssl-nginx.conf
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > certbot/conf/ssl-dhparams.pem
    
    echo -e "${YELLOW}Uruchamianie kontenerów...${NC}"
    run_docker_compose up -d
    
    echo -e "${YELLOW}Usuwanie tymczasowego certyfikatu...${NC}"
    run_docker_compose run --rm --entrypoint "\
      rm -Rf /etc/letsencrypt/live/$domains" certbot
    
    echo -e "${YELLOW}Wnioskowanie o nowy certyfikat...${NC}"
    domain_args=""
    for domain in "${domains[@]}"; do
      domain_args="$domain_args -d $domain"
    done
    
    # Wybór trybu: staging/produkcja
    case "$staging" in
      0) staging_arg="--force-renewal" ;;
      1) staging_arg="--staging --force-renewal" ;;
    esac
    
    run_docker_compose run --rm --entrypoint "\
      certbot certonly --webroot -w /var/www/certbot \
        $staging_arg \
        $domain_args \
        --email $email \
        --rsa-key-size $rsa_key_size \
        --agree-tos \
        --no-eff-email" certbot
    
    echo -e "${YELLOW}Restart kontenerów...${NC}"
    run_docker_compose down
else
    echo -e "${YELLOW}Pomijanie konfiguracji Let's Encrypt...${NC}"
fi

echo -e "${YELLOW}Uruchamianie kontenerów Docker...${NC}"
run_docker_compose up -d

# Sprawdzanie czy uruchomienie się powiodło
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Kontenery zostały uruchomione pomyślnie!${NC}"
    echo -e "${GREEN}Strona jest dostępna pod adresem: http://localhost${NC}"
    
    if [ $setup_letsencrypt -eq 1 ]; then
        echo -e "${GREEN}Strona jest również dostępna pod adresem: https://casiopea.piwo.org${NC}"
    else
        echo -e "${GREEN}Docelowo strona będzie dostępna pod adresem: http://casiopea.piwo.org${NC}"
    fi
else
    echo -e "${YELLOW}Wystąpił błąd podczas uruchamiania kontenerów.${NC}"
    exit 1
fi 