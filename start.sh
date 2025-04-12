#!/bin/bash

# Kolory dla lepszej czytelności
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Dane do konfiguracji Let's Encrypt
domain="casiopea.piwo.org"
rsa_key_size=4096
email="admin@casiopea.piwo.org"  # Zmień na swój adres e-mail
staging=0 # Ustaw na 1, aby testować konfigurację (nie generuje prawdziwych certyfikatów)
setup_letsencrypt=1 # Ustaw na 0, aby pominąć konfigurację Let's Encrypt
test_cert=1 # Ustaw na 1, aby pominąć weryfikację online (generuje samopodpisany certyfikat)

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
        docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# Konfiguracja Let's Encrypt
if [ $setup_letsencrypt -eq 1 ]; then
    echo -e "${YELLOW}Konfiguracja SSL/TLS...${NC}"
    
    # Tworzenie katalogów dla certbot
    mkdir -p certbot/conf
    mkdir -p certbot/www/.well-known/acme-challenge
    
    if [ $test_cert -eq 1 ]; then
        echo -e "${YELLOW}Tworzenie samopodpisanego certyfikatu (bez weryfikacji online)...${NC}"
        
        # Tworzymy katalog dla certyfikatu
        mkdir -p certbot/conf/live/$domain
        
        # Tworzymy samopodpisany certyfikat przy użyciu openssl
        openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 365 \
            -keyout certbot/conf/live/$domain/privkey.pem \
            -out certbot/conf/live/$domain/fullchain.pem \
            -subj "/CN=$domain" \
            -addext "subjectAltName = DNS:$domain"
            
        # Tworzymy potrzebne pliki dla Nginx
        echo "" > certbot/conf/options-ssl-nginx.conf
        openssl dhparam -out certbot/conf/ssl-dhparams.pem 2048
    else
        echo -e "${YELLOW}Tworzenie tymczasowego certyfikatu...${NC}"
        
        # Tworzymy katalog dla certyfikatu
        mkdir -p certbot/conf/live/$domain
        
        # Tworzymy tymczasowy certyfikat przy użyciu openssl
        openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1 \
            -keyout certbot/conf/live/$domain/privkey.pem \
            -out certbot/conf/live/$domain/fullchain.pem \
            -subj "/CN=localhost"
        
        echo -e "${YELLOW}Pobieranie rekomendowanych parametrów TLS...${NC}"
        curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > certbot/conf/options-ssl-nginx.conf
        curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > certbot/conf/ssl-dhparams.pem
        
        echo -e "${YELLOW}Uruchamianie kontenerów...${NC}"
        run_docker_compose up -d
        
        echo -e "${YELLOW}Oczekiwanie na uruchomienie Nginx...${NC}"
        sleep 5
        
        echo -e "${YELLOW}Wnioskowanie o nowy certyfikat...${NC}"
        
        # Wybór trybu: staging/produkcja
        if [ "$staging" -eq 1 ]; then
            staging_arg="--staging"
        else
            staging_arg=""
        fi
        
        # Uruchamianie certbot do pobrania certyfikatu
        docker run --rm \
            -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
            -v "$(pwd)/certbot/www:/var/www/certbot" \
            certbot/certbot \
            certonly --webroot -w /var/www/certbot \
            $staging_arg \
            -d $domain \
            --email $email \
            --rsa-key-size $rsa_key_size \
            --agree-tos \
            --no-eff-email \
            --force-renewal
        
        if [ $? -ne 0 ]; then
            echo -e "${YELLOW}Nie udało się pobrać certyfikatu Let's Encrypt. Tworzenie samopodpisanego certyfikatu...${NC}"
            
            # Usuwamy tymczasowy certyfikat
            rm -rf certbot/conf/live/$domain
            mkdir -p certbot/conf/live/$domain
            
            # Tworzymy samopodpisany certyfikat
            openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 365 \
                -keyout certbot/conf/live/$domain/privkey.pem \
                -out certbot/conf/live/$domain/fullchain.pem \
                -subj "/CN=$domain" \
                -addext "subjectAltName = DNS:$domain"
        fi
        
        echo -e "${YELLOW}Restart kontenerów...${NC}"
        run_docker_compose down
    fi
fi

echo -e "${YELLOW}Uruchamianie kontenerów Docker...${NC}"
run_docker_compose up -d

# Sprawdzanie czy uruchomienie się powiodło
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Kontenery zostały uruchomione pomyślnie!${NC}"
    echo -e "${GREEN}Strona jest dostępna pod adresem: http://localhost${NC}"
    
    if [ $setup_letsencrypt -eq 1 ]; then
        echo -e "${GREEN}Strona jest również dostępna pod adresem: https://$domain${NC}"
        echo -e "${YELLOW}UWAGA: Jeśli używasz samopodpisanego certyfikatu, przeglądarka może wyświetlić ostrzeżenie o niezaufanym połączeniu.${NC}"
    else
        echo -e "${GREEN}Docelowo strona będzie dostępna pod adresem: http://$domain${NC}"
    fi
else
    echo -e "${YELLOW}Wystąpił błąd podczas uruchamiania kontenerów.${NC}"
    exit 1
fi 