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

echo -e "${YELLOW}Uruchamianie kontenerów Docker...${NC}"
run_docker_compose up -d

# Sprawdzanie czy uruchomienie się powiodło
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Kontenery zostały uruchomione pomyślnie!${NC}"
    echo -e "${GREEN}Strona jest dostępna pod adresem: http://localhost${NC}"
    echo -e "${GREEN}Strona jest dostępna pod adresem: http://$domain${NC}"
    
    # Konfiguracja Let's Encrypt
    if [ $setup_letsencrypt -eq 1 ]; then
        echo -e "${YELLOW}Czy chcesz skonfigurować HTTPS z Let's Encrypt? (t/n)${NC}"
        read -r odpowiedz
        if [[ "$odpowiedz" =~ ^[tT]$ ]]; then
            echo -e "${YELLOW}Konfiguracja Let's Encrypt...${NC}"
            
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
                --network casiopeapiwoorg_casiopea-network \
                certbot/certbot \
                certonly --webroot -w /var/www/certbot \
                $staging_arg \
                -d $domain \
                --email $email \
                --rsa-key-size $rsa_key_size \
                --agree-tos \
                --no-eff-email
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Certyfikat Let's Encrypt został pomyślnie pobrany.${NC}"
                echo -e "${YELLOW}Restartowanie kontenerów, aby zastosować certyfikat...${NC}"
                run_docker_compose restart nginx
                echo -e "${GREEN}Strona jest teraz dostępna pod adresem: https://$domain${NC}"
            else
                echo -e "${YELLOW}Nie udało się pobrać certyfikatu Let's Encrypt.${NC}"
                echo -e "${YELLOW}Upewnij się, że domena $domain wskazuje na ten serwer i port 80 jest dostępny z internetu.${NC}"
            fi
        else
            echo -e "${YELLOW}Pominięto konfigurację HTTPS.${NC}"
        fi
    fi
else
    echo -e "${YELLOW}Wystąpił błąd podczas uruchamiania kontenerów.${NC}"
    exit 1
fi 