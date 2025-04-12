#!/bin/bash

# Kolory dla lepszej czytelności
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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
    echo -e "${RED}Docker nie jest zainstalowany. Proszę zainstalować Docker.${NC}"
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
    echo -e "${RED}Docker Compose nie jest zainstalowany. Proszę zainstalować Docker Compose.${NC}"
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

# Tworzenie katalogów dla certbot przed uruchomieniem
mkdir -p certbot/www/.well-known/acme-challenge
mkdir -p certbot/conf

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
            echo -e "${YELLOW}Sprawdzanie dostępności domeny...${NC}"
            
            # Sprawdzanie czy domena jest dostępna
            ip_serwera=$(curl -s ifconfig.me)
            echo -e "${YELLOW}IP tego serwera: $ip_serwera${NC}"
            
            # Zapisanie testowego pliku do katalogu certbot
            echo "testowy_plik" > certbot/www/.well-known/acme-challenge/test.txt
            
            echo -e "${YELLOW}Testowy plik został utworzony. Teraz sprawdzę, czy jest dostępny z zewnątrz...${NC}"
            echo -e "${YELLOW}Próbuję pobrać: http://$domain/.well-known/acme-challenge/test.txt${NC}"
            
            # Sprawdzenie dostępności testowego pliku
            if curl -s "http://$domain/.well-known/acme-challenge/test.txt" | grep -q "testowy_plik"; then
                echo -e "${GREEN}Domena jest poprawnie skonfigurowana i dostępna z internetu!${NC}"
            else
                echo -e "${RED}Nie można pobrać testowego pliku. Sprawdź, czy:${NC}"
                echo -e "${RED}1. Domena $domain wskazuje na IP: $ip_serwera${NC}"
                echo -e "${RED}2. Port 80 jest otwarty i przekierowany do serwera${NC}"
                echo -e "${RED}3. Firewall nie blokuje połączeń HTTP${NC}"
                
                echo -e "${YELLOW}Czy mimo to chcesz spróbować pobrać certyfikat? (t/n)${NC}"
                read -r kontynuuj
                if [[ ! "$kontynuuj" =~ ^[tT]$ ]]; then
                    echo -e "${YELLOW}Pominięto konfigurację HTTPS.${NC}"
                    exit 0
                fi
            fi
            
            echo -e "${YELLOW}Konfiguracja Let's Encrypt...${NC}"
            
            # Wybór trybu: staging/produkcja
            if [ "$staging" -eq 1 ]; then
                staging_arg="--staging"
            else
                staging_arg=""
            fi
            
            # Ustalenie sieci dla certbota
            network_name=$(run_docker_compose ps -q nginx | xargs docker inspect -f '{{range $i, $n := .NetworkSettings.Networks}}{{if eq $i 0}}{{println $i}}{{end}}{{end}}')
            if [ -z "$network_name" ]; then
                network_name="casiopeapiwoorg_casiopea-network"
            fi
            
            echo -e "${YELLOW}Używam sieci: $network_name${NC}"
            
            # Uruchamianie certbot do pobrania certyfikatu
            docker run --rm \
                -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
                -v "$(pwd)/certbot/www:/var/www/certbot" \
                --network "$network_name" \
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
                echo -e "${RED}Nie udało się pobrać certyfikatu Let's Encrypt.${NC}"
                echo -e "${RED}Upewnij się, że domena $domain wskazuje na ten serwer i port 80 jest dostępny z internetu.${NC}"
                echo -e "${YELLOW}Możesz ręcznie sprawdzić status weryfikacji:${NC}"
                echo -e "${YELLOW}curl -I http://$domain/.well-known/acme-challenge/test.txt${NC}"
            fi
        else
            echo -e "${YELLOW}Pominięto konfigurację HTTPS.${NC}"
        fi
    fi
else
    echo -e "${RED}Wystąpił błąd podczas uruchamiania kontenerów.${NC}"
    exit 1
fi 