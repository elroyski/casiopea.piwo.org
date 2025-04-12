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
    
    # Testy diagnostyczne
    echo -e "${YELLOW}Wykonuję testy diagnostyczne...${NC}"
    echo -e "Sprawdzanie lokalnego dostępu do serwera:"
    curl -I http://localhost
    
    echo -e "\nSprawdzanie dostępu przez IP:"
    ip_local=$(hostname -I | awk '{print $1}')
    echo "Lokalne IP: $ip_local"
    curl -I http://$ip_local
    
    # Sprawdzanie nazwy sieci kontenera
    container_id=$(run_docker_compose ps -q nginx)
    echo -e "\nID kontenera Nginx: $container_id"
    
    network_name=$(docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{end}}' $container_id)
    echo -e "Nazwa sieci: $network_name"
    
    # Konfiguracja Let's Encrypt
    if [ $setup_letsencrypt -eq 1 ]; then
        echo -e "${YELLOW}Czy chcesz skonfigurować HTTPS z Let's Encrypt? (t/n)${NC}"
        read -r odpowiedz
        if [[ "$odpowiedz" =~ ^[tT]$ ]]; then
            echo -e "${YELLOW}Sprawdzanie dostępności domeny...${NC}"
            
            # Sprawdzanie czy domena jest dostępna
            ip_serwera=$(curl -s ifconfig.me)
            echo -e "${YELLOW}IP tego serwera: $ip_serwera${NC}"
            
            # Tworzenie testowego pliku
            echo "testowy_plik_$(date +%s)" > certbot/www/.well-known/acme-challenge/test.txt
            echo -e "${YELLOW}Utworzono plik testowy: $(cat certbot/www/.well-known/acme-challenge/test.txt)${NC}"
            
            # Sprawdzenie uprawnień
            chmod -R 755 certbot/www
            
            echo -e "${YELLOW}Testowy plik został utworzony. Teraz sprawdzę, czy jest dostępny lokalnie...${NC}"
            echo -e "Lokalny dostęp: http://localhost/.well-known/acme-challenge/test.txt"
            curl -v http://localhost/.well-known/acme-challenge/test.txt
            
            echo -e "\n${YELLOW}Sprawdzam dostęp z zewnątrz: http://$domain/.well-known/acme-challenge/test.txt${NC}"
            curl -v --connect-timeout 10 http://$domain/.well-known/acme-challenge/test.txt
            
            echo -e "\n${YELLOW}Sprawdzanie DNS domeny...${NC}"
            host $domain
            
            echo -e "\n${YELLOW}Sprawdzenie połączenia do portu 80...${NC}"
            nc -z -v -w5 $domain 80
            
            echo -e "\n${YELLOW}Czy mimo tych testów chcesz spróbować pobrać certyfikat? (t/n)${NC}"
            read -r kontynuuj
            if [[ ! "$kontynuuj" =~ ^[tT]$ ]]; then
                echo -e "${YELLOW}Pominięto konfigurację HTTPS.${NC}"
                exit 0
            fi
            
            echo -e "${YELLOW}Konfiguracja Let's Encrypt...${NC}"
            
            # Wybór trybu: staging/produkcja
            if [ "$staging" -eq 1 ]; then
                staging_arg="--staging"
            else
                staging_arg=""
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
                
                echo -e "\n${RED}Podsumowanie problemu:${NC}"
                echo -e "1. Domena $domain powinna wskazywać na IP: $ip_serwera"
                echo -e "2. Port 80 musi być otwarty i przekierowany do tego serwera"
                echo -e "3. Firewall nie może blokować połączeń HTTP"
                echo -e "4. Router/firewall musi przekierowywać port 80 na lokalny adres IP: $ip_local"
            fi
        else
            echo -e "${YELLOW}Pominięto konfigurację HTTPS.${NC}"
        fi
    fi
else
    echo -e "${RED}Wystąpił błąd podczas uruchamiania kontenerów.${NC}"
    exit 1
fi 